# qutebrowser

## General

Qutebrowser is very dotfiles friendly, nonetheless there are some features which require manual intervention to work correctly at initial setup.

## Ad-blocking

Do not forget to install `python-adblock` if you want brave-like adblocking. To have domain blocking and brave-like adblocking:
```
:set content.blocking.method both
:adblock-update
```

### Automatic adblock list updates:

Adding to your crontab at whatever interval you wish:
```sh
qutebrowser --nowindow ':adblock-update;;later 10000 download-clear;;later 10500 close'
```
will update the adblock lists without starting a qutebrowser window.

## Greasemonkey scripts

To add scripts such as 4chanX to qutebrowser add the js file to `${XDG_DATA_HOME:-$HOME/.local/share}/qutebrowser/greasemonkey`. For 4chanX this would be:

```sh
wget -P ${XDG_DATA_HOME:-$HOME/.local/share}/qutebrowser/greasemonkey https://www.4chan-x.net/builds/4chan-X.user.js
```
followed by a `:greasemonkey-reload` in qutebrowser to activate the newly added Java scripts.
