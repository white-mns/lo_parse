#===================================================================
#        コマンド解析パッケージ
#-------------------------------------------------------------------
#            (C) 2018 @white_mns
#===================================================================


# パッケージの使用宣言    ---------------#
use strict;
use warnings;

use ConstData;
use HTML::TreeBuilder;
use source::lib::GetNode;


require "./source/lib/IO.pm";
require "./source/lib/time.pm";
require "./source/lib/NumCode.pm";

require "./source/command/Action.pm";

use ConstData;        #定数呼び出し

#------------------------------------------------------------------#
#    パッケージの定義
#------------------------------------------------------------------#
package Command;

#-----------------------------------#
#    コンストラクタ
#-----------------------------------#
sub new {
  my $class        = shift;

  bless {
    Datas         => {},
    DataHandlers  => {},
    Methods       => {},
    ResultNo      => "",
    GenerateNo    => "",
  }, $class;
}

#-----------------------------------#
#    初期化
#-----------------------------------#
sub Init{
    my $self = shift;
    ($self->{ResultNo}, $self->{GenerateNo}, $self->{CommonDatas}) = @_;

    #インスタンス作成
    if (ConstData::EXE_COMMAND_ACTION) { $self->{DataHandlers}{Action} = Action->new();}

    #初期化処理
    foreach my $object( values %{ $self->{DataHandlers} } ) {
        $object->Init($self->{ResultNo}, $self->{GenerateNo}, $self->{CommonDatas});
    }
    
    return;
}

#-----------------------------------#
#    コマンドファイルを抽出
#-----------------------------------#
#    
#-----------------------------------#
sub Execute{
    my $self        = shift;

    print "read files...\n";

    my $start = 1;
    my $end   = 0;
    my $directory = './data/command/command' . $self->{ResultNo};
    if (ConstData::EXE_ALLRESULT) {
        #結果全解析
        $end = GetMaxFileNo($directory,"En_input");
    }else{
        #指定範囲解析
        $start = ConstData::FLAGMENT_START;
        $end   = ConstData::FLAGMENT_END;
    }

    print "$start to $end\n";

    for (my $e_no=$start; $e_no<=$end; $e_no++) {
        if ($e_no % 10 == 0) {print $e_no . "\n"};

        $self->ParsePage($directory."/En_input".$e_no,$e_no);
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
    my $self        = shift;
    my $file_name   = shift;
    my $e_no        = shift;

    #結果の読み込み
    my $content = "";
    $content = &IO::FileRead($file_name);

    if (!$content) { return;}

    $content = &NumCode::EncodeEscape($content);
        
    #スクレイピング準備
    my $tree = HTML::TreeBuilder->new;
    $tree->parse($content);

    my $table_ma_nodes = &GetNode::GetNode_Tag_Attr("table", "class", "ma", \$tree);

    my $table_ma_node_hash = {};
    $self->DivideTableMaNodes($table_ma_nodes, $table_ma_node_hash);
    
    # データリスト取得
    if (exists($self->{DataHandlers}{Action})) {$self->{DataHandlers}{Action}->GetData($e_no, $$table_ma_node_hash{"Act"})};

    $tree = $tree->delete;
}

#-----------------------------------#
#       maクラスのtableノードを分類
#-----------------------------------#
#    引数｜maクラスのtableノード
#    　　　分配用ハッシュ配列
##-----------------------------------#
sub DivideTableMaNodes{
    my $self = shift;
    my $table_ma_nodes     = shift;
    my $table_ma_node_hash = shift;

    foreach my $table_ma_node (@$table_ma_nodes) {
        my $td_nodes = &GetNode::GetNode_Tag("td", \$table_ma_node);
        if (scalar(@$td_nodes) == 0) { return;}

        my $td0_text = $$td_nodes[0]->as_text;
        if($td0_text =~ "Act"){
            if (!exists($$table_ma_node_hash{"Act"})) {
                $$table_ma_node_hash{"Act"} = [];
            }
            push (@{$$table_ma_node_hash{"Act"}}, $table_ma_node);

        }
    }
}


#-----------------------------------#
#       最大ファイル番号を取得
#-----------------------------------#
#    引数｜ディレクトリ名
#    　　　ファイル接頭辞
##-----------------------------------#
sub GetMaxFileNo{
    my $directory   = shift;
    my $prefix    = shift;

    #ファイル名リストを取得
    my @fileList = grep { -f } glob("$directory/$prefix*");

    my $max= 0;
    foreach (@fileList) {
        $_ =~ /$prefix(\d+)/;
        if ($max < $1) {$max = $1;}
    }
    return $max
}

#-----------------------------------#
#    出力
#-----------------------------------#
#    引数｜ファイルアドレス
#-----------------------------------#
sub Output{
    my $self = shift;
    foreach my $object( values %{ $self->{Datas} } ) {
        $object->Output();
    }
    foreach my $object( values %{ $self->{DataHandlers} } ) {
        $object->Output();
    }
    return;
}

1;
