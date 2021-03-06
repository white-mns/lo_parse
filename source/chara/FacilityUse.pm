#===================================================================
#        施設利用取得パッケージ
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
package FacilityUse;

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
    $self->{Datas}{FacilityUse}    = StoreData->new();

    my $header_list = "";
   
    $header_list = [
                "result_no",
                "generate_no",
                "e_no",
                "facility_name",
                "facility_effect",
                "facility_lv",
                "facility_e_no",
                "usage",
                "cost",
                "success",
                "number",
                "recovery_lv",
    ];
    $self->{Datas}{FacilityUse}->Init($header_list);
   
    #出力ファイル設定
    $self->{Datas}{FacilityUse}->SetOutputName   ( "./output/chara/facility_use_"   . $self->{ResultNo} . "_" . $self->{GenerateNo} . ".csv" );

    return;
}

#-----------------------------------#
#    データ取得
#------------------------------------
#    引数｜e_no,名前データノード,太字データノード
#-----------------------------------#
sub GetData{
    my $self    = shift;
    my $e_no    = shift;
    my $b_re2_nodes = shift;
    
    $self->{ENo} = $e_no;

    $self->GetFacilityUseData($b_re2_nodes);
    
    return;
}
#-----------------------------------#
#    施設利用データ取得
#------------------------------------
#    引数｜太字データノード
#-----------------------------------#
sub GetFacilityUseData{
    my $self  = shift;
    my $b_re2_nodes = shift;
    
    my $number = 1;
    foreach my $b_re2_node (@$b_re2_nodes){

        my $b_re2_text = $b_re2_node->as_text;
        if ($b_re2_text =~ /　施設　/) {
            my ($facility_name, $facility_effect, $facility_lv, $facility_e_no, $usage, $cost, $success, $recovery_lv) = ("", 0, -1, -1, -1, -1, 1, 0);
            my @right_nodes = $b_re2_node->right;

            foreach my $node (@right_nodes) {
                if ($node =~ /HASH/ && ($node->tag eq "b" || $node->tag eq "hr")) { last;}

                if ($node =~ /HASH/ && $node->tag eq "span" && $node->attr("id") eq "ho1") {
                    ($facility_name, $facility_effect, $facility_lv, $facility_e_no, $usage, $cost, $success, $recovery_lv) = ("", 0, -1, -1, -1, -1, 1, 0);

                    if ($node->as_text =~ /(.+)Lv(\d+)：(.+)/) {
                        $facility_effect = $self->{CommonDatas}{ProperName}->GetOrAddId($1);
                        $facility_lv     = $2;
                        $facility_name   = $3;
                        $facility_name   =~ s/^\s//;
                    }
                }

                if ($node =~ /（所有Eno(\d+)）/) {
                    $facility_e_no = $1;
                }

                if ($node =~ /に(\d+)Tipを支払い完了/) {
                    $usage = $1;
                }

                if ($node =~ /費(\d+)Tip/) {
                    $cost = $1;
                }

                if ($node =~ /が足りなかった。/) {
                    $success = -1;
                }
                
                if ($node =~ /Conditionが回復♪/) {
                    $recovery_lv = $facility_lv;
                }

                if ($node =~ /（\+Ino\d+/ || $node =~ /が足りなかった。/ || $node =~ /能力訓練を行った。その成果は…？/) {
                    $self->{Datas}{FacilityUse}->AddData(join(ConstData::SPLIT, ($self->{ResultNo}, $self->{GenerateNo}, $self->{ENo}, $facility_name, $facility_effect, $facility_lv, $facility_e_no, $usage, $cost, $success, $number, $recovery_lv) ));
                    $number += 1;
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
