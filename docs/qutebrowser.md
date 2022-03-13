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
qutebrowser --nowindow ':adblock-update;;later 10000 download-clear'
```
will update the adblock lists without starting a qutebrowser window.

## Greasemonkey scripts

To add scripts such as 4chanX to qutebrowser add the Js file to `${XDG_DATA_HOME:-$HOME/.local/share}/qutebrowser/greasemonkey`.

### 4chanX

For 4chanX this would be:

```sh
wget -P ${XDG_DATA_HOME:-$HOME/.local/share}/qutebrowser/greasemonkey https://www.4chan-x.net/builds/4chan-X.user.js
```
followed by a `:greasemonkey-reload` in qutebrowser to activate the newly added Java scripts.

### Skip Youtube Ads

Automatically mute, speed up (at least 10x) and skip video ads on youtube.
There are multiple versions out there that try to accomplish the same thing.
Various versions can be found in [this github issue thread](https://github.com/qutebrowser/qutebrowser/issues/6480#issuecomment-876759237).
For me personally version 1.0.0 seems to work best.
Thus, create a file in `${XDG_DATA_HOME:-$HOME/.local/share}/qutebrowser/greasemonkey` with the following content:

```js
// ==UserScript==
// @name         Auto Skip YouTube Ads
// @version      1.0.0
// @description  Speed up and skip YouTube ads automatically
// @author       jso8910
// @match        *://*.youtube.com/*
// @exclude      *://*.youtube.com/subscribe_embed?*
// ==/UserScript==
setInterval(() => {
    const btn = document.querySelector('.videoAdUiSkipButton,.ytp-ad-skip-button')
    if (btn) {
        btn.click()
    }
    const ad = [...document.querySelectorAll('.ad-showing')][0];
    if (ad) {
        document.querySelector('video').playbackRate = 10;
    }
}, 50)
```
followed by a `:greasemonkey-reload` in qutebrowser.
