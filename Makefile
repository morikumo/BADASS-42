all: build-images

# ---------------------------------------------------------------------------------------------------
# Build les images docker pour le host et le routeur
# ---------------------------------------------------------------------------------------------------
build-images-docker:
	@echo "🔨 Construction des images Docker..."
	docker build -f ./P1/router_mabid -t router-mabid .
	docker build -f ./P1/host_mabid -t host-mabid .
	@echo "[✓] Images Docker construites."


# ---------------------------------------------------------------------------------------------------
# Affiche le status des conteneurs, images, volumes et réseaux Docker
# ---------------------------------------------------------------------------------------------------

docker-status:
	@echo "📦 Conteneurs en cours d'exécution :"
	docker ps
	@echo ""
	@echo "📦 Tous les conteneurs :"
	docker ps -a
	@echo ""
	@echo "🖼️  Images Docker :"
	docker images
	@echo ""
	@echo "💾 Volumes Docker :"
	docker volume ls

# ---------------------------------------------------------------------------------------------------
# Nettoie les conteneurs, images, volumes et réseaux Docker pour libérer de l'espace et repartir sur une base propre
# ---------------------------------------------------------------------------------------------------

clean:
	@echo "🧹 Nettoyage de l'espace de travail..."
	docker volume prune --force
	docker network prune --force
	docker image prune --all --force
	docker rm -f $(docker ps -aq)
	docker rmi -f $(docker images)
	@echo "[✓] Docker et fichiers nettoyés."

