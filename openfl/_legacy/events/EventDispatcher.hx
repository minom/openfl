package openfl._legacy.events; #if openfl_legacy


import openfl.events.Event;
import openfl.events.EventPhase;
import openfl.events.IOErrorEvent;
import openfl._legacy.events.IEventDispatcher;
import openfl._legacy.utils.WeakRef;

@:access(openfl._legacy.events.Event)


class EventDispatcher implements IEventDispatcher {

	#if debug_event_listeners
	@:noCompletion public static var ___staticEventMap:Map<Listener, {dispatcher:EventDispatcher, type:String, stack:String}>;
	#end

	@:noCompletion private var __targetDispatcher:IEventDispatcher;
	@:noCompletion private var __eventMap:Map<String, Array<Listener>>;
	
	
	public function new (target:IEventDispatcher = null):Void {
		
		if (target != null) {
			
			__targetDispatcher = target;
			
		}
		
	}
	
	
	public function addEventListener (type:String, listener:Dynamic->Void, useCapture:Bool = false, priority:Int = 0, useWeakReference:Bool = false):Void {
		
		if (__eventMap == null) {
			
			__eventMap = new Map<String, Array<Listener>> ();
			
		}


		#if debug_event_listeners
		if(___staticEventMap == null) {

			___staticEventMap = new Map();

		}
		#end


		if (!__eventMap.exists (type)) {
			
			var list = new Array<Listener> ();
			var listener = new Listener (listener, useCapture, priority);
			list.push (listener);
			__eventMap.set (type, list);

			#if debug_event_listeners
			___staticEventMap.set(listener, {type:type, dispatcher:this, stack:haxe.CallStack.toString(haxe.CallStack.callStack())});
			#end
			
		} else {
			
			var list = __eventMap.get (type);
			
			for (i in 0...list.length) {
				
				if (Reflect.compareMethods (list[i].callback, listener)) return;
				
			}

			var listener = new Listener (listener, useCapture, priority);
			list.push (listener);
			list.sort (__sortByPriority);

			#if debug_event_listeners
			___staticEventMap.set(listener, {type:type, dispatcher:this, stack:haxe.CallStack.toString(haxe.CallStack.callStack())});
			#end
			
		}
		
	}
	
	
	public function dispatchEvent (event:Event):Bool {
		
		if (__eventMap == null || event == null) return false;
		
		var list = __eventMap.get (event.type);
		
		if (list == null) return false;
		
		if (event.target == null) {
			
			if (__targetDispatcher != null) {
				
				event.target = __targetDispatcher;
				
			} else {
				
				event.target = this;
				
			}
			
		}
		
		event.currentTarget = this;
		
		var capture = (event.eventPhase == EventPhase.CAPTURING_PHASE);
		var index = 0;
		var listener;
		
		while (index < list.length) {
			
			listener = list[index];
			
			if (listener.useCapture == capture) {
				
				//listener.callback (event.clone ());
				listener.callback (event);
				
				if (event.__isCancelledNow) {
					
					return true;
					
				}
				
			}
			
			if (listener == list[index]) {
				
				index++;
				
			}
			
		}
		
		return true;
		
	}
	
	
	public function hasEventListener (type:String):Bool {
		
		if (__eventMap == null) return false;
		return __eventMap.exists (type);
		
	}
	
	
	public function removeEventListener (type:String, listener:Dynamic->Void, capture:Bool = false):Void {
		
		if (__eventMap == null) return;
		
		var list = __eventMap.get (type);
		
		if (list == null) return;
		
		for (i in 0...list.length) {
			
			if (list[i].match (listener, capture)) {
				
				var listener = list.splice (i, 1)[0];

				#if debug_event_listeners
				___staticEventMap.remove(listener);
				#end

				break;
				
			}
			
		}
		
		if (list.length == 0) {
			
			__eventMap.remove (type);
			
		}
		
		if (!__eventMap.iterator ().hasNext ()) {
			
			__eventMap = null;
			
		}
		
	}
	
	
	public function toString ():String { 
		
		var full = Type.getClassName (Type.getClass (this));
		var short = full.split (".").pop ();
		
		return untyped "[object " + short + "]";
		
	}
	
	
	public function willTrigger (type:String):Bool {
		
		return hasEventListener (type);
		
	}
	
	
	@:noCompletion public function __dispatchCompleteEvent ():Void {
		
		dispatchEvent (new Event (Event.COMPLETE));
		
	}
	
	
	@:noCompletion public function __dispatchIOErrorEvent ():Void {
		
		dispatchEvent (new IOErrorEvent (IOErrorEvent.IO_ERROR));
		
	}
	
	
	@:noCompletion private static function __sortByPriority (l1:Listener, l2:Listener):Int {
		
		return l1.priority == l2.priority ? 0 : (l1.priority > l2.priority ? -1 : 1);
		
	}
	
	
}


private class Listener {
	
	
	public var callback:Dynamic->Void;
	public var priority:Int;
	public var useCapture:Bool;
	
	
	public function new (callback:Dynamic->Void, useCapture:Bool, priority:Int) {
		
		this.callback = callback;
		this.useCapture = useCapture;
		this.priority = priority;
		
	}
	
	
	public function match (callback:Dynamic->Void, useCapture:Bool) {
		
		return (Reflect.compareMethods (this.callback, callback) && this.useCapture == useCapture);
		
	}
	
	
}


#end