#===================================================================
#        干渉カード成功率情報取得パッケージ
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
package MeddlingSuccessRate;

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
    $self->{Count} = {};
    $self->{Datas}{MeddlingSuccessRate} = StoreData->new();
    $self->{Datas}{MeddlingTarget}      = StoreData->new();

    my $header_list = "";
    
    $header_list = [
                "result_no",
                "generate_no",
                "e_no",
                "card_id",
                "chain",
                "success",
                "miss",
                "no_apply",
                "sum",
                "rate",
    ];

    $self->{Datas}{MeddlingSuccessRate}->Init($header_list);
    
    $header_list = [
                "result_no",
                "generate_no",
                "e_no",
                "card_id",
                "chain",
                "target_id",
                "count",
    ];

    $self->{Datas}{MeddlingTarget}->Init($header_list);
    
    #出力ファイル設定
    $self->{Datas}{MeddlingSuccessRate}->SetOutputName( "./output/battle/meddling_success_rate_" . $self->{ResultNo} . "_" . $self->{GenerateNo} . ".csv" );
    $self->{Datas}{MeddlingTarget}->SetOutputName     ( "./output/battle/meddling_target_"       . $self->{ResultNo} . "_" . $self->{GenerateNo} . ".csv" );
    
    return;
}

#-----------------------------------#
#    データ取得
#------------------------------------
#    引数｜e_no,名前データノード
#-----------------------------------#
sub GetData{
    my $self = shift;
    my $battle_page = shift;
    my $font_player_nodes = shift; 
    my $font_enemy_nodes  = shift; 
    my $link_nodes        = shift; 
    my $table_345_nodes   = shift; 
    
    $self->{NicknameToEno} = {};
    $self->{Pno} = {};

    $self->{BattlePage} = $battle_page;
    $self->{BattlePage} =~ s/-/ VS /;
    
    # 愛称とEnoの紐付け処理
    $self->LinkingNicknameToEno($link_nodes, $table_345_nodes);

    $self->GetMeddlingSuccessRateData($font_player_nodes);
    $self->GetMeddlingSuccessRateData($font_enemy_nodes);
    
    return;
}

#-----------------------------------#
#    愛称-Eno紐付け
#------------------------------------
#    引数｜リンクノード
#    　　｜テーブルノード
#-----------------------------------#
sub LinkingNicknameToEno{
    my $self  = shift;
    my $link_nodes      = shift; 
    my $table_345_nodes = shift;

    my @exist_e_no_list = ();
    my $i = 10000;

    foreach my $node (@$link_nodes) {
        my $text = $node->as_text;
        $i--;
        
        if ($i < 0) {last;}
        if ($text !~ /\(Pn(\d+)\)/) {next;}

        # 戦闘開始時のキャラクターリンクが見つかったとき、そこから最大10人分のEnoを取得する
        if ($i > 10) {$i = 10;}

        $node->attr("href") =~ /Eno(\d+)\.html/;
        my $e_no = $1;

        push(@exist_e_no_list, $e_no);
    }
    
    my $player_nicknames = &GetNode::GetNode_Tag_Attr("font", "color", "#6633ff", \$$table_345_nodes[0]);
    my $enemy_nicknames  = &GetNode::GetNode_Tag_Attr("font", "color", "#996600", \$$table_345_nodes[1]);

    # ターン毎キャラリストテーブルにある愛称に、取得した戦闘参加者Enoを順番に割り当てていく
    my $p_no = "";
    foreach my $nickname_node (@$player_nicknames) {
        my $nickname_text = $nickname_node->as_text;
        $nickname_text =~ /(.+\(Pn\d+\))/;
        my $nickname = $1;
        
        $nickname_text =~ /\(Pn(\d+)\)/;
        $p_no = $1;
        
        $self->{NicknameToEno}{$nickname} = shift(@exist_e_no_list);
    }
    $self->{Pno}{Player} = $p_no;

    foreach my $nickname_node (@$enemy_nicknames) {
        my $nickname_text = $nickname_node->as_text;
        $nickname_text =~ /(.+\(Pn\d+\))/;
        my $nickname = $1;
        
        $nickname_text =~ /\(Pn(\d+)\)/;
        $p_no = $1;
        
        $self->{NicknameToEno}{$nickname} = shift(@exist_e_no_list);
    }
    $self->{Pno}{Enemy} = $p_no;

    return;
}

#-----------------------------------#
#    成功率データ取得
#------------------------------------
#    引数｜Pno
#           データノード
#-----------------------------------#
sub GetMeddlingSuccessRateData{
    my $self      = shift;
    my $nodes     = shift; 

    foreach my $node (@$nodes) {
        my $e_no = -1;
        my $text = $node->as_text;

        if ($text !~ /復活|発動|待機|動静|白紙|低下|上昇|廃棄|効率|確変|伝達|沈着|発揮|素朴|追憶|転化|着実|沈黙/) {next;}
        if ($text !~ /！/) {next;}
        if ($text !~ /Lv(\d+)/) {next;}
        my $lv = $1;

        { # Enoの取得
            my $text = "";

            my $dd_node = $node->parent;
            if ($dd_node->tag ne "dd") {$dd_node = $dd_node->parent;}
            if ($dd_node->tag ne "dd") {next;}
            while ($dd_node) {
                my $dd_text = $dd_node->as_text;
                if ($dd_text !~ /Action|が後に続く|が発動|が先導する/ || $dd_text =~ /の効果が発動/ ) {
                    $dd_node = $dd_node->left;
                    next;
                }

                if ($dd_text =~ /(.+\(Pn\d+\))/) {
                    $text = $1;
                    $e_no = $self->{NicknameToEno}{$1};
                    last;
                }

                if ($dd_node->tag eq "dt") {last;}
                $dd_node = $dd_node->left;
            }
        }

        $text =~ s/！//;
        $text =~ s/\s//g;

        my $chain_effect_name = $text;
        if ($chain_effect_name =~ /：/) {
            my @chain_effect_name_split = split(/：/, $chain_effect_name);
            $chain_effect_name = $chain_effect_name_split[1] . "：" . $chain_effect_name_split[0];
        }
        my $chain_num = 0;
        if ($text =~ /Chain(\d+)：/) {
            $chain_num = $1;
        }
        $text =~ s/Chain(\d+)：//;

        my $effect_name =  "/" . $text; # 全Chain集計用に、通常の先発発動と混ざらないよう接頭詞を付けておく
        if (!${ $self->{Count} }{"0"}) {
            ${ $self->{Count} }{"0"} = {};
        }
        if (!${ $self->{Count} }{$e_no}) {
            ${ $self->{Count} }{$e_no} = {};
        }

        if (!${ $self->{Count} }{"0"}{$effect_name}) {
            ${ $self->{Count} }{"0"}{$effect_name} = [0, -1, 0, 0, 0, {}];
        }
        if (!${ $self->{Count} }{"0"}{$chain_effect_name}) {
            ${ $self->{Count} }{"0"}{$chain_effect_name} = [0, 0, 0, 0, 0, {}];
        }
        if (!${ $self->{Count} }{$e_no}{$effect_name}) {
            ${ $self->{Count} }{$e_no}{$effect_name} = [0, -1, 0, 0, 0, {}];
        }
        if (!${ $self->{Count} }{$e_no}{$chain_effect_name}) {
            ${ $self->{Count} }{$e_no}{$chain_effect_name} = [0, 0, 0, 0, 0, {}];
        }

        my $card_id = 0;
        if ($text =~ /(.+)Lv(\d+)/) {
            my $effect = $1;
            my $lv     = $2;
            $card_id   = $self->{CommonDatas}{CardData}->GetOrAddId(0, [$effect,"", $lv, 0, 0, 0]);
        }

        ${${ $self->{Count} }{"0"}{$effect_name}}[0]       = $card_id;
        ${${ $self->{Count} }{$e_no}{$effect_name}}[0]        = $card_id;
        ${${ $self->{Count} }{"0"}{$chain_effect_name}}[0] = $card_id;
        ${${ $self->{Count} }{$e_no}{$chain_effect_name}}[0]  = $card_id;
        ${${ $self->{Count} }{"0"}{$chain_effect_name}}[1] = $chain_num;
        ${${ $self->{Count} }{$e_no}{$chain_effect_name}}[1]  = $chain_num;

        my $dd_node = $node->parent;
        if ($dd_node->tag ne "dd") {$dd_node = $dd_node->parent;}
        if ($dd_node->tag ne "dd") {next;}
        $dd_node = $dd_node->right;
        while($dd_node) {
            my $dd_text = $dd_node->as_text;
            if ($dd_text =~ /強制復活|設定に変換|Blankカードへ強制変換|レベルアップ！！|レベルダウン！|強制廃棄|発動率が変動/) {
                ${${ $self->{Count} }{"0"}{$effect_name}}[2]++;
                ${${ $self->{Count} }{"0"}{$chain_effect_name}}[2]++;
                ${${ $self->{Count} }{$e_no}{$effect_name}}[2]++;
                ${${ $self->{Count} }{$e_no}{$chain_effect_name}}[2]++;
                my $font_node_player = &GetNode::GetNode_Tag_Color_NoSize("font", "#009999", \$dd_node);
                my $font_node_enemy = &GetNode::GetNode_Tag_Color_NoSize("font", "#666600", \$dd_node);
                my $target_name = "";
                if (scalar(@$font_node_player)) {
                    $target_name = $$font_node_player[0]->as_text;
                }elsif (scalar(@$font_node_enemy)) {
                    $target_name = $$font_node_enemy[0]->as_text;
                }
                $target_name =~ s/Act(\d+)：//;
                # 対象カードと干渉回数を記録
                if ($target_name =~ /(.+)Lv(\d+)/) {
                    my $target_effect = $1;
                    my $target_lv     = $2;
                    my $target_id     = $self->{CommonDatas}{CardData}->GetOrAddId(0, [$target_effect,"", $target_lv, 0, 0, 0]);

                    if (!${${ $self->{Count} }{"0"}{$effect_name}}[5]{$target_id}      ) {${${ $self->{Count} }{"0"}{$effect_name}}[5]{$target_id}       = 0;}
                    if (!${${ $self->{Count} }{"0"}{$chain_effect_name}}[5]{$target_id}) {${${ $self->{Count} }{"0"}{$chain_effect_name}}[5]{$target_id} = 0;}
                    if (!${${ $self->{Count} }{$e_no}{$effect_name}}[5]{$target_id}       ) {${${ $self->{Count} }{$e_no}{$effect_name}}[5]{$target_id}        = 0;}
                    if (!${${ $self->{Count} }{$e_no}{$chain_effect_name}}[5]{$target_id} ) {${${ $self->{Count} }{$e_no}{$chain_effect_name}}[5]{$target_id}  = 0;}

                    ${${ $self->{Count} }{"0"}{$effect_name}}[5]{$target_id}       += 1;
                    ${${ $self->{Count} }{"0"}{$chain_effect_name}}[5]{$target_id} += 1;
                    ${${ $self->{Count} }{$e_no}{$effect_name}}[5]{$target_id}        += 1;
                    ${${ $self->{Count} }{$e_no}{$chain_effect_name}}[5]{$target_id}  += 1;
                }

            }elsif ($dd_text =~ /寸前で回避|失敗/) {
                ${${ $self->{Count} }{"0"}{$effect_name}}[3]       += 1;
                ${${ $self->{Count} }{"0"}{$chain_effect_name}}[3] += 1;
                ${${ $self->{Count} }{$e_no}{$effect_name}}[3]        += 1;
                ${${ $self->{Count} }{$e_no}{$chain_effect_name}}[3]  += 1;

            }elsif ($dd_text =~ /適応できるものはなかった|効果範囲に入ったものはなかった|上限に達している|効果が無かった/) {
                ${${ $self->{Count} }{"0"}{$effect_name}}[4]       += 1;
                ${${ $self->{Count} }{"0"}{$chain_effect_name}}[4] += 1;
                ${${ $self->{Count} }{$e_no}{$effect_name}}[4]        += 1;
                ${${ $self->{Count} }{$e_no}{$chain_effect_name}}[4]  += 1;

            }elsif ($dd_text =~ /Blankカードに変換/) {
            }elsif ($dd_text =~ /罠が発動/) {
                last;
            }elsif ($dd_text =~ /「|\(Pn/) {
            }
            else{last;}
            $dd_node = $dd_node->right;
        }
    }
    return;
}

#-----------------------------------#
#    出力
#------------------------------------
#    引数｜ファイルアドレス
#-----------------------------------#
sub Output(){
    my $self = shift;
    foreach my $e_no (sort{$a <=> $b} keys(%{$self->{Count}})) {
        foreach my $effect_name (sort keys(%{${ $self->{Count} }{$e_no}})) {
            my $data = ${ $self->{Count} }{$e_no}{$effect_name};
            my $cards = join(",",);

            my $use_all   = $$data[2] + $$data[3] + $$data[4];
            my $count_all = $$data[2] + $$data[3];
            my $success_rate = -1;
            my $sum = $count_all;
            $success_rate = $count_all > 0 ? $$data[2] / ($count_all) : 0;

            $self->{Datas}{MeddlingSuccessRate}->AddData(join(ConstData::SPLIT, ($self->{ResultNo}, $self->{GenerateNo}, $e_no, $$data[0], $$data[1], $$data[2], $$data[3], $$data[4], $sum, $success_rate)));
            
            foreach my $target_id (sort{$a <=> $b} keys(%{$$data[5]})) {
                my $count = ${$$data[5]}{$target_id};
                $self->{Datas}{MeddlingTarget}->AddData(join(ConstData::SPLIT, ($self->{ResultNo}, $self->{GenerateNo}, $e_no, $$data[0], $$data[1], $target_id, $count)));

            }
        }
    }
    foreach my $object( values %{ $self->{Datas} } ) {
        $object->Output();
    }
    return;
}
1;
