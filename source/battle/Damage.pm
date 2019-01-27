#===================================================================
#        ダメージ・回復量成功率情報取得パッケージ
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
package Damage;

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
    $self->{Datas}{DamageRate}   = StoreData->new();
    $self->{Datas}{Damage}       = StoreData->new();
    $self->{Datas}{DamageBuffer} = StoreData->new();

    my $header_list = "";
    $header_list = [
                "result_no",
                "generate_no",
                "battle_page",
                "act_id",
                "e_no",
                "turn",
                "party",
                "party_num",
                "line",
                "card_id",
                "chain",
                "target_e_no",
                "target_party",
                "target_party_num",
                "target_line",
                "act_type",
                "element",
                "damage",
                "is_weak",
                "is_critical",
                "is_clean",
                "is_vanish",
                "is_absorb",
    ];
    $self->{Datas}{Damage}->Init($header_list);
    
    $header_list = [
                "result_no",
                "generate_no",
                "battle_page",
                "act_id",
                "e_no",
                "buffer_id",
                "lv",
                "value",
    ];
    $self->{Datas}{DamageBuffer}->Init($header_list);
    
    #出力ファイル設定
    $self->{Datas}{Damage}->SetOutputName       ( "./output/battle/damage_"        . $self->{ResultNo} . "_" . $self->{GenerateNo} . ".csv" );
    $self->{Datas}{DamageBuffer}->SetOutputName ( "./output/battle/damage_buffer_" . $self->{ResultNo} . "_" . $self->{GenerateNo} . ".csv" );
    
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
    my $div_heading_nodes = shift; 
    my $link_nodes        = shift; 
    my $table_345_nodes   = shift; 
    my $table_698_nodes   = shift; 
    
    $self->{NicknameToEno}  = {};
    $self->{NicknameToPno}  = {};
    $self->{NicknameToLine} = {};
    $self->{PartyNameToPno}  = {};
    $self->{Pno} = {};
    $self->{PartyNum} = {};
    $self->{ActId} = 0;

    $self->{BattlePage} = $battle_page;
    $self->{BattlePage} =~ s/-/ VS /;
    
    # 愛称とEnoの紐付け処理
    $self->LinkingNicknameToEno($link_nodes, $table_345_nodes);
    $self->LinkingPartyNameToPno($table_345_nodes, $table_698_nodes);

    $self->ReadHeadingData($div_heading_nodes);
    
    return;
}

#-----------------------------------#
#    パーティ名-Pno紐付け
#------------------------------------
#    引数｜テーブルノード
#-----------------------------------#
sub LinkingPartyNameToPno{
    my $self  = shift;
    my $table_345_nodes = shift;
    my $table_698_nodes = shift;

    my $player_party_name_node = &GetNode::GetNode_Tag_Attr("td", "align", "left",  \$$table_698_nodes[0]);
    my $enemy_party_name_node  = &GetNode::GetNode_Tag_Attr("td", "align", "right", \$$table_698_nodes[0]);
    my $player_party_name_i_node = &GetNode::GetNode_Tag("i",  \$$player_party_name_node[0]);
    my $enemy_party_name_i_node  = &GetNode::GetNode_Tag("i",  \$$enemy_party_name_node[0]);
    my $player_party_name = $$player_party_name_i_node[0]->as_text;
    my $enemy_party_name  = $$enemy_party_name_i_node[0]->as_text;

    my $player_nicknames = &GetNode::GetNode_Tag_Attr("font", "color", "#6633ff", \$$table_345_nodes[0]);
    my $enemy_nicknames  = &GetNode::GetNode_Tag_Attr("font", "color", "#996600", \$$table_345_nodes[1]);

    # ターン毎キャラリストテーブルにある愛称に、取得した戦闘参加者Enoを順番に割り当てていく
    my $p_no = 0;
    foreach my $nickname_node (@$player_nicknames) {
        if ($nickname_node->as_text =~ /\(Pn(\d+)\)/) {
            $p_no = $1;
        }
    }
    $self->{PartyNameToPno}{$player_party_name} = $p_no;

    $p_no = 0;
    foreach my $nickname_node (@$enemy_nicknames) {
        if ($nickname_node->as_text =~ /\(Pn(\d+)\)/) {
            $p_no = $1;
        }
        
    }
    $self->{PartyNameToPno}{$enemy_party_name} = $p_no;

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
        $self->{NicknameToPno}{$nickname} = $p_no;
    }
    $self->{Pno}{Player} = $p_no;

    foreach my $nickname_node (@$enemy_nicknames) {
        my $nickname_text = $nickname_node->as_text;
        $nickname_text =~ /(.+\(Pn\d+\))/;
        my $nickname = $1;
        
        $nickname_text =~ /\(Pn(\d+)\)/;
        $p_no = $1;
        
        $self->{NicknameToEno}{$nickname} = shift(@exist_e_no_list);
        $self->{NicknameToPno}{$nickname} = $p_no;
    }
    $self->{Pno}{Enemy} = $p_no;

    return;
}

#-----------------------------------#
#    ダメージ・回復取得
#------------------------------------
#    引数｜Pno
#          対象Pno
#          データノード
#-----------------------------------#
sub ReadHeadingData{
    my $self  = shift;
    my $nodes = shift; 

    foreach my $node (@$nodes) {
        if ($node->as_text =~ /Turn (\d+)/) {
            my $turn = $1;
            my @right_nodes = $node->right;
            foreach my $right_node (@right_nodes) {
                if ($right_node =~ /HASH/ && $right_node->tag eq "div" && $right_node->attr("class") eq "heading") {last;}

                if ($right_node =~ /HASH/ && $right_node->tag eq "center") {
                    $self->ReadTableNode($right_node);

                } elsif ($right_node =~ /HASH/ && $right_node->tag eq "dl") {
                    $self->ReadTurnDlNode($turn, $right_node);
                }
            }
        }
    }
}

#-----------------------------------#
#    戦闘内容取得
#------------------------------------
#    引数｜参戦キャラ一覧ノード
#-----------------------------------#
sub ReadTableNode{
    my $self     = shift;
    my $center_node = shift;

    $self->{PartyNum} = {};

    my %lines = ("前"=>0,"中"=>1,"後"=>2);
    my $nodes = &GetNode::GetNode_Tag("td", \$center_node);

    foreach my $node (@$nodes) {
        my $in_table_nodes = &GetNode::GetNode_Tag("table", \$node);
        if (scalar(@$in_table_nodes)) {next;} #参戦キャラ一覧テーブルは入れ子構造になっており、親テーブルのtdの場合は処理をしない

        if ($node->as_text =~ /^(.+?)：(.+?\(Pn(\d+)\))/) {
            $self->{NicknameToLine}{$2} = $lines{$1};

            if (!exists($self->{PartyNum}{$3})) {
                $self->{PartyNum}{$3}  = 1;
            } else {
                $self->{PartyNum}{$3} += 1;
            }
           
        }
    }
}

#-----------------------------------#
#    戦闘内容取得
#------------------------------------
#    引数｜ターン
#          戦闘内容ノード
#-----------------------------------#
sub ReadTurnDlNode{
    my $self     = shift;
    my $turn     = shift; 
    my $dl_node = shift;

    my @nodes = $dl_node->content_list;

    my $nickname = "";
    my $trigger_node = "";
    my $element = 0;
    my $buffers = {};
    my $card    = {"name"=>"通常攻撃", "id"=>$self->{CommonDatas}{CardData}->GetOrAddId(0, ["通常攻撃", 0, 0, 0, 0, 0]), "chain"=>0};

    $self->ResetAbnormalData(\$buffers);
    $self->ResetPreDamageData(\$buffers);

    foreach my $node (@nodes) {
        if ($node =~ /HASH/ && $node->tag eq "dl") {
            # 表示上のBUGで戦闘内容が入れ子になった時、再帰的に実行し、現在の深さにあるその後の要素は解析しない
            $self->ReadTurnDlNode($turn, $node);
            last;
        }
        
        $self->GetFieldData($node, \$buffers);
        $self->GetChainPowerData($node, \$buffers);
        
        if ($node->as_text =~ /により/) {next;}

        if ($self->GetTriggerData($node, \$nickname, \$card, \$buffers, \$trigger_node)) {
            $self->ResetPreDamageData(\$buffers);
            $self->ResetChainPowerData(\$buffers);
            $self->ResetElementData(\$element);
            $self->ResetFieldData(\$buffers);
            $self->ResetFPDamageType(\$buffers);
            #print $node->as_text." | $nickname,".$self->{NicknameToEno}{$nickname}."\n";
            #foreach my $name (keys %$buffers) {
            #    print $name.",".$$buffers{$name}{"id"}.",".$$buffers{$name}{"lv"}.",".$$buffers{$name}{"number"}."\n";
            #}
            #print $$card{"name"}.",".$$card{"id"}.",".$$card{"chain"}."\n";
        }

        $self->GetCardData($node, \$card);
        $self->GetCounterData($turn, $node);
        $self->GetPreDamageData($node, \$buffers);
        $self->GetElementData($node, \$element);
        $self->GetDesorptionData($node);
        $self->GetLineCloseData($node);
        
        if ($self->GetDamageData($turn, $node, $nickname, $card, $buffers, $trigger_node, $element)) {
            $self->ResetFPDamageType(\$buffers);
            if (!($$card{"name"} =~ /侵食|吸魔/ && $node->as_text =~ /FPに\d+のダメージ！/ && $node->right->as_text =~ /LPに\d+のダメージ！/)) {
                $self->ResetPreDamageData(\$buffers);
                $self->ResetChainPowerData(\$buffers);
                $self->ResetElementData(\$element);
                $self->ResetFieldData(\$buffers);
            }
        }
        if ($self->GetBlockData($node)) {
            $self->ResetPreDamageData(\$buffers);
            $self->ResetChainPowerData(\$buffers);
            $self->ResetElementData(\$element);
            $self->ResetFieldData(\$buffers);
            $self->ResetFPDamageType(\$buffers);
        }
        if ($self->GetAttaccaData($node, \$nickname, \$card, \$buffers, \$trigger_node)) {
            $self->ResetPreDamageData(\$buffers);
            $self->ResetChainPowerData(\$buffers);
            $self->ResetElementData(\$element);
            $self->ResetFieldData(\$buffers);
            $self->ResetFPDamageType(\$buffers);
        }
    }
}

#-----------------------------------#
#    カウンター内容取得
#------------------------------------
#    引数｜ターン数
#          カウンター起点ノード
#          発動者愛称
#          カード情報
#          発動ノード
#-----------------------------------#
sub ReadCounterDlNode{
    my $self     = shift;
    my $turn     = shift; 
    my $counter_node = shift;
    my $nickname     = shift;
    my $card         = shift;
    my $trigger_node = shift;

    my $buffers = {};
    my $element = 0;

    my @nodes = $counter_node->right;

    $self->ResetAbnormalData(\$buffers);
    $self->ResetPreDamageData(\$buffers);

    foreach my $node (@nodes) {
        if ($node =~ /HASH/ && $node->tag eq "dl") {
            last;
        }
        
        $self->GetFieldData($node, \$buffers);

        if ($node->as_text =~ /により/) {next;}

        $self->GetElementData($node, \$element);
        $self->GetPreDamageData($node, \$buffers);

        if ($self->GetDamageData($turn, $node, $nickname, $card, $buffers, $trigger_node, $element)) {
            last;
        }

    }
}

#-----------------------------------#
#    ダメージ・回復取得
#------------------------------------
#    引数｜ターン数
#          対象ノード
#          発動者愛称
#          カード情報
#          バフデバフ情報
#          発動ノード
#-----------------------------------#
sub GetDamageData{
    my $self         = shift;
    my $turn         = shift;
    my $node         = shift;
    my $nickname     = shift;
    my $card         = shift;
    my $buffers      = shift;
    my $trigger_node = shift;
    my $element      = shift;
   
    my ($act_type, $damage) = (0, 0);

    my $text = $node->as_text;

    if ($text !~ /のダメージ|回復♪|寸前で回避/) {return 0;}

    my $font_node_player = &GetNode::GetNode_Tag_Color_NoSize("font", "#6633ff", \$node);
    my $font_node_enemy  = &GetNode::GetNode_Tag_Color_NoSize("font", "#996600", \$node);
    my $target_node = "";

    if    (scalar(@$font_node_player)) { $target_node = $$font_node_player[0];}
    elsif (scalar(@$font_node_enemy))  { $target_node = $$font_node_enemy[0]; }

    if (!$target_node) {return 0;}

    if ($target_node->attr("color") ne $trigger_node->attr("color")) { # カウンタなどの反撃処理を除外
        return 0;
    }

    my $target_text = $target_node->as_text;

    if ($target_text =~ /(.+\(Pn\d+\))/) {
        my $target_nickname = $1;
    
        my $damage_node = &GetNode::GetNode_Tag("font", \$target_node);

        if (scalar(@$damage_node) > 1 && $$damage_node[1] =~ /HASH/) {
            $damage = $$damage_node[1]->as_text;
        }

        if ($damage =~ /^\d+$/ || $target_text =~ /寸前で回避/) {
            if ($target_text =~ /寸前で回避/) {$damage = -1}

            if    ($target_text =~ /FPに\d+のダメージ！/) { $act_type = $self->{CommonDatas}{ProperName}->GetOrAddId("FPダメージ");}
            elsif ($target_text =~ /LPが\d+回復/)         { $act_type = $self->{CommonDatas}{ProperName}->GetOrAddId("LP回復");}
            elsif ($target_text =~ /FPが\d+回復/)         { $act_type = $self->{CommonDatas}{ProperName}->GetOrAddId("FP回復");}
            else                                          { $act_type = $self->{CommonDatas}{ProperName}->GetOrAddId("ダメージ");}
            if ($target_text =~ /寸前で回避/) {
                if ($$card{"name"} =~ /侵食|吸魔/) {
                    $act_type = $self->{CommonDatas}{ProperName}->GetOrAddId("FPダメージ");
                } else {
                    $act_type = $self->{CommonDatas}{ProperName}->GetOrAddId("ダメージ");
                }
            }
            if ($$card{"name"} =~ /侵食|吸魔/) {
                $self->GetFPDamageType($node, \$buffers);
            }

            my $p_no = $self->{NicknameToPno}{$nickname};
            my $target_p_no = $self->{NicknameToPno}{$target_nickname};

            $self->{Datas}{Damage}->AddData(join(ConstData::SPLIT, ($self->{ResultNo}, $self->{GenerateNo}, $self->{BattlePage}, $self->{ActId},
                        $self->{NicknameToEno}{$nickname}, $turn, $p_no, $self->{PartyNum}{$p_no}, $self->{NicknameToLine}{$nickname}, $$card{"id"}, $$card{"chain"},
                        $self->{NicknameToEno}{$target_nickname}, $target_p_no, $self->{PartyNum}{$target_p_no}, $self->{NicknameToLine}{$target_nickname},
                        $act_type, $element, $damage, -1, -1, -1, -1, -1)));
            foreach my $key (keys %$buffers) {
                $self->{Datas}{DamageBuffer}->AddData(join(ConstData::SPLIT, ($self->{ResultNo}, $self->{GenerateNo}, $self->{BattlePage}, $self->{ActId},
                            $self->{NicknameToEno}{$nickname}, $$buffers{$key}{"id"}, $$buffers{$key}{"lv"}, $$buffers{$key}{"number"})));
            }
            $self->{ActId} = $self->{ActId} + 1;

            return 1;
        }
    }
}

#-----------------------------------#
#    FPダメージ種別取得
#------------------------------------
#    引数｜発動ノード
#          バフデバフ情報
#-----------------------------------#
sub GetFPDamageType{
    my $self         = shift;
    my $node         = shift;
    my $buffers      = shift;

    if ($node->as_text =~ /FPに(\d+)のダメージ！/) {
        my $fp_damage = $1;
        my $type = "";

        if ($node->right->as_text !~ /LPに\d+のダメージ！/){
            $type = "完全FP";

        } else {
            if ($fp_damage == 0) { return 0;}
            $type = "混合LPFP";
        }

        if (exists($$$buffers{$type})) {
            $$$buffers{$type}{"number"} = 1;

        } else {
            $$$buffers{$type} = {"id"=>$self->{CommonDatas}{ProperName}->GetOrAddId($type), "lv"=>0, "number"=>1};
        }
        
        return 1;

    } elsif ($node->as_text =~ /LPに\d+のダメージ！/) {
        if ($node->left->as_text =~ /FPに(\d+)のダメージ！/){
            my $type = "";
            $type = ($1 == 0) ? "完全LP" : "混合LPFP";

            if (exists($$$buffers{$type})) {
                $$$buffers{$type}{"number"} = 1;

            } else {
                $$$buffers{$type} = {"id"=>$self->{CommonDatas}{ProperName}->GetOrAddId($type), "lv"=>0, "number"=>1};
            }
        }
        return 1;

    } else {
        return 0;
    }
}

#-----------------------------------#
#    クリティカル等取得
#------------------------------------
#    引数｜発動ノード
#          バフデバフ情報
#-----------------------------------#
sub GetPreDamageData{
    my $self         = shift;
    my $node         = shift;
    my $buffers      = shift;

    if ($node->as_text =~ /Weak|Critical|Clean Hit|Vanish|Absorb|Revenge|Time Penalty|To the Fallen/) {
        my $attack_node = &GetNode::GetNode_Tag_Attr("font", "color", "#ff3333", \$node);
        my $block_node  = &GetNode::GetNode_Tag_Attr("font", "color", "#009966", \$node);

        my $text = "";
        if    (scalar(@$attack_node)) { $text = $$attack_node[0]->as_text}
        elsif (scalar(@$block_node))  { $text = $$block_node[0]->as_text}

        if ($text =~ /(^WeakPoint|^Critical|^Clean Hit|^Vanish|^Absorb|^Revenge|^Time Penalty|^To the Fallen)/) {
            if (exists($$$buffers{$1})) {
                $$$buffers{$1}{"number"} += 1;

            } else {
                $$$buffers{$1} = {"id"=>$self->{CommonDatas}{ProperName}->GetOrAddId($1), "lv"=>0, "number"=>1};
            }
        }
        return 1;
    } else {
        return 0;
    }
}

#-----------------------------------#
#    発動者取得
#------------------------------------
#    引数｜発動ノード
#          発動者愛称
#          カード情報
#          バフデバフ情報
#          発動ノード
#-----------------------------------#
sub GetTriggerData{
    my $self         = shift;
    my $node         = shift;
    my $nickname     = shift;
    my $card         = shift;
    my $buffers      = shift;
    my $trigger_node = shift;
    
    my $text = $node->as_text;

    if ($text !~ /Action|が後に続く|が発動|が先導する/) {return 0;}
    
    if ($text !~ /(.+\(Pn\d+\))/) {return 0;}
    $$nickname = $1;

    $$card    = {"name"=>"通常攻撃", "id"=>$self->{CommonDatas}{CardData}->GetOrAddId(0, ["通常攻撃", 0, 0, 0, 0, 0]), "chain"=>0};
    $$buffers = {};
    $self->ResetAbnormalData(\$$buffers);

    my $tmp_node = &GetNode::GetNode_Tag("font", \$node);
    $$trigger_node = $$tmp_node[0];

    if (my @buffer_texts = $text =~ /【(.+?)】/g) {
        foreach my $buffer_text (@buffer_texts) {
            if ($buffer_text =~ /(.+)Lv(\d+)（(\d+)）/) {
                $$$buffers{$1} = {"id"=>$self->{CommonDatas}{ProperName}->GetOrAddId($1), "lv"=>$2, "number"=>$3};
            }
        }
    }

    return 1;
}

#-----------------------------------#
#    カード情報取得
#------------------------------------
#    引数｜発動ノード
#          カード情報
#-----------------------------------#
sub GetCardData{
    my $self = shift;
    my $node = shift;
    my $card = shift;
    
    my $font_nodes = "";
    $font_nodes = &GetNode::GetNode_Tag_Attr("font", "color", "#009999", \$node);
    if (!scalar(@$font_nodes)) {
        $font_nodes  = &GetNode::GetNode_Tag_Attr("font", "color", "#666600", \$node);
    }

    if (!scalar(@$font_nodes)) { return 0;}

    my $text = $$font_nodes[0]->as_text;

    if ($text !~ /Lv(\d+)！/) {return 0;}
    my $lv = $1;

    $text =~ s/！//;
    $text =~ s/\s//g;

    my $chain_num = 0;
    if ($text =~ s/Chain(\d+)：//) {
        $chain_num = $1;
    }

    # カード名の解析
    my $effect_name = $text;

    my $card_id = 0;
    if ($text =~ /(.+)Lv(\d+)/) {
        my $effect = $1;
        my $lv     = $2;
        $card_id   = $self->{CommonDatas}{CardData}->GetOrAddId(0, [$effect, 0, $lv, 0, 0, 0]);
        $$card     = {"name"=>$effect_name, "id"=>$card_id, "chain"=>$chain_num};
    }

    return 1;
}

#-----------------------------------#
#    反撃、カウンタ発動時にカード情報を上書き
#------------------------------------
#    引数｜ターン数
#          対象ノード
#-----------------------------------#
sub GetCounterData{
    my $self         = shift;
    my $turn         = shift;
    my $node         = shift;

    my $nickname     = "";
    my $card         = {};
    my $trigger_node = "";

    my $lv = 0;

    my $font_nodes = &GetNode::GetNode_Tag_Attr("font", "color", "#00cccc", \$node);
    my $counter_font_nodes = &GetNode::GetNode_Tag_Attr("font", "color", "#ff3333", \$node);

    if (scalar(@$font_nodes)) {

        my $text = $$font_nodes[0]->as_text;

        if ($text !~ /カウンタ/)  {return 0;}
        if ($text !~ /Lv(\d+)！/) {return 0;}
        my $lv = $1;

        if ($node->as_text !~ /(.+\(Pn\d+\))/) {return 0;}
        $nickname = $1;

        $text =~ s/！//;
        $text =~ s/\s//g;

        my $chain_num = 0;

        # カード名の解析
        my $effect_name = $text;

        my $card_id = 0;
        if ($text =~ /(.+)Lv(\d+)/) {
            my $effect = $1;
            my $lv     = $2;
            $card_id   = $self->{CommonDatas}{CardData}->GetOrAddId(0, [$effect, 0, $lv, 0, 0, 0]);
            $card     = {"name"=>$effect, "id"=>$card_id, "chain"=>$chain_num};
        }
        my $tmp_node = &GetNode::GetNode_Tag("font", \$node);
        $trigger_node = $$tmp_node[0];

    } elsif (scalar(@$counter_font_nodes) && $$counter_font_nodes[0]->as_text eq "Counter！！") {
        my $left_text = $node->left->as_text;
        if ($left_text !~ /(.+\(Pn\d+\))/) {return 0;}
        $nickname = $1;

        my $tmp_node = &GetNode::GetNode_Tag("font", \$node->right);
        $trigger_node = $$tmp_node[0];

        $card    = {"name"=>"反撃", "id"=>$self->{CommonDatas}{CardData}->GetOrAddId(0, ["反撃", 0, 0, 0, 0, 0]), "chain"=>0};

    } else {
        return 0;
    }

    $self->ReadCounterDlNode($turn, $node, $nickname, $card, $trigger_node);

    return 1;
}

#-----------------------------------#
#    アタッカ発動時にカード情報を上書き
#------------------------------------
#    引数｜対象ノード
#          発動者愛称
#          カード情報
#          バフデバフ情報
#          発動ノード
#-----------------------------------#
sub GetAttaccaData{
    my $self         = shift;
    my $node         = shift;
    my $nickname     = shift;
    my $card         = shift;
    my $buffers      = shift;
    my $trigger_node = shift;

    if ($$$card{"name"} ne "通常攻撃" && $$$card{"name"} !~ /アタッカ/) {return;}

    my $font_nodes = "";
    $font_nodes = &GetNode::GetNode_Tag_Attr("font", "color", "#00cccc", \$node);

    if (!scalar(@$font_nodes)) { return 0;}

    my $text = $$font_nodes[0]->as_text;

    if ($text !~ /アタッカ/)  {return 0;}
    if ($text !~ /Lv(\d+)！/) {return 0;}
    my $lv = $1;

    if ($node->as_text !~ /(.+\(Pn\d+\))/) {return 0;}
    $$nickname = $1;

    $text =~ s/！//;
    $text =~ s/\s//g;

    my $chain_num = 0;

    # カード名の解析
    my $effect_name = $text;

    my $card_id = 0;
    if ($text =~ /(.+)Lv(\d+)/) {
        my $effect = $1;
        my $lv     = $2;
        $card_id   = $self->{CommonDatas}{CardData}->GetOrAddId(0, [$effect, 0, $lv, 0, 0, 0]);
        $$card     = {"name"=>$effect, "id"=>$card_id, "chain"=>$chain_num};
    }

    my $tmp_node = &GetNode::GetNode_Tag("font", \$node);
    $$trigger_node = $$tmp_node[0];

    return 1;
}

#-----------------------------------#
#    隊列が詰められた情報を取得
#------------------------------------
#    引数｜対象ノード
#-----------------------------------#
sub GetLineCloseData{
    my $self         = shift;
    my $node         = shift;

    if ($node->as_text !~ /隊列が詰められた！/) {return 0;}

    my $i_nodes = "";
    $i_nodes = &GetNode::GetNode_Tag("i", \$node);

    if (!scalar(@$i_nodes)) { return 0;}

    if ($$i_nodes[0]->as_text =~ /(.+PT)/) {
        my $p_no = $self->{PartyNameToPno}{$1};

        foreach my $nickname (keys %{$self->{NicknameToPno}}) {
            if ($p_no == $self->{NicknameToPno}{$nickname}) {
                $self->{NicknameToLine}{$nickname} -= 1;
            }
        }

        return 1;
    }

    return 0;
}

#-----------------------------------#
#    無効化された攻撃を取得
#------------------------------------
#    引数｜対象ノード
#-----------------------------------#
sub GetBlockData{
    my $self         = shift;
    my $node         = shift;

    if ($node->as_text =~ /攻撃を無効化（.+壁：残強度\d+）/) {return 1;}

    return 0;
}

#-----------------------------------#
#    離脱情報を取得しPT人数を減算
#------------------------------------
#    引数｜対象ノード
#-----------------------------------#
sub GetDesorptionData{
    my $self         = shift;
    my $node         = shift;

    my $font_nodes = "";
    $font_nodes = &GetNode::GetNode_Tag_Attr("font", "color", "#ff3333", \$node);

    if (!scalar(@$font_nodes)) { return 0;}

    if ($$font_nodes[0]->as_text =~ /\(Pn(\d+)\) は離脱/) {
        $self->{PartyNum}{$1} -= 1;

        return 1;
    }

    return 0;
}

#-----------------------------------#
#    攻撃属性情報を取得
#------------------------------------
#    引数｜対象ノード
#-----------------------------------#
sub GetElementData{
    my $self    = shift;
    my $node    = shift;
    my $element = shift;

    if ($node->as_text !~ /属性攻撃！/) {return 0;}

    my $i_nodes = "";
    $i_nodes = &GetNode::GetNode_Tag("i", \$node);

    if (!scalar(@$i_nodes)) { return 0;}

    if ($$i_nodes[0]->as_text =~ /(.{4,6})属性攻撃！/) {
        $$element = $self->{CommonDatas}{ProperName}->GetOrAddId($1);

        return 1;
    }

    return 0;
}

#-----------------------------------#
#    鎖力強化率取得
#------------------------------------
#    引数｜発動ノード
#          バフデバフ情報
#-----------------------------------#
sub GetChainPowerData{
    my $self         = shift;
    my $node         = shift;
    my $buffers      = shift;

    if ($node->as_text =~ /鎖力によりChain効果が/) {
        my $chain_node = &GetNode::GetNode_Tag("font", \$node);

        my $text = "";
        if (scalar(@$chain_node)) { $text = $$chain_node[0]->as_text}

        if ($text =~ /鎖力によりChain効果が(\d+)％強化！/) {
            $$$buffers{$1} = {"id"=>$self->{CommonDatas}{ProperName}->GetOrAddId("鎖力"), "lv"=>0, "number"=>$1};
        }
        return 1;
    } else {
        return 0;
    }
}

#-----------------------------------#
#    強化フィールド取得
#------------------------------------
#    引数｜発動ノード
#          バフデバフ情報
#-----------------------------------#
sub GetFieldData{
    my $self         = shift;
    my $node         = shift;
    my $buffers      = shift;

    if ($node->as_text =~ /属性威力が強化|まったり効いてくる…。/) {
        my $field_node = &GetNode::GetNode_Tag("font", \$node);

        my $text = "";
        if (scalar(@$field_node)) { $text = $$field_node[0]->as_text}

        if ($text =~ /(.+)Lv(\d+)/) {
            $$$buffers{$1} = {"id"=>$self->{CommonDatas}{ProperName}->GetOrAddId($1), "lv"=>$2, "number"=>1};
        }
        return 1;
    } elsif ($node->as_text =~ /属性攻撃を強制変換/) {
        my $field_node = &GetNode::GetNode_Tag("i", \$node);

        my $text = "";
        if (scalar(@$field_node)) { $text = $$field_node[0]->as_text}

        if ($text =~ /(.+)により属性攻撃を強制変換/) {
            $$$buffers{$1} = {"id"=>$self->{CommonDatas}{ProperName}->GetOrAddId($1), "lv"=>0, "number"=>1};
        }
        return 1;
    } else {
        return 0;
    }
}

#-----------------------------------#
#    攻撃属性情報を初期化
#------------------------------------
#    引数｜対象ノード
#-----------------------------------#
sub ResetElementData{
    my $self    = shift;
    my $element = shift;

    $$element = 0;

    return 0;
}

#-----------------------------------#
#    クリティカル等値初期化
#------------------------------------
#    引数｜バフデバフ情報
#-----------------------------------#
sub ResetPreDamageData{
    my $self         = shift;
    my $buffers      = shift;

    my @keys = ("WeakPoint","Critical","Clean Hit","Vanish","Absorb","Revenge","Time Penalty","To the Fallen");
    foreach my $key (@keys) {
        delete($$$buffers{$key});
    }
}

#-----------------------------------#
#    状態異常値初期化
#------------------------------------
#    引数｜バフデバフ情報
#-----------------------------------#
sub ResetAbnormalData{
    my $self         = shift;
    my $buffers      = shift;

    my @keys = ("毒","麻","封","乱","魅");
    foreach my $key (@keys) {
        delete($$$buffers{$key});
    }
}


#-----------------------------------#
#    鎖力強化初期化
#------------------------------------
#    引数｜バフデバフ情報
#-----------------------------------#
sub ResetChainPowerData{
    my $self         = shift;
    my $buffers      = shift;

    foreach my $key (keys %$$buffers) {
        if ($key =~ /鎖力/) {
            delete($$$buffers{$key});
        }
    }
}

#-----------------------------------#
#    強化フィールド初期化
#------------------------------------
#    引数｜バフデバフ情報
#-----------------------------------#
sub ResetFieldData{
    my $self         = shift;
    my $buffers      = shift;

    foreach my $key (keys %$$buffers) {
        if ($key =~ /フィールド/) {
            delete($$$buffers{$key});
        }
    }
}

#-----------------------------------#
#    FPダメージ種別初期化
#------------------------------------
#    引数｜バフデバフ情報
#-----------------------------------#
sub ResetFPDamageType{
    my $self         = shift;
    my $buffers      = shift;

    foreach my $key (keys %$$buffers) {
        if ($key =~ /完全FP|完全LP|混合LPFP/) {
            delete($$$buffers{$key});
        }
    }
}


#-----------------------------------#
#    出力
#------------------------------------
#    引数｜ファイルアドレス
#-----------------------------------#
sub Output(){
    my $self = shift;
    
    foreach my $object( values %{ $self->{Datas} } ) {
        $object->Output();
    }
    return;
}
1;
