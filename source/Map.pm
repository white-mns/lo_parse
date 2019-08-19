#===================================================================
#        模擬戦トップページ解析パッケージ
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

require "./source/map/Frontier.pm";

use ConstData;        #定数呼び出し

#------------------------------------------------------------------#
#    パッケージの定義
#------------------------------------------------------------------#
package Map;

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
    if (ConstData::EXE_MAP_FRONTIER) { $self->{DataHandlers}{Frontier} = Frontier->new();}

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

    my $directory = './data/utf/result' . $self->{ResultNo} . '_' . $self->{GenerateNo} . '/result_map';

    print "Allmap\n";
    $self->ParsePage($directory."/ALLmap.html");
    
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

    #結果の読み込み
    my $content = "";
    $content = &IO::FileRead($file_name);

    if (!$content) { return;}

    $content = &NumCode::EncodeEscape($content);
        
    #スクレイピング準備
    my $tree = HTML::TreeBuilder->new;
    $tree->parse($content);

    my $table_nodes = &GetNode::GetNode_Tag("table", \$tree);

    # データリスト取得
    if (exists($self->{DataHandlers}{Frontier})) {$self->{DataHandlers}{Frontier}->GetData($$table_nodes[1])};

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
