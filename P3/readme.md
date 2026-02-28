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
killall zebra 2>/dev/null
/usr/lib/frr/zebra -d -F traditional -A 127.0.0.1
```

## ROUTEUR 1 


## ROUTEUR 2 


## ROUTEUR 3 


## ROUTEUR 4 


## HOST 1


## HOST 3 


## HOST 2 



