package components
{
	import flash.display.Graphics;
	import flash.display.Sprite;


	/**
	 * @author Pavel fljot
	 */
	public class MetroGalleryGroup extends Group
	{
		protected var s:Sprite;
		protected var tileColorsMatrix:Array = [];
		
		
		public function MetroGalleryGroup()
		{
			super();
		}
		
		
		/** @private */
		private var _numCols:uint = 10;
		
		/**
		 * 
		 */
		public function get numCols():uint
		{
			return _numCols;
		}
		public function set numCols(value:uint):void
		{
			if (_numCols == value)
				return;
			
			_numCols = value;
			
			// invalidate...()
			redrawTiles();
		}
		
		
		/** @private */
		private var _cellWidth:uint = 128;
		
		/**
		 * 
		 */
		public function get cellWidth():uint
		{
			return _cellWidth;
		}
		public function set cellWidth(value:uint):void
		{
			if (_cellWidth == value)
				return;
			
			_cellWidth = value;
			
			// invalidate...()
			redrawTiles();
		}
		
		
		/** @private */
		private var _cellHeight:uint = 128;
		
		/**
		 * 
		 */
		public function get cellHeight():uint
		{
			return _cellHeight;
		}
		public function set cellHeight(value:uint):void
		{
			if (_cellHeight == value)
				return;
			
			_cellHeight = value;
			
			// invalidate...()
			redrawTiles();
		}
		
		
		override protected function preinit():void
		{
			super.preinit();
			
			s = new Sprite();
			addChild(s);
		}
		
			
		override protected function init():void
		{
			super.init();
			
			redrawTiles();
		}
		
		
		protected function redrawTiles():void
		{
			if (isNaN(width) || isNaN(height))
				return;
			
			var nr:uint = 1;
			var nc:uint = numCols;
			var w:uint = cellWidth;
			var h:uint = cellHeight;
			var hPadding:uint = (width - w) >> 1;
			var vPadding:uint = (height - h) >> 1;
			const popOutWidth:uint = 20;
			var g:Graphics = s.graphics;
			g.clear();
			
			var color:uint;
			var untypedColor:*;
			var nextX:uint = hPadding;
			var nextY:uint = vPadding;
			for (var r:uint = 0; r < nr; r++)
			{
				if (!tileColorsMatrix[r])
				{
					tileColorsMatrix[r] = [];
				}
				
				for (var c:uint = 0; c < nc; c++)
				{
					untypedColor = tileColorsMatrix[r][c];
					if (untypedColor == undefined)
					{
						color = 0xFFFFFF * Math.random();
						tileColorsMatrix[r][c] = color;
					}
					else
					{
						color = uint(untypedColor);
					}
					g.beginFill(color);
					g.drawRect(nextX, nextY, w, h);
					g.endFill();
					
					nextX = nextX + w + hPadding - popOutWidth;
				}
			}
			
			// fill with transparent fill for full-size interactivity
			g.beginFill(0, 0);
			g.drawRect(0, 0, nextX + popOutWidth, height);
			g.endFill();			
			
			validateContentSize();
		}
	}
}
