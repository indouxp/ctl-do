#!/bin/bash
###############################################################################
# REFERENCE:https://kore1server.com/247
# Copyright Hirohisa Kawase
# tugboatの設定に依存する
# access_tokenは、Applications & APIの、Personal access tokens
# client_idは、Applications & APIの、Spaces access keys
# api_keyは、Applications & APIの、Spaces access keysのSecret
#
#0 180426-175505 indou@tk2-259-39305:ctl-do:$ ls -l ~/.tugboat
#-rw-------. 1 indou indou 452  4月 26 17:50 /home/indou/.tugboat
#0 180426-175510 indou@tk2-259-39305:ctl-do:$ cat  ~/.tugboat
#---
#authentication:
#  access_token: ****************************************************************
#  client_id: ********************
#  api_key: *******************************************
#connection:
#  timeout: 10
#ssh:
#  ssh_user: root
#  ssh_key_path: "~/.ssh/id_rsa_do4sakura"
#  ssh_port: '22'
#defaults:
#  region: 'sgp1'
#  image: '32456030'
#  size: '1gb'
#  ssh_key: '20035220'
#  private_networking: 'false'
#  backups_enabled: 'false'
#  ip6: 'false'
#0 180426-175514 indou@tk2-259-39305:ctl-do:$
#
###############################################################################
 
#pecify path to your tugboat command if needed.
# tugboatコマンドのパスを必要ならば、指定して下さい。

tugboat='tugboat'
 
# Specify Droplet name to make snapshot.
# 保存するドロップレットの名前を指定して下さい。

droplet='droplet-01'
 
# Specify snapshot name.
# スナップショット名を指定して下さい。

snapshot='snapshot-01'
 
 
# Make temporay file name
# 一時ファイル名生成
 
tempfile=`mktemp`

TERM() {
  rm -f ${tempfile:?}
}

trap 'TERM' 0
 
# Display size menu.
# サイズメニューの表示
 
if [ "${1}" = "--size" ]
then
 
    PS3="Select size, or q)uit > "
 
    # Get droplet sizes.
    # サイズ取得
 
    $tugboat size > $tempfile
 
    awkcommand="{ match(\$0, /(.+) \(id: /, mt); print mt[1]}"
    sizes=`awk -e "$awkcommand" $tempfile`
 
    select item in $sizes
    do
        if [ "${REPLY}" = "q" ]
        then
            exit 0
        fi
 
    if [ -z "$item" ]
    then
        continue
    fi
 
    echo $item
 
    # Make -s option for create command.
    # 作成コマンドのため、-sオプションを作成する
 
    awkcommand="{ match(\$0, /${item} \(id: (.+)\)/, mt); print mt[1]}"
    size=`awk -e "$awkcommand" $tempfile`
        sizeoption="-s ${size}"
 
    break
    done
 
    # Wait three seconds for missed selection.
    # サイズを間違えた時のために、３秒待つ。
 
    sleep 3
fi
 
 
# Get snapshots.
# スナップショットイメージの取得
 
$tugboat images > $tempfile
cat $tempfile
 
# Get latest snapshot image.
# 最後に作成されたスナップショットイメージの取得
 
awkcommand="/^$snapshot \(id: / { match(\$0, /id: (.+), /, mt); print mt[1] }"
latestsnapshot=`awk -e "$awkcommand" $tempfile | sort -r | head -n 1`
 
echo $latestsnapshot
 
if [ -z $latestsnapshot ]
then
    echo Can\'t find droplet by named \'$droplet\' 1>&2
    exit 1
fi
 
# Create a droplat with latest snapshot image.
# 最後に作成されたスナップショットから、ドロップレットを作成する。
 
$tugboat create $droplet -i $latestsnapshot $sizeoption
 
# Get droplets information
# 起動しているドロップレットの情報取得
 
$tugboat droplets > $tempfile
 
# Get latest droplet id.
# 最後に作成されたドロップレットの取得
 
awkcommand="/^$droplet \(ip: / { match(\$0, /id: (.+)\)/, mt); print mt[1] }"
latestdroplet=`awk -e "$awkcommand" $tempfile | sort -r | head -n 1`
 
# Wait the droplet has made just before, to be active.
# 起動されたばかりドロプレットが、activeになるのを待つ。
 
$tugboat wait $droplet -i $latestdroplet -s active
 
# Wait a more while, then connect with SSH.
# (Because of hangup the command sometime when soon connected)
# 時間を開け、SSHに接続
# （activeになった直後にSSHへすぐ接続すると、コマンドがハングアップするため）
 
sleep 30
$tugboat ssh $droplet -i $latestdroplet

