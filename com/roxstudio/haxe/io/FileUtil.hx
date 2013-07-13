package com.roxstudio.haxe.io;

#if cpp
import sys.io.File;
import sys.FileSystem;
#end

using StringTools;

class FileUtil {

    private function new() {
    }

#if (cpp || neko)

    public static function mkdirs(path: String) {
        path = path.replace("\\", "/");
        var dir = "";
        if (path.startsWith("/")) {
            path = path.substr(1);
            dir = "/";
        }
        var arr = path.split("/");
        for (i in 0...arr.length) {
            dir += arr[i];
//            trace("dir=\"" + dir+"\",exists=" + FileSystem.exists(dir));
            var c: Int = dir.length == 2 && dir.fastCodeAt(1) == ':'.code ? dir.fastCodeAt(0) : -1;
            var isDrive = c >= 'a'.code && c <= 'z'.code || c >= 'A'.code && c <= 'Z'.code;
            if (!isDrive && (!FileSystem.exists(dir) || !FileSystem.isDirectory(dir))) {
                FileSystem.createDirectory(dir);
            }
            dir += "/";
        }
    }

    public static function rmdir(path: String, ?force: Bool = false) {
        path = path.replace("\\", "/");
        if (!FileSystem.exists(path) || !FileSystem.isDirectory(path)) return;
        if (!force) { FileSystem.deleteDirectory(path); return; }
        for (name in FileSystem.readDirectory(path)) {
            var sub = path + "/" + name;
//            trace("deleting " + sub + ",isDir=" + FileSystem.isDirectory(sub));
            if (FileSystem.isDirectory(sub)) {
                rmdir(sub, true);
            } else {
                FileSystem.deleteFile(sub);
            }
        }
        FileSystem.deleteDirectory(path);

    }

    public static function fullPath(path: String) {
        var isFull = false;
#if windows
        var c: Int, s: String;
        isFull = path.length > 3 && path.charAt(1) == ":" && ((s = path.charAt(2)) == "\\" || s == "/")
                && ((c = path.charCodeAt(0)) >= 0x41 && c <= 0x5A || c >= 0x61 && c <= 0x7A); // A-Za-z
#else // android, linux etc.
        isFull = path.startsWith("/");
#end
        return isFull ? path : FileSystem.fullPath(path);
    }

    public static inline function fileUrl(s: String) : String {
        var url: String = (#if windows "file:///" #else "file://" #end) + fullPath(s);
        url = url.replace("\\", "/");
//        trace("fileUrl(\"" + s + "\") = \"" + url + "\"");
        return url;
    }

#end

    public static inline function fileExt(s: String, ?lowerCase: Bool = false) : String {
        var idx = s.lastIndexOf(".");
        if (lowerCase) s = s.toLowerCase();
        return idx > 0 ? s.substr(idx + 1) : "";
    }

    public static inline function fileName(s: String) : String {
        var i1 = s.lastIndexOf("/"), i2 = s.lastIndexOf(".");
        if (i2 < 0) i2 = s.length;
        return s.substr(i1 + 1, i2 - i1 - 1);
    }

}
