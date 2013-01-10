package com.roxstudio.haxe.ui;

import nme.events.Event;
import com.roxstudio.haxe.net.RoxURLLoader;
import com.roxstudio.haxe.game.ResKeeper;
import nme.display.Bitmap;
import nme.display.BitmapData;
import nme.display.DisplayObject;
import nme.display.Sprite;

using com.roxstudio.haxe.ui.UiUtil;

class RoxAsyncBitmap extends Sprite {

    public var loader(default, null): RoxURLLoader;
    public var loadingDisplay: DisplayObject;
    public var errorDisplay: DisplayObject;

    private var minWidth: Float = 0;
    private var minHeight: Float = 0;

    public function new(loader: RoxURLLoader, ?minWidth: Float = 0, ?minHeight: Float = 0,
                        ?loadingDisplay: DisplayObject, ?errorDisplay: DisplayObject) {
        super();
        this.minWidth = minWidth;
        this.minHeight = minHeight;
        this.loadingDisplay = loadingDisplay;
        this.errorDisplay = errorDisplay;
        this.loader = loader;
        if (loader.status == RoxURLLoader.LOADING) {
            loader.addEventListener(Event.COMPLETE, update);
        }
        update(null);
    }

    private function update(_) {
        var dp: DisplayObject = switch (loader.status) {
            case RoxURLLoader.OK:
                new Bitmap(cast(loader.data));
            case RoxURLLoader.ERROR:
                errorDisplay;
            case RoxURLLoader.LOADING:
                loadingDisplay;
        }
        if (numChildren > 0) removeChildAt(0);
        if (dp != null) addChild(dp);
        if (width > minWidth) minWidth = width;
        if (height > minHeight) minHeight = height;
        if (minWidth > width || minHeight > height) {
            graphics.beginFill(0xFFFFFF, 0.005);
            graphics.drawRect(0, 0, minWidth, minHeight);
            graphics.endFill();
        }
        if (dp != null) dp.rox_move((minWidth - dp.width) / 2, (minHeight - dp.height) / 2);
//        trace(">2>min="+minWidth+","+minHeight+",this="+this.width+","+this.height+(dp!=null?",dp="+dp.width+","+dp.height:""));
    }

}
