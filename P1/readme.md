# Partie 1 -  GNS3 configuration with Docker

## Dans notre cas nous allons faire un makefile qui va nous installé tout notre atirail pour la p1

Ici nous allons expliqué le makefile étapes par étapes, ainsi que la configuration choisi actuellement.

### Docker

Première étape aprés avoir instancié la machien viruel sur *Debian* (obligatoire pour cette config), on installe Docker comme demandé :

```sh
# ---------------------------------------------------------------------------------------------------
# Installation de Docker
# ---------------------------------------------------------------------------------------------------

install-docker:
	sudo apt update
	sudo apt install -y docker.io
	sudo systemctl enable docker
	sudo usermod -aG docker $(USER)  # Ajout de l'utilisateur au groupe docker
```

On va simplement installé docker et l'appliqué à notre liste de groupe pour ne pas etre en "permission denied".

Une fois ça fait étape suivante.

### GNS3

Ici tout simplement on ve se referer à la documentation officiel sur le sujet.

Link : [text](https://docs.gns3.com/docs/getting-started/installation/linux/)


```sh
# ---------------------------------------------------------------------------------------------------
# Installation du GNS3 GUI et de ses dépendances (Débian)
# ---------------------------------------------------------------------------------------------------

gns3-gui:
	sudo apt update
	sudo apt install -y python3 python3-pip pipx python3-pyqt5 python3-pyqt5.qtwebsockets python3-pyqt5.qtsvg \
	qemu-system-x86 qemu-utils libvirt-clients libvirt-daemon-system virtinst software-properties-common \
	ca-certificates curl gnupg2
	pipx install gns3-server
	pipx install gns3-gui
	#pipx ensurepath  # S'assure que pipx est correctement configuré dans le PATH en commentaire pour le moment
	pipx inject gns3-gui gns3-server PyQt5
```

Ici tout simplement installation de toutes les dépendances propres a GNS3 et enfin l'outil souhaité.

J'ai eu quelques soucis avec la dépandance *software-properties-common* qui n'était pas trouvé avec les sources actuel de debian.
En ajoutant une sources supplémentaires officiel via le site des packages debian nous pouvons maintenant l'installer.
Il va donc falloir ajouter au source de apt notre nouvelle source pour qu'il aille la trouver la bas:

```sh
sudo nano /etc/apt/sources.list
```
Et dans le fichier on ajoute comme nouvelle source:

```sh
deb http://ftp.de.debian.org/debian sid main 
```

Link : [text](https://packages.debian.org/fr/sid/all/software-properties-common/download)

Une fois ça fait on peut lancer la commande gns3 pour un premier aperçu.

### Docker images with attributes

Selon le sujet deux images docker doivent-etre faites et doivent tourner sur GNS3.

Une première image qui dois tourner sur un system avec au minimum busybox dedans.

Busybox sera une boite à outils qui contient les commande de base pour un bon fonctionnement sur Linux.

Elle va etre notre host :

```dockerfile
FROM alpine:latest
RUN apk update && \
    apk add util-linux && \
    apk add busybox-static
```

Et notre seconde image qui elle aura plus de configuaration que la précedente.

On va la considerer comme notre routeur :

```dockerfile
FROM frrouting/frr

ENV DAEMONS="zebra bgpd ospfd isisd"

RUN apk update && \
    apk add util-linux && \
    apk add busybox-static

COPY ./daemons.conf /etc/frr/daemons
```

Ici notre image va se basé sur frrouting.

Qu'est ce que Frrouting :

FRRouting (FRR) est un logiciel libre qui permet à un ordinateur sous Linux/Unix de faire du routage réseau, c’est-à-dire de décider par où faire passer les paquets sur un réseau, grâce à des protocoles comme BGP. Il est surtout utilisé pour transformer une machine (serveur, VM, conteneur dans notre cas) en routeur réel, aussi bien dans des réseaux d’entreprise que chez des fournisseurs d’accès Internet.

Il va donc falloir lui ouvrir quelque deamon pour agir en arrière plan et envoyé ces fameux paquets.

Ici on donne via la commande "ENV" les deamons cité dans le sujet.

On installe busybox pour avoir les commandes de base dans cette images aussi.

Enfin on copie la configuration de nos deamon dans notre conteneur.

En parlant de cette config...

### Fichier de configuration

Ici ça sera notre deamons.conf, que l'on peut retrouver dans l'arborescence de p1.

On va se concentrer sur les services activés:

```conf
zebra=yes
bgpd=yes
ospfd=yes
isisd=yes
vtysh_enable=yes
```

Ce fichier sert à activer ou désactiver les protocoles de routage FRRouting selon les besoins : ici, zebra (le cœur), BGP, OSPF et IS-IS sont activés, tandis que les autres protocoles ne sont pas utilisés. Tous ces services sont lancés automatiquement au démarrage via zebra, et l’option vtysh_enable=yes permet de charger et gérer facilement la configuration avec l’outil de commande FRR.

Avec cette configuration nous allons pouvoir démarré gns3 et finir cette partie 1.


Au démarrage de GNS3, on essaye d'incorporer nos images via Edit > Preferences > Docker Container > ADD.

Une fois ça fait on peut le trouver dans l'ensemble des devices, et on l'ajoute au milieu pour nos services disponibles à utiliser.

On démarre le container via GNS3 et la ... Problème avec busybox.

Attention en plus d'etre présent dans les images il doit aussi etre présent sur la machine donc :
```sh
sudo apt install busybox-static
```

Super on n'as plus l'erreur lorsque l'on le lance, mais cette fois problème avecc uBridge, donc:

```sh
sudo apt update
sudo apt install -y git build-essential libpcap-dev
git clone https://github.com/GNS3/ubridge.git
cd ubridge
make
sudo make install
ubridge -v
```

Une fois ça installé on teste une nouvelle fois, et ça marche enfin.


### GNS3

Bon maintenant on peut agir sur GNS3.

On lance la commande:

```sh
gns3
```

L'interface s'ouvre, on crée un projet et on fait la manip cité ultérieurement : Edit > Preferences > Docker Container > New

On choisie le tout par défaut.

On va sur "Browse all device", on choisi nos container que l'on mets au milieu pouis clique droit pour changer la config.

On choisi la config suivante :

- On ne touche que a "Maximum memory" et "Auxilary console type"
- Maximum memory : 256MB
- Auxilary console type : telnet

Et on les mets au milieu avant de les lancer et clique droit pour auxilary console.

On va essayer d'avoir la meme configue que sur le sujet c'est a dire:


Ce qui n'est pas le cas, il va falloir lancer vtysh pour avoir la meme config, donc on le fait :

```sh
vtysh
```

output:
```sh
Can't open configuration file /etc/frr/vtysh.conf due to 'No such file or directory'
```

Hmm, il va nous falloir de la config supplémentaire pour ça, en cherchant sur internet on a :

Link : [text](https://github.com/sonic-net/sonic-frr/blob/master/vtysh/vtysh.conf.sample)

On ajoute donc notre config a notre dossier P1 et on ajoute au dockerfile une copie de celui-ci.

Enfin on lance nos conteneur dans GNS3, on va dans l'auxilary console pour check notre config sur notre host et routeur:

*Host* :
```sh
/ # ps 
	PID USER COMMAND 
	1 root /bin/sh 
	314 root /gns3/bin/busybox sh -c while true; do TERM=vt100 /gns3/bin/busy 
	320 root /gns3/bin/busybox sh 
	321 root {ps} /gns3/bin/busybox sh
```

*Routeur* :

```sh
/ # ps
PID USER COMMAND
	1 root /sbin/tini -- /usr/lib/frr/docker-start
	309 root /gns3/bin/busybox sh -c while true; do TERM=vt100 /gns3/bin/busy
	315 root /gns3/bin/busybox sh
	322 root {docker-start} /bin/bash /usr/lib/frr/docker-start
	331 root /usr/lib/frr/watchfrr zebra bgpd ospfd isisd staticd
	347 frr /usr/lib/frr/zebra -d -F traditional -s 90000000 --daemon -A 127
	352 frr /usr/lib/frr/bgpd -d -F traditional --daemon -A 127.0.0.1
	359 frr /usr/lib/frr/ospfd -d -F traditional --daemon -A 127.0.0.1
	362 frr /usr/lib/frr/isisd -d -F traditional --daemon -A 127.0.0.1
	365 frr /usr/lib/frr/staticd -d -F traditional --daemon -A 127.0.0.1
	369 root {ps} /gns3/bin/busybox sh
```

Ca ressemble à l'exemple du sujet et ça devrait etre bon pour la Partie 1, du coup petite checklist de nos attendu :

```
- Check-list P1 -

- Host : pas d’IP v4 par défaut (uniquement loopback). Sur eth0 on n’as que du link-local IPv6 fe80:: 

- Routeur : daemons présents (zebra ospfd bgpd isisd watchfrr staticd) → OK. 

Console accessible dans GNS3 (via vtysh et un prompt). 

Nom du routeur contient le login (router-mabid-p1-1) → OK. 

Config FRR “vide” (pas d’adresses, pas de routing activé par défaut) → OK.
```
