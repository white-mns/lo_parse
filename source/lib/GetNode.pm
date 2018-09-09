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
#    引数｜タグ名、ID名
#-----------------------------------#
sub GetNode_Tag_Id {
    my $tag_name  = shift;
    my $attr_id    = shift;
    my $node      = shift;
    
    my $return_nodes    = [];
    
    if (!$$node) {
        print "Warning: Use of uninitialized node [GetNode_Tag_Id:$tag_name, $attr_id]\n";
        return $return_nodes;
    }

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
#    引数｜タグ名、クラス名
#-----------------------------------#
sub GetNode_Tag_Class {
    my $tag_name   = shift;
    my $attr_class  = shift;
    my $node       = shift;
    
    my $return_nodes    = [];
    
    if (!$$node) {
        print "Warning: Use of uninitialized node [GetNode_Tag_Class:$tag_name, $attr_class]\n";
        return $return_nodes;
    }

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
    
    if (!$$node) {
        print "Warning: Use of uninitialized node [GetNode_Tag_ClassName:$tag_name, $attr_class, $attr_name]\n";
        return $return_nodes;
    }

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
