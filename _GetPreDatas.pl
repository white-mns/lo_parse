#===================================================================
#        模擬戦結果ファイル抽出スクリプト
#-------------------------------------------------------------------
#            (C) 2018 @white_mns
#===================================================================

# モジュール呼び出し    ---------------#
require "./source/lib/IO.pm";
require "./source/lib/time.pm";
require "./source/lib/NumCode.pm";

# パッケージの使用宣言    ---------------#
use strict;
use warnings;

use HTML::TreeBuilder;
use source::lib::GetNode;

# 変数の初期化    ---------------#

my $time_checker = TimeChecker->new();


# 実行部    ---------------------------#

$time_checker->CheckTime("start\t");

&Main;

$time_checker->CheckTime("end\t");
$time_checker->OutputTime();
$time_checker = undef;

# 宣言部    ---------------------------#

#-----------------------------------#
#        main
#-----------------------------------#
sub Main{
    my $result_no   = $ARGV[0];
    my $generate_no = $ARGV[1];

    &Execute($result_no,$generate_no)
}

#-----------------------------------#
#    詳細データファイルを探索
#-----------------------------------#
#    
#-----------------------------------#
sub Execute{
    my $result_no   = $ARGV[0];
    my $generate_no = $ARGV[1];

    print "read files...\n";

    my $start = 1;
    my $end   = 0;
    my $directory = './data/utf/result' . $result_no;
    #結果全解析
    $end = GetFileNo($directory."/result_chara","result_Eno");

    print "$start to $end\n";

    for (my $e_no=$start; $e_no<=$end; $e_no++) {
        if ($e_no % 10 == 0) {print $e_no . "\n"};

        ParsePage($directory, $directory."/result_chara/result_Eno".$e_no.".html",$e_no);
    }
    
    return ;
}

#-----------------------------------#
#       ファイルを解析
#-----------------------------------#
#    引数｜ファイル名
#    　　　ENo
##-----------------------------------#
sub ParsePage{
    my $directory = shift;
    my $file_name = shift;
    my $e_no      = shift;

    #結果の読み込み
    my $content = "";
    $content = &IO::FileRead($file_name);

    if (!$content) { return;}

    $content = &NumCode::EncodeEscape($content);
        
    #スクレイピング準備
    my $tree = HTML::TreeBuilder->new;
    $tree->parse($content);

    my $table_ma_nodes = &GetNode::GetNode_Tag_Attr("table", "class", "ma", \$tree);

    if(!scalar(@$table_ma_nodes)){return;}; # 未継続ロストなどシステムメッセージのみの結果を除外
    
    my $a_nodes = &GetNode::GetNode_Tag("a", \$$table_ma_nodes[0]);

    # リンクを元に模擬戦ファイルの取得
    foreach my $a_node (@$a_nodes) {
        if ($a_node->as_text eq "VS") {
            my $pre_file_name = $a_node->attr("href");
            $pre_file_name = substr($pre_file_name, 2);

            for (my $i=0;$i<2;$i++) {
                if ( -s $directory . $pre_file_name) { # 対戦相手の左側ENoと右側Enoで同じ模擬戦ファイルにアクセスが発生するため先に判定
                    last;
                }

                system "wget -O "  . $directory . $pre_file_name . " http://ykamiya.ciao.jp/result" . $pre_file_name;

                sleep 2; 	#負荷軽減用
            }
        }
    }

    $tree = $tree->delete;
}

#-----------------------------------#
#       該当ファイル数を取得
#-----------------------------------#
#    引数｜ディレクトリ名
#    　　　ファイル接頭辞
##-----------------------------------#
sub GetFileNo{
    my $directory   = shift;
    my $prefix    = shift;

    #ファイル名リストを取得
    my @fileList = grep { -f } glob("$directory/$prefix*.html");

    my $max= 0;
    foreach (@fileList) {
        $_ =~ /$prefix(\d+).html/;
        if ($max < $1) {$max = $1;}
    }
    return $max
}

