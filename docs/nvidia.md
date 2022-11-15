# Nvidia

Good luck.
## Installation

Arch: install the `nvidia` package.

## Configuration

### Minimal xorg setup for only running on Nvidia GPU

This minimal configuration should get you started. Add this in `/etc/X11/xorg.conf.d` in a file similar to `10-nvidia-drm-outputclass.conf`

```xf86config
Section "OutputClass"
    Identifier "intel"
    MatchDriver "i915"
    Driver "modesetting"
EndSection

Section "OutputClass"
    Identifier "nvidia"
    MatchDriver "nvidia-drm"
    Driver "nvidia"
    Option "AllowEmptyInitialConfiguration"
    Option "PrimaryGPU" "yes"
    ModulePath "/usr/lib/nvidia/xorg"
    ModulePath "/usr/lib/xorg/modules"
EndSection
```

### Scaling without overscan on PRIME displays
If you cannot use `xrandr --scale ` without leading to over/underscan you need to adjust a kernel parameter:

create a file in `/etc/modprobe.d` (for example called `nvidia-drm-nomodeset.conf`) with the following content.

```xf86config
options nvidia-drm modeset=1
```

and rebuild your kernel via
```sh
sudo mkinitcpio -P
```

After a reboot this should enable scaling for PRIME displays.
