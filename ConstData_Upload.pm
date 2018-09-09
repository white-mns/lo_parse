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
    
    use constant EXE_DATA        => 1;
        use constant EXE_DATA_PROPER_NAME => 1;
        use constant EXE_DATA_CARD_DATA   => 1;
    use constant EXE_CHARA       => 1;
        use constant EXE_CHARA_NAME               => 1;
        use constant EXE_CHARA_PROFILE            => 1;
        use constant EXE_CHARA_PGWS               => 1;
        use constant EXE_CHARA_SUBJECT            => 1;
        use constant EXE_CHARA_PARAMETER_FIGHT    => 1;
        use constant EXE_CHARA_PARAMETER_CONTROL  => 1;
        use constant EXE_CHARA_PARAMETER_PROGRESS => 1;
        use constant EXE_CHARA_CHARACTERISTIC     => 1;
        use constant EXE_CHARA_ITEM               => 1;
        use constant EXE_CHARA_CARD               => 1;
        use constant EXE_CHARA_FACILITY           => 1;
        use constant EXE_CHARA_GETCARD            => 1;
        use constant EXE_CHARA_DROP_MIN_SUBJECT   => 1;
        use constant EXE_CHARA_PLACE              => 1;
        use constant EXE_CHARA_DEVELOPMENT_RESULT => 1;

1;
