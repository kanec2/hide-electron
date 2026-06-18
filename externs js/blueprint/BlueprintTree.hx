package hide.infrastructure.external.blueprint;

import react.ReactComponent;

@:jsRequire("@blueprintjs/core", "Tree")
extern class Tree extends ReactComponentOfProps<TreeProps> {}

typedef TreeProps = {
    var contents:Array<TreeNode>;
    var ?onNodeClick:TreeNode->Array<Int>->Dynamic->Void;
    var ?onNodeCollapse:TreeNode->Array<Int>->Dynamic->Void;
    var ?onNodeExpand:TreeNode->Array<Int>->Dynamic->Void;
    var ?onNodeContextMenu:TreeNode->Array<Int>->Dynamic->Void;
    var ?onNodeDoubleClick:TreeNode->Array<Int>->Dynamic->Void;
    var ?onNodeMouseEnter:TreeNode->Array<Int>->Dynamic->Void;
    var ?onNodeMouseLeave:TreeNode->Array<Int>->Dynamic->Void;
    var ?className:String;
}

typedef TreeNode = {
    var id:Dynamic; // String | Int
    var label:Dynamic; // String | ReactElement
    var ?icon:String;
    var ?secondaryLabel:Dynamic;
    var ?isExpanded:Bool;
    var ?isSelected:Bool;
    var ?disabled:Bool;
    var ?className:String;
    var ?childNodes:Array<TreeNode>;
}