#!/bin/bash
###############################################################################
# REFERENCE:https://kore1server.com/247
# Copyright : Hirohisa Kawase
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

