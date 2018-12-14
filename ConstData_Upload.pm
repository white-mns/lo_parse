#===================================================================
#        定数設定
#-------------------------------------------------------------------
#            (C) 2018 @white_mns
#===================================================================

# パッケージの定義    ---------------#    
package ConstData;

# パッケージの使用宣言    ---------------#
use strict;
use warnings;

# 定数宣言    ---------------#
    use constant SPLIT        => "\t";    # 区切り文字

# ▼ 実行制御 =============================================
#      実行する場合は 1 ，実行しない場合は 0 ．
    
    use constant EXE_DATA                    => 1;
        use constant EXE_DATA_PROPER_NAME              => 1;
        use constant EXE_DATA_CARD_DATA                => 1;
        use constant EXE_DATA_FACILITY_DIVISION_DATA   => 1;
        use constant EXE_DATA_MISSION_NAME             => 1;
    use constant EXE_CHARA                   => 1;
        use constant EXE_CHARA_NAME                    => 1;
        use constant EXE_CHARA_PROFILE                 => 1;
        use constant EXE_CHARA_PGWS                    => 1;
        use constant EXE_CHARA_SUBJECT                 => 1;
        use constant EXE_CHARA_PARAMETER_FIGHT         => 1;
        use constant EXE_CHARA_PARAMETER_CONTROL       => 1;
        use constant EXE_CHARA_PARAMETER_PROGRESS      => 1;
        use constant EXE_CHARA_CHARACTERISTIC          => 1;
        use constant EXE_CHARA_ITEM                    => 1;
        use constant EXE_CHARA_CARD                    => 1;
        use constant EXE_CHARA_FACILITY                => 1;
        use constant EXE_CHARA_GETCARD                 => 1;
        use constant EXE_CHARA_DROP_MIN_SUBJECT        => 1;
        use constant EXE_CHARA_PLACE                   => 1;
        use constant EXE_CHARA_DEVELOPMENT_RESULT      => 1;
        use constant EXE_CHARA_TRAINING                => 1;
        use constant EXE_CHARA_ITEM_USE                => 1;
        use constant EXE_CHARA_MISSION                 => 1;
        use constant EXE_CHARA_MANUFACTURE             => 1;
        use constant EXE_CHARA_FACILITY_USE            => 1;
        use constant EXE_CHARA_BUG                     => 1;
        use constant EXE_CHARA_DICE                    => 1;
    use constant EXE_ALLPRE                  => 1;
        use constant EXE_ALLPRE_PRE_WIN                => 1;
    use constant EXE_BATTLE                  => 1;
        use constant EXE_BATTLE_CARD_USE_PAGE          => 1;
        use constant EXE_BATTLE_CARD_USER              => 1;
        use constant EXE_BATTLE_MAX_CHAIN              => 1;
        use constant EXE_BATTLE_MEDDLING_SUCCESS_RATE  => 1;
        use constant EXE_BATTLE_MEDDLING_TARGET        => 1;
        use constant EXE_BATTLE_DAMAGE                 => 1;
    use constant EXE_NEW                     => 1;
        use constant EXE_NEW_GETCARD                   => 1;
        use constant EXE_NEW_CARD_USE                  => 1;
        use constant EXE_NEW_ITEM_USE                  => 1;
    use constant EXE_COMMAND                 => 1;
        use constant EXE_COMMAND_ACTION                => 1;
        use constant EXE_COMMAND_ACTION_RANKING        => 1;
        use constant EXE_COMMAND_PARAMETER_DEVELOPMENT => 1;

1;
