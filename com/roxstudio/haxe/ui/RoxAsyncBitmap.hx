package com.roxstudio.haxe.ui;

import com.roxstudio.haxe.game.ImageUtil;
import nme.display.Bitmap;
import nme.display.BitmapData;
import nme.display.DisplayObject;
import nme.display.Sprite;

using com.roxstudio.haxe.ui.UiUtil;

class RoxAsyncBitmap extends Sprite {

    public var loader(default, null): RoxBitmapLoader;
    public var loadingDisplay: DisplayObject;
    public var errorDisplay: DisplayObject;

    private var minWidth: Float = 0;
    private var minHeight: Float = 0;

    public function new(url: String, ?minWidth: Float = 0, ?minHeight: Float = 0,
                        ?loadingDisplay: DisplayObject, ?errorDisplay: DisplayObject) {
        super();
        this.minWidth = minWidth;
        this.minHeight = minHeight;
        this.loadingDisplay = loadingDisplay;
        this.errorDisplay = errorDisplay;
        loader = ImageUtil.getBitmapLoader(url);
        if (loader.status == RoxBitmapLoader.READY) {
            loader.load(update);
        }
        update();
    }

    private function update() {
        var dp: DisplayObject = switch (loader.status) {
            case RoxBitmapLoader.OK:
                new Bitmap(loader.bitmapData);
            case RoxBitmapLoader.ERROR:
                errorDisplay;
            case RoxBitmapLoader.LOADING:
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
