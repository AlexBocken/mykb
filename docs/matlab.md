# matlab

## Installation via AUR

### PKGBUILD
Download PKGBUILD: `paru -G matlab`

### Licenses
- Go to [License center](https://www.mathworks.com/licensecenter) on mathworks
- On install and activate tab; select (or create) an appropriate license
- Navigate to download the license file and the file installation key
- Download the **license file** and put the file in the repository
- Copy and paste the **file installation key** in a plain text file

## create Tarball

Check, that `libselinux` and `libxcrypt-compat` are installed. Otherwise the installer will exit with error code 42 and no further instructions.
```sh
paru -S --asdeps libselinux libxcrypt-compat
```

Then:
-  [Download the matlab installer](https://www.mathworks.com/downloads)
-  Unpack and launch the installer
-  After logging in and accepting license; select `Advanced Options > I want to download without installing` from the top dropdown menu.
-  Set the download location to an empty directory called `matlab`
-  Select the toolboxes you want.

After downloading; from the parent directory; do
```sh
tar cf matlab.tar matlab
```
to create the tarball. The folder here called `matlab` usually is given the download-time as it's name. Rename to `matlab` before compressing.

Move the matlab.tar to the repository.
Adjust the `pkgver` and `release` vars in the `PKGBUILD` to reflect current release.
Run `makepkg -si` to install.

## Configuration
### fix graphics driver with intel

In the case of `libGL error: failed to open iris:`:

Add to the `matlab` script (`sudo nvim $(which matlab)`) at the top:
```sh
export MESA_LOADER_DRIVER_OVERRIDE=i965
```

### HiDPI Fix
In Matlab:
```m
s = settings;s.matlab.desktop.DisplayScaleFactor
s.matlab.desktop.DisplayScaleFactor.PersonalValue = 2
```
This value can be a float.
