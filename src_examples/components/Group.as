package components
{
	import flash.display.DisplayObject;
	import com.inreflected.core.IViewport;

	import flash.events.Event;
	import flash.geom.Rectangle;


	/**
	 * This is a light version of
	 * 
	 * @author Pavel fljot
	 */
	public class Group extends UIComponent implements IViewport
	{
		protected static const staticScrollRect:Rectangle = new Rectangle();
		
		
		public function Group()
		{
			super();
		}
		
		
		/** @private */
		private var _clipAndEnableScrolling:Boolean;
		
		/**
		 * 
		 */
		public function get clipAndEnableScrolling():Boolean
		{
			return _clipAndEnableScrolling;
		}
		public function set clipAndEnableScrolling(value:Boolean):void
		{
			if (_clipAndEnableScrolling == value)
				return;
			
			_clipAndEnableScrolling = value;
			
			updateScrollPosition();
		}
		
		
		protected var _contentWidth:Number;
		public function get contentWidth():Number
		{
			return _contentWidth;
		}
		
		
		protected var _contentHeight:Number;
		public function get contentHeight():Number
		{
			return _contentHeight;
		}
		
		
		/** @private */
		private var _horizontalScrollPosition:Number = 0;
		
		/**
		 * 
		 */
		public function get horizontalScrollPosition():Number
		{
			return _horizontalScrollPosition;
		}
		public function set horizontalScrollPosition(value:Number):void
		{
			if (_horizontalScrollPosition == value)
				return;
			
			_horizontalScrollPosition = value;
			
			updateScrollPosition();
		}
		
		
		/** @private */
		private var _verticalScrollPosition:Number = 0;
		
		/**
		 * 
		 */
		public function get verticalScrollPosition():Number
		{
			return _verticalScrollPosition;
		}
		public function set verticalScrollPosition(value:Number):void
		{
			if (_verticalScrollPosition == value)
				return;
			
			_verticalScrollPosition = value;
			
			updateScrollPosition();
		}
		
		
		public function validateContentSize():void
		{
			var oldContentWidth:Number = _contentWidth;
			var oldContentHeight:Number = _contentHeight;
			
			measureContentSize();
			
			if (oldContentWidth != _contentWidth || oldContentHeight != _contentHeight)
			{
				dispatchEvent(new Event(Event.RESIZE));
			}
		}
		
			
		override protected function onSizeChanged():void
		{
			super.onSizeChanged();
			
			updateScrollPosition();
		}
		
		
		protected function updateScrollPosition():void
		{
			if (!clipAndEnableScrolling)
				return;
			
			staticScrollRect.x = horizontalScrollPosition;
			staticScrollRect.y = verticalScrollPosition;
			staticScrollRect.width = width;
			staticScrollRect.height = height;
			
			scrollRect = staticScrollRect;
		}
		
		
		protected function measureContentSize():void
		{
			var bounds:Rectangle;
			var child:DisplayObject;
			var i:uint = numChildren;
			var maxWidth:uint;
			var maxHeight:uint;
			while (i-- > 0)
			{
				child = getChildAt(i);
				bounds = child.getBounds(this);
				if (bounds.right > maxWidth)
				{
					maxWidth = bounds.right;
				}
				if (bounds.bottom > maxHeight)
				{
					maxHeight = bounds.bottom;
				}
			}
			
			_contentWidth = maxWidth;
			_contentHeight = maxHeight;
		}
	}
}