#!/bin/bash

# --- Kolory dla lepszego humoru ---
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' 

echo -e "${GREEN}Szykuj kawę, naprawiam SSH na Twoim Debianie 12...${NC}"

# 1. Sprawdzenie czy masz uprawnienia roota (bo bez tego ani rusz)
if [ "$EUID" -ne 0 ]; then 
  echo -e "${RED}Musisz odpalić to z sudo, kolego!${NC}"
  exit
fi

# 2. Upewnienie się, że katalog .ssh istnieje i ma dobre humory (uprawnienia)
USER_HOME=$(eval echo "~$SUDO_USER")
SSH_DIR="$USER_HOME/.ssh"

if [ ! -d "$SSH_DIR" ]; then
    echo "Tworzę brakujący katalog .ssh..."
    mkdir -p "$SSH_DIR"
fi

# SSH jest jak introwertyk - nienawidzi, gdy inni zaglądają mu w papiery
chmod 700 "$SSH_DIR"
chown $SUDO_USER:$SUDO_USER "$SSH_DIR"

# 3. Naprawa uprawnień kluczy (jeśli istnieją)
if ls "$SSH_DIR"/id_* 1> /dev/null 2>&1; then
    echo "Pacyfikuję uprawnienia kluczy prywatnych..."
    chmod 600 "$SSH_DIR"/id_*
    chmod 644 "$SSH_DIR"/*.pub 2>/dev/null
    chown $SUDO_USER:$SUDO_USER "$SSH_DIR"/*
else
    echo -e "${RED}Brak kluczy! Generuję parę ED25519 (bo są szybkie i bezpieczne)...${NC}"
    sudo -u $SUDO_USER ssh-keygen -t ed25519 -f "$SSH_DIR/id_ed25519" -N ""
fi

# 4. Sprawdzenie pliku authorized_keys
AUTH_KEYS="$SSH_DIR/authorized_keys"
if [ ! -f "$AUTH_KEYS" ]; then
    touch "$AUTH_KEYS"
    chmod 600 "$AUTH_KEYS"
    chown $SUDO_USER:$SUDO_USER "$AUTH_KEYS"
fi

# 5. Konfiguracja serwera SSH (Debian 12)
echo "Odświeżam konfigurację serwera..."
# Upewniamy się, że logowanie kluczem jest włączone
sed -i 's/^#\?PubkeyAuthentication.*/PubkeyAuthentication yes/' /etc/ssh/sshd_config

# 6. Restart usługi - moment prawdy
systemctl restart ssh

if systemctl is-active --quiet ssh; then
    echo -e "${GREEN}Sukces! SSH mruczy jak zadowolony kot.${NC}"
else
    echo -e "${RED}Coś poszło nie tak. Sprawdź 'journalctl -u ssh'${NC}"
fi

echo -e "\nTwoje IP to: $(hostname -I | awk '{print $1}')"
echo "Możesz teraz spróbować się zalogować."