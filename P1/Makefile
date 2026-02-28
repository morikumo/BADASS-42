all: build-images

# ---------------------------------------------------------------------------------------------------
# Build les images docker
# ---------------------------------------------------------------------------------------------------
build-images:
	@echo "🔨 Construction des images Docker..."
	docker build -f router_mabid -t router-mabid .
	docker build -f host_mabid -t host-mabid .
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
	docker volume prune --force
	docker network prune --force
	docker image prune --all --force
	docker rm -f $(docker ps -aq)
	docker rmi -f $(docker images)
	@echo "[✓] Docker et fichiers nettoyés."

