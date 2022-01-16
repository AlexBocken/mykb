# General

[Rainloop](https://www.rainloop.net/) is a web-based email client that works with your local install of dovecot etc. Its easy to install and use.

# Setting up LEMP Stack

1. `apt install mariadb-server`
2. `systemctl enable mysql`
3. `apt install php php-fpm php-mysql -y`
4. `systemctl enable php-fpm` To test the php setup add the following to your site-available nginx folder. Restart nginx using `systemctl restart nginx` and add a new page called `index.php` to your homepage directory with `<?php phpinfo();?>` as the only content. If the php install worked fine, this will show you the installed php packages. Delete this afterwords.



```
	   location ~ \.php$ {
      		include snippets/fastcgi-php.conf;
      		fastcgi_pass unix:/var/run/php/php7.3-fpm.sock;
		}
```

# Installing rainloop

1. `apt install php7.3-{curl,xml}`
2. `wget http://www.rainloop.net/repository/webmail/rainloop-community-latest.zip`
3. `mkdir /var/www/html/rainloop`
4. `unzip rainloop-community-latest.zip -d /var/www/html/rainloop/`
5. `find /var/www/html/rainloop/ -type d -exec chmod 755 {} \;`
6. `find /var/www/html/rainloop/ -type f -exec chmod 644 {} \;`
7. `chown -R www-data.www-data /var/www/html/rainloop/`
8. Edit the `nginx` entry for the webmail : `vim /etc/nginx/sites-available/rainloop.conf`. Make sure that the `php` version you installed above matches the php version in line 20. It also should match the php version of the LEMP stack. Also change the hostname accordingly.
```sh
	server {
 		listen 80;

	server_name webmail.hostname.xyz;
	root /var/www/html/rainloop;

        access_log /var/log/rainloop/access.log;
        error_log /var/log/rainloop/error.log;

	index index.php;

	location / {
		try_files $uri $uri/ /index.php?$query_string;
	}

	location ~ \.php$ {
            fastcgi_index index.php;
            fastcgi_split_path_info ^(.+\.php)(.*)$;
            fastcgi_keep_conn on;
      	    fastcgi_pass unix:/var/run/php/php7.3-fpm.sock;
            include /etc/nginx/fastcgi_params;
            fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
 	}
        location ~ /\.ht {
            deny all;
    }
	location ^~ /data {
	    deny all;
	}
}
```
10. `mkdir /var/log/rainloop`
11. `nginx -t`
12. `ln -s /etc/nginx/sites-available/rainloop.conf /etc/nginx/sites-enabled/`
13. `systemctl reload nginx`

# Configure RainLoop

1. Go to `http:/webmail.hostname.xyz/?admin`. Here a webinterface should pop up (If not - ty to check the php install - all same versions? Is php accessible? Are the permissions set correctly?
2. Log in using `admin` and `12345`. Strongly recommend to change that one as soon as you log in. This can be done under `Security` in the left menu.
3. Under `Domains` add your local domains, ports and authentication method and delete the defaults.
4. Now you should be able to log in to the client on `webmail.hostname.xyz` using your email address and password.

# Add database for contacts

1. `mysql -uroot -p`
2. Add a database (copy paste each single line - change `rainlooppassword` to something propper
```sh

create database rainloopdb;
GRANT ALL PRIVILEGES ON rainloopdb.* TO 'rainloopuser'@'localhost' IDENTIFIED BY 'rainlooppassword';
flush privileges;
quit
```
3. Go to the admin panel to `Contacts` and activate the data base
4. Select storage `mysql` and choose as DSN `mysql:host=localhost;port=3306;dbname=rainloopdb`. The user name is `rainloopuser` and the password the password you used to set up the database.

# Certbot

Give the webmail client proper security using `certbot --nginx` to extend your certificate.
