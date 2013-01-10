package com.roxstudio.haxe.utils;

#if cpp
import cpp.vm.Mutex;
import cpp.vm.Thread;
import nme.events.Event;

/**
 * ...
 * @author Rocks Wang
 */

class Worker {
	
	private var jobs: List<Job>; // completed jobs
	private var lock: Mutex;
	private var thread: Thread;

	public function new() {
		jobs = new List<Job>();
		lock = new Mutex();
		thread = Thread.create(run);
		nme.Lib.current.stage.addEventListener(Event.ENTER_FRAME, update);
	}
	
	public function addJob(job: Job) {
		thread.sendMessage(job);
	}
	
	private function run() {
		while (true) {
			var j: Job = Thread.readMessage(true);
			j.jobRun();
			lock.acquire();
			jobs.add(j);
			lock.release();
		}
	}
	
	private function update(e: Event) {
		var batch: Array<Job> = [];
		lock.acquire();
		while (jobs.length > 0) {
			batch.push(jobs.pop());
		}
		lock.release();
		for (j in batch) {
			j.jobCompleted();
		}
	}
	
}
#else

class Worker {}

#end
