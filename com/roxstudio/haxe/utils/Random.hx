package com.roxstudio.haxe.utils;

#if cpp

typedef Random = cpp.Random;

#else

import nme.display.BitmapData;

/**
 * ...
 * @author Rocks Wang
 */

class Random {

	private var _seed: Int;
	private var _pointer: Int;
	private var bmpd: BitmapData;
	private var seedInvalid: Bool;
	
	public function new() {
		_seed = Std.random(2147483647);
		_pointer = 0;
		bmpd = new BitmapData(1000, 200);
		seedInvalid = true;
	}
	
	public function setSeed(s: Int) : Void {
		if (s != _seed) { 
			seedInvalid = true; 
			_pointer = 0; 
		}
		_seed = s;
	}
		
	public function float() : Float {
		if (seedInvalid) {
			bmpd.noise(_seed, 0, 255, 1|2|4|8);
			seedInvalid = false;
		}
		_pointer = (_pointer + 1) % 200000;
		// Flash's numeric precision appears to run to 0.9999999999999999, but we'll drop one digit to be safe:
		return (bmpd.getPixel32(_pointer % 1000, Std.int(_pointer / 1000)) * 0.999999999999998 + 0.000000000000001) / 4294967295.0;
	}
	
	public inline function int(max: Int) : Int {
		return Std.int(float() * max);
	}
		
}

#end