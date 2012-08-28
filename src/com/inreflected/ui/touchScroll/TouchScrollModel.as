package com.inreflected.ui.touchScroll
{
	import flash.errors.IllegalOperationError;
	import flash.events.TimerEvent;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.system.Capabilities;
	import flash.utils.Timer;
	/**
	 * @author Pavel fljot
	 */
	public class TouchScrollModel
	{
		/**
		 * @private
		 * Default value of maxPull.
		 */
		public static const MAX_PULL_FACTOR:Number = 0.4;
		/**
		 * @private
		 * Default value of maxBounce.
		 */
		public static const MAX_OVERSHOOT_FACTOR:Number = 0.4;
		/**
		 * Factor for pull curve.
		 */
		private static const PULL_TENSION_FACTOR:Number = 1.5;
		/**
		 *  @private
		 *  Minimum velocity needed to start a throw effect, in pixels per millisecond.
		 */
		private static const MIN_START_VELOCITY:Number = 0.6 * Capabilities.screenDPI / 1000;
		/**
		 * based on 20 pixels on a 252ppi device.
		 */
		private static const DIRECTIONAL_LOCK_THRESHOLD_DISTANCE:Number = Math.round(20 / 252 * Capabilities.screenDPI);
		private static const DIRECTIONAL_LOCK_THRESHOLD_ANGLE:Number = 20 * Math.PI / 180;
		
		public var positionUpdateCallback:Function;
		public var throwCompleteCallback:Function;
		
		/**
		 * Whether to bounce/pull at the edges or not.
		 * 
		 * @default true
		 */
		public var bounceEnabled:Boolean = true;
		public var allwaysBounceHorizontal:Boolean = true;
		public var allwaysBounceVertical:Boolean = true;
		/**
		 *  The amount of deceleration to apply to the velocity for each throw effect period.
		 *  For a faster deceleration, you can switch this to TouchScrollDecelerationRate.FAST
		 *  (which is equal to 0.990).
		 */
		public var decelerationRate:Number = TouchScrollDecelerationRate.NORMAL;
		/**
		 * A flag that determines whether scrolling is disabled in a particular direction.
		 * 
		 * <p>If this property is <code>false</code>(the default), scrolling is permitted
		 * in both horizontal and vertical directions. If this property is <code>true</code>
		 * and the user begins dragging in one general direction (horizontally or vertically),
		 * this manager disables scrolling in the other direction.
		 * If the drag direction is diagonal, then scrolling will not be locked and the user
		 * can drag in any direction until the drag completes.</p>
		 * 
		 * @default false
		 */
		public var directionalLock:Boolean;
		public var directionalLockThresholdDistance:Number = DIRECTIONAL_LOCK_THRESHOLD_DISTANCE;
		public var directionalLockThresholdAngle:Number = DIRECTIONAL_LOCK_THRESHOLD_ANGLE;
		
		/**
		 * Minimum velocity needed to start a throw effect, in pixels per millisecond.
		 * 
		 * @default 0.6 inches/s
		 */
		public var minVelocity:Number = 0;
		/**
		 * Maximum velocity for a throw effect. Not limited by default.
		 */
		public var maxVelocity:Number;
		/**
		 * A way to control pull tention/distance. Should be value between 0 and 1.
		 * Setting this property to NaN produces default pull
		 * with maximum value of 0.4 (40% of viewport size).
		 */
		public var maxPull:Number;
		/**
		 * A way to limit bounce tention/distance.
		 * Setting this property to NaN produces default bounce
		 * with maximum value of 0.4 (40% of viewport size).
		 */
		public var maxBounce:Number;
		
		
		protected var _viewportWidth:Number = 0;
		protected var _viewportHeight:Number = 0;
		protected var _positionX:Number;
		protected var _positionY:Number;
		/**
		 *  Keeps track of the horizontal scroll position
		 *  before scrolling started, used to perform drag scroll.
		 */
		protected var _touchHSP:Number;
		/**
		 *  Keeps track of the vertical scroll position
		 *  before scrolling started, used to perform drag scroll.
		 */
		protected var _touchVSP:Number;
		protected var _lastDirectionX:int;
		protected var _lastDirectionY:int;
		protected var _cummulativeOffsetX:Number;
		protected var _cummulativeOffsetY:Number;
		
		protected var _directionalLockTimer:Timer = new Timer(600, 1);
		protected var _directionalLockThresholdAngleCoefficient:Number;
		protected var _directionalLockCummulativeOffsetX:Number = 0;
		protected var _directionalLockCummulativeOffsetY:Number = 0;
		protected var _directionLockTimerStartPoint:Point;
		
		protected var _velocityCalculator:VelocityCalculator = new VelocityCalculator();
		
		protected var _throwEffect:ThrowEffect;
		/**
		 *  @private
		 *  The final position in the throw effect's horizontal motion path
		 */
		protected var _throwFinalHSP:Number;
		protected var _throwFinalVSP:Number;
		
		//----------------------------------
		// Flags 
		//----------------------------------
		protected var _lockHorizontal:Boolean;
		protected var _lockVertical:Boolean;
		
		
		public function TouchScrollModel()
		{
			_directionalLockTimer.addEventListener(TimerEvent.TIMER, directionalLockTimer_timerHandler);
		}
		
		
		/** @private */
		protected var _scrollBounds:Rectangle = new Rectangle();
		
		/**
		 * Scroll bounds may change for 2 reasons:
		 * 1. Device orientation changing leading to viewport size change and 
		 * 2. Other layout changes.
		 * 
		 * If device orientation is changing it is recommended to simply stop throw effect
		 * (if playing) and snap positions to valid values (because it is hard to guess correctly
		 * for any more complicated decision).
		 * 
		 * 
		 */
		public function get scrollBounds():Rectangle
		{
			return _scrollBounds ? _scrollBounds.clone() : null;
		}
		public function set scrollBounds(value:Rectangle):void
		{
			if (!value)
			{
				throw new IllegalOperationError("Cannot set null scrollBounds.");
			}
			
			if (_scrollBounds == value ||
				(_scrollBounds && _scrollBounds.equals(value)))
				return;
			
			_scrollBounds = value.clone();
			
			updateCanScroll();
			// TODO: somewhere in container need to call: checkScrollPosition()
		}
		
		
		protected var _canScrollHorizontally:Boolean;
		/**
		 * Wether viewport will move horizontally.
		 * 
		 * @see #updateCanScroll()
		 */
		public function get canScrollHorizontally():Boolean
		{
			return _canScrollHorizontally;
		}
		
		
		protected var _canScrollVertically:Boolean;
		/**
		 * Wether viewport will move vertically.
		 * 
		 * @see #updateCanScroll()
		 */
		public function get canScrollVertically():Boolean
		{
			return _canScrollVertically;
		}
		
		
		protected var _isScrolling:Boolean;
		/**
		 * 
		 */
		public function get isScrolling():Boolean
		{
			return _isScrolling;
		}
		
		
		
		
		//--------------------------------------------------------------------------
		//
		//  Public methods
		//
		//--------------------------------------------------------------------------
		
		public function setPosition(x:Number, y:Number):void
		{
			//TODO: что-то ещё тут явно надо.. оно вообще нужно публичное??
			_positionX = x;
			_positionY = y;
		}
		
		
		/**
		 * Viewport size affects pull and bounce effects only.
		 * (So changing it is at any time should not bring any critical problems)
		 */
		public function setViewportSize(width:Number, height:Number):void
		{
			if (!(width >= 0) || !(height >= 0))
			{
				throw new ArgumentError("Viewport dimentions must be non negative. " +
				"Passed values: width = " + width + ", height = " + height);
			}
			
			_viewportWidth = width;
			_viewportHeight = height;
		}
		
		
		public function stop():void
		{
			_directionalLockTimer.reset();
			_lockHorizontal = _lockVertical = false;//TODO: maybe in onDragBegin?
			_isScrolling = false;
			
			if (_throwEffect && _throwEffect.isPlaying)
			{
				_throwEffect.stop(false);
			}
		}
		
		
		public function dispose():void
		{
			if (isScrolling)
			{
				stop();
			}
			if (_directionalLockTimer)
			{
				_directionalLockTimer.stop();
				_directionalLockTimer.removeEventListener(TimerEvent.TIMER, directionalLockTimer_timerHandler);
				_directionalLockTimer = null;
			}
			
			positionUpdateCallback = null;
		}
		
		
		public function onInteractionBegin(positionX:Number, positionY:Number):void
		{
			stopThrowEffectOnTouch();
			
			setPosition(positionX, positionY);//TODO: or set fields directly?
			if (isScrolling)
			{
				// touch while throw effect playing
				
				clipToScrollBounds();
				
				if (directionalLock)
				{
					// Touch while throw effect playing with some direction locked.
					// We want to preserve previous locked or free scrolling.
					
					restartDirectionalLockWatch();
				}
			}
			
			// NB! set touch positions to field values, not arguments
			// because "clipToScrollBounds" may change value.
			_touchHSP = _positionX;
			_touchVSP = _positionY;
			
			_lastDirectionX = _lastDirectionY = 0;
			_cummulativeOffsetX = _cummulativeOffsetY = 0;
			
			_velocityCalculator.reset();
		}
		
		
		public function onDragBegin(dx:Number, dy:Number):void
		{
			updateCanScroll();
			
			_isScrolling = true;
			
			if (directionalLock)
			{
				// TODO: optimize of fuckit?
				_directionalLockThresholdAngleCoefficient = Math.sin(directionalLockThresholdAngle) * 2 / Math.sqrt(2);
			} 
			
			onDragUpdate(dx, dy);
		}
		
		
		public function onDragUpdate(dx:Number, dy:Number):void
		{
			if (directionalLock && canScrollHorizontally && canScrollVertically)
			{
				_directionalLockCummulativeOffsetX += dx;
				_directionalLockCummulativeOffsetY += dy;
				
				if (!_directionalLockTimer.running && !_lockHorizontal && !_lockVertical)
				{
					// We have not decided yet wheather locked or free scrolling
					
					//TODO: optimization. Options:
					// 1. precalculate square of directionalLockThresholdDistance
					// 2. use square zone instead of circle
					const dSqr:Number = Math.sqrt(_directionalLockCummulativeOffsetX * _directionalLockCummulativeOffsetX +
						_directionalLockCummulativeOffsetY * _directionalLockCummulativeOffsetY);
					if (dSqr >= directionalLockThresholdDistance)
					{
						// We are out of our "directional lock safe zone"
						// so we have to make decision now
						
						const angle:Number = Math.atan2(_directionalLockCummulativeOffsetY, _directionalLockCummulativeOffsetX);
						const threshold:Number = Math.sin(directionalLockThresholdAngle);
						if (Math.abs(Math.sin(angle)) < threshold)
						{
							_lockHorizontal = true;
							trace("directionalLock set to 'horizontal'");
						}
						else
						if (Math.abs(Math.cos(angle)) < threshold)
						{
							_lockVertical = true;
							trace("directionalLock set to 'vertical'");
						}
						else
						{
							trace("directionalLock set to 'free'");
						}
												
						restartDirectionalLockWatch();
					}
				}
////				else if (!directionalLockTimer.running ||
////					(Math.abs(event.offsetX) >= Gesture.DEFAULT_SLOP && Math.abs(event.offsetY) >= Gesture.DEFAULT_SLOP))
				else if (Math.abs(_directionalLockCummulativeOffsetX) >= directionalLockThresholdDistance ||
						 Math.abs(_directionalLockCummulativeOffsetY) >= directionalLockThresholdDistance)
				{
					// Looks like we are moving intensively enough
					restartDirectionalLockWatch();
				}
			}
			
			if (_lockVertical) dx = 0;
			if (_lockHorizontal) dy = 0;
			
			_lastDirectionX = (canScrollHorizontally && dx != 0) ? (dx > 0 ? 1 : -1) : 0;
			_lastDirectionY = (canScrollVertically && dy != 0) ? (dy > 0 ? 1 : -1) : 0;
			
			_velocityCalculator.addOffsets(dx, dy);
			
			performDrag(dx, dy);
		}
		
		
		public function onDragEnd():void
		{
			_directionalLockTimer.reset();
			
			if (isScrolling)
			{
				const throwVelocity:Point = calculateThrowVelocity();
				performThrow(throwVelocity.x, throwVelocity.y);
			}
			else
			{
				performThrow(0, 0);
			}
		}
		
		
		public function performThrow(velocityX:Number, velocityY:Number):void
		{
			if (isNaN(velocityX) || isNaN(velocityY))
			{
				// Could be useful to catch velocity calculation bugs.
				throw new ArgumentError("One of the velocities is NaN.");
			}
			
			if (setupThrowEffect(velocityX, velocityY))
			{
				_throwEffect.play();
			}
		}
		
		
		
		
		//--------------------------------------------------------------------------
		//
		//  Protected methods
		//
		//--------------------------------------------------------------------------
		
		protected function updateCanScroll():void
		{
			_canScrollHorizontally = (bounceEnabled && allwaysBounceHorizontal) || _scrollBounds.width > 0;
			_canScrollVertically = (bounceEnabled && allwaysBounceVertical) || _scrollBounds.height > 0;
		}
		
		
		protected function clipToScrollBounds():void
		{
			var changed:Boolean = false;
			
			if (_positionX < _scrollBounds.left)
			{
				_positionX = _scrollBounds.left;
				changed = true;
			}
			else
			if (_positionX > _scrollBounds.right)
			{
				_positionX = _scrollBounds.right;
				changed = true;
			}
			
			if (_positionY < _scrollBounds.top)
			{
				_positionY = _scrollBounds.top;
				changed = true;
			}
			else
			if (_positionY > _scrollBounds.bottom)
			{
				_positionY = _scrollBounds.bottom;
				changed = true;
			}
			
			if (changed)
			{
				positionUpdateCallback(_positionX, _positionY);
			}
		}
		
		
		/**
		 * Performs actual calculations for position update on pan (drag).
		 */
		protected function performDrag(dx:Number, dy:Number):void
		{
			_cummulativeOffsetX += dx;
			_cummulativeOffsetY += dy;
			
			var viewportSize:Number;//viewport width or height
			// More natural pull formula can be presented as y = f(x)
			// where x is pullProgress, y is resultingPullProgress.
			// resulting pullOffset = viewportSize * resultingPullProgress 
			// It has these features:
			// resuling pullOffset always <= pullOffset (graph is always lower then y = x);
			// slope of f(x) is constant or gradually decreses.
			
			// http://graph-plotter.cours-de-math.eu/
			// 0.4*(1 - (1-x)^(1.5)) [1.5 == PULL_TENTION_FACTOR]
			// x/2
			
			var pullOffset:Number;// >=0
			var pullProgress:Number;// [0.. 1]
			
			const scrollBounds:Rectangle = _scrollBounds;
			const pullAllowed:Boolean = (maxPull != maxPull || maxPull > 0);
			
			if (canScrollHorizontally)
			{
				var newHSP:Number = _touchHSP - _cummulativeOffsetX;
				if (newHSP < scrollBounds.left || newHSP > scrollBounds.right)
				{
					// If we're pulling the list past its end, we want it to move
					// only a portion of the finger distance to simulate tension.
					if (pullAllowed)
					{
						viewportSize = _viewportWidth;
						if (newHSP < scrollBounds.left)
						{
							// @deprecated simple tension formula:
							// newHSP = scrollBounds.left + (newHSP - scrollBounds.left) * 0.5;
							
							// more natural pull tension:
							pullOffset = scrollBounds.left - newHSP;
							pullProgress = pullOffset < viewportSize ? pullOffset / viewportSize : 1;
							pullProgress = Math.min((maxPull || MAX_PULL_FACTOR) * (1 - Math.pow(1 - pullProgress, PULL_TENSION_FACTOR)), pullProgress);
							newHSP = scrollBounds.left - viewportSize * pullProgress;
						}
						else
						{
							// @deprecated simple tension formula:
							// newHSP = scrollBounds.right + (newHSP - scrollBounds.right) * 0.5;
							
							// more natural pull tension:
							pullOffset = newHSP - scrollBounds.right;
							pullProgress = pullOffset < viewportSize ? pullOffset / viewportSize : 1;
							pullProgress = Math.min((maxPull || MAX_PULL_FACTOR) * (1 - Math.pow(1 - pullProgress, PULL_TENSION_FACTOR)), pullProgress);
							newHSP = scrollBounds.right + viewportSize * pullProgress;
						}
					}
					else
					{
						newHSP = newHSP < scrollBounds.left ? scrollBounds.left : scrollBounds.right;
					}
				}
				_positionX = newHSP;
			}
			
			if (canScrollVertically)
			{
				var newVSP:Number = _touchVSP - _cummulativeOffsetY;
				if (newVSP < scrollBounds.top || newVSP > scrollBounds.bottom)
				{
					// If we're pulling the list past its end, we want it to move
					// only a portion of the finger distance to simulate tension.
					if (pullAllowed)
					{
						viewportSize = _viewportHeight;
						if (newVSP < scrollBounds.top)
						{
							// @deprecated simple tension formula:
							// newVSP = scrollBounds.top + (newVSP - scrollBounds.top) * 0.5;
							
							// more natural pull tension:
							pullOffset = scrollBounds.top - newVSP;
							pullProgress = pullOffset < viewportSize ? pullOffset / viewportSize : 1;
							pullProgress = Math.min((maxPull || MAX_PULL_FACTOR) * (1 - Math.pow(1 - pullProgress, PULL_TENSION_FACTOR)), pullProgress);
							newVSP = scrollBounds.top - viewportSize * pullProgress;
						}
						else
						{
							// @deprecated simple tension formula:
							// newVSP = scrollBounds.bottom + (newVSP - scrollBounds.bottom) * 0.5;
							
							// more natural pull tension:
							pullOffset = newVSP - scrollBounds.bottom;
							pullProgress = pullOffset < viewportSize ? pullOffset / viewportSize : 1;
							pullProgress = Math.min((maxPull || MAX_PULL_FACTOR) * (1 - Math.pow(1 - pullProgress, PULL_TENSION_FACTOR)), pullProgress);
							newVSP = scrollBounds.bottom + viewportSize * pullProgress;
						}
					}
					else
					{
						newVSP = newVSP < scrollBounds.top ? scrollBounds.top : scrollBounds.bottom;
					}
				}
				_positionY = newVSP;
			}
			
			positionUpdateCallback(_positionX, _positionY);
		}
		
		
		protected function restartDirectionalLockWatch():void
		{
			_directionalLockCummulativeOffsetX = 0;
			_directionalLockCummulativeOffsetY = 0;
//			_directionLockTimerStartPoint = panGesture.location;
			_directionalLockTimer.reset();
			_directionalLockTimer.start();
		}
		
		
		protected function calculateThrowVelocity():Point
		{
			const throwVelocity:Point = _velocityCalculator.calculateVelocity();
			
			if (throwVelocity.length < minVelocity)
			{
				throwVelocity.x = 0;
				throwVelocity.y = 0;
			}
			else if (!isNaN(maxVelocity) && maxVelocity > minVelocity)
			{
				throwVelocity.normalize(maxVelocity);
			}
			
			return throwVelocity;
		}
		
		
		/**
		 *  @private
		 *  Set up the effect to be used for the throw animation
		 */
		protected function setupThrowEffect(velocityX:Number, velocityY:Number):Boolean
		{
			if (!_throwEffect)
			{
				_throwEffect = new ThrowEffect();
				_throwEffect.onUpdateCallback = onThrowEffectUpdate;
				_throwEffect.onCompleteCallback = onThrowEffectComplete;
			}
			
			const scrollBounds:Rectangle = _scrollBounds;
			var minHSP:Number = scrollBounds.left;
			var minVSP:Number = scrollBounds.top;
			var maxHSP:Number = scrollBounds.right;
			var maxVSP:Number = scrollBounds.bottom;
			
			var decelerationRate:Number = this.decelerationRate;
			
//			if (pagingEnabled)
//			{
//				// See whether a page switch is warranted for this touch gesture.
//				if (canScrollHorizontally)
//				{
//					_currentPageHSP = determineNewPageScrollPosition(velocityX, HORIZONTAL_SCROLL_POSITION);
//					// "lock" to the current page
//					minHSP = maxHSP = _currentPageHSP; 
//				}
//				if (canScrollVertically)
//				{
//					_currentPageVSP = determineNewPageScrollPosition(velocityY, VERTICAL_SCROLL_POSITION);
//					// "lock" to the current page
//					minVSP = maxVSP = _currentPageVSP;	
//				}
//				
//				// Flex team attenuates velocity here,
//				// but I think it's better to adjust friction to preserve correct starting velocity.
//				decelerationRate *= 0.98;
//			}
			
//			_throwEffect.propertyNameX = canScrollHorizontally ? HORIZONTAL_SCROLL_POSITION : null;
//			_throwEffect.propertyNameY = canScrollVertically ? VERTICAL_SCROLL_POSITION : null;
			_throwEffect.startingVelocityX = velocityX;
			_throwEffect.startingVelocityY = velocityY;
			_throwEffect.startingPositionX = _positionX;
			_throwEffect.startingPositionY = _positionY;
			_throwEffect.minPositionX = minHSP;
			_throwEffect.minPositionY = minVSP;
			_throwEffect.maxPositionX = maxHSP;
			_throwEffect.maxPositionY = maxVSP;
			_throwEffect.decelerationRate = decelerationRate;
			_throwEffect.viewportWidth = _viewportWidth;
			_throwEffect.viewportHeight = _viewportHeight;
			_throwEffect.pull = (maxPull > 0 || maxPull != maxPull);
			_throwEffect.bounce = bounceEnabled;
			_throwEffect.maxBounce = (maxBounce > 0 ? maxBounce : MAX_OVERSHOOT_FACTOR);
			
//	        // In snapping mode, we need to ensure that the final throw position is snapped appropriately.
////	        _throwEffect.finalPositionFilterFunction = snappingFunction == null ? null : getSnappedPosition; 
//	        _throwEffect.finalPositionFilterFunction = snappingDelegate ? snappingDelegate.getSnappedPosition : null;
			_throwEffect.finalPositionFilterFunction = null;//FIXME: temporary line
			
			//TODO: delegate to adjust final position
			if (!_throwEffect.setup())
			{
				stop();
				return false;
			}
			
			_throwFinalHSP = _throwEffect.finalPosition.x;
			_throwFinalVSP = _throwEffect.finalPosition.y;
			
			return true;
		}
		
		
		/**
		 *  Stop the effect if it's currently playing and prepare for a possible scroll,
		 *  snap to valid scroll positions
		 */
		protected function stopThrowEffectOnTouch():void
		{
			if (_throwEffect && _throwEffect.isPlaying)
			{
				// stop the effect.  we don't want to move it to its final value...we want to stop it in place
				_throwEffect.stop(false);
				
				// Flex calls snapContentScrollPosition() here to
				// Snap the scroll position to the content in case the empty space beyond the edge was visible
				// due to bounce/pull.
				// That doesn't seem necessary for me.
			}
		}
		
		
		
		
		//--------------------------------------------------------------------------
		//
		//  Event handlers
		//
		//--------------------------------------------------------------------------
		
		protected function directionalLockTimer_timerHandler(event:TimerEvent):void
		{
//			if (_directionLockTimerStartPoint.subtract(panGesture.location).length < Gesture.DEFAULT_SLOP)
//			{
				_lockHorizontal = _lockVertical = false;
				trace("directionalLock reset");
//			}
//			else
//			{
//				restartDirectionalLockWatch();
//			}
		}
		
		
		protected function onThrowEffectUpdate(positionX:Number, positionY:Number):void
		{
			_positionX = positionX;
			_positionY = positionY;
			
			positionUpdateCallback(_positionX, _positionY);
		}
		
		
		protected function onThrowEffectComplete():void
		{
			stop();
			throwCompleteCallback && throwCompleteCallback();
		}
	}
}
