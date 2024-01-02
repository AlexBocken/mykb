# CalDAV Server with Calcurse

### Goal

- Set up a own caldav server which allows to sync [calcurse](https://www.calcurse.org/) with your other devices.
If you want to run nextcloud anyways, you can also use its caldav server.
This is a more light weight solution, which does not require a full php environment.

### Software used

- A current debian install is assumed, using nginx as its sever. Tested on debian 11.
- [Baikal](https://sabre.io/baikal/)
    - Other more light weight setups possible, see [Radicale](https://radicale.org/v3.html) or [carldav](https://github.com/ksokol/carldav). Did not work with calcurse directly. Planned for the future, as it does not require a php environment.
- [Davx^5 Android](https://www.davx5.com/)

### Install

1. Make sure all the dependencies are installed

```sh
sudo apt-get install nginx php-fpm php-sqlite3 composer php-xml php-curl -y
```

2. Go to your sources directory. Here it is assumed to be `/opt/src/` and install Baikal. Default port is 9999, so adjust it to your wishes. Assumed to be 9999 throughout this write-up.

```sh
cd /opt/src
git clone https://github.com/sabre-io/baikal
cd baikal
composer install
```
3. Make the baikal directory writable by the websever process. This is strictly necessary for `Specfic` and `config`.

```sh
chown -R www-data:www-data Specific config
```

I found an issue, that maybe got solved by owning the whole baikal directory. So in case you find yourself with an error related to write-permission denials, run

```sh
sudo chown -R www-data:www-data .
```

### Server Config

1. Create the corresponding nginx config for the page.

```sh
cd /etc/nginx/sites-available
touch baikal.site
```

2. Copy the following config. Adjust the `root /opt/src/baikal/html` path for your install and make sure that the correct php-version. (See `php --version`).

```sh
server {

    listen 9999 default_server;

    root /opt/src/baikal/html;
    dav_methods PUT DELETE MKCOL COPY MOVE;

    index index.php index.html index.htm index.nginx-debian.html;
    server_name _;

    rewrite ^/.well-known/caldav /dav.php redirect;
    rewrite ^/.well-known/carddav /dav.php redirect;
    charset utf-8;

    location ~ /(\.ht|Core|Specific|config) {
        deny all;
        return 404;
    }
    location ~ ^(.+.php)(.*)$ {
        try_files $fastcgi_script_name =404;
        include /etc/nginx/fastcgi_params;
        fastcgi_split_path_info ^(.+.php)(.*)$;
	    fastcgi_pass unix:/run/php/php7.4-fpm.sock; #Adjust here for your version
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
        fastcgi_param PATH_INFO $fastcgi_path_info;
    }

    location ~ /.ht {
        deny all;
    }

}
```

3. Link the available site to the enabled ones

```sh
ln -s /etc/nginx/sites-available/baikal.site /etc/nginx/sites-enabled/
```

4. Restart nginx after testing the config files

```sh
nginx -t
systemctl restart nginx
```

5. Check if baikal is running on `<hostname/ip>:9999`.

### Baikal Config

1. Follow the setup guide, setting the time-zone, and enable the `basic` authentication type. If wanted, it is possible to send invite emails for upcoming events to its participants. If you are interested in this, check the web, as I did not go down that path.

2. Continue and select the SQLite data base and continue. If you have specific reasons to use SQL, you can do this with

```sh
mysql -u root -p
```

and then create a new baikal data-base.

```sql
CREATE DATABASE baikal;
CREATE USER 'baikal'@'localhost' IDENTIFIED BY '<YOUR BEST PASSWORD123>';
GRANT ALL PRIVILEGES ON baikal.* TO 'baikal'@'localhost';
FLUSH PRIVILEGES;
```
Add your selection of host, name and username to the page and continue. We assume a SQLite database.

3. We now log in to baikal using the admin user. Now we can create users. We create a `testuser` under the mail address `test@testing.ts`. Now we can adjust the default calender or add more calenders if we like. We can also enable or disable todo-sync or note-syncing.

### Calcurse Config

1. Make sure `calcurse-caldav` is available as a command .
2. Copy the config and adjust

```sh
[General]
### Adjust here when you also want to sync todo's and notes! (cal, todo, note)
SyncFilter = cal
DryRun = No
Verbose = Yes

AuthMethod = basic
Hostname = IPADRESS:9999

#Path = /dav.php/calendars/<username>/<calender-name>
Path = /dav.php/calendars/test/default

InsecureSSL = No
# I run this on a local server, which does not have https enabled.
# If you enable https on the baikal page, which is highly recommended when running it open to the web, change this to Yes
HTTPS = No

[Auth]
#Username = <username>
Username = test
#Either use plaintext password (not recommended...) or add your password to your CLI password manager (pass) under baikal/username
#Password = testpassword1234
PasswordCommand = pass baikal/username
```
3. Save and run `calcurse-caldav --init=two-way`. Other initialisation options exists and are explained [here](https://www.calcurse.org/files/calcurse-caldav.html). This does the initial sync between your baikal instance and calcurse.

4. For future sync, either
    - set up a post-save and/or start hook running `calcurse-caldav`
    - just run `calcurse-caldav` everytime you like to have things synced.

### Android

Some calendars have build in caldav support. For those follow their procedure.
If not, we can use Davx^5. Get it from F-Droid and drop in your URL, username and password. Set up a sync period and select the calendar in your calendar app.
In theory it is also possible to sync your address book.


### Future:

- Use some other caldav server, which might be more light weight.
- Test the note and todo sync
- Test the address-book sync, maybe with [abook](https://abook.sourceforge.io/)
