# DNSMasq
A simple and lightweight DNS and DHCP server for local development.

Personally I have only yet used this to circumvent NAT Loopback issues with my router, but it can be used for much more.

## Installation
It's a simple
```sh
pacman -S dnsmasq
```

### Configuration

We need to disable the systemd-resolved service, as it will conflict with DNSMasq.
Afterwards we can start the DNSMasq service.
```sh
systemctl disable systemd-resolved.service
systemctl stop systemd-resolved.service
systemctl enable --now dnsmasq.service
```

We can now look into the configuration file at `/etc/dnsmasq.conf` and make changes to our liking.

```conf
listen-address=::1,127.0.0.1,192.168.1.1
```

More cached DNS queries:
```conf
cache-size=1000
```
(max 10000)


DNSSec validation:
```conf
conf-file=/usr/share/dnsmasq/trust-anchors.conf
dnssec
```

## DNS Forwarding
We will most likely not have all wanted DNS entries ourselves and should look these up on a different server.
We can do this by chaning `/etc/resolv.conf` to the following:
```conf
nameserver ::1
nameserver 127.0.0.1
options trust-ad
```
If we want Networkmanager to not overwrite this file, we can set it to immutable:
```sh
chattr +i /etc/resolv.conf
```
then restart Networkmanager:
```sh
systemctl restart NetworkManager.service
```

Now add your upstream DNS servers to `/etc/dnsmasq.conf`:
```conf
no-resolv

# Google's nameservers, for example
server=8.8.8.8
server=8.8.4.4
```

## Address Overrides
For NAT Loopback we need to override the DNS entries for our local network.
For example if we want to direct `cloud.example.com` to our server directly, we can add the following to `/etc/dnsmasq.conf`:
```conf
address=/cloud.example.com/192.168.1.2
```
adjust the IP address to your setup.

After restarting the dnsmasq service, we can check if the DNS entry is correct:
```sh
drill cloud.example.com
```

You can now set this DNS server as your primary DNS server in your router or on your local machine.
