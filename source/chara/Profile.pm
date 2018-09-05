#===================================================================
#        PC情報取得パッケージ
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
package Profile;

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
    $self->{Datas}{Profile} = StoreData->new();
    $self->{Datas}{PGWS}    = StoreData->new(); # 潜在・得意・苦手・専門学科保存テーブル

    my $header_list = "";
   
    $header_list = [
                "result_no",
                "generate_no",
                "e_no",
                "nickname",
                "tone",
                "first",
                "second",
    ];

    $self->{Datas}{Profile}->Init($header_list);
    
    $header_list = [
                "result_no",
                "generate_no",
                "e_no",
                "pgws_type",   # 1:潜在1、2:潜在2、3:得意属性1、4:得意属性2、5:苦手属性1、6:苦手属性2、7:専門学科1、8:専門学科2
                "pgws_name_id",
    ];

    $self->{Datas}{PGWS}->Init($header_list);

    #出力ファイル設定
    $self->{Datas}{Profile}->SetOutputName( "./output/chara/profile_" . $self->{ResultNo} . "_" . $self->{GenerateNo} . ".csv" );
    $self->{Datas}{PGWS}->SetOutputName( "./output/chara/pgws_" . $self->{ResultNo} . "_" . $self->{GenerateNo} . ".csv" );
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

    $self->GetProfileData($table_in_ma_node);
    
    return;
}
#-----------------------------------#
#    プロフィールデータ取得
#------------------------------------
#    引数｜PCデータノード
#-----------------------------------#
sub GetProfileData{
    my $self  = shift;
    my $table_in_ma_node = shift;
    my ($nickname, $tone, $first, $second) = ("", "", "", "");
    
    # tdの抽出
    my $td_nodes = &GetNode::GetNode_Tag("td",\$table_in_ma_node);
 
    foreach my $td_node(@$td_nodes){    
        my $td_text = $td_node->as_text;
        my $right = $td_node->right;
        my $right_text = ($right && $right =~ /HASH/) ? $right->as_text : $right;

        if($td_text eq "愛称"){
            $nickname    = $right_text;

        }elsif($td_text eq "口調"){
            if ($right_text =~ /(.+?) \/ (.+?) \/ (.+?)$/) {
                $tone = $self->{CommonDatas}{ProperName}->GetOrAddId($1);
                $first  = $2;
                $second = $3;
            }

        }elsif($td_text eq "Main"){
            my $pgws_id = $self->{CommonDatas}{ProperName}->GetOrAddId($right_text);
            $self->{Datas}{PGWS}->AddData(join(ConstData::SPLIT, ($self->{ResultNo}, $self->{GenerateNo}, $self->{ENo}, 1, $pgws_id)));

        }elsif($td_text eq "Sub"){
            my $pgws_id = $self->{CommonDatas}{ProperName}->GetOrAddId($right_text);
            $self->{Datas}{PGWS}->AddData(join(ConstData::SPLIT, ($self->{ResultNo}, $self->{GenerateNo}, $self->{ENo}, 2, $pgws_id)));

        }elsif($td_text eq "Good"){
            my $pgws_id  = 0;

            $right_text =~ /(.+?) (.+?)$/;
            my $good_1  = $1;
            my $good_2  = $2;
            
            $pgws_id = $self->{CommonDatas}{ProperName}->GetOrAddId($good_1);
            $self->{Datas}{PGWS}->AddData(join(ConstData::SPLIT, ($self->{ResultNo}, $self->{GenerateNo}, $self->{ENo}, 3, $pgws_id)));

            $pgws_id = $self->{CommonDatas}{ProperName}->GetOrAddId($good_2);
            $self->{Datas}{PGWS}->AddData(join(ConstData::SPLIT, ($self->{ResultNo}, $self->{GenerateNo}, $self->{ENo}, 4, $pgws_id)));

        }elsif($td_text eq "Weak"){
            my $pgws_id  = 0;

            $right_text =~ /(.+?) (.+?)$/;
            my $weak_1  = $1;
            my $weak_2  = $2;
            
            $pgws_id = $self->{CommonDatas}{ProperName}->GetOrAddId($weak_1);
            $self->{Datas}{PGWS}->AddData(join(ConstData::SPLIT, ($self->{ResultNo}, $self->{GenerateNo}, $self->{ENo}, 5, $pgws_id)));

            $pgws_id = $self->{CommonDatas}{ProperName}->GetOrAddId($weak_2);
            $self->{Datas}{PGWS}->AddData(join(ConstData::SPLIT, ($self->{ResultNo}, $self->{GenerateNo}, $self->{ENo}, 6, $pgws_id)));

        }elsif($td_text eq "専門"){
            my $pgws_id  = 0;

            $right_text =~ /(.+?) (.+?)$/;
            my $speciality_1  = $1;
            my $speciality_2  = $2;
            
            $pgws_id = $self->{CommonDatas}{ProperName}->GetOrAddId($speciality_1);
            $self->{Datas}{PGWS}->AddData(join(ConstData::SPLIT, ($self->{ResultNo}, $self->{GenerateNo}, $self->{ENo}, 7, $pgws_id)));

            $pgws_id = $self->{CommonDatas}{ProperName}->GetOrAddId($speciality_2);
            $self->{Datas}{PGWS}->AddData(join(ConstData::SPLIT, ($self->{ResultNo}, $self->{GenerateNo}, $self->{ENo}, 8, $pgws_id)));

        }
    }

    my @datas=($self->{ResultNo}, $self->{GenerateNo}, $self->{ENo}, $nickname, $tone, $first, $second);
    $self->{Datas}{Profile}->AddData(join(ConstData::SPLIT, @datas));

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
