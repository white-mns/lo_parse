#===================================================================
#        BUG出現情報取得パッケージ
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
package Bug;

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
    $self->{Datas}{Bug}     = StoreData->new();
    $self->{Datas}{BugName} = StoreData->new();
    $self->{Bug} = [];

    my $header_list = "";
   
    $header_list = [
                "result_no",
                "generate_no",
                "e_no",
                "bug_e_no",
                "lv",
    ];

    $self->{Datas}{Bug}->Init($header_list);
   
    $header_list = [
                "name",
                "e_no",
                "icon_url",
    ];

    $self->{Datas}{BugName}->Init($header_list);

    #出力ファイル設定
    $self->{Datas}{Bug}->SetOutputName( "./output/chara/bug_" . $self->{ResultNo} . "_" . $self->{GenerateNo} . ".csv" );
    $self->{Datas}{BugName}->SetOutputName( "./output/data/bug_name.csv" );
    
    $self->ReadBugNameData();

    return;
}

#-----------------------------------#
#    既存データを読み込む
#-----------------------------------#
sub ReadBugNameData(){
    my $self      = shift;
    
    my $file_name = "./output/data/bug_name.csv" ;
    
    #既存データの読み込み
    my $content = &IO::FileRead ( $file_name );
    
    my @file_data = split(/\n/, $content);
    shift (@file_data);
    
    foreach my  $data_set(@file_data) {
        my $datas = []; 
        @$datas   = split(ConstData::SPLIT, $data_set);
        my $name = $$datas[0];
        if(!exists($self->{BugName}{$name})){
            $self->{BugName}{$name} = [[$$datas[1], $$datas[2]]];
        }else{
            $self->AddBugName($name, $$datas[1], $$datas[2]);
        }
    }

    return;
}

#-----------------------------------#
#    BUG名追加
#------------------------------------
#    引数｜BUG名,名前
#-----------------------------------#
sub AddBugName{
    my $self = shift;
    my $name = shift;
    my $add_e_no = shift;
    my $add_icon_url = shift;

    # 名前に対応する同じENoとアイコンアドレスの組み合わせが既にあれば追加しない
    foreach my $data (@{ $self->{BugName}{$name} }) {
        if ($add_e_no == $$data[0] && $add_icon_url eq $$data[1]) {
            return;
        }
    }
    push (@{ $self->{BugName}{$name} }, [$add_e_no, $add_icon_url]);
}

#-----------------------------------#
#    データ取得
#------------------------------------
#    引数｜e_no,名前データノード
#-----------------------------------#
sub GetData{
    my $self = shift;
    my $e_no    = shift;
    my $bug_color2_nodes = shift;
    
    $self->{ENo} = $e_no;

    $self->GetBugData($bug_color2_nodes);
   
    return;
}

#-----------------------------------#
#    BUGデータ取得
#------------------------------------
#    引数｜Pno
#           データノード
#-----------------------------------#
sub GetBugData{
    my $self = shift;
    my $bug_color2_nodes = shift; 

    foreach my $bug_color2_node (@$bug_color2_nodes) {
        if ($bug_color2_node->as_text eq "BUG") {
            $self->GetBugName($bug_color2_node);
            $self->GetBugAppearance($bug_color2_node);
        }
    }
    
    return;
}

#-----------------------------------#
#    BUG出現データ取得
#------------------------------------
#    引数｜Pno
#           データノード
#-----------------------------------#
sub GetBugName{
    my $self = shift;
    my $bug_color2_node = shift; 

    foreach my $node (reverse $bug_color2_node->left) {
        if ($node =~ /HASH/ && $node->tag eq "hr") { last;}
        if ($node =~ /HASH/ && $node->tag eq "a" && $node->as_text =~ /(.+)\(Pn(\d+)\)/) {
            my $name = $1;
            $node->attr("href") =~ /Eno(\d+)\.html/;
            my $e_no = $1;
            $self->AddBugName($name, $e_no, $node->left->attr("src"));
        }
    }
    
    return;
}

#-----------------------------------#
#    BUG出現データ取得
#------------------------------------
#    引数｜Pno
#           データノード
#-----------------------------------#
sub GetBugAppearance{
    my $self = shift;
    my $bug_color2_node = shift; 

    my $last_node = "";
    foreach my $node ($bug_color2_node->right) {
        if ($node =~ /HASH/ && $node->tag eq "div") { last;}
        if ($node =~ /(.+)\(Lv(\d+)\)/) {
            my $name = $1;
            my $lv   = $2;
            if($last_node =~ /HASH/) {
                push (@{ $self->{Bug} }, [$self->{ENo}, $name, $lv, $last_node->attr("src")]);
            }
        }
        $last_node = $node;
    }
    
    return;
}
#-----------------------------------#
#    バグ名からEnoを照合する
#------------------------------------
#    引数｜Pno
#           データノード
#-----------------------------------#
sub GetBugEno{
    my $self = shift;
    my $name = shift;
    my $icon_url = shift;

    foreach my $data (@{ $self->{BugName}{$name} }) {
        if ($icon_url eq $$data[1]) {
            return $$data[0];
        }
    }
    return 0;
}
#-----------------------------------#
#    出力
#------------------------------------
#    引数｜
#-----------------------------------#
sub Output{
    my $self = shift;
    
    # 全BUG情報の書き出し
    foreach my $name (sort{$a cmp $b} keys %{ $self->{BugName} } ) {
        foreach my $data ( @{ $self->{BugName}{$name} } ) {
            $self->{Datas}{BugName}->AddData(join(ConstData::SPLIT, ($name, $$data[0], $$data[1]) ));
        }
    }

    # 新出データ判定用の既出全取得カード情報の書き出し
    foreach my $data (@{ $self->{Bug} } ) {
        my $bug_e_no = $self->GetBugEno($$data[1], $$data[3]);
        $self->{Datas}{Bug}->AddData(join(ConstData::SPLIT, ($self->{ResultNo}, $self->{GenerateNo}, $$data[0], $bug_e_no, $$data[2]) ));
    }

    foreach my $object( values %{ $self->{Datas} } ) {
        $object->Output();
    }
    return;
}
1;
