#!/bin/bash

# 文字色を設定する変数
GREEN='\033[0;32m'
RED='\033[0;31m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# バックアップ元ファイルのパス
DUMP_PM2=~/.pm2/dump.pm2
EXTERNAL_ADAPTOR_TEMP=~/plugin-deployment/external-adapter-template
EXTERNAL_ADAPTOR_FEED=~/plugin-deployment/external-adapter-feeds
EXTERNAL_FEED_SETUP=~/plugin-deployment/data-feed-setup

# 変数定義
backup_dir="/plinode_backups" # バックアップ先のディレクトリ
files=($(ls -t $backup_dir))  # バックアップファイル一覧
file_num=${#files[@]}         # バックアップファイル数
display_num=10                # 一度に表示するバックアップファイル数
start=0                       # 表示開始番号

# ホスト名の取得
host=$(hostname -f)

# バックアップファイル名の指定
BACKUP_PM2_PROCESS="${host}_$(date +%Y_%m_%d_%H_%M).pm2process.tar.gz"

echo
echo -e "${YELLOW}#########################################################################"
echo -e "${YELLOW}"
echo -e "${YELLOW}                   Starting the backup of pm2 process."
echo -e "${YELLOW}                   First, stopping the pm2 process."
echo -e "${YELLOW}"
echo -e "${YELLOW}#########################################################################${NC}"
echo

# pm2の停止
pm2 stop all
pm2 -f save

# 圧縮とバックアップ
echo
echo -e "${YELLOW}#########################################################################"
echo -e "${YELLOW}"
echo -e "${YELLOW}                   Starting the backup of pm2 process."
echo -e "${YELLOW}"
echo -e "${YELLOW}#########################################################################${NC}"
echo

tar -cvpzf "$backup_dir/$BACKUP_PM2_PROCESS" "$EXTERNAL_ADAPTOR_TEMP" "$EXTERNAL_ADAPTOR_FEED" "$EXTERNAL_FEED_SETUP" "$DUMP_PM2"

echo
echo -e "${YELLOW}#########################################################################"
echo -e "${YELLOW}"
echo -e "${YELLOW}                   The pm2 process backup was successful."
echo -e "${YELLOW}"
echo -e "${YELLOW}#########################################################################${NC}"
echo

# pm2の再起動
read -t30 -r -p "pm2 is currently stopped. Would you like to restart pm2 ? [Y/N]: " answer
if [ $? -gt 128 ]; then
    echo
    echo
    echo -e "${PURPLE}      No response for 30 seconds, session will end.${NC}"
    echo -e "${PURPLE}      pm2 remains stopped.${NC}"
    echo
elif [ "$answer" == "Y" ] || [ "$answer" == "y" ]; then
    pm2 restart all
elif [ "$answer" == "N" ] || [ "$answer" == "n" ]; then
    echo "To restart, run pm2 restart all."
elif [ "$input" == "q" ]; then
    break
else
    echo
    echo -e "${PURPLE}      Invalid input.${NC}"
    echo -e "${PURPLE}      pm2 remains stopped.${NC}"
    echo
fi

# バックアップファイルの一覧表示と選択
files=($(ls -t $backup_dir)) # バックアップファイル一覧再取得
file_num=${#files[@]}        # バックアップファイル数再取得
echo
echo -e "${YELLOW}#########################################################################"
echo -e "${YELLOW}"
echo -e "${YELLOW}                Displaying contents of backup file."
echo -e "${YELLOW}"
echo -e "${YELLOW}#########################################################################${NC}"
echo

while true; do
    echo "Displaying backup file.："
    echo
    for ((i = start; i < start + display_num && i < file_num; i++)); do
        filename=${files[i]}
        color=""
        if [[ "$filename" =~ "conf" ]]; then
            color=$BLUE
        elif [[ "$filename" =~ "db" ]]; then
            color=$BLUE
        elif [[ "$filename" =~ "pm2" ]]; then
            color=$RED
            # elif [[ "$filename" =~ "efs" ]]; then
            #     color=$PURPLE
        fi
        echo -e "$((i + 1)). $color${files[i]}$NC"
    done

    # 全てのバックアップファイルが表示されたか判定
    if [ $((start + display_num)) -ge $file_num ]; then
        echo
        echo -e "${YELLOW} All backup files have been displayed.${NC}"
        echo
        break
    fi

    echo
    echo "Press 'n' on the keyboard if there are not 10 shown."
    read -t30 -r -p "Enter 'n' to display the next 10. (q to quit)  : " next
    if [ $? -gt 128 ]; then
        echo
        echo
        echo -e "${PURPLE}      No response for 30 seconds, session will end.${NC}"
        echo
        break
    fi
    if [ "$next" == "q" ]; then
        echo
        echo -e "${PURPLE}      Ending session as is.${NC}"
        echo
        break
    elif [ "$next" != "n" ]; then
        echo
        echo -e "${PURPLE}      Invalid input besides 'n' or 'q'.${NC}"
        echo -e "${PURPLE}      Ending session as is.${NC}"
        echo
        break
    fi
    start=$((start + display_num))
done
