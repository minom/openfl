package openfl.events;


import openfl.events.Event;
import openfl.events.IEventDispatcher;
import openfl.utils.WeakRef;
import haxe.ds.ObjectMap;
import haxe.ds.StringMap;
import haxe.CallStack;


class EventDispatcher implements IEventDispatcher {
	
	
	@:noCompletion private var __eventMap:EventMap;
	@:noCompletion private var __target:IEventDispatcher;

	#if TRACE_EVENT_LISTENERS
	public static var _eventListeners:StringMap<Int>;
	#if TRACE_EVENT_CALLSTACK
	public static var _eventCallStack:StringMap<StringMap<Array<StackItem>>>; 
	#end
	#end
	
	public function new (target:IEventDispatcher = null):Void {
		#if TRACE_EVENT_LISTENERS
		if (_eventListeners == null)
			_eventListeners = new StringMap<Int>();
		#if TRACE_EVENT_CALLSTACK
		if (_eventCallStack == null)
			_eventCallStack = new StringMap<StringMap<Array<StackItem>>>();
		#end
		#end
		__target = (target == null ? this : target);
		__eventMap = null;
	}

	#if TRACE_EVENT_LISTENERS
	public static function printListeners(exclusions:Array<String>=null)
	{
		trace('Listeners:');
		for (e in EventDispatcher._eventListeners.keys())
		{
			var c = EventDispatcher._eventListeners.get(e);
			if (c > 0)
			{
				var excluded = false;
				if (exclusions != null)
					for (exclusion in exclusions) if (e.indexOf(exclusion) != -1) excluded = true;
				if (excluded) continue;
				trace(e + ' : ' + c);
				#if !TRACE_EVENT_CALLSTACK
				continue;
				#else
				trace('============================================================================');
				var calls = EventDispatcher._eventCallStack.get(e);
				for (stack in calls)
				{
					for (line in stack)	trace('   ' + line);
					trace('.............................................................................');
				}
				#end
			}
		}
	}

  public function getEventId(type:String):String
	{
		return this + ' [' + type +']';
	}
	#end


	public function addEventListener (type:String, listener:Function, useCapture:Bool = false, priority:Int = 0, useWeakReference:Bool = false):Void 
	{
		if (useWeakReference) {
			trace ("WARNING: Weak listener not supported for native (using hard reference)");
			useWeakReference = false;
		}
		
		if (__eventMap == null) {
			__eventMap = new EventMap ();
		}
		
		var list = __eventMap.get (type);
		if (list == null) {
			list = new ListenerList ();
			__eventMap.set (type, list);
		}
		
		list.push (new Listener (new WeakRef<Function> (listener, useWeakReference), useCapture, priority));
		list.sort (__sortEvents);

		// ------------------------------ LISTENER TRACKING ----------------------------
		#if TRACE_EVENT_LISTENERS
		var s = getEventId(type);
		var e:Null<Int> = _eventListeners.get(s);
		if (e == null) {
			e = 0; 
		}

    e = 1;
		_eventListeners.set(s, e);

		#if TRACE_EVENT_CALLSTACK
		var stackString = haxe.CallStack.toString(haxe.CallStack.callStack());
		var cs = _eventCallStack.get(s);
		if (cs == null) {
			cs = new StringMap<Array<StackItem>>();
			cs.set(stackString, haxe.CallStack.callStack());
			_eventCallStack.set(s, cs);
		} else
		{
			cs.set(stackString, haxe.CallStack.callStack());
		}
		#end
		#end
		// ------------------------------------------------------------------------------
	}
	
	public function removeEventListener (type:String, listener:Function, capture:Bool = false):Void 
	{
		// ------------------------------ LISTENER TRACKING ----------------------------
		#if TRACE_EVENT_LISTENERS
    var s = getEventId(type);
		var e:Null<Int> = _eventListeners.get(s);
		if (e != null)
		{
			e--;
			if (e < 0) e = 0;
			_eventListeners.set(s, e);
		}
		#end
		// ------------------------------------------------------------------------------

		if (__eventMap == null || !__eventMap.exists (type)) { return; }
		var list = __eventMap.get (type);
		var item;
		for (i in 0...list.length) {
			if (list[i] != null) {
				item = list[i];
				if (item != null && item.is (listener, capture)) {
					list[i] = null;
					return;
				}
			}
		}
	}
	
	

	public function dispatchEvent (event:Event):Bool {
		
		if (__eventMap == null) {
			
			return false;
			
		}
		
		if (event.target == null) {
			
			event.target = __target;
			
		}
		
		if (event.currentTarget == null) {
			
			event.currentTarget = __target;
			
		}
		
		var list = __eventMap.get (event.type);
		var capture = (event.eventPhase == EventPhase.CAPTURING_PHASE);
		
		if (list != null) {
			
			var index = 0;
			var length = list.length;
			
			var listItem, listener;
			
			while (index < length) {
				
				listItem = list[index];
				listener = ((listItem != null && listItem.listener.get() != null) ? listItem : null);
				
				if (listener == null) {
					
					list.splice (index, 1);
					length--;
					
				} else {
					
					if (listener.useCapture == capture) {
						
						listener.dispatchEvent (event);
						
						if (event.__getIsCancelledNow ()) {
							
							return true;
							
						}
						
					}
					
					index++;
					
				}
				
			}
			
			return true;
			
		}
		
		return false;
		
	}
	
	
	public function hasEventListener (type:String):Bool {
		
		if (__eventMap == null) {
			
			return false;
			
		}
		
		var list = __eventMap.get (type);
		
		if (list != null) {
			
			for (item in list) {
				
				if (item != null) return true;
				
			}
			
		}
		
		return false;
		
	}
	
	

	public function toString ():String {
		
		return "[object " + Type.getClassName (Type.getClass (this)) + "]";
		
	}
	
	
	public function willTrigger (type:String):Bool {
		
		if (__eventMap == null) {
			
			return false;
			
		}
		
		return __eventMap.exists (type);
		
	}
	
	
	@:noCompletion public function __dispatchCompleteEvent ():Void {
		
		dispatchEvent (new Event (Event.COMPLETE));
		
	}
	
	
	@:noCompletion public function __dispatchIOErrorEvent ():Void {
		
		dispatchEvent (new IOErrorEvent (IOErrorEvent.IO_ERROR));
		
	}
	
	
	@:noCompletion private static inline function __sortEvents (a:Listener, b:Listener):Int {
		
		if (a == null || b == null) { 
			
			return 0;
			
		}
		
		var al = a;
		var bl = b;
		
		if (al == null || bl == null) {
			
			return 0;
			
		}
		
		if (al.priority == bl.priority) { 
			
			return al.id == bl.id ? 0 : ( al.id > bl.id ? 1 : -1 );
			
		} else {
		
			return al.priority < bl.priority ? 1 : -1;
			
		}
		
	}
	
	
}


class Listener {
	
	
	public var id:Int;
	public var listener:WeakRef <Function>;
	public var priority:Int;
	public var useCapture:Bool;

	private static var __id = 1;
	
	
	public function new (listener:WeakRef <Function>, useCapture:Bool, priority:Int) {
		
		this.listener = listener;
		this.useCapture = useCapture;
		this.priority = priority;
		id = __id++;
		
	}
	
	
	public function dispatchEvent (event:Event):Void {
		
		listener.get () (event);
		
	}
	
	
	public function is (listener:Function, useCapture:Bool) {
		
		return (Reflect.compareMethods (this.listener.get(), listener) && this.useCapture == useCapture);
		
	}
	
	
}


typedef ListenerList = Array<Listener>;
typedef EventMap = haxe.ds.StringMap<ListenerList>;