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
    $self->{Datas}{DamageRate} = StoreData->new();
    $self->{Datas}{Damage}     = StoreData->new();

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

    $self->{Datas}{DamageRate}->Init($header_list);
    
    $header_list = [
                "result_no",
                "generate_no",
                "battle_page",
                "e_no",
                "party",
                "card_id",
                "chain",
                "target_e_no",
                "target_party",
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
    
    #出力ファイル設定
    $self->{Datas}{Damage}->SetOutputName     ( "./output/battle/damage_"       . $self->{ResultNo} . "_" . $self->{GenerateNo} . ".csv" );
    
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

    $self->GetDamageData($self->{Pno}{Player}, $self->{Pno}{Enemy},  $font_player_nodes);
    $self->GetDamageData($self->{Pno}{Enemy},  $self->{Pno}{Player}, $font_enemy_nodes);
    
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
sub GetDamageData{
    my $self        = shift;
    my $p_no        = shift; 
    my $target_p_no = shift; 
    my $nodes       = shift; 

    foreach my $node (@$nodes) {
        my $e_no = -1;
        my $text = $node->as_text;

        if ($text !~ /！/) {next;}
        if ($text !~ /Lv(\d+)/) {next;}
        my $lv = $1;

        { # カード効果のノードから前方に遡ってEnoを取得
            my $text = "";
            my $dd_node = $node->parent;

            if ($dd_node->tag ne "dd") {$dd_node = $dd_node->parent;}
            if ($dd_node->tag ne "dd") {next;}

            while ($dd_node) {
                my $dd_text = $dd_node->as_text;
                if ($dd_text !~ /Action|が後に続く|が発動|が先導する/ ) { # もしもENoを取得できず行動の頭のメッセージまで辿り着いたら除外
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

        my $chain_num = 0;
        if ($text =~ s/Chain(\d+)：//) {
            $chain_num = $1;
        }

        # カード名の解析
        my $chain_effect_name = $text . "：" . sprintf("%03d", $chain_num);
        my $effect_name = $text;

        my $card_id = 0;
        if ($text =~ /(.+)Lv(\d+)/) {
            my $effect = $1;
            my $lv     = $2;
            $card_id   = $self->{CommonDatas}{CardData}->GetOrAddId(0, [$effect, 0, $lv, 0, 0, 0]);
        }

        my $dd_node = $node->parent;
        
        if ($dd_node->tag ne "dd") {$dd_node = $dd_node->parent;}
        if ($dd_node->tag ne "dd") {next;}

        $dd_node = $dd_node->right;

        my ($is_weak, $is_critical, $is_clean, $is_vanish, $is_absorb) = (0, 0, 0, 0, 0);
        # 対象カードの解析
        while($dd_node) {
            my ($target_e_no, $act_type, $element, $damage) = (0, 0, 0, 0);

            my $dd_text = $dd_node->as_text;

            if ($dd_text =~ /のダメージ|回復♪/) {
                if ($dd_text =~ /により/) {
                    $dd_node = $dd_node->right;
                    next;
                }

                my $font_node_player = &GetNode::GetNode_Tag_Color_NoSize("font", "#6633ff", \$dd_node);
                my $font_node_enemy  = &GetNode::GetNode_Tag_Color_NoSize("font", "#996600", \$dd_node);
                my $target_node = "";

                if    (scalar(@$font_node_player)) { $target_node = $$font_node_player[0];}
                elsif (scalar(@$font_node_enemy))  { $target_node = $$font_node_enemy[0]; }

                if (!$target_node) {
                    $dd_node = $dd_node->right;
                    next;
                }

                my $target_text = $target_node->as_text;

                if ($target_text =~ /(.+\(Pn\d+\))/) {
                    $text = $1;
                    $target_e_no = $self->{NicknameToEno}{$1};
                
                    my $damage_node = &GetNode::GetNode_Tag("font", \$target_node);

                    if ($$damage_node[1] =~ /HASH/) {
                        $damage = $$damage_node[1]->as_text;
                    }

                    if ($damage =~ /^\d+$/) {

                        if    ($target_text =~ /FPに\d+のダメージ！/) { $act_type = $self->{CommonDatas}{ProperName}->GetOrAddId("FPダメージ")}
                        elsif ($target_text =~ /LPが\d+回復/)         { $act_type = $self->{CommonDatas}{ProperName}->GetOrAddId("LP回復")}
                        elsif ($target_text =~ /FPが\d+回復/)         { $act_type = $self->{CommonDatas}{ProperName}->GetOrAddId("FP回復")}
                        else                                          { $act_type = $self->{CommonDatas}{ProperName}->GetOrAddId("ダメージ")}

                        $self->{Datas}{Damage}->AddData(join(ConstData::SPLIT, ($self->{ResultNo}, $self->{GenerateNo}, $self->{BattlePage}, $e_no, $p_no, $card_id, $chain_num, $target_e_no, $target_p_no, $act_type, $element, $damage, $is_weak, $is_critical, $is_clean, $is_vanish, $is_absorb)));
                        ($is_weak, $is_critical, $is_clean, $is_vanish, $is_absorb) = (0, 0, 0, 0, 0);
                    }
                }

            }
            elsif ($dd_text =~ /Weak|Critical|Clean|Vanish|Absorb/) {
                my $attack_node = &GetNode::GetNode_Tag_Attr("font", "color", "#ff3333", \$dd_node);
                my $block_node  = &GetNode::GetNode_Tag_Attr("font", "color", "#009966", \$dd_node);

                my $text = "";
                if    (scalar(@$attack_node)) { $text = $$attack_node[0]->as_text}
                elsif (scalar(@$block_node))  { $text = $$block_node[0]->as_text}

                if    ($text =~ /WeakPoint/) { $is_weak     = 1}
                elsif ($text =~ /Critical/)  { $is_critical = 1}
                elsif ($text =~ /Clean/)     { $is_clean    = 1}
                elsif ($text =~ /Vanish/)    { $is_vanish   = 1}
                elsif ($text =~ /Absorb/)    { $is_absorb   = 1}

            }
            elsif ($dd_node->tag eq "dt")     { last; }
            elsif ($dd_text =~ /が後に続く/ ) { last; }
            elsif ($dd_text =~ /「|\(Pn/)     { }

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
    
    foreach my $object( values %{ $self->{Datas} } ) {
        $object->Output();
    }
    return;
}
1;
