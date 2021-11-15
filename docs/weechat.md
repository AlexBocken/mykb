# Weechat

## General
You can move the location of the config folder by setting the enviroment variable `WEECHAT_HOME`.
If you have a similar setup to mine, adding
```sh
export WEECHAT_HOME="${XDG_CONFIG_HOME:-$HOME/.config}/weechat"
```
should do the trick.

## Matrix Support:

We are using [this python plugin](https://github.com/poljar/weechat-matrix) to achieve matrix connections via a TUI.
A [rust version](https://github.com/poljar/weechat-matrix-rs) is in developement, but not as feature rich yet.

### Installation
```
sudo pacman -S libolm
git clone https://github.com/poljar/weechat-matrix
cd weechat-matrix
pip install -r requirements.txt
make install
```

### Configuration

#### Connecting
Configuration is completed primarily through the Weechat interface.  First start Weechat, and then issue the following commands:

1. Start by loading the Weechat-Matrix script:
```
/script load matrix.py
```
2. Add your custom server to the script:
```
/matrix server add myserver myserver.org
```
3. Add the appropriate credentials
```
/set matrix.server.myserver.username johndoe
/set matrix.server.myserver.password jd_is_awesome
```
4. Now try to connect:
```
/matrix connect myserver
```
5. Automatically load the script

```sh
cd $WEECHAT_HOME/python/matrix
ln -s ../matrix.py ~/.weechat/python/autoload
```

6. Automatically connect to the server

```
/set matrix.server.myserver.autoconnect on
```
7. If everything works, save the configuration

```
/save
```
Note how this allows you to connect to multiple matrix servers simultaneously in the same weechat instance.

### Verify session
1. Figure out the session ID of a device you want to use for interactive verification. Either `/olm info all` (`/olm` needs to be executed in a matrix chat. Don't worry the other person will not receive a message). You can also find your session ID in Element under `Settings -> Security & Privacy -> Session ID`
2. In Weechat in a matrix chat, type:
	```
	/olm verification start <your_username> <session ID of other device>
	```
	Note how weechat has tab-completion here.
3. If the other session is an Element session you should see a notification pop-up requesting a verification. Accept this
4. Verify that the emojis match on both devices. In weechat these get displayed in the `1.weechat` room
5. If they do, confirm in the other session and then in weechat using
	```
	/olm verification accept <your_username> <session ID of other device>
	```
6. Your session should now be verified.

### Importing Encryption keys
To get old messages decryped faster, it is reccomended to import encryption keys manually.
1. Export Encryption keys in Element via `Settings -> Security & Privacy -> Cryptography -> Export E2E room keys`. If you're not backing up these encryption keys the password does not need to be complex.
2. In weechat, import them via `/olm import <file> <password>` Note that relative paths start at `WEECHAT_HOME`, not `HOME`.
3. delete previously exported encryption keys

## libnotify Notification support
Should work straight out of the box.
```sh
cd ~/.weechat/python
wget https://raw.githubusercontent.com/s3rvac/weechat-notify-send/master/notify_send.py
cd ~/.weechat/python/autoload
ln -s ../notify_send.py
```

to not display old messages as notifications again when opening buffers for the first time since launch:

```
/set plugins.var.python.notify_send.notify_for_current_buffer off
/save
```
Keep in mind that this will disable notifications for the current buffer at all times. Move to the first buffer or an irrelevant one to still get reliable notifications

See the [Github page](https://github.com/s3rvac/weechat-notify-send) for more configuration options.
