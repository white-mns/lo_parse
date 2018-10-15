#===================================================================
#        学科情報取得パッケージ
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
package GetCard;

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
    $self->{Datas}{GetCard}    = StoreData->new();
    $self->{Datas}{NewGetCard} = StoreData->new();
    $self->{Datas}{AllGetCard} = StoreData->new();

    my $header_list = "";
   
    $header_list = [
                "result_no",
                "generate_no",
                "e_no",
                "name",
                "card_id",
                "get_type",
    ];

    $self->{Datas}{GetCard}->Init($header_list);
    
    $header_list = [
                "result_no",
                "generate_no",
                "card_id",
                "get_type",
    ];

    $self->{Datas}{NewGetCard}->Init($header_list);
    $self->{Datas}{AllGetCard}->Init($header_list);
    
    #出力ファイル設定
    $self->{Datas}{GetCard}->SetOutputName   ( "./output/chara/get_card_"   . $self->{ResultNo} . "_" . $self->{GenerateNo} . ".csv" );
    $self->{Datas}{NewGetCard}->SetOutputName( "./output/new/get_card_"     . $self->{ResultNo} . "_" . $self->{GenerateNo} . ".csv" );
    $self->{Datas}{AllGetCard}->SetOutputName( "./output/new/all_get_card_" . $self->{ResultNo} . "_" . $self->{GenerateNo} . ".csv" );
    
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
        $file_name = "./output/new/all_get_card_" . ($self->{ResultNo} - 1) . "_" . $i . ".csv" ;
        if(-f $file_name) {last;}
    }
    
    #既存データの読み込み
    my $content = &IO::FileRead ( $file_name );
    
    my @file_data = split(/\n/, $content);
    shift (@file_data);
    
    foreach my  $data_set(@file_data){
        my $new_get_card_datas = []; 
        @$new_get_card_datas   = split(ConstData::SPLIT, $data_set);
        my $get_card = $$new_get_card_datas[2];
        my $get_type = $$new_get_card_datas[3];
        if(!exists($self->{AllGetCard}{$get_card."_".$get_type})){
            $self->{AllGetCard}{$get_card."_".$get_type} = [$self->{ResultNo}, $self->{GenerateNo}, $get_card, $get_type];
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
    my $self    = shift;
    my $e_no    = shift;
    my $b_re2_nodes = shift;
    
    $self->{ENo} = $e_no;

    $self->GetGetCardData($b_re2_nodes);
    
    return;
}
#-----------------------------------#
#    取得カードデータ取得
#------------------------------------
#    引数｜太字データノード
#-----------------------------------#
sub GetGetCardData{
    my $self  = shift;
    my $b_re2_nodes = shift;
    
    foreach my $b_re2_node (@$b_re2_nodes){

        my $b_re2_text = $b_re2_node->as_text;
        if ($b_re2_text =~ /スキルカード生成/) {
            $self->GetCreateCardData($b_re2_node);
            
        }elsif ($b_re2_text =~ /本日の収穫/) {
            $self->GetDropCardData($b_re2_node);
        }elsif ($b_re2_text =~ /・・・ E V E N T ・・・/) {
            $self->GetEventCardData($b_re2_node);
        }
    }

    return;
}

#-----------------------------------#
#    生成カードデータ取得
#------------------------------------
#    引数｜太字データノード
#-----------------------------------#
sub GetCreateCardData{
    my $self  = shift;
    my $b_re2_node = shift;

    my @right_nodes = $b_re2_node->right;
    my ($name, $effect, $card_id, $lv, $get_type) = ("", 0, 0, -1, -1);

    foreach my $right_node (@right_nodes) {
        if ($right_node =~ /HASH/ && ($right_node->tag eq "b" || $right_node->tag eq "hr")) { last;}

        if ($right_node =~ /HASH/ && $right_node->tag eq "span") {
            $name = $right_node->as_text;

        }elsif ($right_node =~ m!生成に成功♪（\+Sno\d+?：(.+?) Lv(\d+?)）!) {
            $effect   = $1;
            $lv       = $2;
            $card_id  = $self->{CommonDatas}{CardData}->GetOrAddId(0, [$effect, 0, $lv, 0, 0, 0]);
            $get_type = 1;

            my @datas=($self->{ResultNo}, $self->{GenerateNo}, $self->{ENo}, $name, $card_id, $get_type);
            $self->{Datas}{GetCard}->AddData(join(ConstData::SPLIT, @datas));

            $self->RecordNewGetCardData($card_id, 0);
            $self->RecordNewGetCardData($card_id, $get_type);
            
            ($name, $effect, $card_id, $lv, $get_type) = ("", 0, 0, -1, -1);

        }elsif ($right_node =~ m!しかしカードは生成できなかった。!) {
            $effect   = "";
            $lv       = -1;
            $card_id  = 0;
            $get_type = 0;

            my @datas=($self->{ResultNo}, $self->{GenerateNo}, $self->{ENo}, $name, $card_id, $get_type);
            $self->{Datas}{GetCard}->AddData(join(ConstData::SPLIT, @datas));
            ($name, $effect, $card_id, $lv, $get_type) = ("", 0, 0, -1, -1);
        }
    }
}

#-----------------------------------#
#    獲得カードデータ取得
#------------------------------------
#    引数｜太字データノード
#-----------------------------------#
sub GetDropCardData{
    my $self  = shift;
    my $b_re2_node = shift;

    my @right_nodes = $b_re2_node->right;
    my ($name, $effect, $card_id, $lv, $get_type) = ("", 0, 0, -1, -1);

    foreach my $right_node (@right_nodes) {
        if ($right_node =~ /HASH/ && ($right_node->tag eq "b" || $right_node->tag eq "hr")) { last;}

        if ($right_node =~ /HASH/ && $right_node->tag eq "span" && $right_node->as_text =~ m!(.+?)【(.+?)Lv(\d+?)】!) {
            $name     = $1;
            $effect   = $2;
            $lv       = $3;
            $card_id  = $self->{CommonDatas}{CardData}->GetOrAddId(0, [$effect, 0, $lv, 0, 0, 0]);
            $get_type = 2;

            my @datas=($self->{ResultNo}, $self->{GenerateNo}, $self->{ENo}, $name, $card_id, $get_type);
            $self->{Datas}{GetCard}->AddData(join(ConstData::SPLIT, @datas));

            $self->RecordNewGetCardData($card_id, 0);
            $self->RecordNewGetCardData($card_id, $get_type);

            ($name, $effect, $card_id, $lv, $get_type) = ("", 0, 0, -1, -1);
        }
    }
}

#-----------------------------------#
#    イベント獲得カードデータ取得
#------------------------------------
#    引数｜太字データノード
#-----------------------------------#
sub GetEventCardData{
    my $self  = shift;
    my $b_re2_node = shift;

    my @right_nodes = $b_re2_node->right;
    my ($name, $effect, $card_id, $lv, $get_type) = ("", 0, 0, -1, -1);

    foreach my $right_node (@right_nodes) {
        if ($right_node =~ /HASH/ && ($right_node->tag eq "b" || $right_node->tag eq "hr")) { last;}

        if ($right_node =~ /HASH/ && $right_node->tag eq "span" && $right_node->as_text =~ m!(.+?)【(.{2,20})Lv(\d+?)】!) {
            $name     = $1;
            $effect   = $2;
            $lv       = $3;
            $card_id  = $self->{CommonDatas}{CardData}->GetOrAddId(0, [$effect, 0, $lv, 0, 0, 0]);
            $get_type = 3;

            $self->RecordNewGetCardData($card_id, 0);
            $self->RecordNewGetCardData($card_id, $get_type);

            ($name, $effect, $card_id, $lv, $get_type) = ("", 0, 0, -1, -1);
        }
    }
}

#-----------------------------------#
#    新出取得カードの判定と記録
#------------------------------------
#    引数｜カード識別番号
#          取得方法
#-----------------------------------#
sub RecordNewGetCardData{
    my $self  = shift;
    my $card_id  = shift;
    my $get_type = shift;

    if (exists($self->{AllGetCard}{$card_id."_".$get_type})) {return;}

    my @new_data = ($self->{ResultNo}, $self->{GenerateNo}, $card_id, $get_type);
    $self->{Datas}{NewGetCard}->AddData(join(ConstData::SPLIT, @new_data));

    $self->{AllGetCard}{$card_id."_".$get_type} = [$self->{ResultNo}, $self->{GenerateNo}, $card_id, $get_type];

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
    foreach my $cardid_gettype (sort{$a cmp $b} keys %{ $self->{AllGetCard} } ) {
        $self->{Datas}{AllGetCard}->AddData(join(ConstData::SPLIT, @{ $self->{AllGetCard}{$cardid_gettype} }));
    }
    
    foreach my $object( values %{ $self->{Datas} } ) {
        $object->Output();
    }
    return;
}
1;
