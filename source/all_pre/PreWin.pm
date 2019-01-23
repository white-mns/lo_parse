#===================================================================
#        模擬戦勝数取得パッケージ
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
package PreWin;

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
    $self->{Datas}{Result}   = StoreData->new();
    $self->{Datas}{TotalPartyNum} = StoreData->new();
    my $header_list = "";
   
    $header_list = [
                "result_no",
                "generate_no",
                "e_no",
                "win",
                "draw",
                "lose",
                "all",
    ];

    $self->{Datas}{Result}->Init($header_list);

    $header_list = [
                "result_no",
                "generate_no",
                "e_no",
                "count_type",
                "party_num",
    ];

    $self->{Datas}{TotalPartyNum}->Init($header_list);
    
    #出力ファイル設定
    $self->{Datas}{Result}->SetOutputName  ( "./output/all_pre/pre_win_"       . $self->{ResultNo} . "_" . $self->{GenerateNo} . ".csv" );
    $self->{Datas}{TotalPartyNum}->SetOutputName( "./output/all_pre/total_party_num_" . $self->{ResultNo} . "_" . $self->{GenerateNo} . ".csv" );

    $self->ReadLastData();

    return;
}

#-----------------------------------#
#    既存データを読み込む
#-----------------------------------#
sub ReadLastData(){
    my $self      = shift;
    
    my $file_name = "";
    # 前回結果の確定版ファイルを探索
    for (my $i=5; $i>=0; $i--){
        $file_name = "./output/all_pre/total_party_num_" . ($self->{ResultNo} - 1) . "_" . $i . ".csv" ;
        if(-f $file_name) {last;}
    }
    
    #既存データの読み込み
    my $content = &IO::FileRead ( $file_name );
    
    my @file_data = split(/\n/, $content);
    shift (@file_data);
    
    foreach my  $data_set(@file_data){
        my $pre_win_count_datas = []; 
        @$pre_win_count_datas   = split(ConstData::SPLIT, $data_set);

        if ($$pre_win_count_datas[3] < 100) {next;}

        my $e_no = sprintf("%03d", $$pre_win_count_datas[2]);
        my $count_type = sprintf("%03d", $$pre_win_count_datas[3]);
        my $count = $$pre_win_count_datas[4];
        $self->{Count}{$e_no}{$count_type} = $count;
    }

    return;
}

#-----------------------------------#
#    データ取得
#------------------------------------
#    引数｜模擬戦一覧ノード
#-----------------------------------#
sub GetData{
    my $self    = shift;
    my $table_ma_node = shift;

    $self->GetPreData($table_ma_node);
    
    return;
}

#-----------------------------------#
#    模擬戦勝数データ取得
#------------------------------------
#    引数｜模擬戦一覧ノード
#-----------------------------------#
sub GetPreData{
    my $self  = shift;
    my $table_in_node = shift;
    
    # trの抽出
    my $tr_nodes = &GetNode::GetNode_Tag("tr",\$table_in_node);
    shift(@$tr_nodes);
 
    #tdの抜出
    foreach my $tr_node (@$tr_nodes){
        $self->GetPreResultData($tr_node);
        $self->GetPreTotalPartyNumData($tr_node);
    }

    return;
}

#-----------------------------------#
#    模擬戦勝敗取得
#------------------------------------
#    引数｜模擬戦結果trノード
#-----------------------------------#
sub GetPreResultData{
    my $self  = shift;
    my $tr_node = shift;
    
    #tdの抜出
    my ($e_no, $win, $draw, $lose, $all) = (0, 0, 0, 0, 0);
    my $td_nodes = &GetNode::GetNode_Tag("td",\$tr_node);
    my $link_nodes = &GetNode::GetNode_Tag("a",\$$td_nodes[1]);

    if ($$td_nodes[0]->as_text =~ /(\d)\/(\d)\/(\d)/) {
        $win  = $1;
        $draw = $2;
        $all  = $3;
        $lose = 3 - $win - $draw;
    }

    if ($$link_nodes[0]->attr("href") =~ /result_Eno(\d+).html/) {
        $e_no = $1;
    }
 
    $self->{Datas}{Result}->AddData(join(ConstData::SPLIT, ($self->{ResultNo}, $self->{GenerateNo}, $e_no, $win, $draw, $lose, $all)));

    return;
}

#-----------------------------------#
#    模擬戦召集PT数取得
#------------------------------------
#    引数｜模擬戦結果trノード
#-----------------------------------#
sub GetPreTotalPartyNumData{
    my $self  = shift;
    my $tr_node = shift;
    
    #tdの抜出
    my ($win, $win_0, $win_1, $win_2, $win_3) = (0, 0, 0, 0, 0, 0);
    my $td_nodes = &GetNode::GetNode_Tag("td",\$tr_node);
    my $link_nodes = &GetNode::GetNode_Tag("a",\$$td_nodes[1]);

    if ($$td_nodes[0]->as_text =~ /(\d)\/(\d)\/(\d)/) {
        $win  = $1;
        $win_0 = ($win == 0) ? 1 : 0;
        $win_1 = ($win == 1) ? 1 : 0;
        $win_2 = ($win == 2) ? 1 : 0;
        $win_3 = ($win == 3) ? 1 : 0;
    }

    foreach my $link_node (@$link_nodes) {
        my $e_no = 0;


        if ($link_node->attr("href") =~ /result_Eno(\d+).html#Prof/) {
            $e_no = $1;
        }

        if ($e_no == 0) {next;}

        $e_no = sprintf("%03d",$e_no);

        # 単純勝数
        $self->{Count}{$e_no}{"010"} += $win_0;
        $self->{Count}{$e_no}{"011"} += $win_1;
        $self->{Count}{$e_no}{"012"} += $win_2;
        $self->{Count}{$e_no}{"013"} += $win_3;

        # n以上勝数
        $self->{Count}{$e_no}{"020"} += $win_0 + $win_1 + $win_2 + $win_3;
        $self->{Count}{$e_no}{"021"} += $win_1 + $win_2 + $win_3;
        $self->{Count}{$e_no}{"022"} += $win_2 + $win_3;
        $self->{Count}{$e_no}{"023"} += $win_3;

        # 累計単純勝数
        $self->{Count}{$e_no}{"110"} += $win_1;
        $self->{Count}{$e_no}{"111"} += $win_1;
        $self->{Count}{$e_no}{"112"} += $win_2;
        $self->{Count}{$e_no}{"113"} += $win_3;

        # 累計n以上勝数
        $self->{Count}{$e_no}{"120"} += $win_0 + $win_1 + $win_2 + $win_3;
        $self->{Count}{$e_no}{"121"} += $win_1 + $win_2 + $win_3;
        $self->{Count}{$e_no}{"122"} += $win_2 + $win_3;
        $self->{Count}{$e_no}{"123"} += $win_3;
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
    
    # 新出データ判定用の既出全取得カード情報の書き出し
    foreach my $e_no (sort{$a cmp $b} keys %{ $self->{Count} } ) {
        foreach my $count_type (sort{$a cmp $b} keys %{ $self->{Count}{$e_no} } ) {
            $self->{Datas}{TotalPartyNum}->AddData(join(ConstData::SPLIT, ($self->{ResultNo}, $self->{GenerateNo}, $e_no+0, $count_type+0, $self->{Count}{$e_no}{$count_type})));
        }
    }

    foreach my $object( values %{ $self->{Datas} } ) {
        $object->Output();
    }
    return;
}
1;
