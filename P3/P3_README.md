# Partie 3 — BGP EVPN avec Overlay VXLAN

## Vue d'ensemble

La partie 3 est la plus avancée du projet BADASS. Elle combine tout ce qui a été vu dans les parties précédentes et introduit **EVPN (Ethernet VPN)** comme plan de contrôle pour VXLAN.

En P2, VXLAN était configuré de manière statique (ou via multicast). En P3, **BGP avec la famille d'adresses EVPN** est utilisé pour distribuer dynamiquement les informations de joignabilité MAC et IP entre les VTEPs — plus de configuration statique, plus de multicast nécessaire.

La topologie suit une **architecture spine-leaf** : un routeur spine agit comme **BGP Route Reflector**, et trois routeurs leaf agissent comme VTEPs connectés aux hôtes.

---

## Concepts

### Qu'est-ce qu'EVPN ?

EVPN (Ethernet VPN) est une famille d'adresses BGP (`l2vpn evpn`) définie dans la [RFC 7432](https://datatracker.ietf.org/doc/html/rfc7432). Elle étend BGP pour transporter des informations Layer 2 — adresses MAC et liaisons MAC/IP — sur un réseau IP.

**Pourquoi EVPN plutôt que VXLAN pur ?**  
En P2, chaque VTEP devait être manuellement informé de chaque autre VTEP. Ça ne passe pas à l'échelle. Avec EVPN, les VTEPs annoncent automatiquement leurs adresses MAC locales via BGP. Tous les autres VTEPs reçoivent ces mises à jour et construisent leurs tables de transfert VXLAN automatiquement.

EVPN remplace l'approche *flood and learn* de l'Ethernet traditionnel par une approche **pilotée par le plan de contrôle** : au lieu d'inonder le réseau pour découvrir les MACs, les VTEPs les annoncent via BGP.

### Qu'est-ce qu'un Route Reflector ?

Dans un setup iBGP standard, chaque routeur doit peerer avec chaque autre routeur (full mesh). Avec **N** routeurs, cela fait N×(N-1)/2 sessions — ça ne passe pas à l'échelle.

Un **Route Reflector (RR)** résout ce problème : tous les routeurs peerent uniquement avec le RR, qui reflète (re-annonce) ensuite les routes à tous ses clients. C'est exactement ce que fait `routeur-1` (le spine) en P3.

### Architecture Spine-Leaf

```
                    ┌─────────────────┐
                    │   routeur-1     │  ← Spine (Route Reflector)
                    │   lo: 1.1.1.1   │     BGP AS 1
                    │   eth0: 10.1.1.1/30 ─── routeur-2
                    │   eth1: 10.1.1.5/30 ─── routeur-3
                    │   eth2: 10.1.1.9/30 ─── routeur-4
                    └─────────────────┘

        ┌──────────────────┬──────────────────┐
        │                  │                  │
  [routeur-2]        [routeur-3]        [routeur-4]   ← Leaves (VTEPs)
  lo: 1.1.1.2        lo: 1.1.1.3        lo: 1.1.1.4
  BGP AS 1           BGP AS 1           BGP AS 1
      │                  │                  │
  [host-1]           [host-2]           [host-3]
  20.1.1.1/24        20.1.1.2/24        20.1.1.3/24

  └──────── Overlay VXLAN VNI 10 (20.1.1.0/24) ────────┘
```

Les trois hôtes partagent le même segment Layer 2 (20.1.1.0/24) via VXLAN, même si l'underlay entre routeurs utilise des sous-réseaux /30 séparés (10.1.1.x).

### À quoi sert OSPF ici ?

OSPF est utilisé comme **protocole de routage de l'underlay**. Il s'assure que tous les routeurs peuvent joindre les **adresses loopback** des autres (1.1.1.x/32), qui sont utilisées comme sources des sessions BGP. Sans OSPF, les sessions BGP entre loopbacks ne pourraient pas s'établir.

> Les sessions BGP utilisent les loopbacks (pas les IPs physiques) car les loopbacks sont toujours actifs et offrent un peering stable même si un lien tombe.

---

## Configuration

> SI LE/LES DEAMON NE FONCTIONNE PAS :
```sh
killall zebra #SI le deamon est présent et pose problème (changer zebra par le daemon en question)
/usr/lib/frr/zebra -d -F traditional -A 127.0.0.1 # Si il ne l'ai pas on ne fait que ça (changer zebra par le daemon en question)
```


### `routeur-1` — Spine (Route Reflector)

```bash
# Configuration vtysh
hostname router_mabid_1
no ipv6 forwarding

# Interfaces physiques vers chaque leaf
interface eth0
 ip address 10.1.1.1/30      # lien vers routeur-2

interface eth1
 ip address 10.1.1.5/30      # lien vers routeur-3

interface eth2
 ip address 10.1.1.9/30      # lien vers routeur-4

# Loopback — utilisé comme source BGP
interface lo
 ip address 1.1.1.1/32

# BGP — configuration Route Reflector
router bgp 1
 neighbor ibgp peer-group
 neighbor ibgp remote-as 1
 neighbor ibgp update-source lo
 bgp listen range 1.1.1.0/29 peer-group ibgp   # accepte dynamiquement tout leaf dans cette plage

 address-family l2vpn evpn
  neighbor ibgp activate
  neighbor ibgp route-reflector-client          # reflète les routes EVPN à tous les clients
 exit-address-family

# OSPF — annonce toutes les interfaces
router ospf
 network 0.0.0.0/0 area 0
```

Points clés :
- `peer-group ibgp` + `bgp listen range` permet au spine d'accepter dynamiquement les sessions iBGP de tout leaf dont le loopback est dans `1.1.1.0/29` — pas besoin de lister chaque voisin manuellement.
- `route-reflector-client` indique à BGP de refléter les routes EVPN reçues d'un leaf vers tous les autres leaves.

---

### `routeur-2`, `routeur-3`, `routeur-4` — Leaves (VTEPs)

Les trois leaves suivent le même schéma. Exemple pour `routeur-2` :

**Mise en place Linux (noyau) — VXLAN + Bridge :**
```bash
ip link add br0 type bridge
ip link set dev br0 up
ip link add vxlan10 type vxlan id 10 dstport 4789   # pas de remote/group — BGP EVPN s'en charge
ip link set dev vxlan10 up
brctl addif br0 vxlan10
brctl addif br0 eth1                                 # interface côté hôte
```

> Remarque : contrairement à la P2, il n'y a **pas de `remote` ni de `group`** dans la définition VXLAN. La base de données VTEP est peuplée automatiquement par FRR à partir des mises à jour BGP EVPN.

**Mise en place FRR (vtysh) :**
```bash
hostname routeur_mabid_2
no ipv6 forwarding

interface eth0
 ip address 10.1.1.2/30
 ip ospf area 0              # annonce ce lien via OSPF

interface lo
 ip address 1.1.1.2/32
 ip ospf area 0              # annonce le loopback via OSPF

router bgp 1
 neighbor 1.1.1.1 remote-as 1          # peerer avec le spine (RR)
 neighbor 1.1.1.1 update-source lo     # utiliser le loopback comme source

 address-family l2vpn evpn
  neighbor 1.1.1.1 activate
  advertise-all-vni                    # annonce tous les VNIs locaux au RR
 exit-address-family

router ospf                            # activer OSPF (config par interface)
```

Points clés :
- `advertise-all-vni` indique à FRR d'annoncer automatiquement chaque VNI VXLAN local (ici, VNI 10) via BGP EVPN.
- `update-source lo` garantit que BGP utilise l'IP loopback (`1.1.1.x`) comme source de sa session TCP, correspondant à ce qu'attend le spine.
- OSPF avec `ip ospf area 0` sur chaque interface redistribue automatiquement le loopback et les préfixes de lien.

---

### Hôtes

```bash
# host-1
ip addr add 20.1.1.1/24 dev eth1

# host-2
ip addr add 20.1.1.2/24 dev eth0

# host-3
ip addr add 20.1.1.3/24 dev eth0
```

Les hôtes ignorent complètement VXLAN ou BGP — ils voient simplement un réseau Layer 2 plat.

---

## Images Docker

La P3 utilise la même image `host_mabid` de la P1 et un nouveau `router_mabid` construit depuis `P3/router_mabid` :

```dockerfile
FROM frrouting/frr
ENV DAEMONS="zebra bgpd ospfd isisd"
RUN apk update && apk add util-linux busybox-static iproute2
COPY ./P3/daemons.conf /etc/frr/daemons
COPY ./P3/vtysh.conf.sample /etc/frr/vtysh.conf
```

Construction :
```bash
make build-images-docker-P3
```

---

## Vérification

```bash
# Sur n'importe quel leaf — vérifier les voisins BGP EVPN
vtysh -c "show bgp summary"

# Vérifier les routes EVPN reçues
vtysh -c "show bgp l2vpn evpn"

# Vérifier la base de transfert VXLAN (peuplée par EVPN)
bridge fdb show dev vxlan10

# Ping entre les hôtes (doit fonctionner entre les trois leaves)
ping 20.1.1.2   # depuis host-1 vers host-2
ping 20.1.1.3   # depuis host-1 vers host-3
```
