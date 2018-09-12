#===================================================================
#        固有名詞管理パッケージ
#-------------------------------------------------------------------
#            (C) 2018 @white_mns
#===================================================================


# パッケージの使用宣言    ---------------#
use strict;
use warnings;

use ConstData;
use HTML::TreeBuilder;
use source::lib::GetNode;

require "./source/lib/IO.pm";
require "./source/lib/time.pm";
require "./source/lib/NumCode.pm";

require "./source/data/StoreProperName.pm";
require "./source/data/StoreProperData.pm";
require "./source/data/StoreProperCardData.pm";

use ConstData;        #定数呼び出し

#------------------------------------------------------------------#
#    パッケージの定義
#------------------------------------------------------------------#
package ProperName;

#-----------------------------------#
#    コンストラクタ
#-----------------------------------#
sub new {
  my $class        = shift;

  bless {
    Datas         => {},
    DataHandlers  => {},
    Methods       => {},
  }, $class;
}

#-----------------------------------#
#    初期化
#-----------------------------------#
sub Init{
    my $self = shift;
    ($self->{ResultNo}, $self->{GenerateNo}, $self->{CommonDatas}) = @_;

    #インスタンス作成
    $self->{DataHandlers}{ProperName}           = StoreProperName->new();
    $self->{DataHandlers}{CardData}             = StoreProperCardData->new();
    $self->{DataHandlers}{FacilityDivisionData} = StoreProperData->new();

    #他パッケージへの引き渡し用インスタンス
    $self->{CommonDatas}{ProperName}           = $self->{DataHandlers}{ProperName};
    $self->{CommonDatas}{CardData}             = $self->{DataHandlers}{CardData};
    $self->{CommonDatas}{FacilityDivisionData} = $self->{DataHandlers}{FacilityDivisionData};

    my $header_list = "";
    my $output_file = "";

    # 固有名詞の初期化
    $header_list = [
                "proper_id",
                "name",
    ];
    $output_file = "./output/data/". "proper_name" . ".csv";
    $self->{DataHandlers}{ProperName}->Init($header_list, $output_file," ");
    
    # カード情報の初期化
    $header_list = [
                "card_id",
                "name",
                "kind",
                "lv",
                "lp",
                "fp",
    ];
    $output_file = "./output/data/". "card_data" . ".csv";
    $self->{DataHandlers}{CardData}->Init($header_list, $output_file, [" ", -1, -1, -1, -1]);

    # 施設区分情報の初期化
    $header_list = [
                "division_id",
                "detail",
                "major",
    ];
    $output_file = "./output/data/". "facility_division_data" . ".csv";
    $self->{DataHandlers}{FacilityDivisionData}->Init($header_list, $output_file, [0, 0]);

    return;
}

#-----------------------------------#
#   このパッケージでデータ解析はしない
#-----------------------------------#
#    
#-----------------------------------#
sub Execute{
    my $self        = shift;
    return ;
}

#-----------------------------------#
#    出力
#-----------------------------------#
#    引数｜ファイルアドレス
#-----------------------------------#
sub Output{
    my $self = shift;
    foreach my $object( values %{ $self->{Datas} } ) {
        $object->Output();
    }
    foreach my $object( values %{ $self->{DataHandlers} } ) {
        $object->Output();
    }
    return;
}

1;
