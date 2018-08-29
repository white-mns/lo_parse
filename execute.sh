#!/bin/bash

CURENT=`pwd`	#実行ディレクトリの保存
cd `dirname $0`	#解析コードのあるディレクトリで作業をする

RESULT_NO=$1
GENERATE_NO=$2

LZH_NAME=${RESULT_NO}_$GENERATE_NO

#wget -O data/orig/result${LZH_NAME}.lzh http://ykamiya.ciao.jp/file/result$RESULT_NO.lzh

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

    echo "shift-jis to utf8..."
    cd ../utf/result${LZH_NAME}/    
    nkf -w --overwrite result_chara/*.html
    nkf -w --overwrite result_map/*.html
    nkf -w --overwrite result_maph/*.html
    nkf -w --overwrite result_pre/*.html
    nkf -w --overwrite *.css
    
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
