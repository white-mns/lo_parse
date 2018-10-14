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


if [ ! -f ./data/orig/result${LZH_NAME}.lzh ]; then
    wget -O data/orig/result${LZH_NAME}.lzh http://ykamiya.ciao.jp/file/result${RESULT_NO}.lzh
    :
fi

if [ ! -f ./data/orig/result${LZH_NAME}.lzh ] || [ ! -s ./data/orig/result${LZH_NAME}.lzh ]; then
    ./_result_download.sh $RESULT_NO $GENERATE_NO
fi

if [ -f ./data/orig/result${LZH_NAME}.lzh ]; then
    
    cd ./data/orig

    lha x -q result${LZH_NAME}.lzh
    if [ -d result${RESULT_NO} ]; then
        mv result${RESULT_NO}  result${LZH_NAME}
    else
        mv result result${LZH_NAME}
    fi

    cp -r  result${LZH_NAME} ../utf/result${LZH_NAME}
    echo "rm orig..."
    rm  -rf result${LZH_NAME}

    echo "copy directory..."
    cd ../utf/result${LZH_NAME}/    
    cd ../../../

fi

perl ./GetData.pl $1 $2
perl ./UploadParent.pl $1 $2

# UTFファイルを圧縮
if [ -d ./data/utf/result${LZH_NAME} ]; then
    
    cd ./data/utf/

    echo "utf lzh..."
    lha -cq result${LZH_NAME}.lzh result${LZH_NAME}
    echo "rm utf..."
    rm  -r result${LZH_NAME}
        
    cd ../../

fi

cd $CURENT  #元のディレクトリに戻る
