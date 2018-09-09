#===================================================================
#        開拓戦勝敗取得パッケージ
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
package DevelopmentResult;

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
    $self->{Datas}{Data} = StoreData->new();

    my $header_list = "";
   
    $header_list = [
                "result_no",
                "generate_no",
                "e_no",
                "development_result",
                "bellicose",
                "party_num",
    ];

    $self->{Datas}{Data}->Init($header_list);
    
    #出力ファイル設定
    $self->{Datas}{Data}->SetOutputName( "./output/chara/development_result_" . $self->{ResultNo} . "_" . $self->{GenerateNo} . ".csv" );
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
    my $table_nodes  = shift;
    
    $self->{ENo} = $e_no;

    $self->ParseBNode($b_re2_nodes, $table_nodes);
    
    return;
}

#-----------------------------------#
#    開拓戦勝敗データ取得
#------------------------------------
#    引数｜太字ノード
#          ターン開始時PT一覧テーブルノード
#-----------------------------------#
sub ParseBNode{
    my $self  = shift;
    my $b_re2_nodes = shift;
    my $table_nodes  = shift;
    my ($development_result, $bellicose, $party_num) = (-2, -1, -1);
    
    if(ref($table_nodes) && !scalar(@$table_nodes)){return};
    
    foreach my $b_re2_node (@$b_re2_nodes) {
        my $b_re2_text = $b_re2_node->as_text;
        
        if ($b_re2_text =~ /集合/) {
            $bellicose = $self->GetBellicose($b_re2_node);
            
        }elsif ($b_re2_text =~ /帰還/) {
            $development_result = $self->GetDevelopmentResult($b_re2_node);
        }
    }
    
    $party_num = $self->GetPartyNum($table_nodes);

    my @datas=($self->{ResultNo}, $self->{GenerateNo}, $self->{ENo}, $development_result, $bellicose, $party_num);
    $self->{Datas}{Data}->AddData(join(ConstData::SPLIT, @datas));

    return;
}

#-----------------------------------#
#    好戦度取得
#------------------------------------
#    引数｜太字ノード
#-----------------------------------#
sub GetBellicose{
    my $self  = shift;
    my $b_re2_node = shift;
    
    my @right_nodes = $b_re2_node->right;

    foreach my $right_node (@right_nodes) {
        if ($right_node =~ /HASH/ && ($right_node->tag eq "b" || $right_node->tag eq "hr")) {last;}

        if ($right_node =~ /好戦度を (\d) とした/) {
            return  $1;
        }
    }
    
    return -1;
}
#-----------------------------------#
#    勝敗取得
#------------------------------------
#    引数｜太字ノード
#-----------------------------------#
sub GetDevelopmentResult{
    my $self  = shift;
    my $b_re2_node = shift;
    
    my @right_nodes = $b_re2_node->right;

    foreach my $right_node (@right_nodes) {
        if ($right_node =~ /HASH/ && ($right_node->tag eq "b" || $right_node->tag eq "hr")) {last;}

        if ($right_node =~ /侵攻に成功した。/) {
            return  1;

        }elsif ($right_node =~ /元の場所に戻された/) {
            return  0;

        }elsif ($right_node =~ /負傷したため、前線撤退を余儀なくされた/) {
            return -1;
            
        }
    }
    
    return -2;
}

#-----------------------------------#
#    PT人数取得
#------------------------------------
#    引数｜ターン開始時PT一覧テーブルノード
#-----------------------------------#
sub GetPartyNum{
    my $self  = shift;
    my $table_nodes  = shift;

    my $tr_nodes = &GetNode::GetNode_Tag("tr", \$$table_nodes[0]);

    return scalar(@$tr_nodes) / 2;
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
