
# PreRequisites

1. A domain name provider ([EPIK](epik.com), etc)
2. A VPS provider ([vultr](vultr.com), etc)

# Set DNS Records

1. Get the IP of your server from your VPS provider.
2. Enable Reverse DNS for IPv6
3. Enter the IP in to the DNS system interface of you DNS provider.
	- Enable IPv4 and IPv6 this way.

# Server

- `ssh-copy-id root@domain.xyz`
- Edit /etc/ssh/sshd_config : `UsePAM no` and `PasswordAuthentication no` and restart ssh using `systemctl reload sshd`
- `apt update; apt upgrade` and delete scetchy line from `.bashrc`.
- install webserver stuff `apt install nginx python3-certbot-nginx rsync`

# Website

- In `/etc/nginx/sites-available` copy `default` to `domainname`.
- Here change the root line to `root /PATH/TO/WEBSITE`
- Change the `server_name` line to `server_name HOSTNAME.xyz www.HOSTNAME.xyz`
- Copy this file to make the mail server and change `root` again to something relatable like `root /var/www/mail`.
- Change the `server_name` to mail.HOSTNAME.xyz and www.mail.HOSTNAME.xyz
- Now link both files to `/etc/nginx/sites-enabled/` using `ln -s /etc/nginx/sites-available/mail /etc/nginx/sites-enabled/`
- Create the directories with `mkdir -p /var/www/domainname /var/www/mail` and add a `index.html` to both of them.


## RSYNC command
`rsync -uvrP --delete-after LOCAL root@HOSTNAME.xyz:/var/www/name/`

## CERTBOT

Run `certbot --nginx` and follow the hints on the screen.
It guides you quite detailed through the procedure.
Make sure that in the end you select the port-forwarding.

## MAIL

Use `emailwiz` from `lukesmith.xyz/emailwiz.sh` and run using `internet page` and replace guest.guest with domainname

Copy the output to the txt records on epik.com with mail._domainkey.HOSTNAME.xyz

Add the wanted user using `useradd -G mail -m username` and add password use `passwd username`

To enable the email to pass, you need to set the firewall correctly.
Next to the ports listed below, sometimes port 25 can be probelmatic.
Make sure to use `ufw` to open these ports and also use your VPS interface to open these ports if necessary.

| Server            | Protocol | Port | Handshake | Role     |
| :---              | :---     | :--- | :---      | :---     |
| mail.HOSTNAME.xyz | SMTP     | 587  | STARTLS   | Outgoing |
| mail.HOSTNAME.xyz | IMAP     | 993  | TSL/SSL   | Incoming |

Also set the MX records on you dns service provider and let it point to `mail.HOSTNAME.xyz`.

# Possible Hickups on the way

- If you had that domain already set up on a server with a different IP address, you have to clean out your local `.ssh/known_hosts` before you can connect using `ssh`.
- Make sure that the config files for nginx include `listen 80; listen [::]:80;`, otherwise the certbot install will fail.
