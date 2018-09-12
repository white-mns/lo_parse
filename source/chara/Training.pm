#===================================================================
#        鍛錬情報取得パッケージ
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
package Training;

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
                "training_type",
                "training",
    ];

    $self->{Datas}{Data}->Init($header_list);
    
    #出力ファイル設定
    $self->{Datas}{Data}->SetOutputName( "./output/chara/training_" . $self->{ResultNo} . "_" . $self->{GenerateNo} . ".csv" );
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

    $self->GetTrainingData($b_re2_nodes);
    
    return;
}
#-----------------------------------#
#    鍛錬データ取得
#------------------------------------
#    引数｜太字ノード
#-----------------------------------#
sub GetTrainingData{
    my $self  = shift;
    my $b_re2_nodes = shift;
    
    foreach my $b_re2_node (@$b_re2_nodes) {
        my $b_re2_text = $b_re2_node->as_text;
        
        if ($b_re2_text !~ /鍛錬/) {next;}

        my @right_nodes = $b_re2_node->right;
        foreach my $right_node (@right_nodes) {
            if ($right_node =~ /HASH/ && ($right_node->tag eq "b" || $right_node->tag eq "hr")) { last;}
            
            if ($right_node =~ /HASH/ && $right_node->tag eq "span") {
                my ($training_type, $training) = (-1, 0);

                my $training_text = $right_node->as_text;

                $training_type =  ($training_text =~ /(腕力|体力|理力|精神|器用|敏捷)/) ? 0 : 1; 
                $training = $self->{CommonDatas}{ProperName}->GetOrAddId($training_text);

                my @datas=($self->{ResultNo}, $self->{GenerateNo}, $self->{ENo}, $training_type, $training);
                $self->{Datas}{Data}->AddData(join(ConstData::SPLIT, @datas));
            }
        }
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
    
    foreach my $object( values %{ $self->{Datas} } ) {
        $object->Output();
    }
    return;
}
1;
