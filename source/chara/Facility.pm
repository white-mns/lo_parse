#===================================================================
#        施設情報取得パッケージ
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
package Facility;

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
                "set_col",
                "set_lv",
                "name",
                "holiday",
                "division",
                "detail_division",
                "lv",
                "value",
                "period",
    ];

    $self->{Datas}{Data}->Init($header_list);
    
    #出力ファイル設定
    $self->{Datas}{Data}->SetOutputName( "./output/chara/facility_" . $self->{ResultNo} . "_" . $self->{GenerateNo} . ".csv" );
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
    my $table_ma_node = shift;
    
    $self->{ENo} = $e_no;

    $self->GetFacilityData($table_ma_node);
    
    return;
}
#-----------------------------------#
#    施設データ取得
#------------------------------------
#    引数｜施設データノード
#-----------------------------------#
sub GetFacilityData{
    my $self  = shift;
    my $table_in_node = shift;
    
    # trの抽出
    my $tr_nodes = &GetNode::GetNode_Tag("tr",\$table_in_node);
    shift(@$tr_nodes);
 
    #tdの抜出
    foreach my $tr_node (@$tr_nodes){
        my ($set_col, $set_lv, $name, $holiday, $division, $detail_division, $lv, $value, $period) = (0,"", -1, "", 0, 0, 0, -1, -1, -1);
        my $td_nodes = &GetNode::GetNode_Tag("td",\$tr_node);
        if(scalar(@$td_nodes) < 2){next;};
        
        $$td_nodes[0]->as_text =~ /(.+)-(\d+)/;
        $set_col = $1;
        $set_lv  = $2;

        $name    = $$td_nodes[1]->as_text;
        $holiday = $self->{CommonDatas}{ProperName}->GetOrAddId($$td_nodes[2]->as_text);
        $division = $$td_nodes[3]->as_text =~ /^[0-9]+$/ ? 0 : $self->{CommonDatas}{ProperName}->GetOrAddId($$td_nodes[3]->as_text); # 初回更新はBUGで区分が数字になっているため、数字表記の区分は取得しない
        $$td_nodes[4]->as_text =~ /(.+?)Lv(\d+?) /;
        $detail_division  = $self->{CommonDatas}{ProperName}->GetOrAddId($1);
        $lv      = $2;
        $value   = $$td_nodes[5]->as_text;
        $period  = $$td_nodes[6]->as_text;

        my @datas=($self->{ResultNo}, $self->{GenerateNo}, $self->{ENo}, $set_col, $set_lv, $name, $holiday, $division, $detail_division, $lv, $value, $period);
        $self->{Datas}{Data}->AddData(join(ConstData::SPLIT, @datas));
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
