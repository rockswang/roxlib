package com.roxstudio.haxe.utils;

/**
 * ...
 * @author Rocks Wang
 */

interface Job {

	public function jobRun() : Void;
	
	public function jobCompleted() : Void;

}