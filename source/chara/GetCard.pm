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
package GetCard;

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
                "name",
                "card_id",
                "get_type",
    ];

    $self->{Datas}{Data}->Init($header_list);
    
    #出力ファイル設定
    $self->{Datas}{Data}->SetOutputName( "./output/chara/get_card_" . $self->{ResultNo} . "_" . $self->{GenerateNo} . ".csv" );
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

    $self->GetGetCardData($b_re2_nodes);
    
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
    
    foreach my $b_re2_node (@$b_re2_nodes){

        my $b_re2_text = $b_re2_node->as_text;
        if ($b_re2_text =~ /スキルカード生成/) {
            $self->GetCreateCardData($b_re2_node);
            
        }elsif ($b_re2_text =~ /本日の収穫/) {
            $self->GetDropCardData($b_re2_node);
        }
    }


    return;
}

#-----------------------------------#
#    生成カードデータ取得
#------------------------------------
#    引数｜太字データノード
#-----------------------------------#
sub GetCreateCardData{
    my $self  = shift;
    my $b_re2_node = shift;

    my @right_nodes = $b_re2_node->right;
    my ($name, $effect, $card_id, $lv, $get_type) = ("", 0, 0, -1, -1);

    foreach my $right_node (@right_nodes) {
        if ($right_node =~ /HASH/ && ($right_node->tag eq "b" || $right_node->tag eq "hr")) { last;}

        if ($right_node =~ /HASH/ && $right_node->tag eq "span") {
            $name = $right_node->as_text;

        }elsif ($right_node =~ m!生成に成功♪（\+Sno\d+?：(.+?) Lv(\d+?)）!) {
            $effect  = $1;
            $lv      = $2;
            $card_id = $self->{CommonDatas}{CardData}->GetOrAddId(0, [$effect,"", $lv, 0, 0]);

            my @datas=($self->{ResultNo}, $self->{GenerateNo}, $self->{ENo}, $name, $card_id, 1);
            $self->{Datas}{Data}->AddData(join(ConstData::SPLIT, @datas));
            ($name, $effect, $card_id, $lv, $get_type) = ("", 0, 0, -1, -1);

        }elsif ($right_node =~ m!しかしカードは生成できなかった。!) {
            $effect  = "";
            $lv      = -1;
            $card_id = 0;

            my @datas=($self->{ResultNo}, $self->{GenerateNo}, $self->{ENo}, $name, $card_id, 0);
            $self->{Datas}{Data}->AddData(join(ConstData::SPLIT, @datas));
            ($name, $effect, $card_id, $lv, $get_type) = ("", 0, 0, -1, -1);
        }
    }
}

#-----------------------------------#
#    獲得カードデータ取得
#------------------------------------
#    引数｜太字データノード
#-----------------------------------#
sub GetDropCardData{
    my $self  = shift;
    my $b_re2_node = shift;

    my @right_nodes = $b_re2_node->right;
    my ($name, $effect, $card_id, $lv, $get_type) = ("", 0, 0, -1, -1);

    foreach my $right_node (@right_nodes) {
        if ($right_node =~ /HASH/ && ($right_node->tag eq "b" || $right_node->tag eq "hr")) { last;}

        if ($right_node =~ /HASH/ && $right_node->tag eq "span" && $right_node->as_text =~ m!(.+?)【(.+?)Lv(\d+?)】!) {
            $name    = $1;
            $effect  = $2;
            $lv      = $3;
            $card_id = $self->{CommonDatas}{CardData}->GetOrAddId(0, [$effect,"", $lv, 0, 0]);

            my @datas=($self->{ResultNo}, $self->{GenerateNo}, $self->{ENo}, $name, $card_id, 2);
            $self->{Datas}{Data}->AddData(join(ConstData::SPLIT, @datas));
            ($name, $effect, $card_id, $lv, $get_type) = ("", 0, 0, -1, -1);
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
    
    foreach my $object( values %{ $self->{Datas} } ) {
        $object->Output();
    }
    return;
}
1;
