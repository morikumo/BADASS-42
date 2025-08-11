.PHONY: all base gns3 docker-image

all: base gns3 docker-image
	@echo "[✓] Installation complète terminée."
	@echo "👉 Redémarre ta session pour que les changements prennent effet (accès Docker)."

install-docker:
	@echo "[+] Installation de la configuration de base"
	sudo apt update
	sudo apt install -y docker.io
	sudo systemctl enable docker
	sudo usermod -aG $(USER)
	@echo "[+] Base installée. Redémarre ta session pour que le groupe docker soit pris en compte."

OS := $(shell uname)
ARCH := $(shell uname -m)

install_debian_common:
	sudo apt update
	sudo apt install -y python3 python3-pip pipx python3-pyqt5 python3-pyqt5.qtwebsockets python3-pyqt5.qtsvg qemu-utils libvirt-clients libvirt-daemon-system virtinst software-properties-common ca-certificates curl gnupg2

install_debian_arm:
	$(MAKE) install_debian_common
	sudo apt install -y qemu-system-arm
	sudo apt install python3-pyqt5
	@echo "Note : dynamips n'est pas disponible sur ARM, veuillez l'installer manuellement si nécessaire."
	pipx install gns3-server
	pipx install gns3-gui
	pipx inject gns3-gui gns3-server sip

install_debian_x86_64:
	$(MAKE) install_debian_common
	sudo apt install -y qemu-kvm dynamips
	pipx install gns3-server
	pipx install gns3-gui
	pipx inject gns3-gui gns3-server PyQt5

install_macos:
	brew update
	brew install python3 pipx pyqt qemu libvirt virt-manager dynamips curl gnupg
	pipx install gns3-server
	pipx install gns3-gui
	pipx inject gns3-gui gns3-server PyQt5

install_gns3:
ifeq ($(OS),Linux)
	ifeq ($(ARCH),aarch64)
		$(MAKE) install_debian_arm
	else ifeq ($(ARCH),x86_64)
		$(MAKE) install_debian_x86_64
	else
		$(error Architecture Linux $(ARCH) non supportée)
	endif
else ifeq ($(OS),Darwin)
	$(MAKE) install_macos
else
	$(error OS $(OS) non supporté)
endif

gns3: install_gns3
	@python3 --version
	@pip3 --version
	@echo "[✓] GNS3 GUI installé."


docker-image:
	@echo "🌐 Téléchargement de l'image FRRouting officielle..."
	@if ! docker info > /dev/null 2>&1; then \
		echo "⚠️  L'utilisateur $(USER) n'a pas encore accès à Docker."; \
		echo "👉 Redémarre ta session puis relance : make docker-image"; \
		exit 1; \
	fi
	docker pull frrouting/frr:latest
	@echo "[✓] Image Docker téléchargée."
