# General

GIT is a version control software, that allows you to save the progress of software/text/whatever development.
It is probably best know from GitHub, but we will show how to set up your own GIT instance and how to use it.

## Installing GIT

### What you need

1. A working server, being it self-hosted at home or a remote instance, called REMOTE in the following
2. A local machine that you develop whatever on, called LOCAL in the following

### Installing GIT

On the LOCAL machine, use your favorite package manager, for example

```sh
pacman -S git
```

The same holds for the REMOTE machine, but here I would advice, to use some LTS distro, so probably

```sh
sudo apt install git
```

### Setting up the Server

First we have to add the git-user on the REMOTE, give him a password and enable ssh logins.

```sh
sudo adduser git
su git
passwd
cd
mkdir .ssh & chmod 700 .ssh
touch .ssh/authorized_keys && chmod 600 .ssh/authorized_keys
```
Now add the ssh public keys of your LOCAL machine to the `authorized_keys` file on the REMOTE.
For this on the LOCAL machine generate a key-pair using `ssh-keygen -t rsa` if you don't have one yet.
Then copy the content of `LOCAL/.ssh/id_rsa.pub` to the `REMOTE/.ssh/authorized_keys` file.

## New Repository

To initialize a repository on the REMOTE server we have to create a new folder and tell git to track this folder.
This has to be done once for every new repository.

```sh
cd
mkdir NewRepo.git
cd NewRepo.git
git init --bare
```

On the LOCAL machine we then have to create a folder and tell git to sync this with the server.
We will assume that `REMOTE` is either the IP or the domain-name of the REMOTE instance.

```sh
cd project
git init
git add .
git commit -m 'Initial commit'
git remote add origin git@REMOTE:/home/git/NewRepo.git
git push origin master
```

## Using Git

To now sync this folder to other devices use

```sh
git clone git@gitserver:/home/git/NewRepo.git
cd project
```

To update the repository go to the folder, add the necessary files using `git add <FILES>` and then commit them using `git commit -m '<MESSAGE>`. These steps can be done as one using

```sh
git commit -am 'Fix for README file'
```

Now push it to the server using `git push origin master`.

### Further Info

- [Git Website](https://git-scm.com/book/en/v2/Git-on-the-Server-Setting-Up-the-Server)
