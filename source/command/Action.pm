#===================================================================
#        カードセット取得パッケージ
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
package Action;

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
                "act",
                "s_no",
                "timing",
                "gowait",
                "card_id",
    ];

    $self->{Datas}{Data}->Init($header_list);
    
    #出力ファイル設定
    $self->{Datas}{Data}->SetOutputName( "./output/command/action_" . $self->{ResultNo} . "_" . $self->{GenerateNo} . ".csv" );
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
    my $table_ma_nodes = shift;
    
    $self->{ENo} = $e_no;

    if ($self->{ResultNo} == 3) { # Vol.3以前はコマンドページを取得しなかったため、Vol.3はVol.4の前回設定を参照する
        $self->GetActionData($$table_ma_nodes[1]);
    } else {
        $self->GetActionData($$table_ma_nodes[0]);
    }
    
    return;
}
#-----------------------------------#
#    アイテムデータ取得
#------------------------------------
#    引数｜アイテムデータノード
#-----------------------------------#
sub GetActionData{
    my $self  = shift;
    my $table_in_node = shift;

    my $got_s_no = {};
    
    # trの抽出
    my $tr_nodes = &GetNode::GetNode_Tag("tr",\$table_in_node);
    shift(@$tr_nodes);
 
    #tdの抜出
    foreach my $tr_node (@$tr_nodes){
        my ($act, $s_no, $timing, $gowait, $card_id) = (-1, -1, 0, 0, 0);
        my $td_nodes = &GetNode::GetNode_Tag("td",\$tr_node);
        if(scalar(@$td_nodes) < 2){next;};
        
        $act    = $$td_nodes[0]->as_text;
        
        

        my $font_nodes = &GetNode::GetNode_Tag("font",\$$td_nodes[1]);
        if(scalar(@$font_nodes) > 0){
            if ($$font_nodes[0]->as_text =~ /Sno(\d+)/) {
                $s_no = $1;
                $$got_s_no{$s_no} = 1;
            }
        }

        my $span_nodes = &GetNode::GetNode_Tag_Attr("span", "style", "float: right",\$$td_nodes[1]);
        if(scalar(@$span_nodes) > 0){
            $timing = $self->{CommonDatas}{ProperName}->GetOrAddId($$span_nodes[0]->as_text);
        }

        $gowait = $self->{CommonDatas}{ProperName}->GetOrAddId($$td_nodes[3]->as_text);

        if($$td_nodes[4]->as_text =~ /(.+?)Lv(\d+?)$/){
            my $effect  = $1;
            my $lv      = $2;
            $card_id = $self->{CommonDatas}{CardData}->GetOrAddId(0, [$effect, 0, $lv, 0, 0, 0]);
        }

        $self->{Datas}{Data}->AddData(join(ConstData::SPLIT, ($self->{ResultNo}, $self->{GenerateNo}, $self->{ENo}, $act, $s_no, $timing, $gowait, $card_id) ));
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
