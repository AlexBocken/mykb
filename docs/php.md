# PHP
An easily integratable language for dynamic HTML with read/write file access possible on the server side.

# Installation
As always, we're assuming Debian + Nginx for this.

```sh
apt update
apt install php php-fpm
```
`php-fpm` should automatically enable it's service.
Verify via `systemctl status php7.3-fpm.service`

# Setup
Check whether you want to use a TCP connection or a UNIX socket for php connections.
The default and recommended way is TCP/IP.

## TCP/IP
You can edit the IP and port of the connection in `/etc/php/7.3/fpm/pool.d/www.conf`
The default is:
```
listen = 127.0.0.1:9000
```

## Socket
For socket, use:
```
listen = run/php/php7.3-fpm.sock
```

## Nginx
To enable nginx to talk to php add the following to your website config:
```nginx
location ~\.php${
	include snippets/fastcgi-php.conf
	fastcgi_pass 127.0.0.1:9000;
}
```
replace TCP/IP address with the appropriate socket file if that's your preferred setup.
Afterwards, since you've modified the nginx config, this of course requires a `systemctl restart nginx`.
Tip: `nginx -t` let's you verify your syntx without killing the running nginx instance, leading to a smoother switchover.

Create a file in the root dir for your website (so probably somwhere in `/var/www/`) ending in `.php` with the content:
```php
<?php
	phpinfo();
```

And visit `example.com/file.php` to see whether it worked.
You should get a screen with a lot of information about your php installation.

## File writing permissions
Per default PHP is unable to read or write to your server drive.
It is best for this to re-own any directories where php will be writing to to the user and group `www-data`.
Thus a
```sh
chown -R www-data:www-data <dir>
chmod -R 744 <dir>
```
should be a good starting-off point.
Files only need to have permissions of `644` of course so maybe change that as well.

# Learning PHP
If you're completely new to php [w3schools' course](https://www.w3schools.com/php) is probably a good starting point.
