package com.roxstudio.haxe.utils;

import haxe.Log;
import haxe.PosInfos;
import nme.utils.ByteArray;

/**
 * ...
 * @author Rocks Wang
 */
#if cpp
import nme.Assets;

class GbTracer {
	
	private static var u2g: ByteArray;
	private static var sysTrace = Log.trace;

	private function new() {
	}
	
	public static function init(inDataFile: String) {
		u2g = Assets.getBytes(inDataFile);
		Log.trace = gbTrace;
	}
	
	private static function gbTrace(v: Dynamic, ?inf: PosInfos) : Void {
		if (v == null) { 
			sysTrace(v, inf);
			return;
		}
		var buf = new StringBuf(), s: String = v.toString(), len = s.length, i = 0;
//		var a = new StringBuf();
//		for (i in 0...len) {
//			a.add(s.charCodeAt(i));
//			a.add(",");
//		}
//		sysTrace(a, inf);
        try {
            while (i < len) {
                var c: Int, t: Int, n: Int = 0;
                t = c = s.charCodeAt(i++);
                while ((t & 0x80) != 0) { t <<= 1; n++; }
                switch (n) {
                case 0:
                    buf.add(String.fromCharCode(c));
                case 3:
                    var c1 = s.charCodeAt(i++) << 6, c2 = s.charCodeAt(i++);
                    c = ((c << 12) & 0xf000) + (c1 & 0x0f00) + (c1 & 0xc0) + (c2 & 0x3f);
                    var idx: Int = (c - 0x4e00) * 2, tblen: Int = u2g.length;
                    if (idx < 0 || idx >= tblen) {
                        buf.add("?");
                    } else {
                        buf.add(String.fromCharCode(u2g[idx]));
                        buf.add(String.fromCharCode(u2g[idx + 1]));
                    }
                default: // unrecognized characters, use system tracer
                    sysTrace(v, inf);
                    return;
                }
            }
        } catch (a: Dynamic) {
            sysTrace(v, inf);
            return;
        }
		sysTrace(buf, inf);
	}
	

}
#else
class GbTracer {
    public static function init(f: String) { }
}
#end
