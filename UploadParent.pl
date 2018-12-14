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

    if (!defined($result_no) || !defined($generate_no)) {
        print "error:empty result_no or generate_no";
        return;
    }

    $upload->DBConnect();
    
    if (ConstData::EXE_DATA) {
        if (ConstData::EXE_DATA_PROPER_NAME) {
            $upload->DeleteAll('proper_names');
            $upload->Upload("./output/data/proper_name.csv", 'proper_names');
        }
        if (ConstData::EXE_DATA_MISSION_NAME) {
            $upload->DeleteAll('mission_names');
            $upload->Upload("./output/data/mission_name.csv", 'mission_names');
        }
        if (ConstData::EXE_DATA_CARD_DATA) {
            $upload->DeleteAll('card_data');
            $upload->Upload("./output/data/card_data.csv", 'card_data');
        }
        if (ConstData::EXE_DATA_FACILITY_DIVISION_DATA) {
            $upload->DeleteAll('facility_division_data');
            $upload->Upload("./output/data/facility_division_data.csv", 'facility_division_data');
        }
    }
    if (ConstData::EXE_CHARA) {
        if (ConstData::EXE_CHARA_NAME) {
            $upload->DeleteSameResult('names', $result_no, $generate_no);
            $upload->Upload("./output/chara/name_" . $result_no . "_" . $generate_no . ".csv", 'names');
        }
        if (ConstData::EXE_CHARA_PROFILE) {
            $upload->DeleteSameResult('profiles', $result_no, $generate_no);
            $upload->Upload("./output/chara/profile_" . $result_no . "_" . $generate_no . ".csv", 'profiles');
        }
        if (ConstData::EXE_CHARA_PGWS) {
            $upload->DeleteSameResult('pgws', $result_no, $generate_no);
            $upload->Upload("./output/chara/pgws_" . $result_no . "_" . $generate_no . ".csv", 'pgws');
        }
        if (ConstData::EXE_CHARA_SUBJECT) {
            $upload->DeleteSameResult('subjects', $result_no, $generate_no);
            $upload->Upload("./output/chara/subject_" . $result_no . "_" . $generate_no . ".csv", 'subjects');
        }
        if (ConstData::EXE_CHARA_PARAMETER_FIGHT) {
            $upload->DeleteSameResult('parameter_fights', $result_no, $generate_no);
            $upload->Upload("./output/chara/parameter_fight_" . $result_no . "_" . $generate_no . ".csv", 'parameter_fights');
        }
        if (ConstData::EXE_CHARA_PARAMETER_CONTROL) {
            $upload->DeleteSameResult('parameter_controls', $result_no, $generate_no);
            $upload->Upload("./output/chara/parameter_control_" . $result_no . "_" . $generate_no . ".csv", 'parameter_controls');
        }
        if (ConstData::EXE_CHARA_PARAMETER_PROGRESS) {
            $upload->DeleteSameResult('parameter_progresses', $result_no, $generate_no);
            $upload->Upload("./output/chara/parameter_progress_" . $result_no . "_" . $generate_no . ".csv", 'parameter_progresses');
        }
        if (ConstData::EXE_CHARA_CHARACTERISTIC) {
            $upload->DeleteSameResult('characteristics', $result_no, $generate_no);
            $upload->Upload("./output/chara/characteristic_" . $result_no . "_" . $generate_no . ".csv", 'characteristics');
        }
        if (ConstData::EXE_CHARA_ITEM) {
            $upload->DeleteSameResult('items', $result_no, $generate_no);
            $upload->Upload("./output/chara/item_" . $result_no . "_" . $generate_no . ".csv", 'items');
        }
        if (ConstData::EXE_CHARA_CARD) {
            $upload->DeleteSameResult('cards', $result_no, $generate_no);
            $upload->Upload("./output/chara/card_" . $result_no . "_" . $generate_no . ".csv", 'cards');
        }
        if (ConstData::EXE_CHARA_FACILITY) {
            $upload->DeleteSameResult('facilities', $result_no, $generate_no);
            $upload->Upload("./output/chara/facility_" . $result_no . "_" . $generate_no . ".csv", 'facilities');
        }
        if (ConstData::EXE_CHARA_GETCARD) {
            $upload->DeleteSameResult('get_cards', $result_no, $generate_no);
            $upload->Upload("./output/chara/get_card_" . $result_no . "_" . $generate_no . ".csv", 'get_cards');
        }
        if (ConstData::EXE_CHARA_DROP_MIN_SUBJECT) {
            $upload->DeleteSameResult('drop_min_subjects', $result_no, $generate_no);
            $upload->Upload("./output/chara/drop_min_subject_" . $result_no . "_" . $generate_no . ".csv", 'drop_min_subjects');
        }
        if (ConstData::EXE_CHARA_PLACE) {
            $upload->DeleteSameResult('places', $result_no, $generate_no);
            $upload->Upload("./output/chara/place_" . $result_no . "_" . $generate_no . ".csv", 'places');
        }
        if (ConstData::EXE_CHARA_DEVELOPMENT_RESULT) {
            $upload->DeleteSameResult('development_results', $result_no, $generate_no);
            $upload->Upload("./output/chara/development_result_" . $result_no . "_" . $generate_no . ".csv", 'development_results');
        }
        if (ConstData::EXE_CHARA_TRAINING) {
            $upload->DeleteSameResult('trainings', $result_no, $generate_no);
            $upload->Upload("./output/chara/training_" . $result_no . "_" . $generate_no . ".csv", 'trainings');
        }
        if (ConstData::EXE_CHARA_ITEM_USE) {
            $upload->DeleteSameResult('item_uses', $result_no, $generate_no);
            $upload->Upload("./output/chara/item_use_" . $result_no . "_" . $generate_no . ".csv", 'item_uses');
        }
        if (ConstData::EXE_CHARA_MISSION) {
            $upload->DeleteSameResult('missions', $result_no, $generate_no);
            $upload->Upload("./output/chara/mission_" . $result_no . "_" . $generate_no . ".csv", 'missions');
        }
        if (ConstData::EXE_CHARA_MANUFACTURE) {
            $upload->DeleteSameResult('manufactures', $result_no, $generate_no);
            $upload->Upload("./output/chara/manufacture_" . $result_no . "_" . $generate_no . ".csv", 'manufactures');
        }
        if (ConstData::EXE_CHARA_FACILITY_USE) {
            $upload->DeleteSameResult('facility_uses', $result_no, $generate_no);
            $upload->Upload("./output/chara/facility_use_" . $result_no . "_" . $generate_no . ".csv", 'facility_uses');
        }
        if (ConstData::EXE_CHARA_BUG) {
            $upload->DeleteSameResult('bugs', $result_no, $generate_no);
            $upload->Upload("./output/chara/bug_" . $result_no . "_" . $generate_no . ".csv", 'bugs');
        }
        if (ConstData::EXE_CHARA_DICE) {
            $upload->DeleteSameResult('dices', $result_no, $generate_no);
            $upload->Upload("./output/chara/dice_" . $result_no . "_" . $generate_no . ".csv", 'dices');
        }
    }
    if (ConstData::EXE_COMMAND) {
        if (ConstData::EXE_COMMAND_ACTION) {
            $upload->DeleteSameResult('command_actions', $result_no, $generate_no);
            $upload->Upload("./output/command/action_" . $result_no . "_" . $generate_no . ".csv", 'command_actions');
        }
        if (ConstData::EXE_COMMAND_ACTION_RANKING) {
            $upload->DeleteSameResult('command_action_rankings', $result_no, $generate_no);
            $upload->Upload("./output/command/action_ranking_" . $result_no . "_" . $generate_no . ".csv", 'command_action_rankings');
        }
        if (ConstData::EXE_COMMAND_PARAMETER_DEVELOPMENT) {
            $upload->DeleteSameResult('parameter_developments', $result_no, $generate_no);
            $upload->Upload("./output/command/parameter_development_" . $result_no . "_" . $generate_no . ".csv", 'parameter_developments');
        }
    }
    if (ConstData::EXE_ALLPRE) {
        if (ConstData::EXE_ALLPRE_PRE_WIN) {
            $upload->DeleteSameResult('pre_wins', $result_no, $generate_no);
            $upload->Upload("./output/all_pre/pre_win_" . $result_no . "_" . $generate_no . ".csv", 'pre_wins');
        }
    }
    if (ConstData::EXE_NEW) {
        if (ConstData::EXE_NEW_GETCARD) {
            $upload->DeleteSameResult('new_get_cards', $result_no, $generate_no);
            $upload->Upload("./output/new/get_card_" . $result_no . "_" . $generate_no . ".csv", 'new_get_cards');
        }
        if (ConstData::EXE_NEW_CARD_USE) {
            $upload->DeleteSameResult('new_card_uses', $result_no, $generate_no);
            $upload->Upload("./output/new/card_use_" . $result_no . "_" . $generate_no . ".csv", 'new_card_uses');
        }
        if (ConstData::EXE_NEW_ITEM_USE) {
            $upload->DeleteSameResult('new_item_uses', $result_no, $generate_no);
            $upload->Upload("./output/new/item_use_" . $result_no . "_" . $generate_no . ".csv", 'new_item_uses');
        }
    }
    if (ConstData::EXE_BATTLE) {
        if (ConstData::EXE_BATTLE_MAX_CHAIN) {
            $upload->DeleteSameResult('max_chains', $result_no, $generate_no);
            $upload->Upload("./output/battle/max_chain_" . $result_no . "_" . $generate_no . ".csv", 'max_chains');
        }
        if (ConstData::EXE_BATTLE_CARD_USE_PAGE) {
            $upload->DeleteSameResult('card_use_pages', $result_no, $generate_no);
            $upload->Upload("./output/battle/card_use_page_" . $result_no . "_" . $generate_no . ".csv", 'card_use_pages');
        }
        if (ConstData::EXE_BATTLE_CARD_USER) {
            $upload->DeleteSameResult('card_users', $result_no, $generate_no);
            $upload->Upload("./output/battle/card_user_" . $result_no . "_" . $generate_no . ".csv", 'card_users');
        }
        if (ConstData::EXE_BATTLE_MEDDLING_SUCCESS_RATE) {
            $upload->DeleteSameResult('meddling_success_rates', $result_no, $generate_no);
            $upload->Upload("./output/battle/meddling_success_rate_" . $result_no . "_" . $generate_no . ".csv", 'meddling_success_rates');
        }
        if (ConstData::EXE_BATTLE_MEDDLING_TARGET) {
            $upload->DeleteSameResult('meddling_targets', $result_no, $generate_no);
            $upload->Upload("./output/battle/meddling_target_" . $result_no . "_" . $generate_no . ".csv", 'meddling_targets');
        }
        if (ConstData::EXE_BATTLE_DAMAGE) {
            $upload->DeleteSameResult('damages', $result_no, $generate_no);
            $upload->Upload("./output/battle/damage_" . $result_no . "_" . $generate_no . ".csv", 'damages');
        }
    }

    print "result_no:$result_no,generate_no:$generate_no\n";
    return;
}
