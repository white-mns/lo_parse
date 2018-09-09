#===================================================================
#        現在地情報取得パッケージ
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
package Place;

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
                "invation_col",
                "invation_lv",
                "return_col",
                "return_lv",
    ];

    $self->{Datas}{Data}->Init($header_list);
    
    #出力ファイル設定
    $self->{Datas}{Data}->SetOutputName( "./output/chara/place_" . $self->{ResultNo} . "_" . $self->{GenerateNo} . ".csv" );
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

    $self->GetPlaceData($b_re2_nodes);
    
    return;
}
#-----------------------------------#
#    現在地データ取得
#------------------------------------
#    引数｜現在地データノード
#-----------------------------------#
sub GetPlaceData{
    my $self  = shift;
    my $b_re2_nodes = shift;
    my ($invation_col, $invation_lv, $return_col, $return_lv) = ("", -1, "", -1);
    
    #tdの抜出
    foreach my $b_re2_node (@$b_re2_nodes) {
        my $b_re2_text = $b_re2_node->as_text;
        
        if ($b_re2_text !~ /本日の侵攻/ && $b_re2_text !~ /帰還/) {next;}

        my @right_nodes = $b_re2_node->right;
        foreach my $right_node (@right_nodes) {
            if ($right_node =~ /HASH/ && $right_node->tag eq "a") {
                $right_node->as_text =~ m!≫現在地：(.)-Lv(\d+) !;
                my ($col, $lv) = ($1,$2);

                if ($b_re2_text =~ /本日の侵攻/) {
                    $invation_col = $col;
                    $invation_lv  = $lv;

                }elsif ($b_re2_text =~ /帰還/) {
                    $return_col = $col;
                    $return_lv  = $lv;
                }

                last;
            }
        }
    }

    my @datas=($self->{ResultNo}, $self->{GenerateNo}, $self->{ENo}, $invation_col, $invation_lv, $return_col, $return_lv);
    $self->{Datas}{Data}->AddData(join(ConstData::SPLIT, @datas));

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
