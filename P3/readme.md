# BGP - EVPN
Une fois que le multicast est activer on va activer bgp via nos vtep. EN quoi consiste tout ça.

On commence par quelques explication.

Le but ici va etre de faire une architecture issue de 4 routeur et 3 host qui va se présenter comme un routeur au top (spine et Route reflector)connecter au trois autres (leaf) et eux meme connecter au 3 host.

Le but étant via BGP EVPN de faire un system qui lorsque l'on a une machine qui se connecte a un de nos trois routeur il apprend automatiquement son adresse mac pour l'neregistrer dans son route relfector qui pourra donnné l'information a tout le monde.

C'est ici une architecture souvent utilisé dans les data center.

Le tout avec VXLAN (pour étandre ça capacité) et OSPF (pour trouver le chemin le plus court facilment).

Maintenant cela étant dit il faut maintenant faire la configuration de celle-ci.

Mais avant je remarque que le daemon zebra segfault et c'est du a la regle mise pour une allocation kernel de 90000000 mb de mémoire pour la table de routage, dont je pense la memoire ne suffisait pas, on va donc le faire fonctionner avec les parametre par défaut :


On tue le daemon pour le reparametrer par défaut.
```sh
killall zebra #SI le deamon est présent et pose problème
/usr/lib/frr/zebra -d -F traditional -A 127.0.0.1 # Si il ne l'ai pas on ne fait que ça
```

## ROUTEUR 1 

vtysh
conf t
hostname router_mabid_1
no ipv6 forwarding
interface eth0
ip address 10.1.1.1/30
interface eth1
ip address 10.1.1.5/30
interface eth2
ip address 10.1.1.9/30
interface lo
ip address 1.1.1.1/32
router bgp 1
 neighbor ibgp peer-group
 neighbor ibgp remote-as 1
 neighbor ibgp update-source lo
bgp listen range 1.1.1.0/29 peer-group ibgp
address-family l2vpn evpn
 neighbor ibgp activate
 neighbor ibgp route-reflector-client
exit-address-family
router ospf
 network 0.0.0.0/0 area 0

## ROUTEUR 2 

ip link add br0 type bridge
ip link set dev br0 up
ip link add vxlan10 type vxlan id 10 dstport 4789
ip link set dev vxlan10 up
brctl addif br0 vxlan10
brctl addif br0 eth1
vtysh
conf t
hostname routeur_mabid_2
no ipv6 forwarding
interface eth0
ip address 10.1.1.2/30
ip ospf area 0
interface lo
ip address 1.1.1.2/32
ip ospf area 0
router bgp 1
neighbor 1.1.1.1 remote-as 1
neighbor 1.1.1.1 update-source lo
address-family l2vpn evpn
neighbor 1.1.1.1 activate
advertise-all-vni
exit-address-family
router ospf

## ROUTEUR 3 

ip link add br0 type bridge
ip link set dev br0 up
ip link add vxlan10 type vxlan id 10 dstport 4789
ip link set dev vxlan10 up
brctl addif br0 vxlan10
brctl addif br0 eth0
vtysh
conf t
hostname routeur_mabid_3
no ipv6 forwarding
interface eth1
 ip address 10.1.1.6/30
 ip ospf area 0
interface lo
 ip address 1.1.1.3/32
 ip ospf area 0
router bgp 1
 neighbor 1.1.1.1 remote-as 1
 neighbor 1.1.1.1 update-source lo
 address-family l2vpn evpn
  neighbor 1.1.1.1 activate
  advertise-all-vni
 exit-address-family
router ospf

## ROUTEUR 4 

ip link add br0 type bridge
ip link set dev br0 up
ip link add vxlan10 type vxlan id 10 dstport 4789
ip link set dev vxlan10 up
brctl addif br0 vxlan10
brctl addif br0 eth0
vtysh
conf t
hostname routeur_mabid_4
no ipv6 forwarding
interface eth2
 ip address 10.1.1.10/30
 ip ospf area 0
interface lo
 ip address 1.1.1.4/32
 ip ospf area 0
router bgp 1
 neighbor 1.1.1.1 remote-as 1
 neighbor 1.1.1.1 update-source lo
 address-family l2vpn evpn
  neighbor 1.1.1.1 activate
  advertise-all-vni
 exit-address-family
router ospf

## HOST 1

ip addr add 20.1.1.1/24 dev eth1

## HOST 2

ip addr add 20.1.1.2/24 dev eth0

## HOST 3 

ip addr add 20.1.1.3/24 dev eth0

