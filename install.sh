#!/bin/bash
# FireDNG – Installation über das Terminal (Hot Media Haus)
#
#   Installieren:   curl -fsSL https://raw.githubusercontent.com/Lauserich/firedng-releases/main/install.sh | bash
#   Entfernen:      curl -fsSL https://raw.githubusercontent.com/Lauserich/firedng-releases/main/install.sh | bash -s -- --uninstall
#   Nur prüfen:     … | bash -s -- --dry-run      (lädt und prüft alles, installiert nicht)
#
# Lädt die neueste Version von GitHub, prüft die Signatur der Versionsinformation (ECDSA P-256,
# derselbe Schlüssel wie das Auto-Update im Plugin) und die Prüfsumme des Pakets und installiert
# es mit dem macOS-Installer. Fragt dafür nach dem Admin-Passwort.
set -euo pipefail

REPO="Lauserich/firedng-releases"
BASE="${FIREDNG_BASE_URL:-https://github.com/$REPO/releases/latest/download}"
MEDIACORE="/Library/Application Support/Adobe/Common/Plug-ins/7.0/MediaCore"
PUBKEY="-----BEGIN PUBLIC KEY-----
MFkwEwYHKoZIzj0CAQYIKoZIzj0DAQcDQgAESPPpxn09G2A2pnkRBnpCLMy/GSWy
+POIcTL0EyoxhbmDNVlEcfUjudx2Saj2KDZnJnpm9q60BnwzByyJvfueGQ==
-----END PUBLIC KEY-----"

if [ -t 1 ]; then B=$'\e[1m'; R=$'\e[31m'; G=$'\e[32m'; N=$'\e[0m'; else B= R= G= N=; fi
say()  { printf '%s\n' "$*"; }
fail() { printf '%sFehler:%s %s\n' "$R" "$N" "$*" >&2; exit 1; }

MODE="install"
case "${1:-}" in
  --uninstall) MODE="uninstall" ;;
  --dry-run)   MODE="dry-run" ;;
  "")          ;;
  *)           fail "Unbekannte Option: $1 (erlaubt: --uninstall, --dry-run)" ;;
esac

say "${B}FireDNG${N} – CinemaDNG-Importer für Adobe Premiere Pro"
say ""

if [ "$MODE" = "uninstall" ]; then
  say "FireDNG wird entfernt (Admin-Passwort nötig) …"
  sudo rm -rf "$MEDIACORE/FireDNG" "$MEDIACORE/FireDNG_Importer.bundle" "$MEDIACORE/FireDNG_SourceSettings.plugin" \
              "$MEDIACORE/fpdng" "$MEDIACORE/fpdng_importer.bundle" "$MEDIACORE/fpdng_source_settings.plugin"
  sudo pkgutil --forget de.firedng.premiere >/dev/null 2>&1 || true
  say "${G}Fertig.${N} Premiere Pro neu starten."
  exit 0
fi

# Voraussetzungen
[ "$(uname -s)" = "Darwin" ] || fail "FireDNG gibt es nur für macOS."
[ "$(uname -m)" = "arm64" ] || [ "$(sysctl -n sysctl.proc_translated 2>/dev/null || echo 0)" = "1" ] \
  || fail "FireDNG braucht einen Mac mit Apple Silicon (M1 oder neuer)."
MACOS="$(sw_vers -productVersion)"
[ "${MACOS%%.*}" -ge 13 ] || fail "FireDNG braucht macOS 13 oder neuer (installiert: $MACOS)."

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

say "Lade Versionsinformation …"
curl -fsSL "$BASE/latest.json" -o "$TMP/latest.json"     || fail "Versionsinformation nicht erreichbar (Internet?)."
curl -fsSL "$BASE/latest.json.sig" -o "$TMP/latest.json.sig" || fail "Signatur nicht erreichbar."
printf '%s\n' "$PUBKEY" > "$TMP/pub.pem"
openssl dgst -sha256 -verify "$TMP/pub.pem" -signature "$TMP/latest.json.sig" "$TMP/latest.json" >/dev/null 2>&1 \
  || fail "Die Versionsinformation ist nicht korrekt signiert – Abbruch, es wurde nichts installiert."

field() { plutil -extract "$1" raw -o - "$TMP/latest.json" 2>/dev/null || true; }
VERSION="$(field version)"
PKG_URL="$(field pkg_url)"
SHA="$(field sha256 | tr 'A-F' 'a-f')"
[ -n "$VERSION" ] && [ ${#SHA} -eq 64 ] || fail "Versionsinformation unvollständig."
case "$PKG_URL" in
  https://github.com/$REPO/*) ;;
  http://127.0.0.1*|http://localhost*) [ -n "${FIREDNG_BASE_URL:-}" ] || fail "Unerwartete Paket-Adresse." ;;
  *) fail "Unerwartete Paket-Adresse: $PKG_URL" ;;
esac

say "Lade FireDNG $VERSION …"
curl -fSL --progress-bar "$PKG_URL" -o "$TMP/FireDNG.pkg" || fail "Download fehlgeschlagen."
GOT="$(shasum -a 256 "$TMP/FireDNG.pkg" | cut -d' ' -f1)"
[ "$GOT" = "$SHA" ] || fail "Prüfsumme stimmt nicht – Paket beschädigt oder verändert. Nichts installiert."
say "${G}Signatur und Prüfsumme geprüft.${N}"

if [ "$MODE" = "dry-run" ]; then
  say "Probelauf: FireDNG $VERSION wäre jetzt installiert worden."
  exit 0
fi

if pgrep -qf "Adobe Premiere Pro" 2>/dev/null; then
  say "Hinweis: Premiere Pro läuft gerade – nach der Installation neu starten."
fi
say ""
say "Installiere FireDNG $VERSION (Admin-Passwort nötig) …"
sudo installer -pkg "$TMP/FireDNG.pkg" -target / >/dev/null || fail "Installation fehlgeschlagen."
say ""
say "${G}FireDNG $VERSION ist installiert.${N} Premiere Pro (neu) starten."
say "Import: das erste DNG eines Clip-Ordners importieren, ohne „Bildsequenz“-Häkchen."
