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
    ];

    $self->{Datas}{Parameter}->Init($header_list);

    #出力ファイル設定
    $self->{Datas}{Parameter}->SetOutputName( "./output/command/parameter_development_" . $self->{ResultNo} . "_" . $self->{GenerateNo} . ".csv" );
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
    my $span_ch1_node    = shift;
    my $table_in_ma_node = shift;
    
    $self->{ENo} = $e_no;

    $self->GetParameterData($table_in_ma_node);
    
    return;
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
    my $td_nodes = &GetNode::GetNode_Tag("td",\$table_in_ma_node);

    foreach my $td_node(@$td_nodes){
        my $td_text = $td_node->as_text;
        my $right = $td_node->right;
        my $right_text = ($right && $right =~ /HASH/) ? $right->as_text : $right;

        if($td_text eq "Lv"){
            $lv = $right_text;
        }elsif($td_text eq "Rank"){
            $rank = $right_text;
        }elsif($td_text eq "MLP"){
            $mlp = $right_text;
        }elsif($td_text eq "MFP"){
            $mfp = $right_text;
        }elsif($td_text eq "Cond"){
            $cond = $self->{CommonDatas}{ProperName}->GetOrAddId($right_text);
        }
    }

    $self->{Datas}{Parameter}->AddData(join(ConstData::SPLIT,    ($self->{ResultNo}, $self->{GenerateNo}, $self->{ENo}, $lv, $rank, $mlp, $mfp, $cond)));

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
