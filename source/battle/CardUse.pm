#===================================================================
#        カード使用結果情報取得パッケージ
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
package CardUse;

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
    $self->{Datas}{CardUsePage} = StoreData->new();
    $self->{Datas}{CardUser}    = StoreData->new();
    $self->{Datas}{MaxChain}    = StoreData->new();
    $self->{Datas}{NewCardUse}  = StoreData->new();
    $self->{Datas}{AllCardUse}  = StoreData->new();

    my $header_list = "";
   
    $header_list = [
                "result_no",
                "generate_no",
                "battle_page",
                "party",
                "use_cards",
    ];

    $self->{Datas}{CardUsePage}->Init($header_list);
    
    $header_list = [
                "result_no",
                "generate_no",
                "battle_page",
                "turn",
                "e_no",
                "party",
                "card_id",
                "success",
                "control",
    ];

    $self->{Datas}{CardUser}->Init($header_list);
    
    $header_list = [
                "result_no",
                "generate_no",
                "battle_page",
                "party",
                "max_chain",
    ];

    $self->{Datas}{MaxChain}->Init($header_list);
    
    $header_list = [
                "result_no",
                "generate_no",
                "card_id",
    ];

    $self->{Datas}{NewCardUse}->Init($header_list);
    $self->{Datas}{AllCardUse}->Init($header_list);
    
    #出力ファイル設定
    $self->{Datas}{CardUsePage}->SetOutputName( "./output/battle/card_use_page_" . $self->{ResultNo} . "_" . $self->{GenerateNo} . ".csv" );
    $self->{Datas}{CardUser}->SetOutputName   ( "./output/battle/card_user_"     . $self->{ResultNo} . "_" . $self->{GenerateNo} . ".csv" );
    $self->{Datas}{MaxChain}->SetOutputName   ( "./output/battle/max_chain_"     . $self->{ResultNo} . "_" . $self->{GenerateNo} . ".csv" );
    $self->{Datas}{NewCardUse}->SetOutputName ( "./output/new/card_use_"         . $self->{ResultNo} . "_" . $self->{GenerateNo} . ".csv" );
    $self->{Datas}{AllCardUse}->SetOutputName ( "./output/new/all_card_use_"     . $self->{ResultNo} . "_" . $self->{GenerateNo} . ".csv" );
    
    $self->ReadLastNewData();

    return;
}

#-----------------------------------#
#    既存データを読み込む
#-----------------------------------#
sub ReadLastNewData(){
    my $self      = shift;
    
    my $file_name = "";
    # 前回結果の確定版ファイルを探索
    for (my $i=5; $i>=0; $i--){
        $file_name = "./output/new/all_card_use_" . ($self->{ResultNo} - 1) . "_" . $i . ".csv" ;
        if(-f $file_name) {last;}
    }
    
    #既存データの読み込み
    my $content = &IO::FileRead ( $file_name );
    
    my @file_data = split(/\n/, $content);
    shift (@file_data);
    
    foreach my  $data_set(@file_data){
        my $new_card_use_datas = []; 
        @$new_card_use_datas   = split(ConstData::SPLIT, $data_set);
        my $card_id = $$new_card_use_datas[2];
        if(!exists($self->{AllCardUse}{$card_id})){
            $self->{AllCardUse}{$card_id} = [$self->{ResultNo}, $self->{GenerateNo}, $card_id];
        }
    }

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
    
    $self->{NicknameToEno} = {};
    $self->{NicknameToPno}  = {};
    $self->{Pno} = {};
    $self->{MaxChain} = {};

    $self->{BattlePage} = $battle_page;
    $self->{BattlePage} =~ s/-/ VS /;

    # 愛称とEnoの紐付け処理
    $self->LinkingNicknameToEno($link_nodes, $table_345_nodes);

    # カード使用結果の初期化
    $self->{UseCard} = {};
    $self->{UseCard}{"-ALL"} = {};
    $self->{UseCard}{"PT"} = {};
    foreach my $e_no (values(%{$self->{NicknameToEno}})){
        $self->{UseCard}{$e_no} = {};
    }

    $self->ReadHeadingData($div_heading_nodes);

    $self->TotalingCardData();
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
        if($i > 10){$i = 10;}

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
    $self->{MaxChain}{$p_no} = 0;

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
    $self->{MaxChain}{$p_no} = 0;

    return;
}

#-----------------------------------#
#    ターン数取得
#    　ターン数ノードを元に発動結果取得関数を実行する
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

                if ($right_node =~ /HASH/ && $right_node->tag eq "dl") {
                    $self->ReadTurnDlNode($turn, $right_node);
                }
            }
        }

        if ($node->as_text =~ /Turn Encount/) {
            my $turn = 0;
            my @right_nodes = $node->right;

            foreach my $right_node (@right_nodes) {
                if ($right_node =~ /HASH/) {
                    my @right_child_nodes = $right_node->content_list;

                    foreach my $right_child_node (@right_child_nodes) {
                        if ($right_child_node =~ /HASH/ && $right_child_node->tag eq "dt") {
                            my @right_child_child_nodes = $right_child_node->content_list;

                            foreach my $right_child_child_node (@right_child_child_nodes) {
                                if ($right_child_child_node =~ /HASH/ && $right_child_child_node->tag eq "div" && $right_child_child_node->attr("class") eq "heading") {last;}

                                if ($right_child_child_node =~ /HASH/ && $right_child_child_node->tag eq "dl") {
                                    $self->ReadTurnDlNode($turn, $right_child_child_node);
                                    last;
                                }
                            }
                        }
                    }
                }
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
    my $dl_node  = shift;

    my @nodes = $dl_node->content_list;

    my $nickname = "";
    my $trigger_node = "";

    foreach my $node (@nodes) {
        if ($node =~ /HASH/ && $node->tag eq "dl") {
            # 表示上のBUGで戦闘内容が入れ子になった時、再帰的に実行し、現在の深さにあるその後の要素は解析しない
            $self->ReadTurnDlNode($turn, $node);
            last;
        }
        
        if ($node->as_text =~ /により/) {next;}

        $self->GetTriggerData($node, \$nickname, \$trigger_node);

        $self->GetCardUseData($turn, $node, \$nickname);
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
    my $trigger_node = shift;
    
    my $text = $node->as_text;

    if ($text !~ /Action|が後に続く|が発動|が先導する/) {return 0;}
    
    if ($text !~ /(.+\(Pn\d+\))/) {return 0;}
    $$nickname = $1;

    my $tmp_node = &GetNode::GetNode_Tag("font", \$node);
    $$trigger_node = $$tmp_node[0];

    return 1;
}
#-----------------------------------#
#    カード情報取得
#------------------------------------
#    引数｜発動ノード
#          カード情報
#-----------------------------------#
sub GetCardUseData{
    my $self      = shift;
    my $turn      = shift;
    my $node      = shift;
    my $nickname  = shift;
    
    if ($$nickname eq "") {return;}

    my $font_nodes = "";
    $font_nodes = &GetNode::GetNode_Tag_Attr("font", "color", "#009999", \$node);
    if (!scalar(@$font_nodes)) {
        $font_nodes  = &GetNode::GetNode_Tag_Attr("font", "color", "#666600", \$node);
    }

    if (!scalar(@$font_nodes)) { return 0;}

    my $card_text = $$font_nodes[0]->as_text;

    if ($card_text !~ /Lv(\d+)/) {return 0;}
    my $lv = $1;
    
    my $p_no = $self->{NicknameToPno}{$$nickname};
    my $e_no = $self->{NicknameToEno}{$$nickname};
    
    my $success = -1;
    my $control = -1;

    if($card_text =~ /！/){
        $success = 1;

    }else{
        my $text = $node->as_text;
        if ($text !~ /制御に失敗！\(発動率：(\d+)％\)/) {return 0;}
        $success = 0;
        $control = $1;
    }

    if($card_text =~ /Chain(\d+)：/){
        $self->{MaxChain}{$p_no} = ($self->{MaxChain}{$p_no} < $1) ? $1 : $self->{MaxChain}{$p_no};
    }

    $card_text =~ s/Chain(\d+)：//;
    $card_text =~ s/！//;
    $card_text =~ s/\s//g;

    # カード使用者をデータに追加
    my $effect = $card_text;
    $effect =~ s/Lv(\d+)//;
    my $card_id = $self->{CommonDatas}{CardData}->GetOrAddId(0, [$effect, 0, $lv, 0, 0, 0]);
    $self->{Datas}{CardUser}->AddData(join(ConstData::SPLIT, ($self->{ResultNo}, $self->{GenerateNo}, $self->{BattlePage}, $turn, $e_no, $p_no, $card_id, $success, $control)));
    $self->RecordNewCardUseData($card_id);

    if($success == 0){return 0;}

    $self->{UseCard}{"-ALL"}{$card_text} = 1;
    $self->{UseCard}{"PT"}{$p_no}{$card_text}  = 1;

    return 1;
}

#-----------------------------------#
#    一試合分のカード使用データを集計
#------------------------------------
#    引数｜
#-----------------------------------#
sub TotalingCardData{
    my $self = shift;
   
    # 各PTの使用カードを結合してデータに追加
    foreach my $p_no (keys(%{$self->{UseCard}{"PT"}})){
        my $use_cards = "";
        foreach my $skill (keys(%{$self->{UseCard}{"PT"}{$p_no}})){
            $use_cards = $use_cards eq "" ? $skill : $use_cards . ",$skill";
        }
        my @card_use_data = ($self->{ResultNo}, $self->{GenerateNo}, $self->{BattlePage}, $p_no, $use_cards);
        $self->{Datas}{CardUsePage}->AddData(join(ConstData::SPLIT, @card_use_data));

        my @max_chain_data = ($self->{ResultNo}, $self->{GenerateNo}, $self->{BattlePage}, $p_no, $self->{MaxChain}{$p_no});
        $self->{Datas}{MaxChain}->AddData(join(ConstData::SPLIT, @max_chain_data));
    }
 
    # 試合全体の使用カードを結合してデータに追加
    my $use_cards = "";
    foreach my $skill (keys(%{$self->{UseCard}{"-ALL"}})){
        $use_cards = $use_cards eq "" ? $skill : $use_cards . ",$skill";
    }
    my @card_use_data = ($self->{ResultNo}, $self->{GenerateNo}, $self->{BattlePage}, 0, $use_cards);
    $self->{Datas}{CardUsePage}->AddData(join(ConstData::SPLIT, @card_use_data));

    return;
}

#-----------------------------------#
#    新出発動カードの判定と記録
#------------------------------------
#    引数｜カード識別番号
#-----------------------------------#
sub RecordNewCardUseData{
    my $self  = shift;
    my $card_id  = shift;

    if (exists($self->{AllCardUse}{$card_id})) {return;}

    my @new_data = ($self->{ResultNo}, $self->{GenerateNo}, $card_id);
    $self->{Datas}{NewCardUse}->AddData(join(ConstData::SPLIT, @new_data));

    $self->{AllCardUse}{$card_id} = [$self->{ResultNo}, $self->{GenerateNo}, $card_id];

    return;
}

#-----------------------------------#
#    出力
#------------------------------------
#    引数｜
#-----------------------------------#
sub Output{
    my $self = shift;
    
    # 新出データ判定用の既出全取得カード情報の書き出し
    foreach my $card_id (sort{$a cmp $b} keys %{ $self->{AllCardUse} } ) {
        $self->{Datas}{AllCardUse}->AddData(join(ConstData::SPLIT, @{ $self->{AllCardUse}{$card_id} }));
    }

    foreach my $object( values %{ $self->{Datas} } ) {
        $object->Output();
    }
    return;
}
1;
