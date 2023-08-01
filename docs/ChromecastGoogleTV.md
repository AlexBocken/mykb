# Chromecast with GoogleTV
While being a great SmartTV replacement the default set-up does not allow for much customization and has annoying ads included.
## Changing the Default Launcher
You will need:
- A Chromecast with GoogleTV
- A Laptop with `adb` installed. (On Arch: part of the `android-tools` package)
- A Laptop with Thunderbolt or USB-C which allows for high power throughput to power the Chromecast as well as connect via ADB.

Google, being Google, does not allow for the disabling of Ads in their default Launcher.
This is a tutorial on how you can disable the default launcher and replace it with one of your choice.
We're assuming you're using a Chromecast with Google TV similar to [this one](https://www.digitec.ch/de/s1/product/google-chromecast-mit-google-tv-4k-google-assistant-streaming-media-player-14676764).

### Download a Launcher of your choice
Go to the Google Play Store and choose any Launcher you would like to use. Good ones are FLauncher or Launchy for a more minimalistic approach.
Ensure that the Launcher is installed and working before proceeding.

### Enable Developer Options
Go to `Settings -> Device -> About -> Build` and press the main button about 10 times until a Dialog pops up claiming you're now a developer.

### Connect your Laptop
Plug the Power Cord of the Chromecast into your Laptop. You will most likely require a USB-C to USB-C cable instead of the included USB-A to USB-C one. The Chromecast should now be able to boot up without the low-power warning. If you're getting the low-power warning you cannot continue and might require a different laptop with better Thunderbolt/USB-C support.

On the chromecast there should now pop-up a dialog asking whether you want to trust the connected device. Trust it.

### Disable the Default Launcher via ADB

On your Laptop, open a terminal and ensure that you can find the chromecast via `adb show`. One device should be listed.

Then, use these commands:
```sh
adb shell pm disable-user --user 0 com.google.android.apps.tv.launcherx
adb shell pm disable-user --user 0 com.google.android.tungsten.setupwraith
```
This should have disabled the default launcher. When pressing home, a dialogue should pop up asking for a new default Launcher if multiple are installed.

Your WiFi Credentials might be forgotten for some reason after these steps.
You can just re-add them in your settings and they should persist from now on.

### Re-Enable the Default Launcher via ADB
In case you want to revert these changes you can use these commands to do so:
```sh
adb shell pm enable com.google.android.apps.tv.launcherx
adb shell pm enable com.google.android.tungsten.setupwraith
```
