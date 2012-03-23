package components
{
	import com.inreflected.core.IVisualElement;

	import flash.display.Sprite;
	import flash.events.Event;


	/**
	 * @author Pavel fljot
	 */
	public class UIComponent extends Sprite implements IVisualElement
	{
		public function UIComponent()
		{
			super();
			
			preinit();
			addEventListener(Event.ADDED_TO_STAGE, addedToStageHandler);
		}
		
		
		/** @private */
		protected var _width:Number;
		
		/**
		 * 
		 */
		override public function get width():Number
		{
			return _width;
		}
		override public function set width(value:Number):void
		{
			if (_width == value)
				return;
			
			_width = value;
			
			onSizeChanged();
			if (hasEventListener(Event.RESIZE))
			{
				dispatchEvent(new Event(Event.RESIZE));
			}
		}
		
		
		/** @private */
		protected var _height:Number;
		
		/**
		 * 
		 */
		override public function get height():Number
		{
			return _height;
		}
		override public function set height(value:Number):void
		{
			if (_height == value)
				return;
			
			_height = value;
			
			onSizeChanged();
			if (hasEventListener(Event.RESIZE))
			{
				dispatchEvent(new Event(Event.RESIZE));
			}
		}
		
		
		protected function preinit():void
		{
			
		}
		
		
		protected function init():void
		{
			
		}
		
		
		protected function onSizeChanged():void
		{
			
		}
		
		
		protected function addedToStageHandler(event:Event):void
		{
			removeEventListener(Event.ADDED_TO_STAGE, addedToStageHandler);
			
			init();
		}
	}
}