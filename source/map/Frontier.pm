#===================================================================
#        マップ開拓情報取得パッケージ
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
package Frontier;

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
                "col",
                "lv",
    ];

    $self->{Datas}{Data}->Init($header_list);
    
    #出力ファイル設定
    $self->{Datas}{Data}->SetOutputName( "./output/map/frontier_" . $self->{ResultNo} . "_" . $self->{GenerateNo} . ".csv" );
    return;
}

#-----------------------------------#
#    データ取得
#------------------------------------
#    引数｜e_no,カードデータノード
#-----------------------------------#
sub GetData{
    my $self    = shift;
    my $table_node = shift;

    $self->GetFrontierData($table_node);
    
    return;
}
#-----------------------------------#
#    カードデータ取得
#------------------------------------
#    引数｜カードデータノード
#-----------------------------------#
sub GetFrontierData{
    my $self  = shift;
    my $table_node = shift;

    if (!$table_node) {return;}
    
    # trの抽出
    my $tr_nodes = &GetNode::GetNode_Tag("tr",\$table_node);
    shift(@$tr_nodes);
 
    #tdの抜出
    foreach my $tr_node (@$tr_nodes){
        my ($e_no, $col, $lv) = (0, 0, 0);
        my $td_nodes = &GetNode::GetNode_Tag("td",\$tr_node);
        
        $col = $$td_nodes[0]->as_text;
        $col =~ s/　//g;

        $lv = $$td_nodes[1]->as_text;
        $lv =~ s/\-Lv//;

        my $node3   = $$td_nodes[2]->as_text;
        $node3 =~ /Eno(\d+?) /;
        $e_no = $1;

        $self->{Datas}{Data}->AddData(join(ConstData::SPLIT, ($self->{ResultNo}, $self->{GenerateNo}, $e_no, $col, $lv)));

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
