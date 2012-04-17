package components
{
	import com.inreflected.ui.core.IViewport;
	import com.inreflected.ui.touchScroll.TouchScrollManager;

	import flash.display.DisplayObject;


	/**
	 * This is a light version of scroller component just for example
	 * (extends Sprite, not some fancy UIComponent).
	 * 
	 * @author Pavel fljot
	 */
	public class TouchScroller extends UIComponent
	{
		public function TouchScroller()
		{
			super();
		}
		
		
		/** @private */
		protected var _viewport:IViewport;
		
		/**
		 * 
		 */
		public function get viewport():IViewport
		{
			return _viewport;
		}
		public function set viewport(value:IViewport):void
		{
			if (_viewport == value)
				return;
			
			uninstallViewport(_viewport);
			_viewport = value;
			installViewport(_viewport);
		}
		
		
		/** @private */
		protected var _touchScrollManager:TouchScrollManager;
		
		/**
		 * 
		 */
		public function get touchScrollManager():TouchScrollManager
		{
			return _touchScrollManager;
		}
		public function set touchScrollManager(value:TouchScrollManager):void
		{
			if (_touchScrollManager == value)
				return;
			
			uninstallTouchScrollManager(touchScrollManager);
			_touchScrollManager = value;
			installTouchScrollManager(touchScrollManager);
		}
		
			
		override protected function preinit():void
		{
			super.preinit();
			
			touchScrollManager = createTouchScrollManager();
		}
		
			
		override protected function onSizeChanged():void
		{
			super.onSizeChanged();
			
			resizeViewport();
		}
		
		
		protected function resizeViewport():void
		{
			if (viewport)
			{
				viewport.width = width;
				viewport.height = height;
			}
		}
		
		
		protected function installViewport(viewport:IViewport):void
		{
			if (!viewport)
				return;
			
//			viewport.addEventListener(PropertyChangeEvent.PROPERTY_CHANGE, viewport_propertyChangeHandler);
			viewport.clipAndEnableScrolling = true;
			addChildAt(_viewport as DisplayObject, 0);
			
			if (touchScrollManager)
			{
				touchScrollManager.viewport = viewport;
			}
			
			resizeViewport();
		}
		
		
		protected function uninstallViewport(viewport:IViewport):void
		{
			if (!viewport)
				return;
			
//			viewport.removeEventListener(PropertyChangeEvent.PROPERTY_CHANGE, viewport_propertyChangeHandler);
			viewport.clipAndEnableScrolling = true;
			removeChild(viewport as DisplayObject);
			
			if (touchScrollManager)
			{
				touchScrollManager.viewport = null;
			}
		}
		
		
		protected function installTouchScrollManager(touchScrollManager:TouchScrollManager):void
		{
			if (touchScrollManager && viewport)
			{
				touchScrollManager.viewport = viewport;
			}
		}
		
		
		protected function uninstallTouchScrollManager(touchScrollManager:TouchScrollManager):void
		{
			if (touchScrollManager)
			{
				touchScrollManager.viewport = null;
				// NB! do not forget to dispose touchScrollManager if needed				
			}
		}
		
		
		protected function createTouchScrollManager():TouchScrollManager
		{
			return new TouchScrollManager();
		}
	}
}