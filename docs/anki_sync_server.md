# Anki Sync Server
With the new versions of Anki, `anki` now provides an integrated sync-server feature, allowing for up-to-date scheduler versions as long as anki on the server is also updated regularly.
Other implementations such as [Anki Sync Server](https://github.com/dsnopek/anki-sync-server) might be less resource intensive but need to be updated separately to allow for newer scheduler versions.
This requires quite a bit of memory, but a lot if it is shared. If you run anything else using python (very likely), running this sync server in addition should maybe require an additional 100-200M.

## Installation
Install anki: `paru -S anki`

We're assuming here that you are running the latest Anki on your server, however you manage to do that (some distros are quite conservative with their anki versions). On Arch, I currently maintain the `anki` and `anki-qt5` packages in the AUR so they should be up-to-date.

## Reverse Proxy using nginx
Anki creates a sync server locally on 0.0.0.0:8080. We want to put this behind a reverse proxy for convenience.
Create a new `server{}` section in your nginx setup. Recommended is a new file in `/etc/nginx/sites-available/anki_sync_server`

```nginx
server {
	server_name anki.<yourdomain.tld>;
	listen 80;
	client_max_body_size 500M;
	location / {
		proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
		proxy_set_header Host $host;

		proxy_pass http://0.0.0.0:8080;

		proxy_buffering off;
		proxy_http_version 1.1;
		proxy_set_header Upgrade $http_upgrade;
		proxy_set_header Connection "upgrade";
	}
}
```
Some of these settings are a bit overkill for anki, but are good defaults for modern web applications behind a reverse proxy.

Link to enabled sites:
```
ln -s /etc/nginx/sites-available/anki_sync_server /etc/nginx/sites-enabled/
```

Check whether the syntax is good via `nginx -t` and if so, restart nginx `systemctl restart nginx`.
This is still unencrypted. Using certbot you can now deploy certificates
```sh
certbot --nginx -d anki.<yourdomain.tld>
```
If everything goes good you should be able to verify in `/etc/nginx/sites-available/anki_sync_server`.

##  Create a user and service
Personally, I see this sync data as a kind of database and would like to store it in `/var/lib` because of this.
For security we should start anki as a separate user with write permissions confined to `/var/lib/anki`.
Create a user:

```sh
useradd -b /var/lib/ -s /usr/bin/nologin anki
mkdir /var/lib/anki
chown -R /var/lib/anki anki:anki
```

Using systemd, create a service file: `/etc/systemd/system/anki_sync_server.service`:

```systemd
[Unit]
Description=Personal Anki Sync Server
After=network.target

[Service]
ExecStart=anki --syncserver
Restart=always
User=anki
Group=anki
Environment=SYNC_BASE="/var/lib/anki"
Environment=MAX_SYNC_PAYLOAD_MEGS=500
Environment=SYNC_USER1=<name1>:<password1>
Environment=SYNC_USER2=<name2>:<password2>

[Install]
WantedBy=multi-user.target
```

You can create additional users using the `SYNC_USER<i>` environment variables. This stores the passwords in plain text on the machine so is less than optimal.

TODO: can we somehow store these env vars securely?

You should now be able to start your sync server via `systemctl start anki_sync_server.service`.
If everything looks good in the journal, you can `sytemctl renable anki_sync_server`.


## Connecting from your Client
### Desktop
1. Go to: `Tools -> Preferences -> Syncing`
2. Logout
3. set "Self-hosted-sync-server" to `https://anki.<yourdomain.tld>`
5. Restart anki
6. Click on `Sync` and login using your `<name1>` and `<password1>` which you set in the service file.

## Ankidroid
1. Go to: `Settings -> Advanced -> Custom sync server`
2. Set the sync url to: `https://anki.<yourdomain.tld>`
3. Set the media sync url to `https://anki.<yourdomain.tld>/msync`
4. Click on the sync icon in the main top-bar. Login using your `<name1>` and `<password1>` you set in the service file.

## More info
See https://docs.ankiweb.net/sync-server.html
