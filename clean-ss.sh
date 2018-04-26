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
 
# Specify path to your tugboat command if needed.
# tugboatコマンドのパスを必要ならば、指定して下さい。
 
tugboat='tugboat'
 
# Specify snapshot name.
# スナップショット名を指定して下さい。
 
snapshot='snapshot-01'
 
# Number of holding snapshots.
# 残しておくスナップショットの数
 
remain='1'
 
# Make temporay file name
# 一時ファイル名生成
 
tempfile=`mktemp`

TERM() {
  rm -f ${tempfile:?}
}

trap 'TERM' 0
 
# Get images.
# イメージの取得
 
$tugboat images > $tempfile
 
cat $tempfile
 
# Get image ids to destroy.
# 削除するイメージのIDを取得する。
 
awkcommand="/$snapshot \(id: .+,/ { match(\$0, /\(id: (.+),/, mt); print mt[1] }"
sedcommand="1,$remain d"
destroyimages=`awk -e "$awkcommand" $tempfile | sort -r | sed -e "$sedcommand"`
 
if [ -z $destroyimages ]
then
    echo There are no snapshot images to destroy. 1>&2
    exit 1
fi
 
# Destroy images.
# スナップショットイメージを削除する。
 
for image in ${destroyimages}
do
    $tugboat destroy_image $snapshot -i $image -c
done

