# ---------------------------------------------------------------------------------------------------
# Installation de GNS3 et de Docker sur Debian
# ---------------------------------------------------------------------------------------------------

# Cible principale : installe Docker, GNS3 et l'image Docker de FRRouting
all: gns3 docker-image
	@echo "[✓] Installation complète terminée."
	@echo "👉 Redémarre ta session pour que les changements prennent effet (accès Docker)."

# ---------------------------------------------------------------------------------------------------
# Installation de Docker
# ---------------------------------------------------------------------------------------------------

install-docker:
	@echo "[+] Installation de la configuration de base"
	sudo apt update
	sudo apt install -y docker.io
	sudo systemctl enable docker
	sudo usermod -aG docker $(USER)  # Ajout de l'utilisateur au groupe docker
	@echo "[✓] Base installée. Redémarre ta session pour que le groupe Docker soit pris en compte."

# ---------------------------------------------------------------------------------------------------
# Installation de GNS3 (dépend de l'installation de Docker)
# ---------------------------------------------------------------------------------------------------

gns3: install-docker gns3-gui docker-image
	@python3 --version
	@pip3 --version
	@echo "[✓] GNS3 GUI installé."

# ---------------------------------------------------------------------------------------------------
# Téléchargement de l'image Docker FRRouting
# ---------------------------------------------------------------------------------------------------

docker-image:
	@echo "🌐 Téléchargement de l'image FRRouting officielle..."
	@if ! docker info > /dev/null 2>&1; then \
		echo "⚠️  L'utilisateur $(USER) n'a pas encore accès à Docker."; \
		echo "👉 Redémarre ta session puis relance : make docker-image"; \
		exit 1; \
	fi
	docker pull frrouting/frr:latest
	@echo "[✓] Image Docker téléchargée."

# ---------------------------------------------------------------------------------------------------
# Installation du GNS3 GUI et de ses dépendances
# ---------------------------------------------------------------------------------------------------

gns3-gui:
	@echo "🔧 Installation des dépendances pour GNS3..."
	sudo apt update
	sudo apt install -y python3 python3-pip pipx python3-pyqt5 python3-pyqt5.qtwebsockets python3-pyqt5.qtsvg \
		qemu-system-x86 qemu-utils libvirt-clients libvirt-daemon-system virtinst software-properties-common \
		ca-certificates curl gnupg2
	@echo "[✓] Dépendances installées."

	@echo "📥 Téléchargement et installation de Dynamips..."
	wget http://ftp.us.debian.org/debian/pool/non-free/d/dynamips/dynamips_0.2.14-1_amd64.deb
	sudo dpkg -i dynamips_0.2.14-1_amd64.deb
	@echo "[✓] Dynamips installé."

	@echo "⚙️ Installation de GNS3 Server et GNS3 GUI via pipx..."
	pipx install gns3-server
	pipx install gns3-gui
	pipx ensurepath  # S'assure que pipx est correctement configuré dans le PATH
	pipx inject gns3-gui gns3-server PyQt5
	@echo "[✓] GNS3 GUI installé."

# ---------------------------------------------------------------------------------------------------
# Notes :
# - N'oublie pas de redémarrer ta session pour que Docker et GNS3 fonctionnent correctement.
# - Les étapes d'installation peuvent être modifiées en fonction de tes besoins spécifiques.
# ---------------------------------------------------------------------------------------------------
# ---------------------------------------------------------------------------------------------------
# Nettoyage des fichiers temporaires (par exemple, fichiers .deb)
# ---------------------------------------------------------------------------------------------------

clean:
	@echo "🧹 Nettoyage de l'espace de travail..."
	rm -f dynamips_0.2.14-1_amd64.deb*
	@echo "[✓] Fichiers nettoyés."
