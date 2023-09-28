# Restic

Resitc is an encrypted, compressed and easily usable backup system.

## Install Requirements

- Only need to install restic on the **local** machine! All the other stuff is just ssh. The server is used as a network attached disk.
- Upside: minimal work on the server
- Downside: No easy way to check online for this

```sh
pacman -S restic
```

## Setup

To set up a repository, the name of a backup unit in restic, run on your local machine

```sh
 restic -r sftp:user@backupserver.lan:/backups/machine_id init
```

This initializes (same way as git) the server side under the path `/backups/machine_id`.

You can also initalize it with a different local path (i.e. Harddrive) using

```sh
restic init --repo /path/backups
```

For more details, [RTFM](https://restic.readthedocs.io/en/latest/030_preparing_a_new_repo.html#sftp).

## Backup Methods

To back up your system, you can use restic_files and the following command

```sh
restic -r sftp:user@backupserver.lan:/backups/machine_id --password-command "pass homeserver/restic/T490" --files-from ~/.config/restic/restic_files --no-scan backup
```

`restic_files` is just a file containing the *patterns* or *paths* of the things to back up.
You can also use the usual ssh config for using specific hostnames, users and ports.
You can automate this using a simple cron-job, which runs with the regularity you like.
The `--no-scan` option is useful to save some I/O overhead.
For more details, [RTFM](https://restic.readthedocs.io/en/latest/040_backup.html).

## Restoring from Backups

To restore a full backup, run

```
restic -r sftp:user@backupserver.lan:/backups/machine_id --password-command "pass homeserver/restic/T490" --verbose restore SNAPSHOTNUMBER --target /your/fav/path
```

The snapshot number is the snapshot id you want to restore to, which you get by using

```
restic -r sftp:user@backupserver.lan:/backups/machine_id --password-command "pass homeserver/restic/T490" snapshots
```

This gives you a list of the snapshots with the dates and id's.

You can use `--exclude` and `--include` for the specific inclusion/exclusion of single files or folders. This allows to restore **single files**.
Here the files/folders have to be given using the path inside the snapshots. If you dont remember them, use `restic -r ..... ls latests` or `restic -r ... find filename`.

You can also mount the snapshots using

```
restic -r sftp:user@backupserver.lan:/backups/machine_id --password-command "pass homeserver/restic/T490" mount /your/fav/mountpoint
```
With this, you can browse the different snapshots. For this [`fusermount`](https://archlinux.org/packages/extra/x86_64/fuse2/) has to be installed.

For more details, [RTFM](https://restic.readthedocs.io/en/latest/050_restore.html).

## Keeping an overview

You can **list** all snapshots using

```
restic -r sftp:user@backupserver.lan:/backups/machine_id --password-command "pass homeserver/restic/T490" snapshots
```

You should regularly **check the health** of your backups! This can be done by

```
restic -r sftp:user@backupserver.lan:/backups/machine_id --password-command "pass homeserver/restic/T490" check
```
This however just checks if the structure is okay. If you want to check, if all the data files are unmodified and in tact, this can be done using

```
restic -r sftp:user@backupserver.lan:/backups/machine_id --password-command "pass homeserver/restic/T490" check --read-data
```
This however might take some time.


If you want to **remove** some files from the snapshots, you can use

```
restic -r sftp:user@backupserver.lan:/backups/machine_id --password-command "pass homeserver/restic/T490" rewrite --exclude /path/to/wrongly/added/file SNAPSHOTNUMBER
```

[RTFM](https://restic.readthedocs.io/en/latest/045_working_with_repos.html) for more info.

If you want to remove complete snapshots, either because they are old enough that you dont care anymore, or for other reasons, this can be done using

```
restic -r sftp:user@backupserver.lan:/backups/machine_id --password-command "pass homeserver/restic/T490" forget SNAPSHOTNUMBER
```
To also delte the data that is not needed anymore by any snapshot, run

```
restic -r sftp:user@backupserver.lan:/backups/machine_id --password-command "pass homeserver/restic/T490" prune
```

To combine both, use the `--prune` flag for the `forget` command.
See [here](https://restic.readthedocs.io/en/latest/060_forget.html) for more info.
The selection can be automated using `--keep-last` and `--keep-{hourly, daily, weekly, monthly, yearly}` flags to the `forget` command. For details see [here](https://restic.readthedocs.io/en/latest/060_forget.html#removing-snapshots-according-to-a-policy).
