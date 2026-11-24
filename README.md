# FireDNG – Installer und Updates

CinemaDNG-Importer für Adobe Premiere Pro (Sigma fp / Pixboom Spark) von Hot Media Haus.
Mac mit Apple Silicon, macOS 13 oder neuer, Premiere Pro 2026/2027.

## Installieren

Im Terminal:

```bash
curl -fsSL https://raw.githubusercontent.com/Lauserich/firedng-releases/main/install.sh | bash
```

Oder unter **Releases** die neueste `FireDNG-<Version>.dmg` laden, öffnen und
„FireDNG installieren.pkg“ starten.

Entfernen:

```bash
curl -fsSL https://raw.githubusercontent.com/Lauserich/firedng-releases/main/install.sh | bash -s -- --uninstall
```

Findet der Installer einen anderen CinemaDNG-Importer (z. B. OCTOPUS RAW Studio), fragt er, ob er ihn
deaktivieren soll – er wird dann nur beiseitegelegt, nicht gelöscht. Nur diese Prüfung:

```bash
curl -fsSL https://raw.githubusercontent.com/Lauserich/firedng-releases/main/install.sh | bash -s -- --check-importers
```

Der Installer prüft die Signatur der Versionsinformation und die Prüfsumme des Pakets, bevor er
installiert. Installierte Plugins suchen selbst nach Updates (Source Settings → „Nach Updates suchen“).
