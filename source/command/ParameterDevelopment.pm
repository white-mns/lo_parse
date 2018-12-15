#===================================================================
#        開拓直前パラメータ取得パッケージ
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
package ParameterDevelopment;

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
    $self->{Datas}{Parameter}    = StoreData->new();

    my $header_list = "";
   
    $header_list = [
                "result_no",
                "generate_no",
                "e_no",
                "lv",
                "rank",
                "mlp",
                "mfp",
                "cond",
                "last_result_no",
                "last_generate_no",
    ];

    $self->{Datas}{Parameter}->Init($header_list);

    #出力ファイル設定
    $self->{Datas}{Parameter}->SetOutputName( "./output/command/parameter_development_" . $self->{ResultNo} . "_" . $self->{GenerateNo} . ".csv" );

    if ($self->{ResultNo} < 6) {
        $self->GetLastParameter();
    }

    $self->ReadLastGenerateNo();

    return;
}

#-----------------------------------#
#    前回時点のパラメータを開拓直前パラメータとして登録する
#    ・Vol.6以前は対戦設定静的ページが存在しないため
#-----------------------------------#
sub GetLastParameter(){
    my $self      = shift;
    
    $self->{LastGenerateNo} = 0;
    # 前回結果の確定版ファイルを探索
    for (my $i=5; $i>=0; $i--){
        my $file_name = "./output/chara/parameter_fight_" . ($self->{ResultNo} - 1) . "_" . $i . ".csv" ;
        if(-f $file_name) {
            $self->{LastGenerateNo} = $i;
            last;
        }
    }

    my $file_name = "./output/chara/parameter_fight_" . ($self->{ResultNo} - 1) . "_" . $self->{LastGenerateNo} . ".csv";
    #既存データの読み込み
    my $content = &IO::FileRead ( $file_name );
    
    my @file_data = split(/\n/, $content);
    shift (@file_data);
    
    foreach my  $data_set(@file_data){
        my $data = []; 
        @$data   = split(ConstData::SPLIT, $data_set);
        
        $self->{Datas}{Parameter}->AddData(join(ConstData::SPLIT, ($self->{ResultNo}, $self->{GenerateNo}, $$data[2], $$data[3], $$data[4], $$data[7], $$data[8], 0)));
    }

    return;
}
#-----------------------------------#
#    前回の再更新番号を取得
#-----------------------------------#
sub ReadLastGenerateNo(){
    my $self      = shift;
    
    $self->{LastGenerateNo} = 0;
    # 前回結果の確定版ファイルを探索
    for (my $i=5; $i>=0; $i--){
        my $file_name = "./output/command/parameter_development_" . ($self->{ResultNo} - 1) . "_" . $i . ".csv" ;
        if(-f $file_name) {
            $self->{LastGenerateNo} = $i;
            last;
        }
    }
}

#-----------------------------------#
#    データ取得
#------------------------------------
#    引数｜e_no,名前データノード
#-----------------------------------#
sub GetData{
    my $self    = shift;
    my $e_no    = shift;
    my $span_ch1_node    = shift;
    my $table_in_ma_node = shift;
    
    $self->{ENo} = $e_no;

    if ($self->{ResultNo} >= 6) {
        if ($self->IsDummyData($span_ch1_node)) {return;}
    
        $self->GetParameterData($table_in_ma_node);
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
#    名前データ取得
#------------------------------------
#    引数｜名前データノード
#-----------------------------------#
sub GetParameterData{
    my $self  = shift;
    my $table_in_ma_node = shift;
    my ($lv, $rank, $mlp, $mfp, $cond) = (0, 0, 0, 0, 0);
 
    # tdの抽出
    my $tr_nodes = &GetNode::GetNode_Tag("tr",\$table_in_ma_node);
    my $td0_nodes = &GetNode::GetNode_Tag("td",\$$tr_nodes[0]);
    my $td1_nodes = &GetNode::GetNode_Tag("td",\$$tr_nodes[1]);

    for (my $i=0;$i < scalar(@$td0_nodes);$i++) {
        my $td0_text = $$td0_nodes[$i]->as_text;
        my $td1_text = $$td1_nodes[$i]->as_text;

        if($td0_text eq "Lv"){
            $lv = $td1_text;
        }elsif($td0_text eq "Rank"){
            $rank = $td1_text;
        }elsif($td0_text eq "MLP"){
            $mlp = $td1_text;
        }elsif($td0_text eq "MFP"){
            $mfp = $td1_text;
        }elsif($td0_text eq "Cond"){
            $cond = $self->{CommonDatas}{ProperName}->GetOrAddId($td1_text);
        }
    }

    $self->{Datas}{Parameter}->AddData(join(ConstData::SPLIT, ($self->{ResultNo}, $self->{GenerateNo}, $self->{ENo}, $lv, $rank, $mlp, $mfp, $cond, $self->{ResultNo} - 1, $self->{LastGenerateNo})));

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
