# Unicast

## Routeur 1
```bash
ip link set eth0 up
ip addr add 10.1.1.1/24 dev eth0
ip link add br0 type bridge
ip link set br0 up
ip link add vxlan10 type vxlan \
  id 10 \
  dev eth0 \
  local 10.1.1.1 \
  remote 10.1.1.2 \
  dstport 4789
ip link set vxlan10 up
ip link set vxlan10 master br0
ip link set eth1 up
ip link set eth1 master br0
```

## Routeur 2
```bash
ip link set eth0 up
ip addr add 10.1.1.2/24 dev eth0
ip link add br0 type bridge
ip link set br0 up
ip link add vxlan10 type vxlan \
  id 10 \
  dev eth0 \
  local 10.1.1.2 \
  remote 10.1.1.1 \
  dstport 4789
ip link set vxlan10 up
ip link set vxlan10 master br0
ip link set eth1 up
ip link set eth1 master br0
```

### HOST 1
ip link set eth1 up
ip addr add 30.1.1.1/24 dev eth1

### HOST 2
ip link set eth1 up
ip addr add 30.1.1.2/24 dev eth1



# Multicast

## Routeur 1
```bash
ip link set eth0 up
ip addr add 10.1.1.1/24 dev eth0
ip link add br0 type bridge
ip link set br0 up
ip link add vxlan10 type vxlan \
  id 10 \
  dev eth0 \
  group 239.1.1.1 \
  dstport 4789
ip link set vxlan10 up
ip link set vxlan10 master br0
ip link set eth1 up
ip link set eth1 master br0
```

## Routeur 2

```bash
ip link set eth0 up
ip addr add 10.1.1.1/24 dev eth0
ip link add br0 type bridge
ip link set br0 up
ip link add vxlan10 type vxlan \
  id 10 \
  dev eth0 \
  group 239.1.1.1 \
  dstport 4789
ip link set vxlan10 up
ip link set vxlan10 master br0
ip link set eth1 up
ip link set eth1 master br0
```