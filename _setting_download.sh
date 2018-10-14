#!/bin/bash
# コマンドページ取得プログラム

CURENT=`pwd`	#実行ディレクトリの保存
cd `dirname $0`	#解析コードのあるディレクトリで作業をする

RESULT_NO=$1
GENERATE_NO=$2

LZH_NAME=${RESULT_NO}

mkdir ./data/setting/setting${RESULT_NO}

for ((E_NO=1;E_NO <= 400;E_NO++)) {
    for ((i=0;i < 2;i++)) { # 2回までリトライする
        if [ -s ./data/setting/setting${RESULT_NO}/En_input${E_NO} ]; then
            break
        fi

        wget -O ./data/setting/setting${RESULT_NO}/En_input${E_NO} http://ykamiya.ciao.jp/cgi-bin/command.cgi?En_input=${E_NO}

        sleep 2
    }
}

grep データは存在しません！ -rl ./data/setting/setting${RESULT_NO} | xargs rm # 存在しないキャラのファイルを削除

# ファイルを圧縮
if [ -d ./data/setting/setting${RESULT_NO} ]; then
    
    cd ./data/setting/

    echo "orig lzh..."
    lha -cq setting${RESULT_NO}.lzh setting${RESULT_NO}
    echo "rm directory..."
    rm  -r setting${RESULT_NO}
        
    cd ../../
fi

cd $CURENT  #元のディレクトリに戻る
