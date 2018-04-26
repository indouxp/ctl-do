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
 
# Get droplets.
# 起動中のドロップレットの取得
 
$tugboat droplets > $tempfile
cat $tempfile
 
# Get latest droplet id.
# 最後に作成されたドロップレットの取得
 
awkcommand="/^$droplet \(ip: / { match(\$0, /id: (.+)\)/, mt); print mt[1] }"
latestdroplet=`awk -e "$awkcommand" $tempfile | sort -r | head -n 1`
 
if [ -z $latestdroplet ]
then
    echo Can\'t find droplet by named \'$droplet\' 1>&2
    exit 1
fi
 
# Halt it and wait it.
# 電源をoffにし、終了するまで待つ。
 
$tugboat halt $droplet -i $latestdroplet -h
$tugboat wait $droplet -i $latestdroplet -s off
 
 
# Take a snapshot.
# スナップショットの取得
 
$tugboat snapshot $snapshot $droplet -i $latestdroplet
 
# After processing, it turn on. So wait it.
# 処理が終わると、自動的に起動する。そのため、それを待つ <- 自動的には起動しない
 
#$tugboat wait $droplet -i $latestdroplet -s active
 
# Destroy the droplet.
# ドロップレトの削除
 
$tugboat destroy $droplet -i $latestdroplet -c

