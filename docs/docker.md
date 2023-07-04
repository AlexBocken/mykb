# Docker
General tips and tricks around docker, as it's usage has become unavoidable.

## Docker compose as systemd services
You will be able to start any docker compose program via `systemctl start docker-compose@<program>`.

Create the file `/etc/systemd/system/docker-compose@.service` with the following content:
```
[Unit]
Description=%i service with docker compose
PartOf=docker.service
After=docker.service

[Service]
Type=oneshot
RemainAfterExit=true
WorkingDirectory=/etc/docker/compose/%i
ExecStart=/usr/bin/docker compose up -d
ExecStop=/usr/bin/docker compose stop

[Install]
WantedBy=multi-user.target
```

Create directories as necessary and place your `docker-compose.yml` in an appropriately named folder (as an example: "myprogram") in `/etc/docker-compose`.
Ergo: Your docker-compose.yml should be in `/etc/docker/compose/myprogram/docker-compose.yml`.

Reload the daemon and start your service:
```
systemctl daemon-reload
sysetmctl start docker-compose@myprogram
```
More ideas:
https://gist.github.com/mosquito/b23e1c1e5723a7fd9e6568e5cf91180f
