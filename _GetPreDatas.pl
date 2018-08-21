#===================================================================
#        模擬戦結果ファイル抽出スクリプト本体
#-------------------------------------------------------------------
#            (C) 2016 @white_mns
#===================================================================

# モジュール呼び出し    ---------------#
require "./source/lib/IO.pm";
require "./source/lib/time.pm";
require "./source/lib/NumCode.pm";
require "./source/Character.pm";
require "./source/Battle.pm";


# パッケージの使用宣言    ---------------#
use strict;
use warnings;
use HTML::TreeBuilder;
require LWP::UserAgent;
require LWP::Simple;
use HTTP::Request;
use HTTP::Response;
use File::Spec;

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
    my $resultNum = $ARGV[0];
    my $generateNum = $ARGV[1];

	#結果の読み込み
	my $content = "";
	$content = AccessOriginalData("http://ykamiya.sakura.ne.jp/result/result_pre/");

	mkdir("./data/orig/result" . $resultNum . "_" . $generateNum, 0755);
	mkdir("./data/orig/result" . $resultNum . "_" . $generateNum . "/result_pre", 0755);

	#スクレイピング準備
	my $tree = HTML::TreeBuilder->new;
	$tree->parse($content);
	
    my $link_nodes	= &GetNode::GetNode_Tag("a", \$tree);	# スキルノード取得
    foreach my $link_node (@$link_nodes){
        my $text = $link_node->as_text;
        if($text !~ /Pno(.+)\.html/){next;}
        my $battle_page = $1;

        print $battle_page . "\n";

	    system "wget -P ./data/orig/result" . $resultNum . "_" . $generateNum . " http://ykamiya.sakura.ne.jp/result/result_pre/result_Pno" . $battle_page . ".html";
        sleep 5; 	#負荷軽減用
    }
}

#-----------------------------------#
#	本家ページの読み込み
#-----------------------------------#
#	引数｜
#-----------------------------------#
sub AccessOriginalData{
	my $address	= shift;
	
	my $content = &HTTPAccess($address);
	return $content;
}
#-----------------------------------#
#	HTTPアクセス
#-----------------------------------#
#	引数｜URL
#-----------------------------------#
sub HTTPAccess{
	my ($URL) = @_; # アクセスする URL
	
	my $ua = new LWP::UserAgent;
	$ua->agent('Mozilla/5.0 (compatible; MSIE 10.0; Windows NT 6.1; Trident/6.0)'); # 任意
	$ua->timeout(60); # 任意
	
	#学内プロキシ
	#my $http_proxy = "http://172.16.1.1:3128/";
	#$ua->proxy([qw(http https)], $http_proxy);

    print $URL . "\n";    
	my $req = HTTP::Request->new('GET' => $URL);
	my $res = $ua->request($req);
	my $content = $res->content;
	return $content;
}
