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
echo -e "${YELLOW}                   pm2プロセスのバックアップを開始します"
echo -e "${YELLOW}                   はじめにpm2プロセスを停止します"
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
echo -e "${YELLOW}                   pm2プロセスのバックアップを開始します"
echo -e "${YELLOW}"
echo -e "${YELLOW}#########################################################################${NC}"
echo

tar -cvpzf "$backup_dir/$BACKUP_PM2_PROCESS" "$EXTERNAL_ADAPTOR_TEMP" "$EXTERNAL_ADAPTOR_FEED" "$EXTERNAL_FEED_SETUP" "$DUMP_PM2"

echo
echo -e "${YELLOW}#########################################################################"
echo -e "${YELLOW}"
echo -e "${YELLOW}                   pm2プロセスのバックアップに成功しました"
echo -e "${YELLOW}"
echo -e "${YELLOW}#########################################################################${NC}"
echo

# pm2の再起動
read -t30 -r -p "現在、pm2は停止しています。pm2を再起動しますか？ [Y/N]: " answer
if [ $? -gt 128 ]; then
    echo
    echo -e "${PURPLE}      30秒間応答がなかったため終了します${NC}"
    echo -e "${PURPLE}      現在、pm2は停止したまま状態です${NC}"
    echo
fi
if [ "$answer" == "Y" ] || [ "$answer" == "y" ]; then
    pm2 restart all
elif [ "$answer" == "N" ] || [ "$answer" == "n" ]; then
    echo "再起動したい場合は、pm2 restart allを実行してください"
elif [ "$input" == "q" ]; then
    break
else
    echo
    echo -e "${PURPLE}      無効な入力です${NC}"
    echo -e "${PURPLE}      現在、pm2は停止したまま状態です${NC}"
    echo
fi

# バックアップファイルの一覧表示と選択
echo
echo -e "${YELLOW}#########################################################################"
echo -e "${YELLOW}"
echo -e "${YELLOW}                以下にバックアップファイルの中身を表示します"
echo -e "${YELLOW}"
echo -e "${YELLOW}#########################################################################${NC}"
echo

while true; do
    echo "表示中のバックアップファイル："
    echo
    for ((i = start; i < start + display_num && i < file_num; i++)); do
        filename=${files[i]}
        color=""
        if [[ "$filename" =~ "conf" ]]; then
            color=$RED
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
        echo -e "${YELLOW} すべてのバックアップファイルが表示されました${NC}"
        echo
        break
    fi

    echo
    echo "表示された10個になかった場合は、キーボードのnを押してください"
    # read -p "次の10個を表示する場合は、nを入力してください (q to quit) : " next
    read -t30 -r -p "次の10個を表示する場合は、nを入力してください  (中止したい場合は q )  : " next
    if [ $? -gt 128 ]; then
        echo
        echo
        echo -e "${PURPLE}      30秒間応答がなかったため終了します${NC}"
        echo
        break
    fi
    if [ "$next" == "q" ]; then
        echo
        echo -e "${PURPLE}      このまま終了します${NC}"
        echo
        break
    elif [ "$next" != "n" ]; then
        echo
        echo -e "${PURPLE}      n または q 以外の入力がありました${NC}"
        echo -e "${PURPLE}      このまま終了します${NC}"
        echo
        break
    fi
    start=$((start + display_num))
done
