package com.roxstudio.haxe.ui;

#if cpp
import com.roxstudio.haxe.utils.SimpleJob;
import com.roxstudio.haxe.utils.Worker;
#end
import com.roxstudio.haxe.net.RoxURLLoader;
import nme.events.Event;
import nme.events.ProgressEvent;
import nme.events.EventDispatcher;
import com.roxstudio.haxe.game.ResKeeper;
import nme.display.Sprite;

using StringTools;

class RoxPreloader extends EventDispatcher {

    public var progress: Float = 0.0;

    private var step: Float;
    private var autoUnzip: Bool;
    private var list: List<String>;
    private var bundleId: String;
#if cpp
    private var worker: Worker;
#end

    public function new(urls: Array<String>, ?ids: Array<String>, ?bundleId: String, ?autoUnzip: Bool = false) {
        super();
        if (ids != null && ids.length != urls.length) throw "ID array must be of same length to URL array.";
        if (ids == null) ids = urls;
        this.bundleId = bundleId;

        step = 1 / urls.length;
        list = new List<String>();
#if cpp
        worker = new Worker();
#end

        for (i in 0...urls.length) {
            var url = urls[i], id = ids[i];
            var prefix = url.length > 7 ? url.substr(0, 7) : "";
            switch (prefix) {
                case "http://":
                    download(url);
                case "https:/":
                    download(url);
#if cpp
                case "file://":
                    worker.addJob(new SimpleJob<Dynamic>({ url: url, data: null }, load, loadComplete));
#end
                case "assets:":
                    list.add(url.substr(9));
                default:
                    list.add(url);
            }
        }
        if (list.length > 0) {
            nme.Lib.current.stage.addEventListener(Event.ENTER_FRAME, update);
        }
    }

    private function update(_) {
        if (list.length == 0) {
            nme.Lib.current.stage.removeEventListener(Event.ENTER_FRAME, update);
            return;
        }
        var s = list.pop();
        trace("update: assets=" + s);
        ResKeeper.getAssetImage(s, bundleId);
        addProgress(step);
    }

    private function download(url: String) {
        trace("download: url=" + url);
        var ul = url.toLowerCase();
        var type = ul.endsWith(".jpg") || ul.endsWith(".png") ? RoxURLLoader.IMAGE : RoxURLLoader.BINARY;
        var ldr = new RoxURLLoader(url, type);
        ldr.addEventListener(Event.COMPLETE, onComplete);
    }

    private inline function onComplete(e: Dynamic) {
        trace("oncomplete: e.target=" + e.target);
        var ldr = cast(e.target, RoxURLLoader);
        ResKeeper.add(ldr.url, ldr.data, bundleId);
        addProgress(step);
    }

#if cpp
    private function load(d: Dynamic) {
        trace("load: d=" + d);
        var url = d.url;
        var path = #if windows url.substr(8) #else url.substr(7) #end;
        d.data = ResKeeper.loadLocalImage(path);
    }

    private function loadComplete(d: Dynamic) {
        trace("loadComp: d=" + d);
        ResKeeper.add(d.url, d.data, bundleId);
        addProgress(step);
    }
#end

    private inline function addProgress(p: Float) {
        trace(">>>>progress=" + progress);
        progress += p;
        if (progress >= 1) {
            dispatchEvent(new Event(Event.COMPLETE));
        } else {
            dispatchEvent(new ProgressEvent(ProgressEvent.PROGRESS, Std.int(progress * 100), 100));
        }
    }

}
