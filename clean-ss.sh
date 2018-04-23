#!/bin/bash
###############################################################################
# REFERENCE:https://kore1server.com/247
# Copyright Hirohisa Kawase
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

