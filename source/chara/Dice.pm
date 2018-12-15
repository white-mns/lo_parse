#===================================================================
#        ダイス目取得パッケージ
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
package Dice;

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
                "number",
                "dice",
                "use_item",
    ];

    $self->{Datas}{Data}->Init($header_list);
    
    #出力ファイル設定
    $self->{Datas}{Data}->SetOutputName( "./output/chara/dice_" . $self->{ResultNo} . "_" . $self->{GenerateNo} . ".csv" );
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
    my $b_re2_nodes = shift;
    
    $self->{ENo} = $e_no;

    $self->GetDiceData($b_re2_nodes);
    
    return;
}
#-----------------------------------#
#    ダイス目データ取得
#------------------------------------
#    引数｜太字ノード
#-----------------------------------#
sub GetDiceData{
    my $self  = shift;
    my $b_re2_nodes = shift;
    
    foreach my $b_re2_node (@$b_re2_nodes) {
        my $b_re2_text = $b_re2_node->as_text;
        
        if ($b_re2_text !~ /移動の前に/) {next;}

        my @right_nodes = $b_re2_node->right;
        my ($number, $use_item) = (1, 0);
        foreach my $node (@right_nodes) {
            if ($node =~ /HASH/ && ($node->tag eq "b" || $node->tag eq "hr")) { last;}
            
            if ($node =~ /HASH/ && $node->tag eq "img") {
                my $dice = 0;

                if ($node->attr("src") =~ /dice_(\d)\.gif/) {
                    $dice = $1;

                    $self->{Datas}{Data}->AddData(join(ConstData::SPLIT, ($self->{ResultNo}, $self->{GenerateNo}, $self->{ENo}, $number, $dice, $use_item)));

                    $number   += 1;
                    $use_item  = 0;
                }

            } elsif ($node =~ /HASH/ && $node->tag eq "span" && $node->attr("id") && $node->attr("id") eq "it1") {
                my $use_item_text = $node->as_text;

                if ($use_item_text =~ / (\d)歩カード/) {
                    $use_item = $1;
                }

            } elsif ($node =~ /ダイスを振らず/) {
                    $self->{Datas}{Data}->AddData(join(ConstData::SPLIT, ($self->{ResultNo}, $self->{GenerateNo}, $self->{ENo}, $number, 0, 0)));
                    $number += 1;
                    $self->{Datas}{Data}->AddData(join(ConstData::SPLIT, ($self->{ResultNo}, $self->{GenerateNo}, $self->{ENo}, $number, 0, 0)));

                    return;
            }
        }
    }

    return;
}

#-----------------------------------#
#    出力
#------------------------------------
#    引数｜
#-----------------------------------#
sub Output{
    my $self = shift;
    
    foreach my $object( values %{ $self->{Datas} } ) {
        $object->Output();
    }
    return;
}
1;
