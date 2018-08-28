#===================================================================
#        特性情報取得パッケージ
#-------------------------------------------------------------------
#            (C) 2018 @white_mns
#===================================================================


# パッケージの使用宣言    ---------------#   
use strict;
use warnings;
require "./source/lib/Store_Data.pm";
require "./source/lib/Store_HashData.pm";
use ConstData;        #定数呼び出し
use source::lib::GetNode;


#------------------------------------------------------------------#
#    パッケージの定義
#------------------------------------------------------------------#     
package Characteristic;

#-----------------------------------#
#    コンストラクタ
#-----------------------------------#
sub new {
  my $class = shift;
  
  bless {
        Datas => {},
  }, $class;
}

#-----------------------------------#
#    初期化
#-----------------------------------#
sub Init{
    my $self = shift;
    ($self->{ResultNo}, $self->{GenerateNo}, $self->{CommonDatas}) = @_;
    
    #初期化
    $self->{Datas}{Data} = StoreData->new();

    my $header_list = "";
   
    $header_list = [
                "result_no",
                "generate_no",
                "e_no",
                "str",
                "vit",
                "int",
                "mnd",
                "tec",
                "eva",
    ];

    $self->{Datas}{Data}->Init($header_list);
    
    #出力ファイル設定
    $self->{Datas}{Data}->SetOutputName( "./output/chara/characteristic_" . $self->{ResultNo} . "_" . $self->{GenerateNo} . ".csv" );
    return;
}

#-----------------------------------#
#    データ取得
#------------------------------------
#    引数｜e_no,名前データノード
#-----------------------------------#
sub GetData{
    my $self    = shift;
    my $e_no    = shift;
    my $table_in_ma_node = shift;
    
    $self->{ENo} = $e_no;

    $self->GetCharacteristicData($table_in_ma_node);
    
    return;
}
#-----------------------------------#
#    特性データ取得
#------------------------------------
#    引数｜PCデータノード
#-----------------------------------#
sub GetCharacteristicData{
    my $self  = shift;
    my $table_in_ma_node = shift;
    my ($str, $vit, $int, $mnd, $tec, $eva) = (0, 0, 0, 0, 0, 0);
    
    # tdの抽出
    my $td_nodes = &GetNode::GetNode_Tag("td",\$table_in_ma_node);
 
    foreach my $td_node(@$td_nodes){    
        my $td_text = $td_node->as_text;
        my $right = $td_node->right;
        my $right_text = ($right && $right =~ /HASH/) ? $right->as_text : $right;

        if($td_text eq "腕力"){
            $right_text =~ /(\d+?) /;
            $str = $1;
        }elsif($td_text eq "体力"){
            $right_text =~ /(\d+?) /;
            $vit = $1;
        }elsif($td_text eq "理力"){
            $right_text =~ /(\d+?) /;
            $int = $1;
        }elsif($td_text eq "精神"){
            $right_text =~ /(\d+?) /;
            $mnd = $1;
        }elsif($td_text eq "器用"){
            $right_text =~ /(\d+?) /;
            $tec = $1;
        }elsif($td_text eq "敏捷"){
            $right_text =~ /(\d+?) /;
            $eva = $1;
        }
    }

    my @datas=($self->{ResultNo}, $self->{GenerateNo}, $self->{ENo}, $str, $vit, $int, $mnd, $tec, $eva);
    $self->{Datas}{Data}->AddData(join(ConstData::SPLIT, @datas));

    return;
}

#-----------------------------------#
#    出力
#------------------------------------
#    引数｜ファイルアドレス
#-----------------------------------#
sub Output{
    my $self = shift;
    
    foreach my $object( values %{ $self->{Datas} } ) {
        $object->Output();
    }
    return;
}
1;
