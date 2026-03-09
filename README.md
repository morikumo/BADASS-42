# BADASS — BGP At Scale in a Service Provider Network

> *Un projet réseau de l'école 42 explorant Docker, GNS3, VXLAN et BGP EVPN.*

---

## Table des matières

- [BADASS — BGP At Scale in a Service Provider Network](#badass--bgp-at-scale-in-a-service-provider-network)
  - [Table des matières](#table-des-matières)
  - [Vue d'ensemble](#vue-densemble)
  - [Prérequis](#prérequis)
  - [Structure du dépôt](#structure-du-dépôt)
  - [Glossaire des concepts clés](#glossaire-des-concepts-clés)
    - [Couches réseau](#couches-réseau)
    - [FRRouting (FRR)](#frrouting-frr)
    - [VXLAN](#vxlan)
    - [BGP (Border Gateway Protocol)](#bgp-border-gateway-protocol)
    - [EVPN (Ethernet VPN)](#evpn-ethernet-vpn)
    - [OSPF (Open Shortest Path First)](#ospf-open-shortest-path-first)
    - [Architecture Spine-Leaf](#architecture-spine-leaf)
  - [Référence Makefile](#référence-makefile)
  - [Ressources](#ressources)
    - [RFCs](#rfcs)
    - [Lectures complémentaires](#lectures-complémentaires)

---

## Vue d'ensemble

BADASS est un projet de réseau progressif divisé en trois parties, chacune s'appuyant sur la précédente :

| Partie | Sujet | Technologie clé |
|--------|-------|-----------------|
| **P1** | Mise en place de l'environnement | Docker, FRRouting |
| **P2** | Tunneling overlay Layer 2 | VXLAN (statique & multicast) |
| **P3** | Plan de contrôle dynamique pour VXLAN | BGP EVPN, OSPF, Spine-Leaf |

Le résultat final est une **émulation de réseau de datacenter** entièrement fonctionnelle dans GNS3, où des hôtes virtuels sur des segments physiques différents communiquent de manière transparente via un fabric VXLAN piloté par BGP EVPN.

---

## Prérequis

- [Docker](https://docs.docker.com/get-docker/) installé, avec votre utilisateur dans le groupe `docker`
- [GNS3](https://www.gns3.com/) installé avec l'intégration Docker activée
- Notions de base en réseau Linux (commande `ip`, interfaces, routage)

> Après l'installation de Docker et GNS3, **redémarrez votre session** pour que les changements de groupe soient pris en compte.

---

## Structure du dépôt

```
.
├── Makefile              ← Cibles de build, statut et nettoyage
├── P1/
│   ├── host_mabid        ← Dockerfile : hôte Alpine léger
│   ├── router_mabid      ← Dockerfile : routeur FRRouting
│   ├── daemons.conf      ← Configuration des daemons FRR
│   ├── vtysh.conf.sample ← Configuration du shell vtysh
│   └── P1.gns3project    ← Topologie GNS3 pour la P1
├── P2/
│   ├── host-1 / host-2              ← Scripts de démarrage des hôtes
│   ├── routeur-1-s / routeur-2-s    ← Config VXLAN unicast
│   ├── routeur-1-g / routeur-2-g    ← Config VXLAN multicast
│   └── P2.gns3project    ← Topologie GNS3 pour la P2
└── P3/
    ├── router_mabid      ← Dockerfile : routeur FRRouting (variante P3)
    ├── daemons.conf      ← Configuration des daemons FRR
    ├── vtysh.conf.sample ← Configuration du shell vtysh
    ├── routeur-1         ← Config du spine (BGP Route Reflector)
    ├── routeur-2/3/4     ← Configs des leaves (VTEPs)
    ├── host-1/2/3        ← Scripts de démarrage des hôtes
    └── P3.gns3project    ← Topologie GNS3 pour la P3
```

---

## Glossaire des concepts clés

### Couches réseau

| Terme | Couche | Description |
|-------|--------|-------------|
| **Underlay** | L3 | Le réseau IP réel reliant les routeurs physiques/virtuels |
| **Overlay** | L2 | Le réseau virtuel construit par-dessus (ex : tunnel VXLAN) |
| **VTEP** | L2/L3 | VXLAN Tunnel Endpoint — encapsule/décapsule les trames VXLAN |

---

### FRRouting (FRR)

FRR est une suite logicielle de routage open-source pour Linux. Elle fonctionne comme un ensemble de **daemons**, chacun implémentant un protocole de routage différent :

| Daemon | Protocole | Utilisé dans |
|--------|-----------|--------------|
| `zebra` | — | P1, P3 — Daemon central, toujours requis |
| `bgpd` | BGP | P3 — Distribue les routes EVPN |
| `ospfd` | OSPF | P3 — Routage de l'underlay |
| `isisd` | IS-IS | P1 (disponible, non utilisé en P2/P3) |

La configuration se fait via **vtysh**, le shell CLI unifié de FRR (similaire à Cisco IOS).

---

### VXLAN

**Virtual Extensible LAN** — encapsule des trames Ethernet Layer 2 dans des paquets UDP sur un réseau Layer 3.

- **VNI (VXLAN Network Identifier) :** Identifiant de segment sur 24 bits (jusqu'à ~16M segments, contre 4096 pour les VLANs)
- **Port UDP par défaut :** 4789
- **Trois modes de découverte :**
  - **Unicast :** Les IPs des VTEPs distants sont configurées statiquement (`local` / `remote`)
  - **Multicast :** Les VTEPs rejoignent une adresse de groupe (`group 239.x.x.x`) pour la découverte automatique
  - **EVPN (P3) :** BGP distribue les infos de VTEPs dynamiquement — aucune config statique nécessaire

---

### BGP (Border Gateway Protocol)

BGP est le protocole de routage d'internet. Dans ce projet, il fonctionne en mode **iBGP** (tous les routeurs dans l'AS 1) et transporte des **routes EVPN** plutôt que des préfixes IP classiques.

Concepts BGP clés utilisés en P3 :

| Concept | Description |
|---------|-------------|
| **AS (Autonomous System)** | Groupe de routeurs sous un même domaine administratif. Ici : AS 1. |
| **iBGP** | Session BGP entre routeurs du *même* AS |
| **Peer group** | Groupe nommé de voisins BGP partageant la même configuration |
| **Route Reflector** | Routeur qui re-diffuse les routes iBGP à d'autres pairs iBGP (évite le full mesh) |
| **`update-source lo`** | Utilise le loopback comme source de session BGP (stable, toujours actif) |
| **`bgp listen range`** | Accepte dynamiquement les sessions BGP de tout pair dont l'IP est dans la plage donnée |

---

### EVPN (Ethernet VPN)

L'EVPN est une famille d'adresses BGP (`l2vpn evpn`) qui transporte des informations de joignabilité Layer 2 — adresses MAC, liaisons MAC/IP — sur un réseau IP.

En P3, EVPN est utilisé comme **plan de contrôle du VXLAN** :
1. Chaque leaf (VTEP) apprend une adresse MAC locale (depuis un hôte connecté).
2. Il annonce cette MAC via BGP EVPN au spine (Route Reflector).
3. Le spine reflète la route vers tous les autres leaves.
4. Tous les autres leaves savent maintenant quel VTEP possède cette MAC et peuvent lui envoyer des trames VXLAN directement.

Cela remplace le mécanisme de *flood and learn* de l'Ethernet classique par une approche pilotée par le plan de contrôle, scalable et efficace.

**Commande FRR clé :**
```bash
advertise-all-vni   # Annonce tous les VNIs VXLAN locaux via BGP EVPN
```

---

### OSPF (Open Shortest Path First)

OSPF est un protocole IGP à état de liens utilisé en P3 comme **protocole de routage de l'underlay**. Son rôle est de s'assurer que chaque routeur sait comment atteindre l'adresse loopback des autres (`1.1.1.x/32`), utilisées comme points d'ancrage des sessions BGP.

Sans OSPF, les sessions BGP entre loopbacks ne pourraient pas s'établir (les IPs ne seraient pas joignables).

---

### Architecture Spine-Leaf

Une architecture réseau datacenter à deux niveaux :
- **Niveau Spine :** Un ou plusieurs commutateurs/routeurs haute capacité interconnectant tout. En P3, `routeur-1` est le spine et fait office de BGP Route Reflector.
- **Niveau Leaf :** Commutateurs de bordure connectés aux hôtes. En P3, `routeur-2`, `routeur-3` et `routeur-4` sont les leaves (VTEPs).

Chaque leaf se connecte à chaque spine, mais les leaves ne se connectent jamais directement entre eux. Tout le trafic entre hôtes sur des leaves différents passe par le spine.

---

## Référence Makefile

```bash
make build-images-docker-P1   # Construit les images Docker pour la P1 (hôte + routeur)
make build-images-docker-P3   # Construit les images Docker pour la P3 (hôte de P1 + routeur P3)
make docker-status            # Affiche les conteneurs, images, volumes et réseaux Docker actifs
make clean                    # Supprime tous les conteneurs, images, volumes et réseaux Docker
```

> ⚠️ `make clean` est destructif — il supprime **toutes** les images et conteneurs Docker de votre système, pas seulement ceux du projet.

---

## Ressources

- [Documentation FRRouting](https://docs.frrouting.org/en/latest/index.html)
- [Référence des protocoles FRR](https://docs.frrouting.org/en/latest/protocols.html)
- [FRR avec Docker](https://docs.frrouting.org/projects/dev-guide/en/latest/building-docker.html)
- [RFC 7348 — VXLAN](https://datatracker.ietf.org/doc/html/rfc7348)
- [RFC 7432 — BGP EVPN](https://datatracker.ietf.org/doc/html/rfc7432)
- [Docker et frrouting](https://docs.frrouting.org/projects/dev-guide/en/latest/building-docker.html)
- [Configurer les daemon de frrouting](https://www.packettracernetwork.com/ccna-ccnp-preparation/ccnp-frr.html)


### RFCs

- [RFC 7348 — VXLAN](https://datatracker.ietf.org/doc/html/rfc7348)
- [RFC 7432 — BGP EVPN](https://datatracker.ietf.org/doc/html/rfc7432)
- [RFC 4271 — BGP-4](https://datatracker.ietf.org/doc/html/rfc4271)
- [RFC 4760 — MP-BGP (extensions multiprotocoles)](https://datatracker.ietf.org/doc/html/rfc4760)
- [RFC 2328 — OSPF v2](https://datatracker.ietf.org/doc/html/rfc2328)

### Lectures complémentaires

- [VXLAN & Linux — The Definitive Guide (Vincent Bernat)](https://vincent.bernat.ch/en/blog/2017-vxlan-linux)
- [BGP EVPN with FRRouting — explication détaillée (Vincent Bernat)](https://vincent.bernat.ch/en/blog/2017-vxlan-bgp-evpn)