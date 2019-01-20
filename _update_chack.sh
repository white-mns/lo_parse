#!/bin/bash

CURENT=`pwd`	#実行ディレクトリの保存
cd `dirname $0`	#解析コードのあるディレクトリで作業をする

RESULT_NO=$1
GENERATE_NO=$2

while :
do
    wget http://ykamiya.ciao.jp/index.html

    if [ $GENERATE_NO -eq 0 ]; then
        grep "<FONT color=\"#ff3333\">${RESULT_NO}</FONT> 更新結果公開中！" index.html
        # "
    elif [ $GENERATE_NO -eq 1 ]; then
        grep "<FONT color=\"#ff3333\">${RESULT_NO}</FONT> 再更新結果公開中！" index.html
        # "
    elif [ $GENERATE_NO -eq 2 ]; then
        grep "<FONT color=\"#ff3333\">${RESULT_NO}</FONT> 再々更新結果公開中！" index.html
        # "
    fi

    IS_UPDATE=$?
    rm index.html
    echo $IS_UPDATE

    if [ $IS_UPDATE -eq 0 ]; then
        echo "update!!"
        ./execute.sh ${RESULT_NO} 0
        exit
    fi

    echo "no..."

    sleep 1800
done
