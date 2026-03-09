# Partie 1 — Environnement Docker & Configuration FRRouting

## Vue d'ensemble

La partie 1 est la fondation du projet BADASS. L'objectif est de construire deux images Docker qui seront réutilisées dans les parties suivantes :

- **Un hôte** — un conteneur Alpine léger simulant une machine terminale sur le réseau.
- **Un routeur** — un conteneur basé sur FRRouting (FRR), une suite logicielle de routage open-source complète.

Aucun protocole de routage n'est configuré dans cette partie. Il s'agit uniquement de mettre en place l'environnement correctement pour que GNS3 puisse utiliser ces images dans une topologie réseau.

---

## Concepts

### Qu'est-ce que FRRouting (FRR) ?

FRRouting est une suite de protocoles de routage IP open-source pour Linux. Elle supporte un large éventail de protocoles dont BGP, OSPF, IS-IS, et bien d'autres. FRR fonctionne en exécutant des **daemons** individuels — un par protocole — qui communiquent avec le noyau Linux via **Zebra**, le gestionnaire de routage central.

Pensez à FRR comme un OS de routeur modulaire tournant dans un conteneur : chaque protocole est un processus indépendant que vous pouvez activer ou désactiver.

### Qu'est-ce que Zebra ?

Zebra est le daemon central de FRR. Il joue le rôle d'intermédiaire entre les daemons de protocoles FRR (bgpd, ospfd, etc.) et la table de routage du noyau Linux. Tous les autres daemons communiquent avec Zebra, qui pousse ensuite les routes dans le noyau. **Il doit toujours être activé.**

### Qu'est-ce que vtysh ?

`vtysh` est le shell CLI unifié de FRRouting, similaire à la CLI des routeurs Cisco ou Juniper. Il permet de configurer tous les daemons FRR depuis une seule interface avec des commandes comme `conf t`, `router bgp`, `show ip route`, etc.

---

## Fichiers

### `host_mabid` (Dockerfile)

```dockerfile
FROM alpine:latest
RUN apk update && \
    apk add util-linux && \
    apk add busybox-static
```

Une image Alpine Linux minimale. `util-linux` et `busybox-static` fournissent les outils réseau de base (`ip`, `ping`, etc.). Cette image simule un simple hôte terminal sur le réseau — sans capacités de routage.

---

### `router_mabid` (Dockerfile)

```dockerfile
FROM frrouting/frr
ENV DAEMONS="zebra bgpd ospfd isisd"
RUN apk update && \
    apk add util-linux && \
    apk add busybox-static && \
    apk add iproute2
COPY ./P1/daemons.conf /etc/frr/daemons
COPY ./P1/vtysh.conf.sample /etc/frr/vtysh.conf
```

Construit à partir de l'image FRR officielle. Le paquet `iproute2` ajoute la commande `ip` pour la gestion des interfaces et des routes. Les deux instructions `COPY` injectent la configuration des daemons et la config vtysh dans le conteneur aux chemins attendus par FRR.

---

### `daemons.conf`

Ce fichier indique à FRR quels daemons démarrer au boot. Les daemons activés pour ce projet (marqués `#Subject`) :

| Daemon | Protocole | Rôle |
|--------|-----------|------|
| `zebra` | — | Gestionnaire de routage central (obligatoire) |
| `bgpd` | BGP | Border Gateway Protocol |
| `ospfd` | OSPF | Open Shortest Path First (IPv4) |
| `isisd` | IS-IS | Intermediate System to Intermediate System |

Chaque daemon activé reçoit également des options de démarrage, tous se liant à `127.0.0.1` (loopback) pour la communication inter-processus locale :

```conf
zebra_options=" -s 90000000 --daemon -A 127.0.0.1"
bgpd_options="   --daemon -A 127.0.0.1"
ospfd_options="  --daemon -A 127.0.0.1"
isisd_options="  --daemon -A 127.0.0.1"
```

Le flag `-s 90000000` pour Zebra définit la taille du buffer pour la communication par socket.

---

### `vtysh.conf.sample`

Un fichier de configuration exemple (vide/commenté) pour le shell vtysh. Copié dans le conteneur en tant que `/etc/frr/vtysh.conf`. Dans cette partie, il n'est pas personnalisé — le comportement par défaut est suffisant.

---

## Construction

```bash
make build-images-docker-P1
```

Cela exécute :
```bash
docker build -f ./P1/router_mabid -t router-mabid .
docker build -f ./P1/host_mabid   -t host-mabid .
```

---

## Utilisation dans GNS3

Une fois les images construites, importez-les dans GNS3 en tant qu'appliances Docker. Le fichier `P1.gns3project` contient la topologie pré-construite pour cette partie. Ouvrez-le dans GNS3 pour explorer et tester la configuration. 

Pour recuperer les images sur GNS3 on va dans Edit > Preference > Docker > Docker Container > New (based on existing images).

A tout moment si un daemons cesse de fonctionner ou n'apparait pas dans le ps :

```sh
killall zebra #SI le deamon est présent et pose problème (changer zebra par le daemon en question)
/usr/lib/frr/zebra -d -F traditional -A 127.0.0.1 # Si il ne l'ai pas on ne fait que ça (changer zebra par le daemon en question)
```