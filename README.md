# Jeu-Sae5

Jeu d'énigmes coop à 2 joueurs (Godot **4.7.2**, GDScript). Le serveur est le même projet, lancé sans fenêtre.

## Installer Godot 4.7.2

Télécharge la version **Standard** sur <https://godotengine.org/download/archive/> (la version doit être identique chez tous).

| OS | Installation | Commande Godot |
|---|---|---|
| Windows | `winget install GodotEngine.GodotEngine` ou le .zip | `godot` (ou chemin du `.exe`) |
| macOS | `brew install --cask godot` | `/Applications/Godot.app/Contents/MacOS/Godot` |
| Linux | Flatpak : `flatpak install flathub org.godotengine.Godot`, ou binaire officiel | `godot` (ou `flatpak run org.godotengine.Godot`) |

## Lancer le serveur

Depuis la racine du dépôt :

```bash
godot --headless --path jeu-sae-5 -s res://Scripts/server.gd
```

Port UDP **7777** par défaut (autre port : ajouter `-- --port=9000`).

## Lancer le client

1. Ouvrir `jeu-sae-5` dans Godot.
2. Dans `Scripts/main_menu.gd`, règle `SERVER_IP` (`127.0.0.1` en local).
3. Serveur démarré, lance avec **F5** puis clique sur **Jouer**.

Test à 2 joueurs : **Debug > Run Multiple Instances > Run 2 Instances**.
