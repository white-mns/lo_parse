#===================================================================
#        詳細パラメータ取得パッケージ
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
package Parameter;

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
    $self->{Datas}{ParameterFight}    = StoreData->new();
    $self->{Datas}{ParameterControl}  = StoreData->new();
    $self->{Datas}{ParameterProgress} = StoreData->new();

    my $header_list = "";
   
    $header_list = [
                "result_no",
                "generate_no",
                "e_no",
                "lv",
                "rank",
                "exp",
                "next",
                "mlp",
                "mfp",
    ];

    $self->{Datas}{ParameterFight}->Init($header_list);
    
    $header_list = [
                "result_no",
                "generate_no",
                "e_no",
                "cond",
                "day",
                "mod",
                "cvp",
                "pvp",
    ];
    
    $self->{Datas}{ParameterControl}->Init($header_list);
    
    $header_list = [
                "result_no",
                "generate_no",
                "e_no",
                "tip",
                "tip_t",
                "build_t",
                "mark_t",
    ];
    
    $self->{Datas}{ParameterProgress}->Init($header_list);
    
    #出力ファイル設定
    $self->{Datas}{ParameterFight}->SetOutputName( "./output/chara/parameter_fight_" . $self->{ResultNo} . "_" . $self->{GenerateNo} . ".csv" );
    $self->{Datas}{ParameterControl}->SetOutputName( "./output/chara/parameter_control_" . $self->{ResultNo} . "_" . $self->{GenerateNo} . ".csv" );
    $self->{Datas}{ParameterProgress}->SetOutputName( "./output/chara/parameter_progress_" . $self->{ResultNo} . "_" . $self->{GenerateNo} . ".csv" );
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
    my ($lv, $rank, $exp, $next, $mlp, $mfp) = (0, 0, 0, 0, 0, 0);
    my ($cond, $day, $mod, $cvp, $pvp)       = (0, 0, 0, 0, 0);
    my ($tip, $tip_t, $build_t, $mark_t)     = (0, 0, 0, 0);
 
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
        }elsif($td_text eq "EXP"){
            $exp = $right_text;
        }elsif($td_text eq "NEXT"){
            $next = $right_text;
        }elsif($td_text eq "MLP"){
            $mlp = $right_text;
        }elsif($td_text eq "MFP"){
            $mfp = $right_text;
        }elsif($td_text eq "Cond"){
            $cond = $self->{CommonDatas}{ProperName}->GetOrAddId($right_text);
        }elsif($td_text eq "Day"){
            $day = $right_text;
        }elsif($td_text eq "Mod"){
            $mod = $right_text;
        }elsif($td_text eq "CVP"){
            $cvp = $right_text;
        }elsif($td_text eq "PVP"){
            $pvp = $right_text;
        }elsif($td_text eq "Tip"){
            $tip = $right_text;
        }elsif($td_text eq "Tip.T"){
            $tip_t = $right_text;
        }elsif($td_text eq "Build.T"){
            $build_t = $right_text;
        }elsif($td_text eq "Mark.T"){
            $mark_t = $right_text;
        }
    }

    $self->{Datas}{ParameterFight}->AddData(join(ConstData::SPLIT,    ($self->{ResultNo}, $self->{GenerateNo}, $self->{ENo}, $lv, $rank, $exp, $next, $mlp, $mfp)));
    $self->{Datas}{ParameterControl}->AddData(join(ConstData::SPLIT,  ($self->{ResultNo}, $self->{GenerateNo}, $self->{ENo}, $cond, $day, $mod, $cvp, $pvp)));
    $self->{Datas}{ParameterProgress}->AddData(join(ConstData::SPLIT, ($self->{ResultNo}, $self->{GenerateNo}, $self->{ENo}, $tip, $tip_t, $build_t, $mark_t)));

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
