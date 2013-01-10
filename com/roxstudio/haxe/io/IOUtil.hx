package com.roxstudio.haxe.io;

import sys.FileSystem;
using StringTools;

class IOUtil {

    private function new() {
    }

    public static function mkdirs(path: String) {
        path = path.replace("\\", "/");
        var arr = path.split("/");
        var dir = "";
        for (i in 0...arr.length) {
            dir += arr[i] + "/";
            if (!FileSystem.exists(dir)) {
                FileSystem.createDirectory(dir);
            }
        }
    }


}
