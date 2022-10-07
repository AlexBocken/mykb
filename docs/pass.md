# Pass

Pass is a password manager that follows the UNIX philosophy of doing one thing and doing it well. It is designed to be simple and easy to use, while still being secure and flexible.
It is basically just a simple shell-script, working on files.
The main idea is to have a bunch of gpg encrypted files, storing the passwords.
These files can then be synced using your favourite way, being it git, syncthing or anything else.
Or just kept locally on your machine.
In the end - its just a file, or a bunch of them.

This allows you to not rely on the good security practice of a large company, which is a primary target for attacks.

Pass has several very useful extensions, allowing easy access, generation of OTP for 2FA and more.

## Install

### Generate a gpg key

1. If you already have a gpg key, you are done here. If not, lets generate a key:

```sh
gpg --full-gen-key
```
2. Select your key type (if no idea what, choose RSA).
3. Select a 4096 bit long key
4. Your key should not expire. So select the corresponding option (usually 0)
5. Name your key and add an email. This email does not have to be your real one, but this key can also be used to sign/encrypt mails. If this is your plan, choose the mail address you plan to use with this key.
6. Add a password to the key (keep blank for an empty password)


### Install on Arch

```sh
pacman -S pass pass-otp
```

### Setup

1. We want to set up pass. For this we run the following command. This tells pass to use the gpg key connected to the email address given.

```sh
pass init <email_used_for_gpg_key>
```

### Usage

1. **Adding passwords**. To do this, type the following command. Here we use a name to identify which password this is. Usually this is the service/website/program/file/... this password is used for. If several accounts exists for one service, one can also created nested structure like `serviceA/account1` and `serviceA/account2`. This will just create a folder called `serviceA` and put the corresponding files in there. After running below command, it asks you to type the password you want to store.

```sh
pass add <name_linked_to_password>
```

2. **Retrieving the password**. To look up the password, simply run the command below. It may be that a prompt asks you to type in your GPG key-pair password.

```sh
pass <name_linked_to_password>
```

### Quality of life improvements

1. **passmenu**. If you use `dmenu`, install [this](https://tools.suckless.org/dmenu/scripts/passmenu2) script to enable a dmenu friendly list. Just type a substring of the file name, and this script copies the contents to your clipboard. For OTP this automatically generates the code and copies it to your clipboard. If the file contains two lines, the second line is copied in to your selection. This is useful to store user names or similar information. Bind this script to a keyboard shortcut for actual usability.

2. **One Time Passwords/Multi Factor Authentication**. Most of the time you get a QR code that you should scan with something like microsoft authenticator. Save this qr code as an image, and run it through `zbarimg` (Installed via `pacman -S zbar`). This returns an uri starting `otpauth://...`. Create a new "password" using `pass otp add <otp_password_file>`, and paste the uri as the password. Now run `pass otp <otp_password_file>`. This generates the one time password. Again, this works with passmenu script above. Maybe you have to change the script linked to adjust to your naming convention of otp files.

3. **Syncing**: Usually you want to have your passwords in more than one place. Laptop and Phone are a very common setup. For android you have several options.
   The most straight forward, and probably safest way, is to copy the files to your device and also copy over the private key.
   This key is then imported in to an app like [OpenKeyChain](https://www.openkeychain.org/). Now you can open these files using this app.
   But this comes with a harsh drawback on usability.
   Another setup would be a private git repo, which you can clone to different devices.
   Again, on android [Password Store](https://passwordstore.app/) is a very powerful tool, which allows you to auto-insert in browsers and also generate the OTP.
   To set up a git sync, you enable it with pass using `pass git init`. Then add the remote repo as origin using `pass git remote add origin user@service:pos`.
   Now this is set up and `pass git push` auto-commits and pushes to the remote repo. `pass git pull` pulls from there.
   In Password Store you can now clone from this repo and use the key you imported to OpenKeyChain to decrypt the passwords!
   On iOS I don't know of a similar setup, but am happy to take in recommendations!


### Useful commands

- `pass list` : Shows the folder structure of all stored passwords
- `pass grep <...>` : Searches for a files including the search string when decrypted
- `pass edit <...>` : If a password changed, this allows to edit the file.
- `pass generate <...>` : In need of a new password? Just let pass generate a secure one
- You are able to use pass in a script, for example to enter secret information automatically without keeping it in clear text.
