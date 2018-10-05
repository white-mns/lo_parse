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
    my $font_player_nodes = shift; 
    my $font_enemy_nodes  = shift; 
    my $link_nodes        = shift; 
    my $table_345_nodes   = shift; 
    
    $self->{NicknameToEno} = {};
    $self->{Pno} = {};
    $self->{UseCard} = {};
    $self->{UseCard}{"-ALL"} = {};

    $self->{BattlePage} = $battle_page;
    $self->{BattlePage} =~ s/-/ VS /;
    
    # 愛称とEnoの紐付け処理
    $self->LinkingNicknameToEno($link_nodes, $table_345_nodes);

    $self->GetCardUseData($self->{Pno}{Player}, $font_player_nodes);
    $self->GetCardUseData($self->{Pno}{Enemy}, $font_enemy_nodes);
    
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
#    カード使用データ取得
#------------------------------------
#    引数｜Pno
#           データノード
#-----------------------------------#
sub GetCardUseData{
    my $self      = shift;
    my $p_no      = shift; 
    my $nodes     = shift; 

    my $max_chain = 0;
    my $e_no      = -1;

    # カード使用結果の初期化
    $self->{UseCard}{"PT"} = {};
    foreach my $e_no (values(%{$self->{NicknameToEno}})){
        $self->{UseCard}{$e_no} = {};
    }

    # カード使用結果の探索
    foreach my $node (@$nodes){
        
        my $text = $node->as_text;

        if($text !~ /Lv(\d+)/){next;}

        my $lv = $1;
        my $success = -1;
        my $control = -1;

        if($text =~ /！/){
            $success = 1;

        }else{
            my $parent_text = $node->parent->as_text;
            if ($parent_text !~ /制御に失敗！\(発動率：(\d+)％\)/) {next;}
            $success = 0;
            $control = $1;
        }

        if($text =~ /Chain(\d+)：/){
            $max_chain = $max_chain < $1 ? $1 : $max_chain;
        }

        $text =~ s/Chain(\d+)：//;
        $text =~ s/！//;
        $text =~ s/\s//g;
        my $skill_name = $text;

        my $dd_node = $node->parent;
        if($dd_node->tag ne "dd"){$dd_node = $dd_node->parent;}
        if($dd_node->tag ne "dd"){next;}
        while($dd_node){
            my $dd_text = $dd_node->as_text;
            if($dd_text !~ /Action|が後に続く|が発動|が先導する/ || $dd_text =~ /の効果が発動/ ){
                $dd_node = $dd_node->left;
                next;
            }

            if($dd_text =~ /(.+\(Pn\d+\))/){
                my $user = $self->{NicknameToEno}{$1};
                my $card_use = [$user, $lv, $success, $control];
                $self->{UseCard}{$user}{$text} = $card_use;
                last;
            }

            if($dd_node->tag eq "dt"){last;}
            $dd_node = $dd_node->left;
        }
        if($success == 0){next;}
        $self->{UseCard}{"-ALL"}{$text} = 1;
        $self->{UseCard}{"PT"}{$text}  = 1;
    }

    foreach my $e_no (values(%{$self->{NicknameToEno}})){
        foreach my $effect (keys(%{$self->{UseCard}{$e_no}})){
            my $data = $self->{UseCard}{$e_no}{$effect};
            $effect =~ s/Lv\d+//;
            my $card_id = $self->{CommonDatas}{CardData}->GetOrAddId(0, [$effect, 0, $$data[1], 0, 0, 0]);
            my @card_user_data = ($self->{ResultNo}, $self->{GenerateNo}, $self->{BattlePage}, $$data[0], $p_no, $card_id, $$data[2], $$data[3]);
            $self->{Datas}{CardUser}->AddData(join(ConstData::SPLIT, @card_user_data));

            $self->RecordNewCardUseData($card_id);
        }
    }
    
    # PTの使用カードを結合してデータに追加
    my $use_cards = "";
    foreach my $skill (keys(%{$self->{UseCard}{"PT"}})){
        $use_cards = $use_cards eq "" ? $skill : $use_cards . ",$skill";
    }

    my @card_use_data = ($self->{ResultNo}, $self->{GenerateNo}, $self->{BattlePage}, $p_no, $use_cards);
    $self->{Datas}{CardUsePage}->AddData(join(ConstData::SPLIT, @card_use_data));

    my @max_chain_data = ($self->{ResultNo}, $self->{GenerateNo}, $self->{BattlePage}, $p_no, $max_chain);
    $self->{Datas}{MaxChain}->AddData(join(ConstData::SPLIT, @max_chain_data));
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
