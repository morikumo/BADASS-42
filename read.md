# 🔵 PROJECT OVERVIEW

---

## 1️⃣ Fonctionnement de base de GNS3

GNS3 est un **simulateur/émulateur de réseau**.

Il permet de :

* créer des topologies réseau virtuelles
* connecter des routeurs, switches, machines
* utiliser des vraies images (Docker, VM, IOS…)

Il fonctionne ainsi :

* Chaque équipement est un conteneur ou une VM
* Les liens sont des interfaces virtuelles
* On peut capturer le trafic (Wireshark)
* On simule un vrai réseau

👉 C’est un laboratoire réseau virtuel.

---

## 2️⃣ Fonctionnement global et intérêt de BGP

Border Gateway Protocol (BGP) est le protocole qui :

* connecte les systèmes autonomes (AS)
* permet à Internet de fonctionner

Il échange des **routes entre AS**.

Pourquoi il est important :

* Scalabilité énorme
* Contrôle des politiques de routage
* Fonctionne entre organisations différentes

Dans ton projet :

* On utilise une extension de BGP (EVPN)
* Pour transporter des MAC au lieu d’IP

---

## 3️⃣ Différence couche 2 vs couche 3

### 🔹 Couche 2 (L2)

* Basée sur les MAC
* Switch
* Broadcast
* Même domaine Ethernet

Ex : VLAN, Bridge

---

### 🔹 Couche 3 (L3)

* Basée sur les IP
* Routage
* Pas de broadcast global
* Communication entre réseaux

Ex : OSPF, BGP

---

# 🔵 PART 1 – THEORY

---

## 1️⃣ Packet routing software

Un logiciel de routage est un programme qui :

* maintient une table de routage
* échange des routes
* prend des décisions de forwarding

Exemple moderne :

FRRouting

Il remplace les routeurs physiques Cisco/Juniper.

---

## 2️⃣ BGPD

BGPD = service BGP daemon.

Il :

* établit les sessions BGP
* échange les routes
* applique les politiques

Dans ton projet :

* Il gère EVPN en P3

---

## 3️⃣ OSPFD

Open Shortest Path First

OSPF :

* protocole IGP
* fonctionne en L3
* calcule les plus courts chemins

Dans ton projet :

* construit l’underlay
* rend toutes les loopback joignables

---

## 4️⃣ Routing engine service

C’est le moteur global de routage :

* gère la RIB (Routing Information Base)
* installe les routes dans le kernel
* coordonne les protocoles

Ex : zebra dans FRRouting.

---

## 5️⃣ Busybox

BusyBox

Busybox :

* regroupe les outils Linux essentiels
* shell minimal
* commandes réseau

Permet d’avoir une image légère pour les hosts.

---

# 🔵 PART 2 – THEORY

---

## 1️⃣ VXLAN vs VLAN

VXLAN

VXLAN :

* encapsule L2 dans UDP
* permet 16 millions de segments (VNI)
* traverse L3

VLAN :

* limité à 4096 ID
* ne traverse pas L3
* purement local

👉 VXLAN = extension des VLAN à grande échelle.

---

## 2️⃣ Switch

Un switch :

* équipement L2
* apprend les MAC
* fait du forwarding Ethernet

---

## 3️⃣ Bridge

Un bridge Linux :

* switch logiciel
* relie plusieurs interfaces L2
* apprend les MAC dynamiquement

Dans ton projet :

* br0 relie eth1 et vxlan10

---

## 4️⃣ Broadcast vs Multicast

Broadcast :

* envoyé à tout le monde
* ff:ff:ff:ff:ff:ff

Multicast :

* envoyé à un groupe spécifique
* ex 239.1.1.1

Multicast réduit le flooding global.

---

## 5️⃣ Fonctionnement attendu de la topo P2

Host1 → bridge → VXLAN → R2 → Host2

En statique :

* FDB manuelle

En group :

* Utilise multicast
* Pas besoin de remote statique

Avantages multicast :

* Pas besoin de config remote
* Plus scalable

---

# 🔵 PART 3 – THEORY

---

## 1️⃣ BGP-EVPN

Ethernet VPN

EVPN :

* extension de BGP
* transporte des MAC
* remplit automatiquement la FDB

Remplace :

* FDB statique
* Multicast flood

---

## 2️⃣ Route Reflection

Principe :

* Évite full-mesh BGP
* Un routeur central reflète les routes

Dans ton topo :

* R1 = Route Reflector
* R2/R3/R4 = clients

Avantage :

* Scalabilité
* Moins de sessions BGP

---

## 3️⃣ VTEP

VTEP = VXLAN Tunnel Endpoint.

Il :

* encapsule/décapsule VXLAN
* annonce ses MAC en EVPN
* apprend les MAC distantes

Dans ton schéma :

* R2 R3 R4 sont des VTEP.

---

## 4️⃣ VNI

VNI = VXLAN Network Identifier.

* Remplace VLAN ID
* 24 bits
* ID 10 dans ton projet

Permet d’identifier le segment overlay.

---

## 5️⃣ Route type 2 vs type 3

Type 3 :

* annonce l’existence d’un VNI
* existe même sans host

Type 2 :

* annonce une MAC/IP
* apparaît quand un host est actif

---

## 6️⃣ Fonctionnement attendu topo P3

1. OSPF construit l’underlay
2. BGP EVPN s’établit via loopback
3. Type 3 visibles sans host
4. Activation host → type 2 apparaît
5. MAC propagée via RR
6. Ping fonctionne
7. OSPF visible dans capture

---

# 🎯 Pourquoi cette architecture ?

Architecture leaf-spine :

* Bande passante élevée
* Pas de boucle L2
* Scalable
* Standard data center moderne

Utilisée par :

* Cloud providers
* Data centers d’entreprise
* Réseaux multi-tenant

---

# 🔥 Point clé à retenir pour impressionner

P2 = Data plane only
P3 = Data plane + Control plane

EVPN supprime :

* Flooding massif
* Config statique
* Problèmes de scalabilité

---

