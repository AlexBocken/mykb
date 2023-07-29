# Searx on Arch
This tutorial is on how to install Searx on Arch servers.
On Debian or other distros lacking morty, filtron, and searx in their repos the guide giving by the Searx devs themselves is fine but you will have to rely on Python VENVs and updating is difficult/tedious.

For this tutorial we will follow the recommended setup of installing morty and filtron alongside searx for a more secure setup.

For this tutorial we are assuming you already have nginx set up, a SSL certificate for the domain you want to use, and the domain we use as a dummy is `example.com`.

## Installation
Switch to a non-root user with sudo rights for an AUR manager:
```sh
su - alex
paru -S morty-git filtron-git searx
```

## Configuration
### Services
#### Morty
First we need a morty secret key which should be base64 encoded:
```sh
openssl rand -hex 16 | base64
```

Edit the `ExecStart` in `/usr/lib/systemd/system/morty.service`:
```ini
ExecStart=/usr/bin/morty -listen 127.0.0.1:3000 -key '<your_key_here>' -timeout 5
```
and add
```ini
Environment=DEBUG=false
```

We also need to add this to our `/etc/searx/settings.yml`:
```yml
result_proxy:
	url: example.com/morty/
	key: !!binary "<your_key_here>"
```

### Filtron
Should be good with defaults

### Searx
### Sytemd
Adjust your service file for searx (`/etc/uwsgi/searx.ini`) to include
```ini
# comment out the http-socket line
http = 127.0.0.1:8888

env = LANG=C.UTF-8
env = LANGUAGE=C.UTF-8
env = LC_ALL=C.UTF-8

# OPTIONAl and does nothing if disable-logging = true
logger = systemd
```

#### settings.yml
Change the following lines in `/etc/searx/settings.yml`
```yml
server:
	image_proxy: True
	http_protocol_version: "1.1"

ui:
	theme_args:
		oscar-style: logicodev-dark

# Ensure that this is also set to something, should be done automatically by the PKGBUILD for searx
server:
	secret_key: "<ensure_this_is_set_to_something_secure>"
```

#### Nginx

In the appropriate `server{}` section of your nginx setup add the following:
Where `MINOR_VERSION` should be `11` for example for python 3.11, adjust appropriately.
```nginx
location /searx/static/ {
	alias /usr/lib/python3.<MINOR VERSION>/site-packages/searx/static/;
}
location /morty {
	proxy_pass         http://127.0.0.1:3000/;

	proxy_set_header   Host             $host;
	proxy_set_header   Connection       $http_connection;
	proxy_set_header   X-Real-IP        $remote_addr;
	proxy_set_header   X-Forwarded-For  $proxy_add_x_forwarded_for;
	proxy_set_header   X-Scheme         $scheme;
}
location /searx{
    proxy_pass         http://127.0.0.1:4004/;

    proxy_set_header   Host             $host;
    proxy_set_header   Connection       $http_connection;
    proxy_set_header   X-Real-IP        $remote_addr;
    proxy_set_header   X-Forwarded-For  $proxy_add_x_forwarded_for;
    proxy_set_header   X-Scheme         $scheme;
    proxy_set_header   X-Script-Name    /searx;
}
```

Verify via `nginx -t`, then we are ready to start our services.

```sh
systemctl daemon-reload
sysetmctl restart nginx
systemctl enable --now morty
systemctl enable --now filtron
systemctl enable --now uwsgi@searx
```

You should now be able to use searx @ https://example.com/searx
