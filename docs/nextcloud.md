#Nextcloud
## Installation
We're assuming an Arch Linux installation, but the steps should be similar for other distributions.
There are two possible ways to serve Nextclouds PHP code: uWSGI and PHP-FPM.
We'll be using PHP-FPM as this is the recommended way and nginx is easier to setup with it, especially if you wish to enable additional plugins such as LDAP.

TODO

## Setup a drop-off folder in Nextcloud

1. Create a folder in Nextcloud, e.g. `Drop-off`.
2. Click on the share icon and under share link select "File-drop". This will create a link that you can share with others.
3. Optional: If you want to password protect the link, click on "Advanced settings" under the Sharing tab for the folder detailsand use a password of your choice.

### Human-readable link with redirect
If you want a nice human-readable link you can use your own nginx for this.
Add to your existant server block with port 443 in `/etc/nginx/sites-available/nextcloud` or your domain of choice with the following content:

```nginx
location /dropoff {
	return 301 <your nextcloud share link>;
}
```

## Sync contacts with khard
TODO

See [neomutt.md](./neomutt.md) for more details on how to use khard with neomutt for autocompletion.

## Sync Calendar with Calcurse
TODO
