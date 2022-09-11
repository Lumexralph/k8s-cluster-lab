# setup the loadbalancer
# LOADBALANACER
# download and install the loabbalancer
sudo apt-get update && sudo apt-get install -y haproxy

# create configuration file
cat <<EOF | sudo tee /etc/haproxy/haproxy.cfg
global
    log /dev/log local0
    log /dev/log local1 notice
    daemon

defaults
    mode                    http
    log                     global
    option                  httplog
    option                  dontlognull
    option http-server-close
    option forwardfor       except 127.0.0.0/8
    option                  redispatch
    retries                 1
    timeout http-request    10s
    timeout queue           20s
    timeout connect         5s
    timeout client          20s
    timeout server          20s
    timeout http-keep-alive 10s
    timeout check           10s

frontend kubernetes
    bind 192.168.5.30:6443
    option tcplog
    mode tcp
    default_backend kubernetes-controller-nodes

backend kubernetes-controller-nodes
    option httpchk GET /healthz
    http-check expect status 200
    mode tcp
    option ssl-hello-chk
    balance     roundrobin
    server controller-1 192.168.5.11:6443 check fall 3 rise 2
    server controller-2 192.168.5.12:6443 check fall 3 rise 2
EOF

sudo service haproxy restart
