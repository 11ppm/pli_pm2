#!/bin/bash

# 文字色を設定する変数
GREEN='\033[0;32m'
RED='\033[0;31m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

# CSVファイル名
csv_file="./translations/translations.csv"

# 言語の選択
echo
echo "Select a language 言語を選択してください :"
echo
echo "1. English"
echo "2. 日本語"
echo
read -t30 -p "Enter the number 数字を入力してください : " lang_choice

# 選択された言語に応じた列番号を設定
case $lang_choice in
1)
    lang_col=2 # 英語列
    ;;
2)
    lang_col=3 # 日本語列
    ;;
*)
    echo "無効な選択です。"
    exit 1
    ;;
esac

# CSVファイルからメッセージを読み込み
while read line; do
    # キー名を取得
    # cutコマンドで`|`を区切り文字とし、1列目のフィールドを抽出
    key=$(echo $line | cut -d '|' -f 1)
    # 選択された言語に対応するメッセージを取得
    # awk -Fオプションを使ってフィールド区切り文字を`|`に指定、$で$lang_colで指定された列を取得
    message=$(echo $line | awk -F '|' '{print $'$lang_col'}')
    # 変数に格納
    eval "$key=\"$message\""
done <$csv_file

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
echo -e "${YELLOW}                   $START_BACKUP_PM2"
echo -e "${YELLOW}                   $STOP_PM2_FIRST"
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
echo -e "${YELLOW}                   $COMPRESS_AND_BACKUP"
echo -e "${YELLOW}"
echo -e "${YELLOW}#########################################################################${NC}"
echo

tar -cvpzf "$backup_dir/$BACKUP_PM2_PROCESS" "$EXTERNAL_ADAPTOR_TEMP" "$EXTERNAL_ADAPTOR_FEED" "$EXTERNAL_FEED_SETUP" "$DUMP_PM2"

echo
echo -e "${YELLOW}#########################################################################"
echo -e "${YELLOW}"
echo -e "${YELLOW}                   $SUCCESSFUL_BACKUP"
echo -e "${YELLOW}"
echo -e "${YELLOW}#########################################################################${NC}"
echo

# pm2の再起動
read -t30 -r -p "$PM2_STOPPED_RESTART [Y/N]: " answer
if [ $? -gt 128 ]; then
    echo
    echo
    echo -e "${PURPLE}      $NO_RESPONSE_SESSION_END${NC}"
    echo -e "${PURPLE}      $PM2_REMAINS_STOPPED${NC}"
    echo
elif [ "$answer" == "Y" ] || [ "$answer" == "y" ]; then
    pm2 restart all
elif [ "$answer" == "N" ] || [ "$answer" == "n" ]; then
    echo "$RESTART_PM2"
elif [ "$input" == "q" ]; then
    break
else
    echo
    echo -e "${PURPLE}      $INVALID_INPUT${NC}"
    echo -e "${PURPLE}      $PM2_REMAINS_STOPPED${NC}"
    echo
fi

# バックアップファイルの一覧表示と選択
files=($(ls -t $backup_dir)) # バックアップファイル一覧再取得
file_num=${#files[@]}        # バックアップファイル数再取得
echo
echo -e "${YELLOW}#########################################################################"
echo -e "${YELLOW}"
echo -e "${YELLOW}                $DISPLAY_BACKUP_CONTENTS"
echo -e "${YELLOW}"
echo -e "${YELLOW}#########################################################################${NC}"
echo

while true; do
    echo "$DISPLAY_BACKUP_FILE"
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
        echo -e "${YELLOW} $ALL_BACKUP_FILES_DISPLAYED${NC}"
        echo
        break
    fi

    echo
    read -t30 -r -p "$DISPLAY_NEXT_PAGE : " nextpage
    if [ $? -gt 128 ]; then
        echo
        echo
        echo -e "${PURPLE}      $NO_RESPONSE_SESSION_END${NC}"
        echo
        break
    fi
    if [ "$nextpage" == "q" ]; then
        echo
        echo -e "${PURPLE}      $ENDING_SESSION${NC}"
        echo
        break
    elif [ "$nextpage" != "n" ]; then
        echo
        echo -e "${PURPLE}      $INVALID_INPUT${NC}"
        echo -e "${PURPLE}      $ENDING_SESSION${NC}"
        echo
        break
    fi
    start=$((start + display_num))
done


# echo "$key"
# echo "$BACKUP"
# echo "$START_BACKUP_PM2"
# echo "$STOP_PM2_FIRST"
# echo "$START_BACKUP_PM2_AGAIN"
# echo "$SUCCESSFUL_BACKUP"
# echo "$PM2_STOPPED_RESTART"
# echo "$NO_RESPONSE_SESSION_END"
# echo "$PM2_REMAINS_STOPPED"
# echo "$RESTART_PM2"
# echo "$INVALID_INPUT"
# echo "$DISPLAY_BACKUP_CONTENTS"
# echo "$DISPLAY_BACKUP_FILE"
# echo "$ALL_BACKUP_FILES_DISPLAYED"
# echo "$PRESS_N_NOT_TEN_SHOWN"
# echo "$NO_RESPONSE_SESSION_END_AGAIN"
# echo "$ENDING_SESSION"
# echo "$INVALID_INPUT_BESIDES_N_Q"
# echo "$RESTORE"
# echo "$RESTORE_DISPLAY_LIST"
# echo "$RESTORE_DISPLAY_NEXT_PAGE"
# echo "$RESTORE_ENTER_FILE_NUMBER"
# echo "$RESTORE_INVALID_NUMBER"
# echo "$RESTORE_NOTE_CHOOSE_PM2"
# echo "$RESTORE_RESTORING_FOLLOWING_FILE"
# echo "$RESTORE_ARE_YOU_OKAY"
# echo "$RESTORE_STOPPING_PM2_PROCESS"
# echo "$RESTORE_STARTING_PM2_RESTORATION"
# echo "$RESTORE_PM2_RESTORATION_COMPLETE"
# echo "$RESTORE_NEXT_RESTART_PM2_SERVICE"
# echo "$RESTORE_SUCCESSFUL_RESTORATION"
# echo "$RESTORE_RESTORATION_CANCELLED"
# echo "$RESTORE_ENTER_FILE_NUMBER_AGAIN"
# echo "$RESTORE_ENTER_N_TO_DISPLAY_NEXT_PAGE"
