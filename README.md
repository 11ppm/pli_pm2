# Backup and Restore PM2 PROCESSes

 [README 日本語版](https://github.com/11ppm/pli_pm2/blob/main/README_JP.md)


Back up the following directories and files within the PluginNode.

* data-feed-setup/
* external-adapter-feeds/
* external-adapter-template/
* dump.pm2

The above directories and files are assumed to be located in the following location.

```
    ~/plugin-deployment/
    │   ├── data-feed-setup/
    │   ├── external-adapter-feeds/
    │   └── external-adapter-template/
    ~/.pm2/
        └── dump.pm2
```

---

**Backup of conf and db**

It is recommended to backup `Conf files` and `Database files` beforehand.
```sh
cd ~/plugin-deployment && ./_plinode_setup_bkup.sh && ./_plinode_backup.sh -full
```

---

# Backup of PM2 PROCESSes

## 1． Clone from GitHub

```sh
cd $HOME
git clone https://github.com/11ppm/pli_pm2
cd pli_pm2
chmod +x *.sh
```


## 2． Perform the backup

```sh
./pm2process_backup.sh 
```


* Backup the above directories and files to `/plinode_backups`.
* The backup file will have a file name including the host name and date and time, in the format of `pm2process.tar.gz`.
* Only backup the directories set on the node.


#### 2-1  Stop pm2 process
When executed, it will stop the pm2 process first.
<img src="./img/backup1.png">


#### 2-2  Start backup
Next, the backup of the pm2 process will start.
<img src="./img/backup2.png">


#### 2-3  Restart pm2
Once the backup is finished, you will be asked if you want to restart the pm2 process. If you want to restart, please enter `Y(y)`. The restart will begin. If not, enter `N(n)` to exit. If no Y/N input is received within `30 seconds`, pm2 will remain stopped and the session will end.
<img src="./img/backup3.png">

#### 2-4  File check
If the backup is successful, a message indicating success will be displayed. Then, you will be able to check the backed-up files by seeing the list of backed-up files in the `/plinode_backups` directory.
<img src="./img/backup4.png">



# Restore of PM2 PROCESSes

## 3． Perform the restoration
```shell
./pm2process_restore.sh
```

* Executing will show a list of backup files in `/plinode_backups` in increments of 10. Select the number of the file you want to restore.

* If the desired file is not listed in the displayed list, press `n` to go to the next page. When the desired `pm2process` file is found, enter the number.

* The list will also display `conf` and `db` files, but they cannot be selected. If you want to restore these files, please refer to the following site [GoPlugin official site.](https://github.com/GoPlugin/plugin-deployment/blob/main/docs/node_backup_restore.md)



* After selecting the number, there will be a confirmation. If you wish to proceed, enter `y`, if you wish to cancel, enter `q`. Entering `y` will start the restore process.

#### 3-1  List display
The script will display a list of backup files 10 at a time.
<img src="./img/restore1.png">

#### 3-2  pm2 process stop
When the restoration begins, all pm2 processes are first stopped.
<img src="./img/restore2.png">

#### 3-3  Start of restoration
Starts restoring the backup file.
<img src="./img/restore3.png">

Directories and files to be restored are as follows Only backed up directories and files will be restored.

* data-feed-setup/
* external-adapter-feeds/
* external-adapter-template/
* dump.pm2

The restoration is to be performed at the following locations
```
    ~/plugin-deployment/
    │   ├── data-feed-setup/
    │   ├── external-adapter-feeds/
    │   └── external-adapter-template/
    ~/.pm2/
        └── dump.pm2
```


#### 3-4  Restart pm2
When the restore is complete, restart the pm2 service and restart the pm2 process.
<img src="./img/restore4.png">

Finally, make sure that the `↺` number in the pm2 process has not increased.

# Refreshing your local repo

The repository may be updated, in which case the following command should be executed to update the repository.

```        
cd ~/pli_pm2
git fetch
git reset --hard HEAD
git merge '@{u}'
chmod +x *.sh
```

# Author

* @11ppm


