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
#    引数｜タグ名、color、size
#-----------------------------------#
sub GetNode_Tag_ColorSize {
    my $tag_name        = shift;
    my $attr_color      = shift;
    my $attr_size       = shift;
    my $node            = shift;
    
    my $return_nodes    = [];
    
    #各メニュー情報の抜出
    @$return_nodes = $$node->look_down(
                _tag => $tag_name,
                sub {
                    if( $_[0]->attr('color') && $_[0]->attr('size')){
                        $_[0]->attr('color') eq $attr_color &&
                        $_[0]->attr('size') eq $attr_size
                    }
                }
    );
    return $return_nodes;
}


#-----------------------------------#
#    ノードの取得
#-----------------------------------#
#    引数｜タグ名、color
#-----------------------------------#
sub GetNode_Tag_Color_NoSize {
    my $tag_name        = shift;
    my $attr_color      = shift;
    my $node            = shift;
    
    my $return_nodes    = [];
    
    #各メニュー情報の抜出
    @$return_nodes = $$node->look_down(
                _tag => $tag_name,
                sub {
                    if( $_[0]->attr('color') && !$_[0]->attr('size')){
                        $_[0]->attr('color') eq $attr_color
                    }
                }
    );
    return $return_nodes;
}

#-----------------------------------#
#    ノードの取得
#-----------------------------------#
#    引数｜タグ名、属性名、条件
#-----------------------------------#
sub GetNode_Tag_Attr {
    my $tag_name   = shift;
    my $attr_name  = shift;
    my $attr_value = shift;
    my $node       = shift;
    
    my $return_nodes    = [];
    
    if (!$$node) {
        print "Warning: Use of uninitialized node [GetNode_Tag_Attr:$tag_name, $attr_name, $attr_value]\n";
        return $return_nodes;
    }

    #各メニュー情報の抜出
    @$return_nodes = $$node->look_down(
                _tag => $tag_name,
                sub {
                    if( $_[0]->attr($attr_name)){
                        $_[0]->attr($attr_name) eq $attr_value
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
    
    if (!$$node) {
        print "Warning: Use of uninitialized node [GetNode_Tag:$tag_name]\n";
        return $return_nodes;
    }

    #各メニュー情報の抜出
    @$return_nodes = $$node->look_down(
                _tag => $tag_name,
    );
    return $return_nodes;
}

1;
