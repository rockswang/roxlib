package com.roxstudio.haxe.ui;

import nme.geom.Point;
import nme.display.BitmapData;
import nme.Vector;
import nme.geom.Rectangle;

class RoxNinePatchData {

    public var ninePatchGrid(default, null): Rectangle;
    public var contentGrid(default, null): Rectangle;
    public var bitmapData(default, null): BitmapData;
    public var clipRect(default, null): Rectangle;
#if !html5
    public var uvs(default, null): Vector<Float>;
    public var ids(default, null): Vector<Int>;
#else
    public var gridBmds: Array<BitmapData>;
#end

    public function new(ninePatchGrid: Rectangle, ?contentGrid: Rectangle, ?bitmapData: BitmapData, ?clipRect: Rectangle) {
        var g = this.ninePatchGrid = ninePatchGrid;
        this.contentGrid = contentGrid == null ? ninePatchGrid : contentGrid;
        this.bitmapData = bitmapData;
        var c = clipRect;
        if (c == null) {
            c = new Rectangle(0, 0, bitmapData != null ? bitmapData.width : 2 * g.x + g.width,
            bitmapData != null ? bitmapData.height : 2 * g.y + g.height);
        }
        this.clipRect = c;
        if (bitmapData == null) return;
        var w = bitmapData.width, h = bitmapData.height;
#if !html5
        uvs = new Vector<Float>();
        ids = new Vector<Int>();
        var hval = [ c.x / w, (c.x + g.x) / w, (c.x + g.right) / w, c.right / w ];
        var vval = [ c.y / h, (c.y + g.y) / h, (c.y + g.bottom) / h, c.bottom / h ];
        for (i in 0...4) {
            for (j in 0...4) {
                uvs.push(hval[j]);
                uvs.push(vval[i]);
            }
        }
        var i = 0;
        while (i < 11) {
            if (((i + 1) & 0x3) == 0) i++;
            ids.push(i);
            ids.push(i + 1);
            ids.push(i + 4);
            ids.push(i + 1);
            ids.push(i + 5);
            ids.push(i + 4);
            i++;
        }
#else
        gridBmds = [];
        var hval = [ c.x, g.x, c.x + g.x, g.width, c.x + g.right, c.width ];
        var vval = [ c.y, g.y, c.y + g.y, g.height, c.y + g.bottom, c.height ];
        for (i in 0...3) {
            var yy = vval[i << 1], hh = vval[(i << 1) + 1];
            for (j in 0...3) {
                var xx = hval[j << 1], ww = hval[(i << 1) + 1];
                if (ww == 0 || hh == 0) {
                    gridBmds.push(null);
                } else {
                    var bbmd = new BitmapData(Std.int(ww), Std.int(hh), true, 0);
                    bbmd.copyPixels(bitmapData, new Rectangle(xx, yy, ww, hh), new Point(0, 0));
                    gridBmds.push(bbmd);
                }
            }
        }
#end
    }

    public function dispose() {
//        trace(">>>>disposing 9 patch.");
        ninePatchGrid = null;
        contentGrid = null;
#if !html5
        uvs = null;
        ids = null;
#else
        if (gridBmds != null)
            for (b in gridBmds) { if (b != null) b.dispose(); }
        gridBmds = null;
#end
    }

    /**
    * The input BitmapData MUST be a valid Android ".9.png" file.
    * Thus, a normal png with an extra single pixel border indicating the grid
    **/
    public static function fromAndroidNinePng(bmd: BitmapData) : RoxNinePatchData {
        var w = bmd.width - 2, h = bmd.height - 2;
        var x1: Int, x2: Int, y1: Int, y2: Int, b1: Int, b2: Int, r1: Int, r2: Int;
        x1 = y1 = b1 = r1 = 0;
        x2 = b2 = w - 1;
        y2 = r2 = h - 1;
        var line = bmd.getPixels(new Rectangle(1, 0, w, 1));
        while (x1 < w && (line[x1 << 2] & 0xFF) == 0) x1++;
        while (x2 >= 0 && (line[x2 << 2] & 0xFF) == 0) x2--;
        line = bmd.getPixels(new Rectangle(0, 1, 1, h));
        while (y1 < w && (line[y1 << 2] & 0xFF) == 0) y1++;
        while (y2 >= 0 && (line[y2 << 2] & 0xFF) == 0) y2--;
        line = bmd.getPixels(new Rectangle(1, h + 1, w, 1));
        while (b1 < w && (line[b1 << 2] & 0xFF) == 0) b1++;
        while (b2 >= 0 && (line[b2 << 2] & 0xFF) == 0) b2--;
        line = bmd.getPixels(new Rectangle(w + 1, 1, 1, h));
        while (r1 < w && (line[r1 << 2] & 0xFF) == 0) r1++;
        while (r2 >= 0 && (line[r2 << 2] & 0xFF) == 0) r2--;
        if (x2 < x1) { x1 = 0; x2 = w - 1; }
        if (y2 < y1) { y1 = 0; y2 = h - 1; }
        if (b2 < b1) { b1 = 0; b2 = w - 1; }
        if (r2 < r1) { r1 = 0; r2 = h - 1; }
        var newbmd = new BitmapData(w, h, true, 0);
        newbmd.copyPixels(bmd, new Rectangle(1, 1, w, h), new Point(0, 0));
        return new RoxNinePatchData(new Rectangle(x1, y1, x2 - x1 + 1, y2 - y1 + 1),
                new Rectangle(b1, r1, b2 - b1 + 1, r2 - r1 + 1), newbmd,
                new Rectangle(0, 0, w, h));
    }
}
