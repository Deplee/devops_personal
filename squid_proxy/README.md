Squid Proxy cloud server config for local/home network
=======================================================================

# Install squid

```
apt update && sudo apt upgrade
apt install squid
```

# Configure
Copy *.conf squid file
```
cp /etc/squid/squid.conf /etc/squid/squid.conf.back
```




```
vim /etc/squid/squid.conf
```

```
acl homenet src 95.104.186.25 # test
access allow homenet
http_port 3128
http_access deny all

# safe ports rule
acl SSL_ports port 443
acl Safe_ports port 80          # http
acl Safe_ports port 21          # ftp
acl Safe_ports port 443         # https
acl Safe_ports port 70          # gopher
acl Safe_ports port 210         # wais
acl Safe_ports port 1025-65535  # unregistered ports
acl Safe_ports port 280         # http-mgmt
acl Safe_ports port 488         # gss-http
acl Safe_ports port 591         # filemaker
acl Safe_ports port 777         # multiling http
acl CONNECT method CONNECT

# deny access to all ports except safe ports rule
http_access deny !Safe_ports

# deny connect to ports except ssl ports rule
http_access deny CONNECT !SSL_ports

# allow acces to cachemgr from  homenet
http_access allow homenet manager
http_access deny manager

```
Restart squid service

```
systemctl restart squid
```
Get squid status

```
systemctl status squid
```

# Logs of squid

Log path by default is /var/log/squid


*access.log* - main of squid log (requests & etc in this file)
*cache.log* - log with squid caches


