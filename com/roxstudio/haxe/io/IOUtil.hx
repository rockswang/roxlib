package com.roxstudio.haxe.io;

import haxe.io.Bytes;
import nme.utils.ByteArray;

class IOUtil {

    private function new() {
    }

    public static inline function rox_toByteArray(bytes: Bytes) : ByteArray {
        return #if flash bytes.getData() #else ByteArray.fromBytes(bytes) #end;
    }

    public static inline function rox_toBytes(byteArray: ByteArray) : Bytes {
        return #if flash Bytes.ofData(byteArray) #else cast(byteArray) #end;
    }

    public static inline function byteArray(?length: Null<Int>) : ByteArray {
#if (flash || html5)
        var bb = new ByteArray();
        if (length != null) bb.length = length;
        return bb;
#else
        return length != null ? new ByteArray(length) : new ByteArray();
#end
    }
}
