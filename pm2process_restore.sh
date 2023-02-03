#!/bin/bash

# 文字色を設定する変数
GREEN='\033[0;32m'
RED='\033[0;31m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

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
echo -e "${YELLOW}                    Displaying list of backup files."
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
        if [[ "$filename" =~ "pm2" ]]; then
            color=$RED
        elif [[ "$filename" =~ "db" ]] || [[ "$filename" =~ "conf" ]]; then
            color=$BLUE
            # elif [[ "$filename" =~ "efs" ]]; then
            #     color=$PURPLE
        fi
        # 色分け状態で一覧表示
        echo -e "$((i + 1)). $color${files[i]}$NC"
    done
    # 表示リスト頁の最終番号が全バックアップファイル数に達した時
    if [ $end -eq $((file_num - 1)) ]; then
        echo
        echo -e " All backup files have been displayed."
    fi
    # 次の頁&番号入力
    echo
    echo "Enter 'n' to display next page."
    read -t30 -r -p "Enter the number of the file you want to restore. (q to cancel) : " input
    # 終了ステータス
    if [ $? -gt 128 ]; then
        echo
        echo
        echo -e "${PURPLE}      No response for 30 seconds, session will end.${NC}"
        echo
        break
    fi
    echo
    if [ "$input" == "q" ] || [ "$input" == "Q" ]; then
        break
    fi
    if [ "$input" == "n" ] || [ "$input" == "N" ]; then
        start=$((end + 1))
        continue
    fi
    # 変数inputに格納された値を変数file_indexとする
    file_index=$((input - 1))
    if [ $file_index -lt 0 ] || [ $file_index -ge $file_num ]; then
        echo -e "${PURPLE} Invalid number input. Please input a valid number.${NC}"
        echo
        continue
    fi
    file=${files[file_index]}
    # ファイル名にpm2processが含まれているか判定
    if [[ $file != *"pm2process"* ]]; then
        echo -e "${PURPLE} Note: choose pm2 process file.${NC}"
        echo
        continue
    fi
    echo "Restoring the following file.:"
    echo $file
    read -t30 -r -p "Are you okay with this ? (Y/N) : " confirm
    if [ $? -gt 128 ]; then
        echo
        echo
        echo -e "${PURPLE}      No response for 30 seconds, session will end.${NC}"
        echo
        break
    fi
    if [ "$confirm" == "Y" ] || [ "$confirm" == "y" ]; then

        # pm2の停止
        echo
        echo -e "${YELLOW}#########################################################################"
        echo -e "${YELLOW}"
        echo -e "${YELLOW}                         Stopping pm2 process."
        echo -e "${YELLOW}"
        echo -e "${YELLOW}#########################################################################${NC}"
        echo

        pm2 stop all
        pm2 -f save

        echo
        echo -e "${YELLOW}#########################################################################"
        echo -e "${YELLOW}"
        echo -e "${YELLOW}                    Starting PM2 process restoration."
        echo -e "${YELLOW}"
        echo -e "${YELLOW}#########################################################################${NC}"
        echo

        # 復元処理
        tar -U --recursive-unlink -xvpzf $backup_dir/$file -C /
        echo
        echo -e "${YELLOW}#########################################################################"
        echo -e "${YELLOW}"
        echo -e "${YELLOW}                    PM2 process restoration complete."
        echo -e "${YELLOW}                    Next, restart the pm2 service." # restart pm2 service
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
        echo -e "${YELLOW}                 Successful restoration of pm2 process."
        echo -e "${YELLOW}"
        echo -e "${YELLOW}#########################################################################${NC}"
        echo
        break
    # fi
    elif [ "$confirm" == "N" ] || [ "$confirm" == "n" ]; then
        echo
        echo -e "${PURPLE}      Restoration cancelled.${NC}"
        echo
        break
    else
        echo
        echo -e "${PURPLE}      Invalid input.${NC}"
        echo
        echo -e "Enter the number of the file you want to restore. : "
        echo -e "Enter 'n' to display next page (q to cancel) :  "
        echo
    fi
    start=$((file_index + 1))
done
