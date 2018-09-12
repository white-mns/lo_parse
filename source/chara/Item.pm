#===================================================================
#        アイテム情報取得パッケージ
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
package Item;

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
                "i_no",
                "name",
                "equip",
                "kind",
                "effect",
                "lv",
                "potency",
                "potency_str",
                "precision",
    ];

    $self->{Datas}{Data}->Init($header_list);
    
    #出力ファイル設定
    $self->{Datas}{Data}->SetOutputName( "./output/chara/item_" . $self->{ResultNo} . "_" . $self->{GenerateNo} . ".csv" );
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

    $self->GetItemData($table_ma_node);
    
    return;
}
#-----------------------------------#
#    アイテムデータ取得
#------------------------------------
#    引数｜アイテムデータノード
#-----------------------------------#
sub GetItemData{
    my $self  = shift;
    my $table_in_node = shift;
    
    # trの抽出
    my $tr_nodes = &GetNode::GetNode_Tag("tr",\$table_in_node);
    shift(@$tr_nodes);
 
    #tdの抜出
    foreach my $tr_node (@$tr_nodes){
        my ($item_no, $name, $equip, $kind, $effect, $lv, $potency, $potency_str, $precision) = (0, "", 0, 0, 0, -1, 0, "", 0);
        my $td_nodes = &GetNode::GetNode_Tag("td",\$tr_node);
        if(scalar(@$td_nodes) < 2){next;};
        
        $item_no = $$td_nodes[0]->as_text;

        my $node1   = $$td_nodes[1]->as_text;
        if($node1 =~ /^【(.+?)】(.+?)$/){
            $equip = $self->{CommonDatas}{ProperName}->GetOrAddId($1);
            $name  = $2;
        }else{
            $name  = $node1;
        }

        $kind    = $self->{CommonDatas}{ProperName}->GetOrAddId($$td_nodes[2]->as_text);

        my $node3   = $$td_nodes[3]->as_text;
        my $effect_text = "";
        if($node3 =~ /(.+?)Lv(\d+?)$/){
            $effect_text = $1;
            $lv     = $2;
        }else{
            $effect_text = $node3;
            $lv     = -1;
        }
        $effect = $self->{CommonDatas}{ProperName}->GetOrAddId($effect_text);

        $potency    = $$td_nodes[4]->as_text eq "-" ? -1 : $$td_nodes[4]->as_text;
        $potency_str= $potency;
        $precision  = $$td_nodes[5]->as_text eq "-" ? -1 : $$td_nodes[5]->as_text;

        my @datas=($self->{ResultNo}, $self->{GenerateNo}, $self->{ENo}, $item_no, $name, $equip, $kind, $effect, $lv, $potency, $potency_str, $precision);
        $self->{Datas}{Data}->AddData(join(ConstData::SPLIT, @datas));

        if ($$td_nodes[2]->as_text =~ /設置/) { #施設名詳細データの取得
            my $right = $tr_node->right;
            if ($right->as_text !~ /（区分：(.+)）/) {next;}

            # 新規登録時に配られたカードだけ施設区分名が違っていたのでデータに登録しない
            my $major_division_text = $1;
            if ($major_division_text =~ /(武器屋|魔器屋|衣服屋|護符屋)/) {next;}

            my $major_division = $self->{CommonDatas}{ProperName}->GetOrAddId($major_division_text);
            $self->{CommonDatas}{FacilityDivisionData}->GetOrAddId(1, [$effect,$major_division]);

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
