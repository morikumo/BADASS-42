all: build-images

# ---------------------------------------------------------------------------------------------------
# Build les images docker pour la p1
# ---------------------------------------------------------------------------------------------------
build-images-docker-P1:
	@echo "🔨 Construction des images Docker..."
	docker build -f ./P1/router_mabid -t router-mabid .
	docker build -f ./P1/host_mabid -t host-mabid .
	@echo "[✓] Images Docker construites."


# ---------------------------------------------------------------------------------------------------
# Build les images docker pour la p3
# ---------------------------------------------------------------------------------------------------
build-images-docker-P3:
	@echo "🔨 Construction des images Docker..."
	docker build -f ./P3/router_mabid -t router-mabid .
	docker build -f ./P1/host_mabid -t host-mabid .
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

