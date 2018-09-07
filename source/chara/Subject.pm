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
package Subject;

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
    
    $self->{SubjectNames} = ["斬術", "突術", "打術", "射撃", "護衛", "舞踊", "盗術", "料理", "工芸", "機動", "化学", "算術", "火術", "神術", "命術", "冥術", "地学", "天文", "風水", "心理", "音楽", "呪術", "幻術", "奇術"];
    $self->ResetSubjectValue();

    #初期化
    $self->{Datas}{Data} = StoreData->new();

    my $header_list = "";
   
    $header_list = [
                "result_no",
                "generate_no",
                "e_no",
                "slash",
                "thrust",
                "stroke",
                "shot",
                "guard",
                "dance",
                "theft",
                "cooking",
                "technology",
                "movement",
                "chemistry",
                "arithmetic",
                "fire",
                "theology",
                "life",
                "demonology",
                "geography",
                "astronomy",
                "fengshui",
                "psychology",
                "music",
                "curse",
                "illusion",
                "trick",
    ];

    $self->{Datas}{Data}->Init($header_list);
    
    #出力ファイル設定
    $self->{Datas}{Data}->SetOutputName( "./output/chara/subject_" . $self->{ResultNo} . "_" . $self->{GenerateNo} . ".csv" );
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

    $self->ResetSubjectValue();
    $self->GetSubjectData($table_in_ma_node);
    
    return;
}

#-----------------------------------#
#    データ取得
#------------------------------------
#    引数｜e_no,名前データノード
#-----------------------------------#
sub ResetSubjectValue{
    my $self    = shift;

    foreach my $subject_name (@{$self->{SubjectNames}}) {
        $self->{SubjectValue}{$subject_name} = 0;
    }
}

#-----------------------------------#
#    学科データ取得
#------------------------------------
#    引数｜学科データノード
#-----------------------------------#
sub GetSubjectData{
    my $self  = shift;
    my $table_in_ma_node = shift;
    
    # tdの抽出
    my $td_nodes = &GetNode::GetNode_Tag("td",\$table_in_ma_node);
 
    foreach my $td_node(@$td_nodes) {    
        my $td_text = $td_node->as_text;
        my $right = $td_node->right;
        my $right_text = ($right && $right =~ /HASH/) ? $right->as_text : $right;

        foreach my $subject_name (@{$self->{SubjectNames}}) {
            if($td_text eq $subject_name){
                $self->{SubjectValue}{$subject_name} = $right_text;
                last;
            }
        }
    }

    my @datas=($self->{ResultNo}, $self->{GenerateNo}, $self->{ENo});

    foreach my $subject_name (@{$self->{SubjectNames}}) {
        push (@datas, $self->{SubjectValue}{$subject_name});
    }

    $self->{Datas}{Data}->AddData(join(ConstData::SPLIT, @datas));

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
