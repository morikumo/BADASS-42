Dans la partie 1 nous avons initié GNS3 et deux images docker pour notre host et notre router.

Ici nous allons connecter le tout avec un nouvel outil appelé VXLAN.

Tout d'abord qu'est ce que c'est?

### *VXLAN* : 

*VXLAN (Virtual eXtensible LAN)* est une technologie de virtualisation réseau qui permet de créer des réseaux de niveau 2 au-dessus d’une infrastructure IP (niveau 3).
Elle utilise l’encapsulation UDP pour relier des machines distantes comme si elles étaient sur le même réseau local.

L2 (niveau 2) = qui tu es (MAC) sur le réseau local, L3  (niveau 3)= où tu es (IP) entre réseaux




On va donc reprendre nos images docker faites dans la p1 et dupliqués le tout pour avoir 2 switcher et 2 hosts. 
ON ajoutes a cela un switcher (disponibles dans les devices sur la barre de gauche), et on connecte le tout avec la dernière option a gauche en bas.

Contrairement a templates de la p1 il va falloir ajouter des port pour connecter le tout, donc clic droit sur notre template de routeur et on ajoute des port (5 par exemples).

Et la on peut connecter le tout. Ensuite on les demarre et on ouvre l'auxilary console de notre routeur a laquel on doit ajouter un bridge nommé br0 selon le sujet.

```sh
ip link add br0 type bridge
ip link set dev br0 up
ip addr add 10.1.1.1/24 dev eth0
```

Une fois ça fait on peut verifier le resultat avec :

```sh
ip addr show eth0
```

Ensuite on mets en place le vxlan:

```sh
ip link add name vxlan10 type vxlan id 10 dev eth0 remote 10.1.1.2 local 10.1.1.1 dstport 1234
ip addr add 20.1.1.1/24 dev vxlan10
```

Pour voir le resultat de celui-ci:

```sh
ip link show vxlan10
ip addr show vxlan10
```


On ajoute maintenant nos regles de bridge vers les host:

```sh
brctl addif br0 eth1 #Vers le host en eth1
brctl addif br0 vxlan10 #On donne aussi les accès au vxlan pour un communication meilleur
```

On peut enfin lancer notre vxlan configurer maintenat :

```sh
ip link set dev vxlan10 up
```

On peut donc voir que le service est up maintenant :
```sh
ip addr show vxlan10
ip link show vxlan10
ip link show eth1
```

Premier router de fait il faut maintenant le faire pour le second :

```sh
ip link add br0 type bridge
ip link set dev br0 up
ip addr add 10.1.1.2/24 dev eth0
ip addr show eth0
ip link add name vxlan10 type vxlan id 10 dev eth0 remote 10.1.1.2 local 10.1.1.1 dstport 1234
ip addr add 20.1.1.2/24 dev vxlan10
ip link show vxlan10
ip addr show vxlan10
brctl addif br0 eth1 #Vers le host en eth1
brctl addif br0 vxlan10 #On donne aussi les accès au vxlan pour un communication meilleur
ip link set dev vxlan10 up
ip addr show vxlan10
ip link show vxlan10
ip link show eth1
```

17:51