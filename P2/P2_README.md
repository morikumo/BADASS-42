# Partie 2 — VXLAN : Virtual Extensible LAN

## Vue d'ensemble

La partie 2 introduit **VXLAN**, une technologie de tunneling qui permet à deux machines sur des réseaux physiques différents de communiquer comme si elles étaient sur le même réseau local (Layer 2).

Deux routeurs sont configurés avec un tunnel VXLAN entre eux, et chaque routeur est connecté à un hôte. Les deux hôtes, bien qu'étant sur des segments réseau séparés, peuvent se joindre via le tunnel VXLAN.

Deux variantes sont explorées :
- **Statique / Unicast** (`routeur-X-s`) — les points de terminaison du tunnel sont définis explicitement.
- **Dynamique / Multicast** (`routeur-X-g`) — les points de terminaison sont découverts via un groupe multicast.

---

## Concepts

### Qu'est-ce que VXLAN ?

VXLAN (Virtual Extensible LAN) est une technologie de virtualisation réseau définie dans la [RFC 7348](https://datatracker.ietf.org/doc/html/rfc7348). Elle encapsule des trames Ethernet Layer 2 dans des paquets UDP, leur permettant de traverser un réseau Layer 3 (IP).

**Pourquoi est-ce utile ?**  
Dans les datacenters, on souhaite souvent que des machines virtuelles ou des conteneurs sur des serveurs physiques complètement différents apparaissent comme branchés sur le même switch Ethernet. VXLAN rend cela possible en créant un segment Layer 2 virtuel (appelé **VNI**) au-dessus d'un réseau IP existant.

Termes clés :
- **VNI (VXLAN Network Identifier) :** Identifiant de segment sur 24 bits (supporte jusqu'à ~16 millions de segments, contre 4096 pour les VLANs).
- **VTEP (VXLAN Tunnel Endpoint) :** Le dispositif (ou l'interface) qui encapsule/décapsule le trafic VXLAN. Dans ce projet, chaque routeur agit comme un VTEP.
- **dstport 4789 :** Le port UDP standard utilisé pour le trafic VXLAN.

### Qu'est-ce qu'un Bridge Linux ?

Un bridge Linux (`br0`) agit comme un switch Ethernet virtuel. Dans ce projet, le bridge connecte :
- L'**interface VXLAN** (`vxlan10`) — le côté tunnel
- L'**interface côté hôte** (`eth1`) — le côté local

Toute trame arrivant sur `eth1` depuis l'hôte est transmise dans le tunnel VXLAN, et vice versa.

### VXLAN Unicast vs Multicast

| Mode | Comment les VTEPs se trouvent | Mot-clé de config |
|------|-------------------------------|-------------------|
| **Unicast (statique)** | Chaque VTEP connaît explicitement l'IP de l'autre | `local` / `remote` |
| **Multicast (dynamique)** | Les VTEPs rejoignent un groupe multicast ; la découverte est automatique | `group` |

Le multicast est plus simple à faire évoluer (pas besoin de lister chaque VTEP distant), mais nécessite le support du multicast sur le réseau underlay.

---

## Topologie réseau

```
[host-1]──eth1──[Routeur 1]──eth0──(underlay 10.1.1.0/24)──eth0──[Routeur 2]──eth1──[host-2]
  30.1.1.1/24      VTEP 10.1.1.1                               VTEP 10.1.1.2        30.1.1.2/24

                        └──────── Tunnel VXLAN VNI 10 ────────┘
                             (overlay L2 — les deux hôtes sur 30.1.1.0/24)
```

L'**underlay** (10.1.1.0/24) est le vrai réseau IP entre les routeurs.  
L'**overlay** (30.1.1.0/24) est le segment L2 virtuel que voient les hôtes — transporté dans le tunnel VXLAN.

---

## Fichiers de configuration

### Hôtes

**`host-1`**
```bash
ip link set eth1 up
ip addr add 30.1.1.1/24 dev eth1
```

**`host-2`**
```bash
ip link set eth1 up
ip addr add 30.1.1.2/24 dev eth1
```

Simple : chaque hôte reçoit une IP sur le sous-réseau overlay `30.1.1.0/24`. Ils ne savent rien de VXLAN — le tunnel est transparent pour eux.

---

### Routeurs — Mode Unicast

**`routeur-1-s`** (statique, local = 10.1.1.1, remote = 10.1.1.2)
```bash
ip link set eth0 up
ip addr add 10.1.1.1/24 dev eth0          # IP underlay

ip link add br0 type bridge               # créer un switch virtuel
ip link set br0 up

ip link add vxlan10 type vxlan \
  id 10 \                                 # VNI = 10
  dev eth0 \                              # interface underlay
  local 10.1.1.1 \                        # IP de ce VTEP
  remote 10.1.1.2 \                       # IP du VTEP distant
  dstport 4789                            # port UDP standard VXLAN
ip link set vxlan10 up

ip link set vxlan10 master br0            # attacher le tunnel au bridge
ip link set eth1 up
ip link set eth1 master br0              # attacher le port hôte au bridge
```

**`routeur-2-s`** est l'image miroir avec `local 10.1.1.2` et `remote 10.1.1.1`.

---

### Routeurs — Mode Multicast

**`routeur-1-g` / `routeur-2-g`** (config identique — les deux rejoignent le même groupe multicast)
```bash
ip link add vxlan10 type vxlan \
  id 10 \
  dev eth0 \
  group 239.1.1.1 \                       # adresse du groupe multicast
  dstport 4789
```

La différence clé : au lieu de spécifier une IP `remote`, les deux VTEPs rejoignent le groupe multicast `239.1.1.1`. VXLAN utilise ce groupe pour découvrir les autres VTEPs et envoyer le trafic BUM (Broadcast, Unknown unicast, Multicast).

> `239.1.1.1` appartient à la plage multicast à portée administrative (RFC 2365), couramment utilisée pour le multicast privé/local.

---

## Construction & Exécution

Aucune étape de build Docker spécifique n'est nécessaire pour la P2 — elle réutilise les images de la P1. La configuration est appliquée directement dans la topologie GNS3 via des scripts de démarrage.

Ouvrez `P2.gns3project` dans GNS3, démarrez tous les nœuds, et appliquez les scripts de config à chaque nœud. Vérifiez ensuite la connectivité :

```bash
# Depuis host-1, ping host-2
ping 30.1.1.2

# Depuis host-2, ping host-1
ping 30.1.1.1
```

---

## Commandes utiles

```bash
# Vérifier l'interface VXLAN
ip -d link show vxlan10

# Vérifier les membres du bridge
bridge link show

# Vérifier la FDB (Forwarding Database) — affiche les adresses MAC apprises
bridge fdb show dev vxlan10
```
