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
    
    $self->{SubjectValue}{"斬術"} = 0;
    $self->{SubjectValue}{"突術"} = 0;
    $self->{SubjectValue}{"打術"} = 0;
    $self->{SubjectValue}{"射撃"} = 0;
    $self->{SubjectValue}{"護衛"} = 0;
    $self->{SubjectValue}{"舞踊"} = 0;
    $self->{SubjectValue}{"盗術"} = 0;
    $self->{SubjectValue}{"料理"} = 0;
    $self->{SubjectValue}{"工芸"} = 0;
    $self->{SubjectValue}{"機動"} = 0;
    $self->{SubjectValue}{"化学"} = 0;
    $self->{SubjectValue}{"算術"} = 0;
    $self->{SubjectValue}{"火術"} = 0;
    $self->{SubjectValue}{"神術"} = 0;
    $self->{SubjectValue}{"命術"} = 0;
    $self->{SubjectValue}{"冥術"} = 0;
    $self->{SubjectValue}{"地学"} = 0;
    $self->{SubjectValue}{"天文"} = 0;
    $self->{SubjectValue}{"風水"} = 0;
    $self->{SubjectValue}{"心理"} = 0;
    $self->{SubjectValue}{"音楽"} = 0;
    $self->{SubjectValue}{"呪術"} = 0;
    $self->{SubjectValue}{"幻術"} = 0;
    $self->{SubjectValue}{"奇術"} = 0;

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

    $self->GetSubjectData($table_in_ma_node);
    
    return;
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

        foreach my $subject_name(keys %{$self->{SubjectValue}}) {
            if($td_text eq $subject_name){
                $self->{SubjectValue}{$subject_name}    = $right_text;
                last;
            }
        }
    }

    my @datas=($self->{ResultNo}, $self->{GenerateNo}, $self->{ENo},
                $self->{SubjectValue}{"斬術"},
                $self->{SubjectValue}{"突術"},
                $self->{SubjectValue}{"打術"},
                $self->{SubjectValue}{"射撃"},
                $self->{SubjectValue}{"護衛"},
                $self->{SubjectValue}{"舞踊"},
                $self->{SubjectValue}{"盗術"},
                $self->{SubjectValue}{"料理"},
                $self->{SubjectValue}{"工芸"},
                $self->{SubjectValue}{"機動"},
                $self->{SubjectValue}{"化学"},
                $self->{SubjectValue}{"算術"},
                $self->{SubjectValue}{"火術"},
                $self->{SubjectValue}{"神術"},
                $self->{SubjectValue}{"命術"},
                $self->{SubjectValue}{"冥術"},
                $self->{SubjectValue}{"地学"},
                $self->{SubjectValue}{"天文"},
                $self->{SubjectValue}{"風水"},
                $self->{SubjectValue}{"心理"},
                $self->{SubjectValue}{"音楽"},
                $self->{SubjectValue}{"呪術"},
                $self->{SubjectValue}{"幻術"},
                $self->{SubjectValue}{"奇術"},
    );

    $self->{Datas}{Data}->AddData(join(ConstData::SPLIT, @datas));

    return;
}

#-----------------------------------#
#    出力
#------------------------------------
#    引数｜ファイルアドレス
#-----------------------------------#
sub Output{
    my $self = shift;
    
    foreach my $object( values %{ $self->{Datas} } ) {
        $object->Output();
    }
    return;
}
1;
