package com.inreflected.ui.touchScroll
{
	import flash.geom.Point;
	import flash.utils.getTimer;


	/**
	 * @author Pavel fljot
	 */
	public class VelocityCalculator
	{
		/**
		 *  @private
		 *  Weights to use when calculating velocity, giving the last velocity more of a weight 
		 *  than the previous ones.
		 */
		private static const VELOCITY_WEIGHTS:Vector.<Number> = Vector.<Number>([1, 1.33, 1.66, 2, 2.33]);
		/**
		 *  @private
		 *  Number of mouse movements to keep in the history to calculate 
		 *  velocity.
		 */
		private static const HISTORY_LENGTH:uint = 5;
		
		/**
		 *  @private
		 *  Keeps track of the coordinates where the mouse events 
		 *  occurred.  We use this for velocity calculation along 
		 *  with timeHistory.
		 */
		protected var _coordinatesHistory:Vector.<Point>;
		/**
		 *  @private
		 *  Length of items in the mouseEventCoordinatesHistory and 
		 *  timeHistory Vectors since a circular buffer is used to 
		 *  conserve points.
		 */
		protected var _historyLength:uint = 0;
		/**
		 *  @private
		 *  A history of times the last few mouse events occurred.
		 *  We keep HISTORY objects in memory, and we use this mouseEventTimeHistory
		 *  Vector along with mouseEventCoordinatesHistory to determine the velocity
		 *  a user was moving their fingers.
		 */
		protected var _timeHistory:Vector.<int>;
		
		protected var _lastUpdateTime:int;
		
		
		public function VelocityCalculator()
		{
			_coordinatesHistory = new Vector.<Point>(HISTORY_LENGTH);
			_timeHistory = new Vector.<int>(HISTORY_LENGTH);
		}
		
		
		public function reset():void
		{
			// reset circular buffer index/length
			_historyLength = 0;
			_lastUpdateTime = getTimer();
		}
		
		
		public function addOffsets(dx:Number, dy:Number, dt:uint = 0):Point
		{
			// either use a Point object already created or use one already created
			// in mouseEventCoordinatesHistory
			var currentPoint:Point;
			const currentIndex:int = (_historyLength % HISTORY_LENGTH);
			if (_coordinatesHistory[currentIndex])
			{
				currentPoint = _coordinatesHistory[currentIndex] as Point;
				currentPoint.x = dx;
				currentPoint.y = dy;
			}
			else
			{
				currentPoint = new Point(dx, dy);
				_coordinatesHistory[currentIndex] = currentPoint;
			}
			
			// add time history as well
			const now:int = getTimer();
			_timeHistory[currentIndex] = dt || (now - _lastUpdateTime);
			_lastUpdateTime = now;
//			CONFIG::Debug
//			{
//				trace("adding mouses event history:", dx, dy, _mouseEventTimeHistory[currentIndex]);
//			}
			
			// increment current length if appropriate
			_historyLength++;
			
			return currentPoint;
		}
		
		
		public function calculateVelocity(lastDt:uint = 0):Point
		{
			if (lastDt == 0)
			{
				lastDt = getTimer() - _lastUpdateTime;
			}
			if (lastDt > 100)
			{
				// No movement for the past 100ms, so we treat it as a full stop.
				return new Point(0, 0);
			}
			
			
			const len:int = (_historyLength > HISTORY_LENGTH ? HISTORY_LENGTH : _historyLength);
			
			// if haven't wrapped around, then startIndex = 0.  If we've wrapped around,
			// then startIndex = mouseEventLength % EVENT_HISTORY_LENGTH.  The equation
			// below handles both of those cases
			const startIndex:int = ((_historyLength - len) % HISTORY_LENGTH);
			
			// variables to store a running average
			var weightedSumX:Number = 0;
			var weightedSumY:Number = 0;
			var totalWeight:Number = 0;
			
			var currentIndex:int = startIndex;
			var velocityWeight:Number;
			var currCoord:Point;
			
			var i:int = 0;
			while (i < len)
			{
				currCoord = _coordinatesHistory[currentIndex] as Point;
				
				var dt:int = _timeHistory[currentIndex];
				var dx:Number = currCoord.x;
				var dy:Number = currCoord.y;
				
				// TODO: фиксим "особенности платформы" (tm)?
				if (dt < 10)
				{
					dt = 10;
				}
				
				// calculate a weighted sum for velocities
				velocityWeight = VELOCITY_WEIGHTS[i];
				weightedSumX += (dx / dt) * velocityWeight;
				weightedSumY += (dy / dt) * velocityWeight;
				totalWeight += velocityWeight;
				
				i++;
				currentIndex++;
				if (currentIndex >= HISTORY_LENGTH)
					currentIndex = 0;
			}
			
			const vel:Point = new Point(0, 0);
			if (totalWeight > 0)
			{
				vel.x = weightedSumX / totalWeight;
				vel.y = weightedSumY / totalWeight;
			}
			
			CONFIG::Debug
			{
				trace('calculateVelocity(): ' + (vel));
			}
			return vel;
		}
	}
}
