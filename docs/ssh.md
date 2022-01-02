# General
The basic syntax is
```
ssh user@domain
```
You can either log in using a password or an ssh key.
The second method is considered safer and more user friendly.
To initialize the ability to log in using an ssh key, you need a local ssh key-pair.
If you dont have one, generate one on your local machine using
```
ssh-keygen -t rsa
```
and following the instructions.
This generated a public and private key pair which are saved in `~/.ssh`.
To then enable the key based login, you have to make sure that `~/.ssh` exists on the server.
Change the permisions of this folder using `chmod 700 ~/.ssh`.
The next step is to make the `authorized_keys` file using
```
touch ~/authorized_keys
chmod 600 ~/.ssh/authorized_keys ```
Now open the `authorized_keys` and copy-paste the public key contents in to it.

One can also use `ssh-copy-id user@domain` after generating the key-pair.



## Add keys to Keychain

If you added a passphrase to your key, you may be tired of typing it over and over again.
Add the following to your `~/.ssh/config`.

```
Host HOME
  User root
  HostName domain.example
  IdentityFile ~/.ssh/id_rsa
  AddKeysToAgent yes
  UseKeychain yes
```

This saves the passphrase in the keychain for the current session.
It also allows you to specify which specific key to use and to use `ssh HOME` to connect to the server.


## Add keys for layered logins

If you need to connect to an access server before connecting to the actual server you want to connect to, this can be automized by adding

```
IgnoreUnknown AddKeysToAgent,UseKeychain

## All EXEMPLUM-COMPANY
Host EXEMP*
  User username
  IdentityFile ~/.ssh/id_rsa
  AddKeysToAgent yes
  UseKeychain yes

## Access server
Host EXEMPaccess
  HostName login.example.com

## Working server
Host EXEMPwork
  HostName work.example.com
  proxycommand ssh -CW %h:%p EXEMPaccess ## access server

```
to your `~/.ssh/config`.
To connect to the working server, just type `ssh EXEMPwork`.
