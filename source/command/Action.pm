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
    $self->{Datas}{Action}     = StoreData->new();
    $self->{Datas}{ActionRank} = StoreData->new();

    $self->{ActionRank}    = {};
    $self->{ActionRank}{0} = {};
    $self->{ActionRank}{1} = {};

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

    $self->{Datas}{Action}->Init($header_list);
    
    $header_list = [
                "result_no",
                "generate_no",
                "card_id",
                "rank_type",
                "rank",
                "num",
    ];

    $self->{Datas}{ActionRank}->Init($header_list);
    #出力ファイル設定
    $self->{Datas}{Action}->SetOutputName    ( "./output/command/action_"         . $self->{ResultNo} . "_" . $self->{GenerateNo} . ".csv" );
    $self->{Datas}{ActionRank}->SetOutputName( "./output/command/action_ranking_" . $self->{ResultNo} . "_" . $self->{GenerateNo} . ".csv" );
    return;
}

#-----------------------------------#
#    データ取得
#------------------------------------
#    引数｜e_no,対戦設定タイトルノード,対戦設定データノード
#-----------------------------------#
sub GetData{
    my $self    = shift;
    my $e_no    = shift;
    my $span_ch1_node  = shift;
    my $table_ma_nodes = shift;
    
    $self->{ENo} = $e_no;

    if ($self->IsDummyData($span_ch1_node)) {return;}

    if ($self->{ResultNo} == 3) { # Vol.3以前はコマンドページを取得しなかったため、Vol.3はVol.4の前回設定を参照する
        $self->GetActionData($$table_ma_nodes[1]);
    } else {
        $self->GetActionData($$table_ma_nodes[0]);
    }
    
    return;
}

#-----------------------------------#
#    欠番ダミーデータの判定
#------------------------------------
#    引数｜対戦設定タイトルノード
#-----------------------------------#
sub IsDummyData{
    my $self  = shift;
    my $span_ch1_node = shift;

    if (!$span_ch1_node) {return 1;}

    if ($span_ch1_node->as_text =~ /Eno(\d+)：の対戦設定/) {
        return 1;

    } else {
        return 0;
    }
}
 
#-----------------------------------#
#    対戦設定データ取得
#------------------------------------
#    引数｜対戦設定データノード
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
        my $is_count_num = 1;
        my $td_nodes = &GetNode::GetNode_Tag("td",\$tr_node);
        if(scalar(@$td_nodes) < 2){next;};
        
        $act    = $$td_nodes[0]->as_text;

        my $font_nodes = &GetNode::GetNode_Tag("font",\$$td_nodes[1]);
        if(scalar(@$font_nodes) > 0){
            if ($$font_nodes[0]->as_text =~ /Sno(\d+)/) {
                $s_no = $1;
                if (exists $$got_s_no{$s_no}) { $is_count_num = 0;}
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

            if ($is_count_num) {
                $self->AddActionNum($effect, $lv);
            }
        }

        $self->{Datas}{Action}->AddData(join(ConstData::SPLIT, ($self->{ResultNo}, $self->{GenerateNo}, $self->{ENo}, $act, $s_no, $timing, $gowait, $card_id) ));
    }
    return;
}
#-----------------------------------#
#    アイテムデータ取得
#------------------------------------
#    引数｜アイテムデータノード
#-----------------------------------#
sub AddActionNum{
    my $self  = shift;
    my $effect  = shift;
    my $lv      = shift;

    my $card_id     = $self->{CommonDatas}{CardData}->GetOrAddId(0, [$effect, 0, $lv, 0, 0, 0]);
    my $card_lv1_id = $self->{CommonDatas}{CardData}->GetOrAddId(0, [$effect, 0, 1, 0, 0, 0]);

    if (!exists $self->{ActionRank}{0}{$card_id}) {
        $self->{ActionRank}{0}{$card_id} = 0;
    }
    $self->{ActionRank}{0}{$card_id} += 1;
    if (!exists $self->{ActionRank}{1}{$card_lv1_id}) {
        $self->{ActionRank}{1}{$card_lv1_id} = 0;
    }
    $self->{ActionRank}{1}{$card_lv1_id} += 1;

    return;
}
#-----------------------------------#
#    出力
#------------------------------------
#    引数｜
#-----------------------------------#
sub Output{
    my $self = shift;
    
    # 一枚も使われていないカード効果を登録
    my $all_card_id = $self->{CommonDatas}{CardData}->GetAllId();
    foreach my $card_id (@$all_card_id) {
        if (!exists $self->{ActionRank}{0}{$card_id}) {$self->{ActionRank}{0}{$card_id} = 0;}
        if (!exists $self->{ActionRank}{1}{$card_id}) {$self->{ActionRank}{1}{$card_id} = 0;}
    }

    # 取得用ハッシュデータを出力用配列データに変換
    foreach my $type (sort keys(%{$self->{ActionRank}})) {
        my $hash = ${$self->{ActionRank}}{$type};
        my $rank      = 0;
        my $last_num  = 9999;
        my $rank_add  = 1;

        foreach my $card_id (sort {${ $hash }{$b} <=> ${ $hash }{$a} }  keys(%$hash)) {
            my $num = ${$self->{ActionRank}}{$type}{$card_id};
            if ($num < $last_num) {
                $rank += $rank_add;
                $last_num = $num;
                $rank_add = 1;
            } else {
                $rank_add += 1;
            }

            $self->{Datas}{ActionRank}->AddData(join(ConstData::SPLIT, ($self->{ResultNo}, $self->{GenerateNo}, $card_id, $type, $rank, $num)));
        }
    }

    foreach my $object( values %{ $self->{Datas} } ) {
        $object->Output();
    }
    return;
}
1;
