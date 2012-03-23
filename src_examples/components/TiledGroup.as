package components
{
	import flash.display.BitmapData;
	import flash.display.Graphics;
	import flash.display.Sprite;


	/**
	 * @author Pavel fljot
	 */
	public class TiledGroup extends Group
	{
		private static const borderPattern:BitmapData = createBorderPattern();
		
		protected var s:Sprite;
		protected var tileColorsMatrix:Array = [];
		
		
		public function TiledGroup()
		{
			super();
		}
		
		
		private static function createBorderPattern():BitmapData
		{
			var bmd:BitmapData = new BitmapData(4, 4, false, 0x222222);
			var color:uint = 0xEEEEEE;
			bmd.setPixel(0, 0, color);
			bmd.setPixel(3, 1, color);
			bmd.setPixel(2, 2, color);
			bmd.setPixel(1, 3, color);
			
			return bmd;
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
		private var _numRows:uint = 80;
		
		/**
		 * 
		 */
		public function get numRows():uint
		{
			return _numRows;
		}
		public function set numRows(value:uint):void
		{
			if (_numRows == value)
				return;
			
			_numRows = value;
			
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
			var nr:uint = numRows;
			var nc:uint = numCols;
			var w:uint = cellWidth;
			var h:uint = cellHeight;
			var g:Graphics = s.graphics;
			g.clear();
			var color:uint;
			var untypedColor:*;
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
					g.drawRect(w * c, h * r, w, h);
					g.endFill();
				}
			}
			
			g.beginBitmapFill(borderPattern);
			g.drawRect(0, 0, w * nc, h * nr);
			var borderOffsetX:uint = Math.min(cellWidth * 0.1, 10);
			var borderOffsetY:uint = Math.min(cellHeight * 0.1, 10);
			g.drawRect(borderOffsetX, borderOffsetY, w * nc - 2 * borderOffsetX, h * nr - 2 * borderOffsetY);
			g.endFill();
			
			
			validateContentSize();
		}
	}
}