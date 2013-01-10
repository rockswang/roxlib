package com.roxstudio.haxe.net;

import nme.display.Bitmap;
import nme.display.BitmapData;
import nme.display.Loader;
import nme.errors.Error;
import nme.events.Event;
import nme.events.EventDispatcher;
import nme.events.IOErrorEvent;
import nme.events.ProgressEvent;
import nme.net.URLLoader;
import nme.net.URLLoaderDataFormat;
import nme.net.URLRequest;
import nme.utils.ByteArray;

/**
* Currently support: String, ByteArray, BitmapData
**/
class RoxURLLoader extends EventDispatcher {

    public static inline var BINARY = 1;
    public static inline var TEXT = 2;
    public static inline var IMAGE = 3;


    public static inline var OK = 0;
    public static inline var LOADING = 1;
    public static inline var ERROR = -1;

    public var url(default, null): String;
    public var type(default, null): Int;
    public var status(default, null): Int = OK;
    public var progress(default, null): Float;
    public var bytesTotal(default, null): Float;
    public var data(default, null): Dynamic;

    private var loader: URLLoader;

    public function new(?url: String, ?type: Int = BINARY) {
        super();
        if (url != null) load(url, type);
    }

    public function load(url: String, ?type: Int = BINARY) {
        if (status == LOADING) throw "Cannot load while previous task is not completed.";
        this.url = url;
        this.type = type;
        status = LOADING;
        data = null;
        progress = bytesTotal = 0.0;
        try {
            loader = new URLLoader();
            loader.dataFormat = type == TEXT ? URLLoaderDataFormat.TEXT : URLLoaderDataFormat.BINARY;
            loader.load(new URLRequest(url));
            loader.addEventListener(Event.COMPLETE, onComplete);
            loader.addEventListener(ProgressEvent.PROGRESS, onProgress);
            loader.addEventListener(IOErrorEvent.IO_ERROR, onError);
#if !html5
            loader.addEventListener(nme.events.SecurityErrorEvent.SECURITY_ERROR, onError);
#end
        } catch (e: Dynamic) {
            trace("url=" + url + ",error="+e);
            onError(null);
        }
    }

    private inline function onComplete(_) {
        status = OK;
        switch (type) {
            case IMAGE:
                var ldr = new Loader();
                ldr.loadBytes(cast(loader.data));
                var imageDone = function(_) {
                    data = cast(ldr.content, Bitmap).bitmapData;
                    loader = null;
                    dispatchEvent(new Event(Event.COMPLETE));
                }
                if (ldr.content != null) {
                    imageDone(null);
                } else {
                    var ldri = ldr.contentLoaderInfo;
                    ldri.addEventListener(Event.COMPLETE, imageDone);
                }
                return;
            default: // TEXT & BINARY
                data = loader.data;
        }
        loader = null;
        dispatchEvent(new Event(Event.COMPLETE));
    }

    private inline function onError(e: Dynamic) {
        trace("url=" + url + ",error=!" + e);
        status = ERROR;
        loader = null;
        dispatchEvent(new Event(Event.COMPLETE));
    }

    private inline function onProgress(e: ProgressEvent) {
        status = LOADING;
        bytesTotal = e.bytesTotal;
        progress = e.bytesLoaded / bytesTotal;
    }

    public function dispose() {
        url = null;
        status = OK;
        if (data != null) {
            if (type == IMAGE) cast(data, BitmapData).dispose();
            data = null;
        }
        loader = null;
    }

}
