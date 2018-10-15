#!/bin/bash

CURENT=`pwd`	#実行ディレクトリの保存
cd `dirname $0`	#解析コードのあるディレクトリで作業をする

#------------------------------------------------------------------
# 更新回数、再更新番号の定義確認、設定

RESULT_NO=$1
GENERATE_NO=$2

if [ -z "$RESULT_NO" ]; then
    exit
fi

# 再更新番号の指定がない場合、取得済みで最も再更新番号の大きいファイルを探索して実行する
if [ -z "$2" ]; then
    for ((GENERATE_NO=5;GENERATE_NO >=0;GENERATE_NO--)) {
        
        LZH_NAME=${RESULT_NO}_$GENERATE_NO

        echo "test $LZH_NAME"
        if [ -f ./data/utf/result${LZH_NAME}.lzh ]; then
            echo "execute $LZH_NAME"
            break
        fi
    }
fi

if [ $GENERATE_NO -lt 0 ]; then
    exit
fi

LZH_NAME=${RESULT_NO}_$GENERATE_NO

#------------------------------------------------------------------
# 圧縮結果をダウンロード。なければ各個アクセスするシェルスクリプトを実行
if [ ! -f ./data/utf/result${LZH_NAME}.lzh ]; then
    wget -O data/utf/result${LZH_NAME}.lzh http://ykamiya.ciao.jp/file/result${RESULT_NO}.lzh
    :
fi

if [ ! -f ./data/utf/result${LZH_NAME}.lzh ] || [ ! -s ./data/utf/result${LZH_NAME}.lzh ]; then
    ./_result_download.sh $RESULT_NO $GENERATE_NO
fi

#------------------------------------------------------------------
# 圧縮結果ファイルを展開
if [ -f ./data/utf/result${LZH_NAME}.lzh ]; then
    
    cd ./data/utf

    lha x -q result${LZH_NAME}.lzh
    if [ -d result${RESULT_NO} ]; then # 前期は半々の割合でresultの後に番号がついていなかったので分岐処理
        mv result${RESULT_NO}  result${LZH_NAME}
    else
        mv result result${LZH_NAME}
    fi

    cd ../../

    perl ./GetData.pl      $RESULT_NO $GENERATE_NO
    perl ./UploadParent.pl $RESULT_NO $GENERATE_NO

#------------------------------------------------------------------
# 展開したファイルを削除
    
    cd ./data/utf

    echo "rm utf..."
    rm  -rf result${LZH_NAME}
        
    cd ../../

fi

cd $CURENT  #元のディレクトリに戻る
