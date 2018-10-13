#===================================================================
#        キャラステータス解析パッケージ
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

require "./source/chara/Name.pm";
require "./source/chara/Profile.pm";
require "./source/chara/Subject.pm";
require "./source/chara/Parameter.pm";
require "./source/chara/Characteristic.pm";
require "./source/chara/Item.pm";
require "./source/chara/Card.pm";
require "./source/chara/Facility.pm";
require "./source/chara/GetCard.pm";
require "./source/chara/DropMinSubject.pm";
require "./source/chara/Place.pm";
require "./source/chara/DevelopmentResult.pm";
require "./source/chara/Training.pm";
require "./source/chara/ItemUse.pm";
require "./source/chara/Mission.pm";

use ConstData;        #定数呼び出し

#------------------------------------------------------------------#
#    パッケージの定義
#------------------------------------------------------------------#
package Character;

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
    if (ConstData::EXE_CHARA_NAME)               { $self->{DataHandlers}{Name}              = Name->new();}
    if (ConstData::EXE_CHARA_PROFILE)            { $self->{DataHandlers}{Profile}           = Profile->new();}
    if (ConstData::EXE_CHARA_SUBJECT)            { $self->{DataHandlers}{Subject}           = Subject->new();}
    if (ConstData::EXE_CHARA_PARAMETER)          { $self->{DataHandlers}{Parameter}         = Parameter->new();}
    if (ConstData::EXE_CHARA_CHARACTERISTIC)     { $self->{DataHandlers}{Characteristic}    = Characteristic->new();}
    if (ConstData::EXE_CHARA_ITEM)               { $self->{DataHandlers}{Item}              = Item->new();}
    if (ConstData::EXE_CHARA_CARD)               { $self->{DataHandlers}{Card}              = Card->new();}
    if (ConstData::EXE_CHARA_FACILITY)           { $self->{DataHandlers}{Facility}          = Facility->new();}
    if (ConstData::EXE_CHARA_GETCARD)            { $self->{DataHandlers}{GetCard}           = GetCard->new();}
    if (ConstData::EXE_CHARA_DROP_MIN_SUBJECT)   { $self->{DataHandlers}{DropSubject}       = DropMinSubject->new();}
    if (ConstData::EXE_CHARA_PLACE)              { $self->{DataHandlers}{Place}             = Place->new();}
    if (ConstData::EXE_CHARA_DEVELOPMENT_RESULT) { $self->{DataHandlers}{DevelopmentResult} = DevelopmentResult->new();}
    if (ConstData::EXE_CHARA_TRAINING)           { $self->{DataHandlers}{Training}          = Training->new();}
    if (ConstData::EXE_CHARA_ITEM_USE)           { $self->{DataHandlers}{ItemUse}           = ItemUse->new();}
    if (ConstData::EXE_CHARA_MISSION)            { $self->{DataHandlers}{Mission}           = Mission->new();}

    #初期化処理
    foreach my $object( values %{ $self->{DataHandlers} } ) {
        $object->Init($self->{ResultNo}, $self->{GenerateNo}, $self->{CommonDatas});
    }
    
    return;
}

#-----------------------------------#
#    圧縮結果から詳細データファイルを抽出
#-----------------------------------#
#    
#-----------------------------------#
sub Execute{
    my $self        = shift;

    print "read files...\n";

    my $start = 1;
    my $end   = 0;
    my $directory = './data/utf/result' . $self->{ResultNo} . '_' . $self->{GenerateNo} . '/result_chara';
    if (ConstData::EXE_ALLRESULT) {
        #結果全解析
        $end = GetFileNo($directory,"result_Eno");
    }else{
        #指定範囲解析
        $start = ConstData::FLAGMENT_START;
        $end   = ConstData::FLAGMENT_END;
    }

    print "$start to $end\n";

    for (my $e_no=$start; $e_no<=$end; $e_no++) {
        if ($e_no % 10 == 0) {print $e_no . "\n"};

        $self->ParsePage($directory."/result_Eno".$e_no.".html",$e_no);
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

    my $span_in3_nodes = &GetNode::GetNode_Tag_Attr("span", "id", "in3", \$tree);
    my $table_ma_nodes = &GetNode::GetNode_Tag_Attr("table", "class", "ma", \$tree);

    if(!scalar(@$span_in3_nodes)){return;}; # 未継続ロストなどシステムメッセージのみの結果を除外

    my $table_ma_node_hash = {};
    $self->DivideTableMaNodes($table_ma_nodes, $table_ma_node_hash);
    
    my $table_in_ma_nodes    = &GetNode::GetNode_Tag("table", \$$table_ma_node_hash{"Profile"});
    my $b_re2_nodes = &GetNode::GetNode_Tag_Attr("b", "id", "re2", \$tree);
    my $div_heading_nodes = &GetNode::GetNode_Tag_Attr("div", "class", "heading", \$tree);
    my $table_width345_nodes    = &GetNode::GetNode_Tag_Attr("table", "width", "345", \$tree);

    # データリスト取得
    if (exists($self->{DataHandlers}{Name}))              {$self->{DataHandlers}{Name}->GetData($e_no, $$span_in3_nodes[0])};
    if (exists($self->{DataHandlers}{Item}))              {$self->{DataHandlers}{Item}->GetData($e_no, $$table_ma_node_hash{"Item"})};
    if (exists($self->{DataHandlers}{Card}))              {$self->{DataHandlers}{Card}->GetData($e_no, $$table_ma_node_hash{"Card"})};
    if (exists($self->{DataHandlers}{Facility}))          {$self->{DataHandlers}{Facility}->GetData($e_no, $$table_ma_node_hash{"Facility"})};
    if (exists($self->{DataHandlers}{Mission}))           {$self->{DataHandlers}{Mission}->GetData($e_no, $$table_ma_node_hash{"Mission"}, $$table_ma_node_hash{"MissionA"})};
    if (exists($self->{DataHandlers}{Profile}))           {$self->{DataHandlers}{Profile}->GetData($e_no, $$table_in_ma_nodes[2])};
    if (exists($self->{DataHandlers}{Subject}))           {$self->{DataHandlers}{Subject}->GetData($e_no, $$table_in_ma_nodes[1])};
    if (exists($self->{DataHandlers}{Parameter}))         {$self->{DataHandlers}{Parameter}->GetData($e_no, $$table_in_ma_nodes[1])};
    if (exists($self->{DataHandlers}{Characteristic}))    {$self->{DataHandlers}{Characteristic}->GetData($e_no, $$table_in_ma_nodes[1])};
    if (exists($self->{DataHandlers}{GetCard}))           {$self->{DataHandlers}{GetCard}->GetData($e_no, $b_re2_nodes)};
    if (exists($self->{DataHandlers}{DropSubject}))       {$self->{DataHandlers}{DropSubject}->GetData($e_no, $$table_in_ma_nodes[1], $b_re2_nodes)};
    if (exists($self->{DataHandlers}{Place}))             {$self->{DataHandlers}{Place}->GetData($e_no, $b_re2_nodes)};
    if (exists($self->{DataHandlers}{DevelopmentResult})) {$self->{DataHandlers}{DevelopmentResult}->GetData($e_no, $b_re2_nodes, $div_heading_nodes, $table_width345_nodes)};
    if (exists($self->{DataHandlers}{Training}))          {$self->{DataHandlers}{Training}->GetData($e_no, $b_re2_nodes)};
    if (exists($self->{DataHandlers}{ItemUse}))           {$self->{DataHandlers}{ItemUse}->GetData($e_no, $b_re2_nodes)};

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
        if($td0_text =~ "Lv"){
            $$table_ma_node_hash{"Profile"} = $table_ma_node;

        }elsif($td0_text =~ "Ino"){
            $$table_ma_node_hash{"Item"} = $table_ma_node;

        }elsif($td0_text =~ "Sno"){
            $$table_ma_node_hash{"Card"} = $table_ma_node;

        }elsif($td0_text =~ "Ano"){
            $$table_ma_node_hash{"Facility"} = $table_ma_node;

        }elsif($td0_text =~ "Mission List"){
            $$table_ma_node_hash{"Mission"} = $table_ma_node;

        }elsif($td0_text =~ "Mission#A List"){
            $$table_ma_node_hash{"MissionA"} = $table_ma_node;
        }
    }
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
