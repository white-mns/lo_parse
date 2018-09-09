#===================================================================
#    データベースへのアップロード
#-------------------------------------------------------------------
#        (C) 2018 @white_mns
#===================================================================

# モジュール呼び出し    ---------------#
require "./source/Upload.pm";
require "./source/lib/time.pm";

# パッケージの使用宣言    ---------------#
use strict;
use warnings;
require LWP::UserAgent;
use HTTP::Request;
use HTTP::Response;

# 変数の初期化    ---------------#
use ConstData_Upload;        #定数呼び出し

my $timeChecker = TimeChecker->new();

# 実行部    ---------------------------#
$timeChecker->CheckTime("start  \t");

&Main;

$timeChecker->CheckTime("end    \t");
$timeChecker->OutputTime();
$timeChecker = undef;

# 宣言部    ---------------------------#

sub Main {
    my $result_no = $ARGV[0];
    my $generate_no = $ARGV[1];
    my $upload = Upload->new();

    if(!defined($result_no) || !defined($generate_no)){
        print "error:empty result_no or generate_no";
        return;
    }

    $upload->DBConnect();
    
    if(ConstData::EXE_DATA){
        if(ConstData::EXE_DATA_PROPER_NAME){
            $upload->DeleteAll('proper_names');
            $upload->Upload("./output/data/proper_name.csv", 'proper_names');
        }
        if(ConstData::EXE_DATA_CARD_DATA){
            $upload->DeleteAll('card_data');
            $upload->Upload("./output/data/card_data.csv", 'card_data');
        }
    }
    if(ConstData::EXE_CHARA){
        if(ConstData::EXE_CHARA_NAME){
            $upload->DeleteSameResult('names', $result_no, $generate_no);
            $upload->Upload("./output/chara/name_" . $result_no . "_" . $generate_no . ".csv", 'names');
        }
        if(ConstData::EXE_CHARA_PROFILE){
            $upload->DeleteSameResult('profiles', $result_no, $generate_no);
            $upload->Upload("./output/chara/profile_" . $result_no . "_" . $generate_no . ".csv", 'profiles');
        }
        if(ConstData::EXE_CHARA_PGWS){
            $upload->DeleteSameResult('pgws', $result_no, $generate_no);
            $upload->Upload("./output/chara/pgws_" . $result_no . "_" . $generate_no . ".csv", 'pgws');
        }
        if(ConstData::EXE_CHARA_SUBJECT){
            $upload->DeleteSameResult('subjects', $result_no, $generate_no);
            $upload->Upload("./output/chara/subject_" . $result_no . "_" . $generate_no . ".csv", 'subjects');
        }
        if(ConstData::EXE_CHARA_PARAMETER_FIGHT){
            $upload->DeleteSameResult('parameter_fights', $result_no, $generate_no);
            $upload->Upload("./output/chara/parameter_fight_" . $result_no . "_" . $generate_no . ".csv", 'parameter_fights');
        }
        if(ConstData::EXE_CHARA_PARAMETER_CONTROL){
            $upload->DeleteSameResult('parameter_controls', $result_no, $generate_no);
            $upload->Upload("./output/chara/parameter_control_" . $result_no . "_" . $generate_no . ".csv", 'parameter_controls');
        }
        if(ConstData::EXE_CHARA_PARAMETER_PROGRESS){
            $upload->DeleteSameResult('parameter_progresses', $result_no, $generate_no);
            $upload->Upload("./output/chara/parameter_progress_" . $result_no . "_" . $generate_no . ".csv", 'parameter_progresses');
        }
        if(ConstData::EXE_CHARA_CHARACTERISTIC){
            $upload->DeleteSameResult('characteristics', $result_no, $generate_no);
            $upload->Upload("./output/chara/characteristic_" . $result_no . "_" . $generate_no . ".csv", 'characteristics');
        }
        if(ConstData::EXE_CHARA_ITEM){
            $upload->DeleteSameResult('items', $result_no, $generate_no);
            $upload->Upload("./output/chara/item_" . $result_no . "_" . $generate_no . ".csv", 'items');
        }
        if(ConstData::EXE_CHARA_CARD){
            $upload->DeleteSameResult('cards', $result_no, $generate_no);
            $upload->Upload("./output/chara/card_" . $result_no . "_" . $generate_no . ".csv", 'cards');
        }
        if(ConstData::EXE_CHARA_FACILITY){
            $upload->DeleteSameResult('facilities', $result_no, $generate_no);
            $upload->Upload("./output/chara/facility_" . $result_no . "_" . $generate_no . ".csv", 'facilities');
        }
        if(ConstData::EXE_CHARA_GETCARD){
            $upload->DeleteSameResult('get_cards', $result_no, $generate_no);
            $upload->Upload("./output/chara/get_card_" . $result_no . "_" . $generate_no . ".csv", 'get_cards');
        }
        if(ConstData::EXE_CHARA_DROP_MIN_SUBJECT){
            $upload->DeleteSameResult('drop_min_subjects', $result_no, $generate_no);
            $upload->Upload("./output/chara/drop_min_subject_" . $result_no . "_" . $generate_no . ".csv", 'drop_min_subjects');
        }
    }

    print "result_no:$result_no,generate_no:$generate_no\n";
    return;
}
