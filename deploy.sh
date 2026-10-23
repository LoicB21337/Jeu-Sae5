#!/usr/bin/env bash
set -euo pipefail
export MSYS_NO_PATHCONV=1
cd "$(dirname "$0")"
source ./config.env

ips() { multipass exec "$1" -- hostname -I | tr ' ' '\n' | grep -E '^[0-9]+\.' || true; }

SERVICES_IP=$(ips services | head -n1)
JEU_INTERNAL_IP=$(ips jeu | head -n1)
if [ -n "${NETWORK:-}" ]; then PUBLIC_HOST=$(ips jeu | tail -n1); else PUBLIC_HOST=$JEU_INTERNAL_IP; fi
echo "services=$SERVICES_IP  jeu(interne)=$JEU_INTERNAL_IP  jeu(public, vu par les clients)=$PUBLIC_HOST"

rm -rf build && mkdir -p build/services build/jeu

cp -r services-api build/services/services-api
cp systemd/services-api.service build/services/
cat > build/services/.env <<ENV
PORT=4000
API_KEY=$API_KEY
DB_HOST=127.0.0.1
DB_PORT=5432
DB_USER=jeu
DB_PASSWORD=$DB_PASSWORD
DB_NAME=jeu
JEU_IP=$JEU_INTERNAL_IP
ENV
cat > build/services/install.sh <<'INSTALL'
#!/usr/bin/env bash
set -euo pipefail
cd ~/deploy
set -a; . ./.env; set +a

# Base de données
sudo -u postgres psql -tc "SELECT 1 FROM pg_roles WHERE rolname='$DB_USER'" | grep -q 1 \
  || sudo -u postgres psql -c "CREATE USER $DB_USER WITH PASSWORD '$DB_PASSWORD'"
sudo -u postgres psql -tc "SELECT 1 FROM pg_database WHERE datname='$DB_NAME'" | grep -q 1 \
  || sudo -u postgres createdb -O "$DB_USER" "$DB_NAME"
PGPASSWORD="$DB_PASSWORD" psql -h 127.0.0.1 -U "$DB_USER" -d "$DB_NAME" -f services-api/schema.sql

# API
rm -rf ~/services-api && cp -r services-api ~/services-api && cp .env ~/services-api/.env
(cd ~/services-api && npm install --omit=dev)
sudo cp services-api.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable services-api
sudo systemctl restart services-api

# Pare-feu : SSH + API accessible uniquement depuis la VM "jeu"
sudo ufw allow 22/tcp
sudo ufw allow from "$JEU_IP" to any port 4000 proto tcp
sudo ufw --force enable
INSTALL

cp -r orchestrator build/jeu/orchestrator
cp systemd/orchestrator.service build/jeu/
echo ">> Copie du projet Godot (sans le cache .godot)"
mkdir -p build/jeu/project
tar -C "$GODOT_PROJECT_DIR" --exclude=.godot -cf - . | tar -C build/jeu/project -xf -
cat > build/jeu/.env <<ENV
PORT=3000
PUBLIC_HOST=$PUBLIC_HOST
GODOT_BIN=/usr/local/bin/godot
GODOT_PROJECT=/home/ubuntu/jeu-project
PORT_MIN=7778
PORT_MAX=7799
SERVICES_URL=http://$SERVICES_IP:4000
API_KEY=$API_KEY
GODOT_URL=$GODOT_URL
ENV
cat > build/jeu/install.sh <<'INSTALL'
#!/usr/bin/env bash
set -euo pipefail
cd ~/deploy
set -a; . ./.env; set +a

# Godot (une seule fois)
if [ ! -x /usr/local/bin/godot ]; then
  curl -fL "$GODOT_URL" -o /tmp/godot.zip
  rm -rf /tmp/godot && unzip -o /tmp/godot.zip -d /tmp/godot
  sudo install -m 755 /tmp/godot/Godot_v*_linux.x86_64 /usr/local/bin/godot
fi

# Projet Godot + import des ressources (génère le dossier .godot côté Linux)
rm -rf ~/jeu-project && cp -r project ~/jeu-project
godot --headless --path ~/jeu-project --import || true

# Orchestrateur
rm -rf ~/orchestrator && cp -r orchestrator ~/orchestrator && cp .env ~/orchestrator/.env
(cd ~/orchestrator && npm install --omit=dev)
sudo cp orchestrator.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable orchestrator
sudo systemctl restart orchestrator

# Pare-feu : SSH, lobby HTTP, ports de jeu UDP
sudo ufw allow 22/tcp
sudo ufw allow 3000/tcp
sudo ufw allow 7778:7799/udp
sudo ufw --force enable
INSTALL

deliver() {  # $1 = nom de la VM, $2 = dossier build/<x>
  tar czf "build/$1.tgz" -C "$2" .
  multipass transfer "build/$1.tgz" "$1:/home/ubuntu/$1.tgz"
  multipass exec "$1" -- bash -c "rm -rf ~/deploy && mkdir ~/deploy && tar xzf ~/$1.tgz -C ~/deploy && bash ~/deploy/install.sh"
}

echo ">> Déploiement sur 'services'"; deliver services build/services
echo ">> Déploiement sur 'jeu'";      deliver jeu build/jeu

echo
echo "Terminé. Tests :"
echo "  curl http://$PUBLIC_HOST:3000/health"
echo "  curl -X POST http://$PUBLIC_HOST:3000/rooms"
echo "Dans le client Godot, mettre LOBBY_URL = \"http://$PUBLIC_HOST:3000\""
