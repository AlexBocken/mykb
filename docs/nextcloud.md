# Nextcloud
## Installation
We're assuming an Arch Linux installation, but the steps should be similar for other distributions.
There are two possible ways to serve Nextclouds PHP code: uWSGI and PHP-FPM.
We'll be using PHP-FPM as this is the recommended way and nginx is easier to setup with it, especially if you wish to enable additional plugins such as LDAP.

Be prepared for quite a bit of work, with too many files which look identical, but it's worth it.
This instal guide is based on the [Arch Wiki](https://wiki.archlinux.org/index.php/Nextcloud) and the [Nextcloud documentation](https://docs.nextcloud.com/server/20/admin_manual/installation/source_installation.html). It mainly emphasizes some points which go under in the Arch Wiki article.

We assume postgresql as the database backend, but you can also use mysql/mariadb (which is also the recommended way by Nextcloud). I do this because I run a lot of other stuff on postgresql already and like it :).
PostgreSQL is said to deliver better performance and overall has fewer quirks compared to MariaDB/MySQL but expect less support from Nextcloud devs and community.
Nginx is already assumed to be set up and you have a certbot certificate for your domain.
In these instructions we will use `cloud.example.com` as the domain name, but you should of course replace it with your own.

First, install the required packages:
```sh
pacman -S nextcloud
```
When asked, choose `php-legacy` as your PHP version.
```sh
pacman -S php-legacy-imagick lbrsvg --asdeps
```
### Configuration
#### PHP
```sh
cp /etc/php-legacy/php.ini /etc/webapps/nextcloud
chown nextcloud:nextcloud /etc/webapps/nextcloud/php.ini
```
enable the following extensions in `/etc/webapps/nextcloud/php.ini`:
```ini
extension=bcmath
extension=bz2
extension=exif
extension=gd
extension=iconv
extension=intl
extension=sysvsem
; in case you installed php-legacy-imagick (as recommended)
extension=imagick
```
Set date.timezone. For example:
```ini
date.timezone = Europe/Zurich
```
Raise PHP memory limit to at least 512MB:
```ini
memory_limit = 512M
```
Limit Nextcloud's access to the filesystem:
```ini
open_basedir=/var/lib/nextcloud:/tmp:/usr/share/webapps/nextcloud:/etc/webapps/nextcloud:/dev/urandom:/usr/lib/php-legacy/modules:/var/log/nextcloud:/proc/meminfo:/proc/cpuinfo
```

#### Nextcloud
In `/etc/webapps/nextcloud/config/config.php` add:

```php
'trusted_domains' =>
  array (
    0 => 'localhost',
    1 => 'cloud.example.com',
  ),
'overwrite.cli.url' => 'https://cloud.example.com/',
'htaccess.RewriteBase' => '/',
```

#### System and environment

To make sure the Nextcloud specific `php.ini` is used by the `occ` tool set the environment variable `NEXTCLOUD_PHP_CONFIG`:
```sh
export NEXTCLOUD_PHP_CONFIG=/etc/webapps/nextcloud/php.ini
```
And also add this to your `.bashrc` or `.zshrc` (whichever is your shell) to make it permanent.

As a privacy and security precaution create the dedicated directory for session data:
```sh
install --owner=nextcloud --group=nextcloud --mode=700 -d /var/lib/nextcloud/sessions
```

#### PostgreSQL
I'm assuming you already have postgres installed and running. (Till feel free to improve this section)
For additional security in this scenario it is recommended to configure PostgreSQL to only listen on a local UNIX socket:
In `/var/lib/postgres/data/postgresql.conf`:
```
listen_addresses = ''
```

Especially do not forget to initialize your database with `initdb` if you have not setup postgresql yet.

Now create a database and user for Nextcloud:
```sh
su - postgres
psql
CREATE USER nextcloud WITH PASSWORD 'db-password';
CREATE DATABASE nextcloud TEMPLATE template0 ENCODING 'UNICODE';
ALTER DATABASE nextcloud OWNER TO nextcloud;
GRANT ALL PRIVILEGES ON DATABASE nextcloud TO nextcloud;
\q
```
and of course replace `db-password` with a strong password of your choice.

Additionally install `php-legacy-pgsql`:
```sh
pacman -S php-legacy-pgsql --asdeps
```
and enable this in /etc/webapps/nextcloud/php.ini:
```ini
extension=pdo_pgsql
```

Now setup Nextcloud's database schema with:
```sh
occ maintenance:install \
    --database=pgsql \
    --database-name=nextcloud \
    --database-host=/run/postgresql \
    --database-user=nextcloud \
    --database-pass=<db-password> \
    --admin-pass=<admin-password> \
    --admin-email=<admin-email> \
    --data-dir=/var/lib/nextcloud/data
```
and adjust the appropriate values in `<>` to your specific setup.

Congrats, you now have nextcloud setup. Currently it is not yet being served, for this we need to continue with our fpm and nginx setup.

#### FPM
Install `php-legacy-fpm`:
```sh
pacman -S php-legacy-fpm --asdeps
```
##### php-fpm.ini
We don't want to use the default php.ini for php-fpm, but a dedicated one. Hence we first copy the default php.ini to a dedicated one:

```sh
cp /etc/php-legacy/php.ini /etc/php-legacy/php-fpm.ini
```

Enable opcache in `/etc/php-legacy/php-fpm.ini`:
```ini
zend_extension=opcache
```
And set the following parameters under `[opcache]` in `/etc/php-legacy/php-fpm.ini`:
```ini
[opcache]
opcache.enable = 1
opcache.interned_strings_buffer = 8
opcache.max_accelerated_files = 10000
opcache.memory_consumption = 128
opcache.save_comments = 1
opcache.revalidate_freq = 1
```
This should differ from the default only in `opcache.revalidate_freq` but be sure to uncomment all of them anyways.

#### nextcloud.conf
Next you have to create a so called pool file for FPM. It is responsible for spawning dedicated FPM processes for the Nextcloud application. Create a file `/etc/php-legacy/php-fpm.d/nextcloud.conf`.
You can use the file in this repository as a template [Here a link](../static/nextcloud/nextcloud.conf). It should work out of the box without any modifications.

Create the access log directory:
```sh
mkdir -p /var/log/php-fpm-legacy/access
```

#### Systemd service
To overwrite the default php-fpm-legacy service create a file in `/etc/systemd/system/php-fpm-legacy.service.d/override.conf` with the following content:
```ini
[Service]
ExecStart=
ExecStart=/usr/bin/php-fpm-legacy --nodaemonize --fpm-config /etc/php-legacy/php-fpm.conf --php-ini /etc/php-legacy/php-fpm.ini
ReadWritePaths=/var/lib/nextcloud
ReadWritePaths=/etc/webapps/nextcloud/config
```

Now you can `systemctl enable --now php-fpm-legacy`.

##### Keep /etc tidy
As a small bonus you can remove the unnecessary uwsgi config files by adding this to `/etc/pacman.conf`:

```
# uWSGI configuration that comes with Nextcloud is not needed
NoExtract = etc/uwsgi/nextcloud.ini
```
#### Nginx
Finally we're at the nginx part and are almost ready to test our setup.
We're assuming you have a working nginx setup with a certbot certificate for your domain and possible domains are in `/etc/nginx/sites-available/` and symlinked to `/etc/nginx/sites-enabled/` to enable them (like Debian).

The nextcloud documentation has a great [example nginx configuration](https://docs.nextcloud.com/server/20/admin_manual/installation/source_installation.html#example-nginx-configuration) which we will use as a base.
You can find the modified version in this repository [here](../static/nextcloud/nextcloud_nginx).
Simply copy this file into `/etc/nginx/sites-available/nextcloud`, replace `cloud.example.com` with your domain, and symlink it to `/etc/nginx/sites-enabled/nextcloud`.

You should now be able to restart nginx and access your nextcloud instance at https://cloud.example.com.

##### Strict Transport Security
For additional security, if everything works fine and you're happy with your domain you can uncomment the HSTS section in the nginx setup.
```nginx
    add_header Strict-Transport-Security "max-age=15768000; includeSubDomains; preload" always;
```

#### Background jobs
Nextcloud requires certain tasks to be run on a scheduled basis. See Nextcloud's documentation for some details. The easiest (and most reliable) way to set up these background jobs is to use the systemd service and timer units that are already installed by nextcloud.

Override to the correct php version by adding the file `/etc/systemd/system/nextcloud-cron.service.d/override.conf` with the following content:
```ini
[Service]
ExecStart=
ExecStart=/usr/bin/php-legacy -c /etc/webapps/nextcloud/php.ini -f /usr/share/webapps/nextcloud/cron.php
```

After that enable and start nextcloud-cron.timer (not the service).
```sh
systemctl enable --now nextcloud-cron.timer
```

### Performance Improvements by in-memory caching
Nextcloud's documentation recommends to apply some kind of in-memory object cache to significantly improve performance.
You are able to use both APCu and Redis simultaneously for caching. The combination should be faster than either one alone.

#### APCu
Install `php-legacy-apcu`:
```sh
pacman -S php-legacy-apcu --asdeps
```

Uncomment the follwing in `/etc/php-legacy/conf.d/apcu.ini`:
```ini
extension=apcu.so
```

In `/etc/webapps/nextcloud/php.ini` enable the following extensions by uncommenting this:
```ini
extension=apcu
apc.ttl=7200
apc.enable_cli = 1
```
Order is relevant so uncomment, don't add.

in `/etc/php-legacy/php-fpm.d/nextcloud.conf` uncomment the following under `[nextcloud]`:
```ini
php_value[extension] = apcu
php_admin_value[apc.ttl] = 7200
```
Restart your application server:
```sh
systemctl restart php-fpm-legacy
```
Add to `/etc/webapps/nextcloud/config/config.php `:
```php
'memcache.local' => '\OC\Memcache\APCu',
```
to the `CONFIG` array. (So `);` should be after this)
A second application server retart is required and everything should be working.
```sh
systemctl restart php-fpm-legacy
```
#### Redis

Install redis and the php-legacy extensions:
```sh
pacman -S redis
pacman -S php-legacy-redis php-legacy-igbinary --asdeps
```

Adjust the following in `/etc/redis.conf`:
```ini
protected-mode yes # only listen on localhost
port 0 # only listen on unix socket
unixsocket /run/redis/redis.sock
unixsocketperm 770
```
The rest should be able to stay as is.
Start and enable the redis service:
```sh
systemctl enbale --now redis
```
and check that it is running:
```sh
systemctl status redis
```
Also check that the socket is created:
```sh
ls -l /run/redis/redis.sock
```
You can also run a sanity check by connecting to the socket:
```sh
redis-cli -s /run/redis/redis.sock ping
```
(You should get a `PONG` response)

If everything works fine on the redis side, we can now configure php to use it.

In `/etc/php-legacy/conf.d/redis.ini` uncomment the following:
```ini
extension=redis
```
and analogously in `/etc/php-legacy/php-fpm.d/igbinary.ini`:
```ini
[igbinary]
extension=igbinary.so

igbinary.compact_strings=On
```
Now we can configure Nextcloud to use redis as a cache.
First, add the nextcloud user to the redis group:
```sh
usermod -a -G redis nextcloud
```
You can verify that nextcloud now has access to the redis socket by running:
```sh
sudo -u nextcloud redis-cli -s /run/redis/redis.sock ping
```

In `/etc/webapps/nextcloud/php.ini` uncomment the following:
```ini
; REDIS
extension=igbinary
extension=redis
```
and add the redis unix socket directory to the `open_basedir` directive:
```ini
open_basedir = <your_current_value>:/run/redis
```

In /etc/webapps/nextcloud/config/config.php add the following to the `CONFIG` array:
```php
'memcache.distributed' => '\\OC\\Memcache\\Redis',
'filelocking.enabled' => 'true',
'memcache.locking' => '\\OC\\Memcache\\Redis',
'redis' =>
array (
    'host' => '/run/redis/redis.sock',
    'port' => 0,
),
```
And finally in `/etc/php-legacy/fpm.d/nextcloud.conf` uncomment:
```ini
php_value[extension] = igbinary
php_value[extension] = redis
```
Also, add to the `open_basedir` directive the redis unix socket directory:
```ini
php_value[open_basedir] = <your_current_value>:/run/redis
```
Restart your application server:
```sh
systemctl restart php-fpm-legacy
```
Check that everything works by visiting cloud.example.com and checking the admin overview page.
If you have an internal server error and are not even able to access cloud.example.com, check the nginx error log for details.

### Do not bruteforce throttle local connections
You might see in your admin overview (https://cloud.example.com/settings/admin/overview) an error message like this:

Your remote address was identified as "192.168.1.1" and is bruteforce throttled at the moment slowing down the performance of various requests. If the remote address is not your address this can be an indication that a proxy is not configured correctly. Further information can be found in the documentation ↗.

This is because Nextcloud is not able to detect the specific local machine you're connecting from and hence throttles all local connections.
The underlying issue is not Nextcloud but your Network setup, specifically your router not allowing for the disabling of NAT Loopback.
Discussion of this problem can be found here: https://help.nextcloud.com/t/all-lan-ips-are-shown-as-the-router-gateway-how-can-i-get-the-actual-ip-address/134872

Your solution: Set up a local DNS server and resolve your domain to your local IP address, not the public one.
A simple appraoch would be to use dnsmasq for this.
See [my dnsmasq.md](./dnsmasq.md) for more details on how to set this up.

## Syncing files with Nextcloud
They GUI for syncing is surprisingly unusable, luckily the CLI is much better.
On Arch Linux you can install the `nextcloud-client` package.
Syncing should now be a simple

```
nextcloudcmd -u "email@example.com" --password "$(pass <your_password_path> | head -n1)"  <local_folder_for_syncing> https://cloud.example.com
```
Of course adjust to your setup.
Adding `-s` will make it sync a bit less verbose.

## Setup a drop-off folder in Nextcloud
This is a quite useful feature to allow others to upload files to your Nextcloud without having to create an account.
Very user-friendly for non-technical people to share high-resolution photos for example.
The share link can also be password-protected such that not everyone can upload files to your server.

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
We are using `vdirsyncer` to sync our contacts with Nextcloud. For this, install it:

```sh
sudo pacman -S vdirsyncer
```

Then create a config file `~/.config/vdirsyncer/config` with the following content:
```
[general]
status_path = "~/.config/vdirsyncer/status/"

[pair nextcloud_contacts]
a = "nextcloud_contacts_local"
b = "nextcloud_contacts_remote"
collections = ["from a", "from b"]

[storage nextcloud_contacts_local]
type = "filesystem"
path = "~/.local/share/vdirsyncer/"
fileext = ".vcf"

[storage nextcloud_contacts_remote]
type = "carddav"
url = "https://cloud.example.com/remote.php/dav/addressbooks/users/<your_user>/contacts/"
auth = "basic"
username = "<your_user>"
password.fetch = ["shell", "pass <your_password_path> | head -n1"]
```
Note that <your_user> is not your email address but the username you can also use to login into nextcloud.
You can find it under https://cloud.example.com/settings/users as the smaller text under your display name.

Add to your `~/.config/khard/khard.conf`:
```
[addressbooks]
[[nextcloud]]
path = ~/.local/share/vdirsyncer/contacts/
```
And create `~/.local/share/vidirsyncer/contacts` if not already existing.
We will use this folder to store our contacts.

Initial discovery requires you to run

```sh
vdirsyncer discover nextcloud_contacts
```
once.
You should now be able to sync your contacts with `vdirsyncer sync` and view them with `khard`.

### Cronjob
You can now of course add `vdirsyncer sync` to your cronjob to sync your contacts regularly.
Keep in mind that this will require additional environment variables for pass to work as well, sourcing your `.zprofile` should do the trick with a correct setup.
Ergo your cronjob should look something like this:

```cron
*/15 * * * * . ~/.zprofile && vdirsyncer sync
```
See [neomutt.md](./neomutt.md) for more details on how to use khard with neomutt for autocompletion.

## Sync Calendar with Calcurse

Create a config file `~/.config/calcurse/caldav/config`. You can use the following template:
```
# If you want to synchronize calcurse with a CalDAV server using
# calcurse-caldav, create a new directory at $XDG_CONFIG_HOME/calcurse/caldav/
# (~/.config/calcurse/caldav/) and $XDG_DATA_HOME/calcurse/caldav/
# (~/.local/share/calcurse/caldav/) and copy this file to
# $XDG_CONFIG_HOME/calcurse/caldav/config and adjust the configuration below.
# Alternatively, if using ~/.calcurse, create a new directory at
# ~/.calcurse/caldav/ and copy this file to ~/.calcurse/caldav/config and adjust
# the configuration file below.

[General]
# Path to the calcurse binary that is used for importing/exporting items.
Binary = calcurse

# Host name of the server that hosts CalDAV. Do NOT prepend a protocol prefix,
# such as http:// or https://. Append :<port> for a port other than 80.
Hostname = cloud.example.com

# Path to the CalDAV calendar on the host specified above. This is the base
# path following your host name in the URL.
Path = /remote.php/dav/calendars/<your_username>/<your_calendar_name>/

# Type of authentication to use. Must be "basic" or "oauth2"
#AuthMethod = basic

# Enable this if you want to skip SSL certificate checks.
InsecureSSL = No

# Disable this if you want to use HTTP instead of HTTPS.
# Using plain HTTP is highly discouraged.
HTTPS = Yes

# This option allows you to filter the types of tasks synced. To this end, the
# value of this option should be a comma-separated list of item types, where
# each item type is either "event", "apt", "recur-event", "recur-apt", "todo",
# "recur" or "cal". Note that the comma-separated list must not contain any
# spaces. Refer to the documentation of the --filter-type command line argument
# of calcurse for more details. Set this option to "cal" if the configured
# CalDAV server doesn't support tasks, such as is the case with Google
# Calendar.
#SyncFilter = cal,todo
SyncFilter = cal

# Disable this option to actually enable synchronization. If it is enabled,
# nothing is actually written to the server or to the local data files. If you
# combine DryRun = Yes with Verbose = Yes, you get a log of what would have
# happened with this option disabled.
DryRun = No

# Enable this if you want detailed logs written to stdout.
Verbose = Yes

# Credentials for HTTP Basic Authentication (if required).
# Set `Password` to your password in plaintext (unsafe),
# or `PasswordCommand` to a shell command that retrieves it (recommended).
[Auth]
Username = alexander@bocken.org
# Password = <your_password>
# PasswordCommand = # Does not appear to work

# Optionally specify additional HTTP headers here.
#[CustomHeaders]
#User-Agent = Mac_OS_X/10.9.2 (13C64) CalendarAgent/176

# Use the following to synchronize with an OAuth2-based service
# such as Google Calendar.
#[OAuth2]
#ClientID = your_client_id
#ClientSecret = your_client_secret

# Scope of access for API calls. Synchronization requires read/write.
#Scope = https://example.com/resource/scope

# Change the redirect URI if you receive errors, but ensure that it is identical
# to the redirect URI you specified in the API settings.
#RedirectURI = http://127.0.0.1
```

The `Path` variable is simply the path you get when your click on the edit button for the calendar in the web interface and copy the "Internal link".

Adjusting the username and calendar name in the above template should also simply work:
You can find your username as described in the khard section.
The calendar name is the name you gave your calendar in the web interface all lower case.

For Authentication I could not get the `PasswordCommand` to work. Simply storing the password using the Password option is of course not recommended.
Luckily there is the `CALCURSE_CALDAV_PASSWORD` environment varibale which we can set programmatically instead.

To initialize the setup run now:
```sh
CALCURSE_CALDAV_PASSWORD=$(pass <nextcloud_password_path>) calcurse-caldav --init=two-way
```

And for future syncing a simple
```sh
CALCURSE_CALDAV_PASSWORD=$(pass <nextcloud_password_path>) calcurse-caldav
```
does the trick.

Like with `khard` you can now add this to your cronjob to sync your calendar regularly and will also require a sorucing of `~/.zprofile` to work with `pass`. Maybe a wrapper script is appropriate here.
See my [syncclouds.sh script as an example](https://bocken.org/git/Alexander/dotfiles/src/branch/master/.local/bin/syncclouds.sh) which also handles corrupted lockfiles because of unexpected aborts.

TODO: investigate wheter todos are possible to also be synced. Could not get it working myself.

### Sync to Android

If you wish to sync your calendar to your Android phone, you can use the [DAVx⁵](https://www.davx5.com/) app. Contacts are also possible
