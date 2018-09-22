#===================================================================
#        推定カード獲得条件取得パッケージ
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
package DropMinSubject;

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
    
    $self->ResetSubjectValue();
    $self->{DropSubject} = {};
    $self->{SubjectNames} = ["斬術", "突術", "打術", "射撃", "護衛", "舞踊", "盗術", "料理", "工芸", "機動", "化学", "算術", "火術", "神術", "命術", "冥術", "地学", "天文", "風水", "心理", "音楽", "呪術", "幻術", "奇術"];

    #初期化
    $self->{Datas}{Data} = StoreData->new();

    my $header_list = "";
   
    $header_list = [
                "result_no",
                "generate_no",
                "card_id",
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
    $self->{Datas}{Data}->SetOutputName( "./output/chara/drop_min_subject_" . $self->{ResultNo} . "_" . $self->{GenerateNo} . ".csv" );
    $self->ReadLastData();
    return;
}

#-----------------------------------#
#    既存データを読み込む
#-----------------------------------#
sub ReadLastData(){
    my $self      = shift;
    
    # 前回結果の確定版ファイルを探索
    for (my $i=5; $i>=0; $i--){
        my $file_name = "./output/chara/drop_min_subject_" . ($self->{ResultNo} - 1) . "_" . $i . ".csv" ;
        if(-f $file_name) {
            $self->{LastGenerateNo} = $i;    
        }
    }

    my $file_name = "./output/chara/drop_min_subject_" . ($self->{ResultNo} - 1) . "_" . $self->{LastGenerateNo} . ".csv";
    #既存データの読み込み
    my $content = &IO::FileRead ( $file_name );
    
    my @file_data = split(/\n/, $content);
    shift (@file_data);
    
    foreach my  $data_set(@file_data){
        my $data = []; 
        @$data   = split(ConstData::SPLIT, $data_set);
        my $card_id = $$data[2];
        
        my $subject_num = scalar(@{$self->{SubjectNames}});
        $self->{DropSubjects}{$card_id} = {};

        for (my $i=0; $i< $subject_num; $i++) {
            $self->{DropSubjects}{$card_id}{${$self->{SubjectNames}}[$i]} = $$data[$i+3];
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
    my $table_ma_node = shift;
    my $b_re2_nodes = shift;
    
    $self->{ENo} = $e_no;

    $self->ResetSubjectValue();
    $self->GetSubjectData($table_ma_node);
    $self->GetGetCardData($b_re2_nodes);
    
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
        $self->{SubjectValue}{$subject_name} = 99999;
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
    
    #tdの抜出
    foreach my $b_re2_node (@$b_re2_nodes){

        my $b_re2_text = $b_re2_node->as_text;
        if ($b_re2_text =~ /本日の収穫/) {
            $self->GetDropMinSubjectData($b_re2_node);
        }
    }
    return;
}

#-----------------------------------#
#    獲得カードデータ取得
#------------------------------------
#    引数｜太字データノード
#-----------------------------------#
sub GetDropMinSubjectData{
    my $self  = shift;
    my $b_re2_node = shift;

    my @right_nodes = $b_re2_node->right;

    foreach my $right_node (@right_nodes) {
        if ($right_node =~ /HASH/ && ($right_node->tag eq "b" || $right_node->tag eq "hr")) { last;}
        
        my ($effect, $card_id, $lv) = (0, 0, -1);
        if ($right_node =~ /HASH/ && $right_node->tag eq "span" && $right_node->as_text =~ m!(.+?)【(.+?)Lv(\d+?)】!) {
            $effect  = $2;
            $lv      = $3;
            $card_id = $self->{CommonDatas}{CardData}->GetOrAddId(0, [$effect,"", $lv, 0, 0]);

            # 新出カードIDの初期化処理
            if(!exists($self->{DropSubjects}{$card_id})){
                foreach my $subject_name (@{$self->{SubjectNames}}) {
                    $self->{DropSubjects}{$card_id}{$subject_name} = 99999;
                }
            }

            foreach my $subject_name (@{$self->{SubjectNames}}) {
                $self->{DropSubjects}{$card_id}{$subject_name} = ($self->{SubjectValue}{$subject_name} < $self->{DropSubjects}{$card_id}{$subject_name}) ? $self->{SubjectValue}{$subject_name} : $self->{DropSubjects}{$card_id}{$subject_name};
            }
        }
    }
}

#-----------------------------------#
#    出力
#------------------------------------
#    引数｜
#-----------------------------------#
sub Output{
    my $self = shift;
    
    # 取得用ハッシュデータを出力用配列データに変換
    foreach my $card_id (sort keys(%{$self->{DropSubjects}})){
        my $drop_subject = $self->{DropSubjects}{$card_id};

        my @data = ($self->{ResultNo}, $self->{GenerateNo}, $card_id);

        foreach my $subject_name (@{$self->{SubjectNames}}) {
            push (@data, $self->{DropSubjects}{$card_id}{$subject_name});
        }
        $self->{Datas}{Data}->AddData(join(ConstData::SPLIT, @data));
    }

    foreach my $object( values %{ $self->{Datas} } ) {
        $object->Output();
    }
    return;
}
1;
