# LaptopSetup

General Tips and tricks for setting up Laptops in particular. Assuming Arch Linux/systemd.

## Power/Hibernation

We want to not edit pacman-provided files but provide drop-ins.
Hence create the folder `/etc/systemd/logind.conf.d` if not already present.

All the following settings will be written into `/etc/systemd/logind.conf.d/logind.conf`

### Let DWM handle PowerOff

```conf
[Login]
HandlePowerKey=ignore
```

### Hibernate on Lid close

```conf
[Login]
HandleLidSwitch=hibernate
HandleLidSwitchExternalPower=hibernate
```
