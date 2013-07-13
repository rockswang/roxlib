package com.roxstudio.haxe.ui;

import nme.events.Event;
import spritesheet.Spritesheet;
import spritesheet.AnimatedSprite;

class AutoplaySprite extends AnimatedSprite {

    private var autoplayBehavior: Dynamic;
    private var prevTime: Int;

    public function new(spritesheet: Spritesheet, smoothing: Bool = false) {
        super(spritesheet, smoothing);
        addEventListener(Event.ADDED_TO_STAGE, function(_) {
//            trace("added to stage");
            prevTime = nme.Lib.getTimer();
            if (autoplayBehavior == null) {
                setAutoplayBehavior(spritesheet.behaviors.keys().next());
            }
            addEventListener(Event.ENTER_FRAME, onFrame);
        });
        addEventListener(Event.REMOVED_FROM_STAGE, function(_) {
//            trace("removed from stage");
            removeEventListener(Event.ENTER_FRAME, onFrame);
        });
    }

    public function setAutoplayBehavior(behavior: Dynamic) {
        autoplayBehavior = behavior;
        this.showBehavior(behavior);
    }

    private function onFrame(_) {
        var currTime = nme.Lib.getTimer();
        var deltaTime: Int = currTime - prevTime;
        this.update(deltaTime);
        prevTime = currTime;
    }

}
