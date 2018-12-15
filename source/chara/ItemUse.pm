#===================================================================
#        アイテム使用結果取得パッケージ
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
package ItemUse;

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
    $self->{Datas}{ItemUse}    = StoreData->new();
    $self->{Datas}{NewItemUse} = StoreData->new();
    $self->{Datas}{AllItemUse} = StoreData->new();

    my $header_list = "";
   
    $header_list = [
                "result_no",
                "generate_no",
                "e_no",
                "i_no",
                "name",
                "recovery_lv",
    ];

    $self->{Datas}{ItemUse}->Init($header_list);
    
    $header_list = [
                "result_no",
                "generate_no",
                "name",
    ];

    $self->{Datas}{NewItemUse}->Init($header_list);
    $self->{Datas}{AllItemUse}->Init($header_list);
    
    #出力ファイル設定
    $self->{Datas}{ItemUse}->SetOutputName   ( "./output/chara/item_use_"   . $self->{ResultNo} . "_" . $self->{GenerateNo} . ".csv" );
    $self->{Datas}{NewItemUse}->SetOutputName( "./output/new/item_use_"     . $self->{ResultNo} . "_" . $self->{GenerateNo} . ".csv" );
    $self->{Datas}{AllItemUse}->SetOutputName( "./output/new/all_item_use_" . $self->{ResultNo} . "_" . $self->{GenerateNo} . ".csv" );
    
    $self->ReadLastNewData();
    $self->ReadLastItemData();

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
        $file_name = "./output/new/all_item_use_" . ($self->{ResultNo} - 1) . "_" . $i . ".csv" ;
        if(-f $file_name) {last;}
    }
    
    #既存データの読み込み
    my $content = &IO::FileRead ( $file_name );
    
    my @file_data = split(/\n/, $content);
    shift (@file_data);
    
    foreach my  $data_set(@file_data){
        my $new_item_use_datas = []; 
        @$new_item_use_datas   = split(ConstData::SPLIT, $data_set);
        my $name = $$new_item_use_datas[2];
        if(!exists($self->{AllItemUse}{$name})){
            $self->{AllItemUse}{$name} = [$self->{ResultNo}, $self->{GenerateNo}, $name];
        }
    }

    return;
}

#-----------------------------------#
#    既存アイテムデータを読み込む
#-----------------------------------#
sub ReadLastItemData(){
    my $self      = shift;
    
    my $file_name = "";
    # 前回結果の確定版ファイルを探索
    for (my $i=5; $i>=0; $i--){
        $file_name = "./output/chara/item_" . ($self->{ResultNo} - 1) . "_" . $i . ".csv" ;
        if(-f $file_name) {last;}
    }
    
    #既存データの読み込み
    my $content = &IO::FileRead ( $file_name );
    
    my @file_data = split(/\n/, $content);
    shift (@file_data);
    
    foreach my  $data_set(@file_data){
        my $item_datas = []; 
        @$item_datas   = split(ConstData::SPLIT, $data_set);
        my $e_no = $$item_datas[2];
        my $i_no = $$item_datas[3];
        my $lv = $$item_datas[8];
        $self->{LastItem}{$e_no}{$i_no} = $lv;
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

    $self->GetItemUseData($b_re2_nodes);
    
    return;
}
#-----------------------------------#
#    アイテム使用データ取得
#------------------------------------
#    引数｜太字データノード
#-----------------------------------#
sub GetItemUseData{
    my $self  = shift;
    my $b_re2_nodes = shift;
    
    foreach my $b_re2_node (@$b_re2_nodes){

        my $b_re2_text = $b_re2_node->as_text;
        if ($b_re2_text =~ /　使用　/) {
            my @right_nodes = $b_re2_node->right;

            foreach my $node (@right_nodes) {
                if ($node =~ /HASH/ && ($node->tag eq "b" || $node->tag eq "hr")) { last;}

                if ($node =~ /HASH/ && $node->tag eq "span") {
                    my ($i_no, $name, $recovery_lv) = (0, "", 0);
                    my $text = $node->as_text;

                    if ($text =~ m!Ino(\d+) (.+)!) {
                        $i_no = $1;
                        $name = $2;

                        my @item_right_nodes = $node->right;
                        if ($item_right_nodes[4] =~ /Conditionが回復♪/) {
                            $recovery_lv = $self->{LastItem}{$self->{ENo}}{$i_no};
                        }

                        my @datas=($self->{ResultNo}, $self->{GenerateNo}, $self->{ENo}, $i_no, $name, $recovery_lv);
                        $self->{Datas}{ItemUse}->AddData(join(ConstData::SPLIT, @datas));

                        $self->RecordNewItemUseData($name);

                        last;
                    }
                }
            }        
        }
    }

    return;
}

#-----------------------------------#
#    新規アイテム使用の判定と記録
#------------------------------------
#    引数｜アイテム名
#-----------------------------------#
sub RecordNewItemUseData{
    my $self  = shift;
    my $name  = shift;

    if (exists($self->{AllItemUse}{$name})) {return;}

    my @new_data = ($self->{ResultNo}, $self->{GenerateNo}, $name);
    $self->{Datas}{NewItemUse}->AddData(join(ConstData::SPLIT, @new_data));

    $self->{AllItemUse}{$name} = [$self->{ResultNo}, $self->{GenerateNo}, $name];

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
    foreach my $name (sort{$a cmp $b} keys %{ $self->{AllItemUse} } ) {
        $self->{Datas}{AllItemUse}->AddData(join(ConstData::SPLIT, @{ $self->{AllItemUse}{$name} }));
    }
    
    foreach my $object( values %{ $self->{Datas} } ) {
        $object->Output();
    }
    return;
}
1;
