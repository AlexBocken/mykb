#Nextcloud
## Installation
We're assuming an Arch Linux installation, but the steps should be similar for other distributions.
There are two possible ways to serve Nextclouds PHP code: uWSGI and PHP-FPM.
We'll be using PHP-FPM as this is the recommended way and nginx is easier to setup with it, especially if you wish to enable additional plugins such as LDAP.

TODO

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
