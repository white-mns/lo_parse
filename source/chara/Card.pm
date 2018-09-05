#===================================================================
#        所持カード情報取得パッケージ
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
package Card;

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
                "s_no",
                "name",
                "possession",
                "card_id",
    ];

    $self->{Datas}{Data}->Init($header_list);
    
    #出力ファイル設定
    $self->{Datas}{Data}->SetOutputName( "./output/chara/card_" . $self->{ResultNo} . "_" . $self->{GenerateNo} . ".csv" );
    return;
}

#-----------------------------------#
#    データ取得
#------------------------------------
#    引数｜e_no,カードデータノード
#-----------------------------------#
sub GetData{
    my $self    = shift;
    my $e_no    = shift;
    my $table_ma_node = shift;
    
    $self->{ENo} = $e_no;

    $self->GetCardData($table_ma_node);
    
    return;
}
#-----------------------------------#
#    カードデータ取得
#------------------------------------
#    引数｜カードデータノード
#-----------------------------------#
sub GetCardData{
    my $self  = shift;
    my $table_in_node = shift;
    
    # trの抽出
    my $tr_nodes = &GetNode::GetNode_Tag("tr",\$table_in_node);
    shift(@$tr_nodes);
 
    #tdの抜出
    foreach my $tr_node (@$tr_nodes){
        my ($s_no, $name, $possession, $kind, $card_id) = (0, "", 0, 0, 0);
        my ($effect, $lv, $lp, $fp) = ("", 0, -1, -1);
        my $td_nodes = &GetNode::GetNode_Tag("td",\$tr_node);
        if(scalar(@$td_nodes) < 2){next;};
        
        $s_no    = $$td_nodes[0]->as_text;
        $name    = $$td_nodes[1]->as_text;

        $possession = $self->{CommonDatas}{ProperName}->GetOrAddId($$td_nodes[2]->as_text);
        $kind       = $self->{CommonDatas}{ProperName}->GetOrAddId($$td_nodes[3]->as_text);

        my $node3   = $$td_nodes[4]->as_text;
        $node3 =~ /(.+?)Lv(\d+?)$/;
        $effect = $1;
        $lv     = $2;
        $lp     = $$td_nodes[5]->as_text;
        $fp     = $$td_nodes[6]->as_text;

        $card_id = $self->{CommonDatas}{CardData}->GetOrAddId(1, [$effect,$kind, $lv, $lp, $fp]);

        my @datas=($self->{ResultNo}, $self->{GenerateNo}, $self->{ENo}, $s_no, $name, $possession, $card_id);
        $self->{Datas}{Data}->AddData(join(ConstData::SPLIT, @datas));

    }


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
