package openfl.display;


import openfl.display.DisplayObject;
import openfl.events.Event;
import openfl.geom.Rectangle;
import openfl.Lib;


class DirectRenderer extends DisplayObject {
	
	private var __addToStageListener:Dynamic;
	private var __removedFromStageListener:Dynamic;

	public function new (type:String = "DirectRenderer") {
		
		super (lime_direct_renderer_create (), type);

		__addToStageListener = function(_) lime_direct_renderer_set (__handle, __onRender);
		__removedFromStageListener = function(_) lime_direct_renderer_set (__handle, null);
		addEventListener (Event.ADDED_TO_STAGE, __addToStageListener);
		addEventListener (Event.REMOVED_FROM_STAGE, __removedFromStageListener);
		
	}
	

	public function dispose()
	{
		removeEventListener (Event.ADDED_TO_STAGE, __addToStageListener);
		removeEventListener (Event.REMOVED_FROM_STAGE, __removedFromStageListener);
	}

	public dynamic function render (rect:Rectangle):Void {
		
		
		
	}
	
	
	@:noCompletion private function __onRender (rect:Dynamic):Void {
		
		if (render != null) render (new Rectangle (rect.x, rect.y, rect.width, rect.height));
		
	}
	
	
	
	
	// Native Methods
	
	
	
	
	private static var lime_direct_renderer_create = Lib.load ("lime", "lime_direct_renderer_create", 0);
	private static var lime_direct_renderer_set = Lib.load ("lime", "lime_direct_renderer_set", 2);
	
	
}