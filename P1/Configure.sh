#!/usr/bin/env sh

echo "[+] Installation de la configuration de base"
sudo apt update
sudo apt install -y docker.io
sudo systemctl enable docker
sudo usermod -aG docker "$USER"

sudo add-apt-repository ppa:gns3/ppa -y
sudo apt update
sudo apt install -y gns3-gui

echo "[+] Fait ! Redémarre ta session pour que le groupe docker soit pris en compte."
