#===================================================================
#        模擬戦解析パッケージ
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

require "./source/battle/CardUse.pm";
require "./source/battle/MeddlingSuccessRate.pm";
require "./source/battle/Damage.pm";

use ConstData;        #定数呼び出し

#------------------------------------------------------------------#
#    パッケージの定義
#------------------------------------------------------------------#
package Battle;

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
    if (ConstData::EXE_BATTLE_CARD_USE)              { $self->{DataHandlers}{CardUse}             = CardUse->new();}
    if (ConstData::EXE_BATTLE_MEDDLING_SUCCESS_RATE) { $self->{DataHandlers}{MeddlingSuccessRate} = MeddlingSuccessRate->new();}
    if (ConstData::EXE_BATTLE_DAMAGE)                { $self->{DataHandlers}{Damage}              = Damage->new();}

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

    print "read battle files...\n";

    my $start = 1;
    my $end   = 0;
    my $parse_max = 100000;

    my $directory = './data/utf/result' . $self->{ResultNo} . '_' . $self->{GenerateNo} . '/result_pre';
    my @file_names = glob($directory . '/*.html');

    if (ConstData::EXE_ALLRESULT) {
        #結果全解析
        $end = scalar(@file_names);
    }else{
        #指定範囲解析
        $start = ConstData::FLAGMENT_START;
        $end   = ConstData::FLAGMENT_END;
        $parse_max = $end - $start + 1;
    }

    print "$start to $end\n";

    my $i = 0;
    foreach my $file_name (@file_names) {
        if ($i % 10 == 0)    {print $i . "\n"};
        if ($parse_max < $i) {last;}
        $i++;

        $self->ParsePage($file_name);
    }
    
    return ;
}
#-----------------------------------#
#       ファイルを解析
#-----------------------------------#
#    引数｜ファイル名
##-----------------------------------#
sub ParsePage{
    my $self        = shift;
    my $file_name   = shift;

    if($file_name !~ /Pno(.*)\.html/){return;}
    my $result_page = $1;

    #結果の読み込み
    my $content = "";
    $content = &IO::FileRead($file_name);

    if (!$content) { return;}

    $content = &NumCode::EncodeEscape($content);
        
    #スクレイピング準備
    my $tree = HTML::TreeBuilder->new;
    $tree->parse($content);

    my $font_player_nodes = &GetNode::GetNode_Tag_Attr("font", "color", "#009999", \$tree);
    my $font_enemy_nodes  = &GetNode::GetNode_Tag_Attr("font", "color", "#666600", \$tree);
    my $link_nodes        = &GetNode::GetNode_Tag("a", \$tree);
    my $table_345_nodes   = &GetNode::GetNode_Tag_Attr("table", "width", "345",     \$tree);
    my $div_heading_nodes = &GetNode::GetNode_Tag_Attr("div",   "class", "heading", \$tree);

    # データリスト取得
    if (exists($self->{DataHandlers}{CardUse}))             {$self->{DataHandlers}{CardUse}->GetData            ($result_page, $font_player_nodes, $font_enemy_nodes, $link_nodes, $table_345_nodes)};
    if (exists($self->{DataHandlers}{MeddlingSuccessRate})) {$self->{DataHandlers}{MeddlingSuccessRate}->GetData($result_page, $font_player_nodes, $font_enemy_nodes, $link_nodes, $table_345_nodes)};
    if (exists($self->{DataHandlers}{Damage}))              {$self->{DataHandlers}{Damage}->GetData             ($result_page, $div_heading_nodes, $link_nodes, $table_345_nodes)};

    $tree = $tree->delete;
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
