#===================================================================
#        ミッション情報取得パッケージ
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
package Mission;

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
                "mission_id",
                "mission_type",
                "status",
                "col",
                "lv",
    ];

    $self->{Datas}{Data}->Init($header_list);
    
    #出力ファイル設定
    $self->{Datas}{Data}->SetOutputName( "./output/chara/mission_" . $self->{ResultNo} . "_" . $self->{GenerateNo} . ".csv" );
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
    my $table_mission_node = shift;
    my $table_missionA_node = shift;
    
    $self->{ENo} = $e_no;

    $self->GetMissionData($table_mission_node, 0);
    $self->GetMissionData($table_missionA_node, 1);
    
    return;
}
#-----------------------------------#
#    ミッションデータ取得
#------------------------------------
#    引数｜ミッションデータノード
#-----------------------------------#
sub GetMissionData{
    my $self  = shift;
    my $table_in_node = shift;
    my $type = shift;
    
    # trの抽出
    my $tr_nodes = &GetNode::GetNode_Tag("tr",\$table_in_node);
    shift(@$tr_nodes);
 
    #tdの抜出
    foreach my $tr_node (@$tr_nodes){
        my ($mission_id, $status, $col, $lv) = (0, -99, "", -1);

        my $tr_text = $tr_node->as_text;
        my $span_nodes = &GetNode::GetNode_Tag_Attr("span", "id", "pr5", \$tr_node);

        if(scalar(@$span_nodes) == 0){next;};

        my $mission_name = $$span_nodes[0]->as_text;
        $mission_name =~ s/^＃//;
        $mission_id = $self->{CommonDatas}{MissionName}->GetOrAddId($mission_name);

        if ($tr_text =~ /目的地：(.+)-Lv(\d+)/) {
            $status = 0;
            $col = $1;
            $lv  = $2;
        }

        $status = ($tr_text =~ /☆ Clear ☆/) ?  1 : $status;
        $status = ($tr_text =~ /… Lost …/)  ? -1 : $status;

        $self->{Datas}{Data}->AddData( join(ConstData::SPLIT, ($self->{ResultNo}, $self->{GenerateNo}, $self->{ENo}, $mission_id, $type, $status, $col, $lv)) );

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
