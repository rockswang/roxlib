package com.roxstudio.haxe.utils;

/**
 * ...
 * @author Rocks Wang
 */

class SimpleJob<T> implements Job {
	
	private var data: T;
	private var _run: T -> Void;
	private var _completed: T -> Void;
	
	public function new(inData: T, inJobRunFunction: T -> Void, inJobCompletedFunction: T -> Void) {
		this.data = inData;
		this._run = inJobRunFunction;
		this._completed = inJobCompletedFunction;
	}
	
	public function jobRun() : Void {
		this._run(data);
	}
	
	public function jobCompleted() : Void {
		this._completed(data);
	}
	
}
