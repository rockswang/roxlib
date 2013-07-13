package com.roxstudio.haxe.ui;

import com.roxstudio.haxe.gesture.RoxGestureEvent;
import com.roxstudio.haxe.gesture.RoxGestureAgent;
import com.roxstudio.haxe.game.GameUtil;
import com.roxstudio.haxe.ui.RoxNinePatchData;
import com.roxstudio.haxe.ui.UiUtil;
import nme.events.MouseEvent;
import nme.geom.Rectangle;
import nme.display.DisplayObject;
import nme.display.Sprite;

using com.roxstudio.haxe.ui.UiUtil;

class RoxFlowPane extends Sprite {

    public var anchor(default, set_anchor): Int;
    public var length(default, null): Int;

    private static inline var DEFAULT_GAP = 4.0;

    private var bg: RoxNinePatch;
    private var content: DisplayObject;

    public function new(?width: Null<Float>, ?height: Null<Float>, ?anchor: Int = UiUtil.TOP_LEFT,
                        children: Array<DisplayObject>, ?bg: RoxNinePatch,
                        ?childrenAlign: Int = UiUtil.VCENTER, ?gaps: Array<Float>,
                        ?listener: Dynamic -> Void) {
        super();
        length = children.length;
        content = switch (children.length) {
            case 0: null;
            case 1: children[0];
            default: group(children, childrenAlign, gaps);
        };
        if (bg == null) bg = new RoxNinePatch(new RoxNinePatchData(new Rectangle(12, 12, 20, 20)));
        this.bg = bg;
        var bgw = width != null ? width : (content != null ? content.width : 0) + bg.marginLeft + bg.marginRight;
        var bgh = height != null ? height : (content != null ? content.height : 0) + bg.marginTop + bg.marginBottom;
        this.bg.setDimension(bgw, bgh);
        addChild(this.bg);
        if (content != null) addChild(this.content);
        var hasListner = listener != null;
        if (hasListner) {
            var agent = new RoxGestureAgent(this);
            agent.swipeTimeout = 0;
            addEventListener(RoxGestureEvent.GESTURE_TAP, listener);
        }
        mouseEnabled = hasListner;
        mouseChildren = !hasListner;
        set_anchor(anchor);
//        trace("w="+this.width+",h="+this.height+",cont_grid=" + bg.contentGrid.rox_rectStr() + ",content="+content.rox_dimension().rox_rectStr());
    }

    public inline function childAt(idx: Int) : DisplayObject {
        return switch (length) {
            case 0: null;
            case 1: content;
            default: cast(content, Sprite).getChildAt(idx);
        }
    }

    private function set_anchor(a: Int) : Int {
        this.anchor = a;
        var bgx = (a & 0x0F) == UiUtil.RIGHT ? -bg.width : (a & 0x0F) == UiUtil.HCENTER ? -bg.width / 2 : 0;
        var bgy = (a & 0xF0) == UiUtil.BOTTOM ? -bg.height : (a & 0xF0) == UiUtil.VCENTER ? -bg.height / 2 : 0;
        bg.rox_move(bgx, bgy);
        var r = bg.getContentRect();
        if (content != null)
            content.rox_move(bgx + r.x + (r.width - content.width) / 2, bgy + r.y + (r.height - content.height) / 2);
//        trace("bgx="+bgx+",bgy="+bgy+",r="+r.rox_rectStr()+",cont="+content.rox_dimension().rox_rectStr());
        return a;
    }

    private function group(cc: Array<DisplayObject>, align: Int, gaps: Array<Float>) : DisplayObject {
        var sp = new Sprite();
        var mw = 0.0, mh = 0.0;
        for (c in cc) {
            if (c.width > mw) mw = c.width;
            if (c.height > mh) mh = c.height;
        }
        var gap = DEFAULT_GAP, offset = 0.0;
        if (gaps == null) gaps = [];
        if ((align & 0xF0) != 0) { // horizotal layout
            align &= 0xF0;
            for (i in 0...cc.length) {
                var c = cc[i];
                if (i < gaps.length) gap = gaps[i];
                sp.addChild(c.rox_move(offset,
                        align == UiUtil.VCENTER ? (mh - c.height) / 2 : align == UiUtil.BOTTOM ? mh - c.height : 0));
                offset += c.width + gap;
            }
        } else { // vertical layout
            align &= 0x0F;
            for (i in 0...cc.length) {
                var c = cc[i];
                if (i < gaps.length) gap = gaps[i];
                sp.addChild(c.rox_move(align == UiUtil.HCENTER ? (mw - c.width) / 2
                        : align == UiUtil.RIGHT ? mw - c.width : 0, offset));
                offset += c.height + gap;
            }
        }
        return sp;
    }

}
