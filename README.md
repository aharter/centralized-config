# centralized-config

## Motivation
I have several machines running the same OS. Over time, my configuration evolved and I had a hard time to keep it in sync on all machines. To make matters worse, some machines might require a slightly deviated configuration.
While many have their config in some (D)VCS, the files are still manually copied. This script replaces that processes by setting symlinks.

## Usage
```bash
usage: centralized-config.py [-h] [-lc] [-d] [configs [configs ...]]

positional arguments:
  configs              Configurations to use.

optional arguments:
  -h, --help           show this help message and exit
  -lc, --list-configs  List all available configurations.
  -d, --dry-run        Dry run. Only display symlinks that will be created
```

### Adding configs
1. Create folder, its name becomes the config name
1. Below, folder structure represents the root structure and determines how to symlink.

##### Example
```
common/etc/skel/.bashrc => /etc/skel/.bashrc
```

#### `home`-folder
The `home`-folder is setup slightly differnetly. It does **NOT** require a username. The script automatically adds the current user to the path. This allows to share the same config across different usernames.

##### Example
```
common/home/.bashrc => /home/<username>/.bashrc
```
