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

# 変数定義
backup_dir="/plinode_backups" # バックアップが格納されたディレクトリ
files=($(ls -t $backup_dir))  # バックアップファイル一覧
file_num=${#files[@]}         # バックアップファイル数
display_num=10                # 一度に表示するバックアップファイル数
start=0                       # 表示開始番号

# バックアップファイルをの一覧を表示します。
echo
echo -e "${YELLOW}#########################################################################"
echo -e "${YELLOW}"
echo -e "${YELLOW}                    $RESTORE_DISPLAY_LIST"
echo -e "${YELLOW}"
echo -e "${YELLOW}#########################################################################${NC}"
echo

while true; do
    end=$((start + display_num - 1))
    if [ $end -ge $file_num ]; then
        end=$((file_num - 1))
    fi
    for i in $(seq $start $end); do
        # 一覧表示の際にファイル別に色分け
        filename=${files[i]}
        color=""
        if [[ "$filename" =~ "pm2process" ]]; then
            color=$RED
        elif [[ "$filename" =~ "db" ]] || [[ "$filename" =~ "conf" ]]; then
            color=$BLUE
            # elif [[ "$filename" =~ "efs" ]]; then
            #     color=$PURPLE
        fi
        # 色分け状態で一覧表示
        echo -e "$((i + 1)). $color${files[i]}$NC"
    done

    # 表示リスト最終ページ

    if [ $end -eq $((file_num - 1)) ]; then
        echo
        echo -e "$ALL_BACKUP_FILES_DISPLAYED"
        read -t30 -r -p "$RESTORE_ENTER_FILE_NUMBER : " input
    else
        echo
        echo "$RESTORE_DISPLAY_NEXT_PAGE"
        read -t30 -r -p "$RESTORE_ENTER_FILE_NUMBER : " input
    fi

    # ちょっと切り離し

    # $? は終了ステータス
    if [ $? -gt 128 ]; then
        echo
        echo
        echo -e "${PURPLE}      $NO_RESPONSE_SESSION_END${NC}"
        echo
        break
    elif [ "$input" == "q" ] || [ "$input" == "Q" ]; then
        break
    elif [ "$input" == "n" ] || [ "$input" == "N" ]; then
        echo
        start=$((end + 1))
        continue
    # else
    #     echo "入力が無効です。再度入力してください。"
    fi



    # ↓選択したファイルの確認

    # 変数inputに格納された値を変数file_indexとする
    file_index=$((input - 1))
    if [ $file_index -lt 0 ] || [ $file_index -ge $file_num ]; then
        echo
        echo -e "${PURPLE}$RESTORE_INVALID_NUMBER${NC}"
        echo
        continue
    fi
    file=${files[file_index]}
    # ファイル名にpm2processが含まれているか判定
    if [[ $file != *"pm2process"* ]]; then
        echo
        echo -e "${PURPLE}$RESTORE_NOTE_CHOOSE_PM2${NC}"
        echo
        continue
    fi
    echo
    echo -e "$RESTORE_RESTORING_FOLLOWING_FILE: ${RED}$file${NC}"
    echo
    read -t30 -r -p "$RESTORE_ARE_YOU_OKAY [Y/N] : " confirm
    if [ $? -gt 128 ]; then
        echo
        echo
        echo -e "${PURPLE}      $NO_RESPONSE_SESSION_END${NC}"
        echo
        break
    fi

    # ↓復元実行

    if [ "$confirm" == "Y" ] || [ "$confirm" == "y" ]; then

        # pm2の停止
        echo
        echo -e "${YELLOW}#########################################################################"
        echo -e "${YELLOW}"
        echo -e "${YELLOW}                         $RESTORE_STOPPING_PM2_PROCESS"
        echo -e "${YELLOW}"
        echo -e "${YELLOW}#########################################################################${NC}"
        echo

        pm2 stop all
        pm2 -f save

        echo
        echo -e "${YELLOW}#########################################################################"
        echo -e "${YELLOW}"
        echo -e "${YELLOW}                    $RESTORE_STARTING_PM2_RESTORATION"
        echo -e "${YELLOW}"
        echo -e "${YELLOW}#########################################################################${NC}"
        echo

        # 復元処理
        tar -U --recursive-unlink -xvpzf $backup_dir/$file -C /
        echo
        echo -e "${YELLOW}#########################################################################"
        echo -e "${YELLOW}"
        echo -e "${YELLOW}                    $RESTORE_PM2_RESTORATION_COMPLETE"
        echo -e "${YELLOW}                    $RESTORE_NEXT_RESTART_PM2_SERVICE" # restart pm2 service
        echo -e "${YELLOW}"
        echo -e "${YELLOW}#########################################################################${NC}"
        echo
        echo

        # pm2サービスの再起動
        sudo systemctl restart pm2-$(whoami).service

        # pm2再起動
        pm2 start all
        pm2 save
        sleep 5s
        pm2 reset all
        sleep 5s
        pm2 list
        echo
        echo -e "${YELLOW}#########################################################################"
        echo -e "${YELLOW}"
        echo -e "${YELLOW}                 $RESTORE_SUCCESSFUL_RESTORATION"
        echo -e "${YELLOW}"
        echo -e "${YELLOW}#########################################################################${NC}"
        echo
        break
    # fi
    elif [ "$confirm" == "N" ] || [ "$confirm" == "n" ]; then
        echo
        echo -e "${PURPLE}      $RESTORE_RESTORATION_CANCELLED${NC}"
        echo
        break
    else
        echo
        echo -e "${PURPLE}      $INVALID_INPUT${NC}"
        echo
        echo -e "$RESTORE_ENTER_FILE_NUMBER : "
        echo -e "$RESTORE_ENTER_N_TO_DISPLAY_NEXT_PAGE :  "
        echo
    fi
    start=$((file_index + 1))
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
