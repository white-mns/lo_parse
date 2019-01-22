#===================================================================
#        模擬戦勝数取得パッケージ
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
package PreWin;

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
    $self->{Datas}{Result}   = StoreData->new();
    $self->{Datas}{WinCount} = StoreData->new();
    my $header_list = "";
   
    $header_list = [
                "result_no",
                "generate_no",
                "e_no",
                "win",
                "draw",
                "lose",
                "all",
    ];

    $self->{Datas}{Result}->Init($header_list);

    #出力ファイル設定
    $self->{Datas}{Result}->SetOutputName  ( "./output/all_pre/pre_win_"       . $self->{ResultNo} . "_" . $self->{GenerateNo} . ".csv" );
    return;
}

#-----------------------------------#
#    データ取得
#------------------------------------
#    引数｜模擬戦一覧ノード
#-----------------------------------#
sub GetData{
    my $self    = shift;
    my $table_ma_node = shift;

    $self->GetPreData($table_ma_node);
    
    return;
}

#-----------------------------------#
#    模擬戦勝数データ取得
#------------------------------------
#    引数｜模擬戦一覧ノード
#-----------------------------------#
sub GetPreData{
    my $self  = shift;
    my $table_in_node = shift;
    
    # trの抽出
    my $tr_nodes = &GetNode::GetNode_Tag("tr",\$table_in_node);
    shift(@$tr_nodes);
 
    #tdの抜出
    foreach my $tr_node (@$tr_nodes){
        $self->GetPreResultData($tr_node);
    }

    return;
}

#-----------------------------------#
#    模擬戦勝数取得
#------------------------------------
#    引数｜模擬戦一覧ノード
#-----------------------------------#
sub GetPreResultData{
    my $self  = shift;
    my $tr_node = shift;
    
    #tdの抜出
    my ($e_no, $win, $draw, $lose, $all) = (0, 0, 0, 0, 0);
    my $td_nodes = &GetNode::GetNode_Tag("td",\$tr_node);
    my $link_nodes = &GetNode::GetNode_Tag("a",\$$td_nodes[1]);

    if ($$td_nodes[0]->as_text =~ /(\d)\/(\d)\/(\d)/) {
        $win  = $1;
        $draw = $2;
        $all  = $3;
        $lose = 3 - $win - $draw;
    }

    if ($$link_nodes[0]->attr("href") =~ /result_Eno(\d+).html/) {
        $e_no = $1;
    }
 
    $self->{Datas}{Result}->AddData(join(ConstData::SPLIT, ($self->{ResultNo}, $self->{GenerateNo}, $e_no, $win, $draw, $lose, $all)));

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
