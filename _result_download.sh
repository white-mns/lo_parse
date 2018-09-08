#!/bin/bash

CURENT=`pwd`	#実行ディレクトリの保存
cd `dirname $0`	#解析コードのあるディレクトリで作業をする

RESULT_NO=$1
GENERATE_NO=$2

LZH_NAME=${RESULT_NO}_$GENERATE_NO

mkdir ./data/orig/result${RESULT_NO}
mkdir ./data/orig/result${RESULT_NO}/result_chara
mkdir ./data/orig/result${RESULT_NO}/result_pre

wget -O ./data/orig/result${RESULT_NO}/base.css http://ykamiya.ciao.jp/result/base.css
wget -O ./data/orig/result${RESULT_NO}/manual.css http://ykamiya.ciao.jp/result/manual.css
wget -O ./data/orig/result${RESULT_NO}/sub.css http://ykamiya.ciao.jp/result/sub.css

for ((E_NO=$1;E_NO <= 400;E_NO++)) {
    for ((i=0;i < 2;i++)) { # 2回までリトライする
        wget -O ./data/orig/result${RESULT_NO}/result_chara/result_Eno${E_NO}.html http://ykamiya.ciao.jp/result/result_chara/result_Eno${E_NO}.html

        sleep 2

        if [ -s ./data/orig/result${RESULT_NO}/result_chara/result_Eno${E_NO}.html ]; then
            break
        fi
    }
}

find ./data/orig/result${RESULT_NO} -type f -empty -delete
perl _GetPreDatas.pl $1 $2

# ファイルを圧縮
if [ -d ./data/orig/result${RESULT_NO} ]; then
    
    cd ./data/orig/

    echo "orig lzh..."
    lha -cq result${LZH_NAME}.lzh result${RESULT_NO}
    echo "rm directory..."
    rm  -r result${RESULT_NO}
        
    cd ../../
fi

cd $CURENT  #元のディレクトリに戻る
