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
		protected var _positionX:Number = 0;
		protected var _positionY:Number = 0;
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
		
		protected var _currentPageHSP:Number = 0;
		protected var _currentPageVSP:Number = 0;
		
		//----------------------------------
		// Flags 
		//----------------------------------
		protected var _lockHorizontal:Boolean;
		protected var _lockVertical:Boolean;
		protected var _throwReachedEdgePosition:Boolean;
		
		
		public function TouchScrollModel()
		{
			_directionalLockTimer.addEventListener(TimerEvent.TIMER, directionalLockTimer_timerHandler);
		}
		
		
		/** @private */
		protected var _scrollBounds:Rectangle = new Rectangle();
		protected var _measuredScrollBounds:Rectangle = new Rectangle();
		protected var _explicitScrollBounds:Rectangle;
		
		/**
		 * Scroll bounds may change for 2 reasons:
		 * 1. Device orientation changing leading to viewport size change and 
		 * 2. Other layout changes.
		 * 
		 * If device orientation is changing it is recommended to simply stop throw effect
		 * (if playing) and snap positions to valid values (because it is hard to guess correctly
		 * for any more complicated decision).
		 */
		public function get scrollBounds():Rectangle
		{
			return _scrollBounds.clone();
		}
		public function set scrollBounds(value:Rectangle):void
		{
			if (_explicitScrollBounds == value ||
				(_explicitScrollBounds && value && _explicitScrollBounds.equals(value)))
				return;
			
			_explicitScrollBounds = value ? value.clone() : null;
			
			invalidateScrollBounds();
		}
		
		
		protected var _contentWidth:Number = 0;
		public function get contentWidth():Number
		{
			return _contentWidth;
		}
		
		
		protected var _contentHeight:Number = 0;
		public function get contentHeight():Number
		{
			return _contentHeight;
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
		
		
		protected var _inTouchInteraction:Boolean;
		public function get inTouchInteraction():Boolean
		{
			return _inTouchInteraction;
		}
		
		
		protected var _isScrolling:Boolean;
		/**
		 * 
		 */
		public function get isScrolling():Boolean
		{
			return _isScrolling;
		}
		
		
		/** @private */
		private var _pagingEnabled:Boolean;
		
		/**
		 * 
		 */
		public function get pagingEnabled():Boolean
		{
			return _pagingEnabled;
		}
		public function set pagingEnabled(value:Boolean):void
		{
			if (_pagingEnabled == value)
				return;
			
			_pagingEnabled = value;
			
			invalidateScrollBounds();
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
		
		
		public function setContentSize(width:Number, height:Number):void
		{
			//TODO: maybe allow NaN for unlimited bounds (endless scrolling)?
			if (!(width >= 0) || !(height >= 0))
			{
				throw new ArgumentError("Content size must be non negative. " +
				"Passed values: width = " + width + ", height = " + height);
			}
			
			_contentWidth = width;
			_contentHeight = height;
			
			invalidateScrollBounds();
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
			
			invalidateScrollBounds();
		}
		
		/**
		 * An alias to scrollBounds setter, just for consistency in "setXXX" API.
		 */
		public function setScrollBounds(bounds:Rectangle):void
		{
			this.scrollBounds = bounds;
		}
		
		
		public function stop():void
		{
			_inTouchInteraction = false;
			
			_directionalLockTimer.reset();
			_lockHorizontal = _lockVertical = false;//TODO: maybe in onDragBegin?
			_isScrolling = false;
			
			if (_throwEffect && _throwEffect.isPlaying)
			{
				_throwEffect.stop(false);
			}
			
			snapToValidPosition();
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
			
			_inTouchInteraction = true;
			
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
			
			if (_lockVertical || !canScrollHorizontally) dx = 0;
			if (_lockHorizontal || !canScrollVertically) dy = 0;
			
			_lastDirectionX = (canScrollHorizontally && dx != 0) ? (dx > 0 ? 1 : -1) : 0;
			_lastDirectionY = (canScrollVertically && dy != 0) ? (dy > 0 ? 1 : -1) : 0;
			
			_velocityCalculator.addOffsets(dx, dy);
			
			performDrag(dx, dy);
		}
		
		
		public function onInteractionEnd():void
		{
			_inTouchInteraction = false;
			
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
		
		protected function setEffectiveScrollBounds(left:Number, top:Number, right:Number, bottom:Number):void
		{
			_scrollBounds.left = left;
			_scrollBounds.top = top;
			_scrollBounds.right = right;
			_scrollBounds.bottom = bottom;
			
			updateCanScroll();
			
			validatePosition();
		}
		
		
		protected function getExplicitOrMeasuredScrollBounds():Rectangle
		{
			return _explicitScrollBounds || _measuredScrollBounds;
		}
		
		
		protected function updateCanScroll():void
		{
			const scrollBounds:Rectangle = _scrollBounds;
			_canScrollHorizontally = (bounceEnabled && allwaysBounceHorizontal) || scrollBounds.width > 0;
			_canScrollVertically = (bounceEnabled && allwaysBounceVertical) || scrollBounds.height > 0;
		}
		
		
		protected function measureScrollBounds():void
		{
			_measuredScrollBounds.left = 0;
			_measuredScrollBounds.top = 0;
			
			if (pagingEnabled)
			{
				_measuredScrollBounds.width = Math.max(0, int(_contentWidth / _viewportWidth) - 1) * _viewportWidth;
				_measuredScrollBounds.height = Math.max(0, int(_contentHeight / _viewportHeight) - 1) * _viewportHeight;
			}
			else
			{
				_measuredScrollBounds.width = Math.max(0, _contentWidth - _viewportWidth);
				_measuredScrollBounds.height = Math.max(0, _contentHeight - _viewportHeight);
			}
		}
		
		
		protected function invalidateScrollBounds():void
		{
			measureScrollBounds();
			const scrollBounds:Rectangle = getExplicitOrMeasuredScrollBounds();
			setEffectiveScrollBounds(scrollBounds.left, scrollBounds.top, scrollBounds.right, scrollBounds.bottom);
		}
		
		
		/**
		 * Used to adjust scroll positions on interaction start (if it's currently pulled/bounces).
		 */
		protected function clipToScrollBounds():void
		{
			const scrollBounds:Rectangle = _scrollBounds;
			var changed:Boolean = false;
			
			if (_positionX < scrollBounds.left)
			{
				_positionX = scrollBounds.left;
				changed = true;
			}
			else
			if (_positionX > scrollBounds.right)
			{
				_positionX = scrollBounds.right;
				changed = true;
			}
			
			if (_positionY < scrollBounds.top)
			{
				_positionY = scrollBounds.top;
				changed = true;
			}
			else
			if (_positionY > scrollBounds.bottom)
			{
				_positionY = scrollBounds.bottom;
				changed = true;
			}
			
			if (changed)
			{
				positionUpdateCallback(_positionX, _positionY);
			}
		}
		
		
		protected function validatePosition():void
		{
			const scrollBounds:Rectangle = _scrollBounds;
			
			if (_throwEffect && _throwEffect.isPlaying)
			{
				var needRethrow:Boolean = false;
				
				if (!pagingEnabled)
				{
					// Condition explanation:
					// _throwReachedEdgePosition == true means throw effect will bounce off the edge,
					// which is probably not desired given new scroll bounds.
					if (_throwReachedEdgePosition ||
						_throwFinalVSP > scrollBounds.bottom || _throwFinalVSP < scrollBounds.top ||
						_throwFinalHSP > scrollBounds.right || _throwFinalHSP < scrollBounds.left)
					{
						needRethrow = true;
					}
				}
				else if (getSnappedPosition(_throwFinalVSP, _viewportHeight, scrollBounds.top, scrollBounds.bottom) != _throwFinalVSP ||
						 getSnappedPosition(_throwFinalHSP, _viewportWidth, scrollBounds.left, scrollBounds.right) != _throwFinalHSP)
				{
					needRethrow = true;
				}
				
				//TODO: this case could be potentially improved
				
				if (needRethrow)
				{
					// Stop the current animation and start a new one that gets us to the correct position.
					
					// Get the effect's current velocity
					const velocity:Point = _throwEffect.getCurrentVelocity();
					
					// Stop the existing throw animation now that we've determined its current velocities.
					_throwEffect.stop(false);
					
					// Now perform a new throw to get us to the right position.
					if (setupThrowEffect(-velocity.x, -velocity.y))
					{
						_throwEffect.play();
					}
				}
			}
			else
			if (_inTouchInteraction)
			{
				// Touch interaction is in effect.
				
				if (_positionX < scrollBounds.left || _positionX > scrollBounds.right)
				{
					// We were in pull and still are - do nothing (i.e. "pull to refresh")
					// or we are simply out of the bounds now (unlikely to happen, TODO clip maybe)
				}
				else
				{
					_touchHSP = _positionX;
					_cummulativeOffsetX = 0;
				}
				
				if (_positionY < scrollBounds.top || _positionY > scrollBounds.bottom)
				{
					// We were in pull and still are - do nothing (i.e. "pull to refresh")
					// or we are simply out of the bounds now (unlikely to happen, TODO clip maybe)
				}
				else
				{
					_touchVSP = _positionY;
					_cummulativeOffsetY = 0;
				}
			}
			else
			{
				// No touch interaction is in effect, but the content may be sitting at
				// a scroll position that is now invalid.  If so, snap the content to
				// a valid position.
				
				snapToValidPosition();
			}
		}
		
		
		protected function snapToValidPosition():void
		{
			const scrollBounds:Rectangle = _scrollBounds;
			var pos:Number;
			var changed:Boolean = false;
			
			pos = getSnappedPosition(_positionX, _viewportWidth, scrollBounds.left, scrollBounds.right);
			if (_positionX != pos)
			{
				_positionX = pos;
				changed = true;
			}
			
			pos = getSnappedPosition(_positionY, _viewportHeight, scrollBounds.top, scrollBounds.bottom);
			if (_positionY != pos)
			{
				_positionY = pos;
				changed = true;
			}
			
			if (pagingEnabled)
			{
				//TODO: move this somewhere else maybe?
				_currentPageHSP = _positionX;
				_currentPageVSP = _positionY;
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
			var minX:Number = scrollBounds.left;
			var minY:Number = scrollBounds.top;
			var maxX:Number = scrollBounds.right;
			var maxY:Number = scrollBounds.bottom;
			
			var decelerationRate:Number = this.decelerationRate;
			
			if (pagingEnabled)
			{
				// See whether a page switch is warranted for this touch gesture.
				if (canScrollHorizontally)
				{
					_currentPageHSP = determineNewPageScrollPosition(velocityX, _positionX, _currentPageHSP, _viewportWidth, minX, maxX);
					// "lock" to the current page
					minX = maxX = _currentPageHSP; 
				}
				if (canScrollVertically)
				{
					_currentPageVSP = determineNewPageScrollPosition(velocityY, _positionY, _currentPageVSP, _viewportHeight, minY, maxY);
					// "lock" to the current page
					minY = maxY = _currentPageVSP;	
				}
				
				// Normally we don't want to see much of a bounce, so
				// Flex team attenuates velocity here,
				// but I think it's better to adjust friction to preserve correct starting velocity.
				decelerationRate *= 0.98;
			}
			
//			_throwEffect.propertyNameX = canScrollHorizontally ? HORIZONTAL_SCROLL_POSITION : null;
//			_throwEffect.propertyNameY = canScrollVertically ? VERTICAL_SCROLL_POSITION : null;
			_throwEffect.startingVelocityX = velocityX;
			_throwEffect.startingVelocityY = velocityY;
			_throwEffect.startingPositionX = _positionX;
			_throwEffect.startingPositionY = _positionY;
			_throwEffect.minPositionX = minX;
			_throwEffect.minPositionY = minY;
			_throwEffect.maxPositionX = maxX;
			_throwEffect.maxPositionY = maxY;
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
			
			_throwReachedEdgePosition = (_throwFinalVSP == maxY || _throwFinalVSP == minY ||
										 _throwFinalHSP == maxX || _throwFinalHSP == minX);
			
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
		
		
		/**
		 *  This function determines whether a switch to an adjacent page is warranted, given 
		 *  the distance dragged and/or the velocity thrown. 
		 */
		protected function determineNewPageScrollPosition(velocity:Number,
														  position:Number,
														  currPagePosition:Number,
														  viewportSize:Number,
														  minPosition:Number,
														  maxPosition:Number):Number
		{
			const stationaryOffsetThreshold:Number = viewportSize * 0.5;
			var pagePosition:Number;
			
			// Check both the throw velocity and the drag distance. If either exceeds our threholds, then we switch to the next page.
			if (velocity < -minVelocity || position >= currPagePosition + stationaryOffsetThreshold)
			{
				// Go to the next page
				// Set the new page scroll position so the throw effect animates the page into place
				pagePosition = Math.min(currPagePosition + viewportSize, maxPosition);
			}
			else
			if (velocity > minVelocity || position <= currPagePosition - stationaryOffsetThreshold)
			{
				// Go to the previous page
				pagePosition = Math.max(currPagePosition - viewportSize, minPosition);
			}
			else
			{
				// Snap to the current one
				pagePosition = currPagePosition;
			}
			
			// Ensure the new page position is snapped appropriately
			pagePosition = getSnappedPosition(pagePosition, viewportSize, minPosition, maxPosition);
			
			return pagePosition;
		}
		
		
		/**
		 *  This function takes a scroll position and the associated property name, and finds
		 *  the nearest snapped position (i.e. one that satifises the current scrollSnappingMode).
		 */
		protected function getSnappedPosition(position:Number, viewportSize:Number, minPosition:Number, maxPosition:Number):Number
		{
//			if (pagingEnabled && !snappingDelegate)//TODO different condition if custom snapping defined
			if (pagingEnabled)
			{
				// If we're in paging mode and no snapping is enabled, then we must snap
				// the position to the beginning of a page. i.e. a multiple of the 
				// viewport size.
				if (viewportSize > 0)
				{
					// If minPosition is NaN or some Infinity we use 0 as a base.
					const basePosition:Number = ((minPosition * 0) == 0) ? minPosition : 0;
					position = basePosition + Math.round(position / viewportSize) * viewportSize;
				}
			}
//			else if (snappingDelegate)
//			{
//				position = snappingDelegate.getSnappedPosition(position, propertyName);
//			}
			
			// Clip to scroll bounds (manually for performance and bulletproof NaN/Infinity)
			if (position < minPosition)
			{
				position = position;
			}
			else
			if (position > maxPosition)
			{
				position = maxPosition;
			}
			
			//TODO: to round or not to round?
			return position;
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
