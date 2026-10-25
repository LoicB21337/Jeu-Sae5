# Infrastructure 2 VMs (Multipass) : serveur de jeu + services

```
Clients Godot ──HTTP 3000──► VM "jeu"      : orchestrateur Node.js + 1 Godot headless par salle
      │                         │  ▲
      └────UDP 7778-7799───────►┘  │ HTTP 4000 (clé API)
                                   ▼
                              VM "services" : API Node.js + PostgreSQL
```

- **Orchestrateur** (`orchestrator/`) : `POST /rooms` lance `godot --headless ... -- --port=XXXX` (le `server.gd` du dev gère déjà `--port=`) et renvoie `{code, host, port}`. Il suit le nombre de joueurs en lisant les logs de `server.gd`, ferme les salles vides et envoie la durée de chaque session à l'API services.
- **API services** (`services-api/`) : reçoit les sessions, les écrit dans PostgreSQL. Seule la VM "jeu" peut l'appeler (pare-feu + clé `x-api-key`). **Le schéma (`schema.sql`) est un exemple** : à remplacer par celui de la personne qui gère la base.

## Étape 0 : réseau (important pour jouer à plusieurs PC)

Par défaut, une VM Multipass n'est joignable que depuis **le PC qui l'héberge**. Pour que les autres membres de l'équipe se connectent à la VM "jeu", il faut la mettre en réseau "bridged" (le jeu utilise de l'UDP, donc la redirection de ports est à éviter) :

```bash
multipass networks                        # repérer la carte réseau (Wi-Fi / Ethernet)
multipass set local.bridged-network="<nom de la carte>"
```

Puis dans `config.env` : `NETWORK=bridged`. Si vous testez uniquement sur un seul PC, laissez `NETWORK` vide.

## Étapes

1. Éditer `config.env` : `GODOT_VERSION` (identique aux clients), `API_KEY`, `DB_PASSWORD`, `GODOT_PROJECT_DIR`.
2. Créer les VMs : `./setup-vms.sh`
3. Déployer : `./deploy.sh` (relançable à chaque modification du code ou du projet Godot)

Sous Windows, lancer les scripts depuis **Git Bash** ou **WSL** (avec `multipass.exe` dans le PATH).

À la fin, `deploy.sh` affiche l'IP à utiliser dans le client.

## Tests

```bash
curl http://<IP_VM_JEU>:3000/health
curl -X POST http://<IP_VM_JEU>:3000/rooms            # -> {"code":"K7QM","host":"...","port":7778}
curl -X POST http://<IP_VM_JEU>:3000/rooms/K7QM/join  # -> 200, ou 409 si la salle est pleine

multipass exec jeu -- journalctl -u orchestrator -f       # logs de l'orchestrateur
multipass exec services -- journalctl -u services-api -f  # logs de l'API
multipass exec services -- sudo -u postgres psql jeu -c "SELECT * FROM sessions;"
```

## Côté client Godot (à faire par les devs)

1. Remplacer `Scripts/main_menu.gd` par `godot/main_menu.gd` et ajouter dans `main_menu.tscn` : un `HTTPRequest`, un `LineEdit` (`code_input`), un bouton `join` et un `Label` (`status`). Régler `LOBBY_URL`.
2. **Afficher le code de salle** au joueur qui crée la partie (le menu est quitté dès la connexion) : par exemple le stocker dans un autoload et l'afficher dans le menu pause, pour que le 2e joueur puisse le saisir.
3. `test_multi.gd` n'est plus utile : il se connecte en dur à `127.0.0.1:7777`.

## Ce qui a été vérifié, et ce qui ne l'a pas été

- **Testé** : la logique de l'orchestrateur (création, join, salle pleine 409, salle inconnue 404, fermeture d'une salle vide, envoi de la session) avec un faux Godot ; l'authentification et la validation de l'API services ; la syntaxe des scripts bash et des fichiers cloud-init.
- **Non testé** : l'exécution sur de vraies VMs Multipass, le téléchargement du binaire Godot, et les requêtes SQL sur un PostgreSQL réel. Au premier lancement, surveillez `deploy.sh` et corrigez si besoin (URL de Godot, noms de paquets).

## Points d'attention

- **URL de Godot** : `GODOT_URL` suppose le pattern `releases/download/<version>-stable/Godot_v<version>-stable_linux.x86_64.zip`. Vérifiez qu'il existe pour votre version (le README du jeu dit 4.7.2, `project.godot` dit 4.8 : à trancher).
- **Binaire éditeur requis** : l'orchestrateur lit la sortie standard de Godot. Avec le binaire standard (celui du README) c'est instantané ; un export "release" bufferiserait les logs et casserait le comptage des joueurs.
- **Salles** : 22 salles max (ports 7778-7799). Une salle sans joueur est fermée après 30 s, une salle jamais rejointe après 5 min, et toute salle après 2 h.
- **Sécurité** : changez `API_KEY` et `DB_PASSWORD` (lettres/chiffres uniquement). La base n'écoute que sur `127.0.0.1` de la VM "services", et l'API n'accepte que l'IP de la VM "jeu".
- **IP des VMs** : si la VM "jeu" reçoit une nouvelle IP après un redémarrage, relancez `./deploy.sh` (il relit les IPs) et mettez à jour `LOBBY_URL` dans le client.
