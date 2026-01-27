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
# Installation du GNS3 GUI et de ses dépendances (Débian)
# ---------------------------------------------------------------------------------------------------

gns3-gui:
	@echo "🔧 Installation des dépendances pour GNS3..."
	sudo add-apt-repository ppa:gns3/ppa
	sudo apt update                                
	sudo apt install gns3-gui gns3-server
	sudo apt remove docker docker-engine docker.io
	sudo snap remove docker
	sudo apt-get install apt-transport-https ca-certificates curl software-properties-common
	@echo "[✓] Dépendances installées."
	curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
	sudo apt update
	sudo apt install docker-ce
	sudo usermod -aG ubridge,libvirt,kvm,wireshark,docker $(whoami)
	@echo "[✓] GNS3 GUI installé."


# ---------------------------------------------------------------------------------------------------
# Build les images docker
# ---------------------------------------------------------------------------------------------------
build-images:
	@echo "🔨 Construction des images Docker..."
	docker build -f router_mabid -t router-mabid-p1 .
	docker build -f host_mabid -t host-mabid-p1 .
	@echo "[✓] Images Docker construites."


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
	rm -f *.deb *venv
	docker rmi -f $(docker images)
	docker volume prune --force
	docker network prune --force
	docker image prune --all --force
	docker rm -f $(docker ps -aq)
	@echo "[✓] Docker et fichiers nettoyés."

