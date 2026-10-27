**Mise en place du serveur local (uniquement pour les tests)**


## Étapes
1. Installer multipass
2. Éditer `config.env` : `GODOT_VERSION`, `GODOT_PROJECT_DIR`.
3. Créer les VMs : `./setup-vms.sh`
4. Déployer : `./deploy.sh` (Relancer ce script à chaque modification du serveur !)

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

