#===================================================================
#        スクレイピング用基本パッケージ
#-------------------------------------------------------------------
#            (C) 2014 @white_mns
#===================================================================

package GetNode;
use HTML::TreeBuilder;

#-----------------------------------#
#    ノードの取得
#-----------------------------------#
#    引数｜タグ名、cellpading数
#-----------------------------------#
sub GetNode_Tag_CellPadding {
    my $tag_name        = shift;
    my $attr_cellpadding = shift;
    my $node            = shift;
    
    my $return_nodes    = [];
    
    #各メニュー情報の抜出
    @$return_nodes = $$node->look_down(
                _tag => $tag_name,
                sub {
                    if( $_[0]->attr('cellpadding')){
                        $_[0]->attr('cellpadding') eq $attr_cellpadding
                    }
                }
    );
    return $return_nodes;
}

#-----------------------------------#
#    ノードの取得
#-----------------------------------#
#    引数｜タグ名、色
#-----------------------------------#
sub GetNode_Tag_Color {
    my $tag_name  = shift;
    my $attr_color= shift;
    my $node      = shift;
    
    my $return_nodes    = [];
    
    #各メニュー情報の抜出
    @$return_nodes = $$node->look_down(
                _tag => $tag_name,
                sub {
                    if( $_[0]->attr('color')){
                        $_[0]->attr('color')    eq $attr_color
                    }
                }
    );
    return $return_nodes;
}


#-----------------------------------#
#    ノードの取得
#-----------------------------------#
#    引数｜タグ名、ID名
#-----------------------------------#
sub GetNode_Tag_Id {
    my $tag_name  = shift;
    my $attr_id    = shift;
    my $node      = shift;
    
    my $return_nodes    = [];
    
    #各メニュー情報の抜出
    @$return_nodes = $$node->look_down(
                _tag => $tag_name,
                sub {
                    if( $_[0]->attr('id')){
                        $_[0]->attr('id')    eq $attr_id
                    }
                }
    );
    return $return_nodes;
}

#-----------------------------------#
#    ノードの取得
#-----------------------------------#
#    引数｜タグ名、name
#-----------------------------------#
sub GetNode_Tag_Name {
    my $tag_name   = shift;
    my $attr_name  = shift;
    my $node       = shift;
    
    my $return_nodes    = [];
    
    #各メニュー情報の抜出
    @$return_nodes = $$node->look_down(
                _tag => $tag_name,
                sub {
                    if( $_[0]->attr('name')){
                        $_[0]->attr('name')    eq $attr_name
                    }
                }
    );
    return $return_nodes;
}


#-----------------------------------#
#    ノードの取得
#-----------------------------------#
#    引数｜タグ名、クラス名
#-----------------------------------#
sub GetNode_Tag_Class {
    my $tag_name   = shift;
    my $attr_class  = shift;
    my $node       = shift;
    
    my $return_nodes    = [];
    
    #各メニュー情報の抜出
    @$return_nodes = $$node->look_down(
                _tag => $tag_name,
                sub {
                    if( $_[0]->attr('class')){
                        $_[0]->attr('class')    eq $attr_class
                    }
                }
    );
    return $return_nodes;
}

#-----------------------------------#
#    ノードの取得
#-----------------------------------#
#    引数｜タグ名、クラス名
#-----------------------------------#
sub GetNode_Tag_ClassName {
    my $tag_name   = shift;
    my $attr_class  = shift;
    my $attr_name   = shift;
    my $node       = shift;
    
    my $return_nodes    = [];
    
    #各メニュー情報の抜出
    @$return_nodes = $$node->look_down(
                _tag => $tag_name,
                sub {
                    if( $_[0]->attr('class') && $_[0]->attr('name')){
                        $_[0]->attr('class')   eq $attr_class &&
                        $_[0]->attr('name')    eq $attr_name;
                    }
                }
    );
    return $return_nodes;
}
#-----------------------------------#
#    ノードの取得
#-----------------------------------#
#    引数｜タグ名
#-----------------------------------#
sub GetNode_Tag {
    my $tag_name  = shift;
    my $node      = shift;
    
    my $return_nodes            = [];
    
    #各メニュー情報の抜出
    @$return_nodes = $$node->look_down(
                _tag => $tag_name,
    );
    return $return_nodes;
}

1;
