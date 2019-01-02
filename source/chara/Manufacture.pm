#===================================================================
#        作製結果取得パッケージ
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
package Manufacture;

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
    $self->{Datas}{Manufacture}    = StoreData->new();

    my $header_list = "";
   
    $header_list = [
                "result_no",
                "generate_no",
                "e_no",
                "facility_name",
                "facility_effect",
                "facility_lv",
                "facility_e_no",
                "item_name",
                "usage",
                "cost",
                "kind",
                "effect",
                "effect_lv",
                "potency",
                "precision",
                "total",
    ];
    $self->{Datas}{Manufacture}->Init($header_list);
   
    #出力ファイル設定
    $self->{Datas}{Manufacture}->SetOutputName   ( "./output/chara/manufacture_"   . $self->{ResultNo} . "_" . $self->{GenerateNo} . ".csv" );

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

    $self->GetManufactureData($b_re2_nodes);
    
    return;
}
#-----------------------------------#
#    作製データ取得
#------------------------------------
#    引数｜太字データノード
#-----------------------------------#
sub GetManufactureData{
    my $self  = shift;
    my $b_re2_nodes = shift;
    
    foreach my $b_re2_node (@$b_re2_nodes){

        my $b_re2_text = $b_re2_node->as_text;
        if ($b_re2_text =~ /　施設　/) {
            my ($facility_name, $facility_effect, $facility_lv, $facility_e_no, $item_name, $usage, $cost, $kind, $effect, $effect_lv, $potency, $precision, $total) = ("", 0, -1, -1, "", -1, -1, 0, 0, -1, -1, -1, -1);
            my @right_nodes = $b_re2_node->right;

            foreach my $node (@right_nodes) {
                if ($node =~ /HASH/ && ($node->tag eq "b" || $node->tag eq "hr")) { last;}

                if ($node =~ /HASH/ && $node->tag eq "span" && $node->attr("id") eq "ho1") {
                    ($facility_name, $facility_effect, $facility_lv, $facility_e_no, $item_name, $usage, $cost, $kind, $effect, $effect_lv, $potency, $precision, $total) = ("", 0, -1, -1, "", -1, -1, 0, 0, -1, -1, -1, -1);

                    if ($node->as_text =~ /(.+)Lv(\d+)：(.+)/) {
                        $facility_effect = $self->{CommonDatas}{ProperName}->GetOrAddId($1);
                        $facility_lv     = $2;
                        $facility_name   = $3;
                    }
                }

                if ($node =~ /（所有Eno(\d+)）/) {
                    $facility_e_no = $1;
                }

                if ($node =~ /に(\d+)Tipを支払い完了/) {
                    $usage = $1;
                }

                if ($node =~ /作製費(\d+)Tip/) {
                    $cost = $1;
                }

                if ($node =~ /HASH/ && $node->tag eq "span" && $node->attr("id") eq "it1") {
                    $item_name = $node->as_text;
                }

                if ($node =~ /を作製完了。（(?:\+Ino\d+ )*(.+)\/(.+)Lv(\d+)\/効力(\d+)\/精度(\d+)/) {
                    $kind      = $self->{CommonDatas}{ProperName}->GetOrAddId($1);
                    $effect    = $self->{CommonDatas}{ProperName}->GetOrAddId($2);
                    $effect_lv = $3+0;
                    $potency   = $4+0;
                    $precision = $5+0;
                    $total     = $potency + $precision;

                    $self->{Datas}{Manufacture}->AddData(join(ConstData::SPLIT, ($self->{ResultNo}, $self->{GenerateNo}, $self->{ENo}, $facility_name, $facility_effect, $facility_lv, $facility_e_no, $item_name, $usage, $cost, $kind, $effect, $effect_lv, $potency, $precision, $total) ));
                }
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
