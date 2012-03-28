package com.inreflected.ui.managers 
{
	import com.inreflected.core.IDisposable;
	import com.inreflected.core.IViewport;
	import com.inreflected.ui.managers.supportClasses.ThrowEffect;

	import org.gestouch.core.GestureState;
	import org.gestouch.events.GestureStateEvent;
	import org.gestouch.events.PanGestureEvent;
	import org.gestouch.gestures.Gesture;
	import org.gestouch.gestures.PanGesture;

	import mx.events.FlexEvent;
	import mx.events.PropertyChangeEvent;
	import mx.events.TouchInteractionEvent;
	import mx.events.TouchInteractionReason;

	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.display.InteractiveObject;
	import flash.display.Stage;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.MouseEvent;
	import flash.events.TimerEvent;
	import flash.events.TouchEvent;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.system.Capabilities;
	import flash.ui.Multitouch;
	import flash.utils.Timer;
	import flash.utils.getDefinitionByName;
	import flash.utils.getTimer;


	[Event(name="touchInteractionStarting", type="mx.events.TouchInteractionEvent")]
	[Event(name="touchInteractionStart", type="mx.events.TouchInteractionEvent")]
	[Event(name="touchInteractionEnd", type="mx.events.TouchInteractionEvent")]
	/**
	 * TODO:
	 * - move throw velocity calculation out of this class (to Gestouch utils maybe?)
	 * - improve directionalLock
	 * - check if it works with unlimited bounds (endless scroll)
	 * 
	 * @see http://opensource.adobe.com/wiki/display/flexsdk/Mobile+List,+Scroller+and+Touch
	 * @author Pavel fljot
	 */
	public class TouchScrollManager extends EventDispatcher implements IDisposable
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
		 *  Number of mouse movements to keep in the history to calculate 
		 *  velocity.
		 */
		private static const EVENT_HISTORY_LENGTH:uint = 5;
		/**
		 *  @private
		 *  Minimum velocity needed to start a throw gesture, in pixels per millisecond.
		 */
		private static const MIN_START_VELOCITY:Number = 0.6 * Capabilities.screenDPI / 1000;
		/**
		 *  @private
		 *  The amount of deceleration to apply to the velocity for each effect period
		 *  For a faster deceleration, you can switch this to 0.990.
		 */
		private static const THROW_EFFECT_DECEL_FACTOR:Number = 0.995;	
		/**
		 *  @private
		 *  Weights to use when calculating velocity, giving the last velocity more of a weight 
		 *  than the previous ones.
		 */
		private static const VELOCITY_WEIGHTS:Vector.<Number> = Vector.<Number>([1, 1.33, 1.66, 2, 2.33]);
		/**
		 *  @private
		 *  Used so we don't have to keep allocating Point(0,0) to do coordinate conversions
		 *  while draggingg
		 */
		private static const ZERO_POINT:Point = new Point(0, 0);
		/**
		 *  @private
		 *  The name of the viewport's horizontal scroll position property
		 */
		public static const HORIZONTAL_SCROLL_POSITION:String = "horizontalScrollPosition";
		/**
		 *  @private
		 *  The name of the viewport's vertical scroll position property
		 */
		public static const VERTICAL_SCROLL_POSITION:String = "verticalScrollPosition";
		
		
		//----------------------------------
		//  Settings
		//----------------------------------
		/**
		 *  Slop - the scrolling threshold (minimum number of 
		 *  pixels needed to move before scrolling starts).
		 *  Default value is <code>Gesture.DEFAULT_SLOP</code>
		 *  
		 *  @see org.gestouch.gestures.Gestute#DEFAULT_SLOP
		 */
		public var slop:uint = Gesture.DEFAULT_SLOP;
		/**
		 * Whether to bounce/pull at the edges or not.
		 * 
		 * @default true
		 */
		public var bounceEnabled:Boolean = true;
		/**
		 *  The amount of deceleration to apply to the velocity for each effect period
		 *  For a faster deceleration, you can switch this to 0.990.
		 */
		public var frictionFactor:Number = THROW_EFFECT_DECEL_FACTOR;
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
		
		public var allwaysBounceHorizontal:Boolean = true;
		public var allwaysBounceVertical:Boolean = true;
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
		 * <b>NB!</b> Doesn't work correctly for rotated viewport. 
		 * 
		 * @default false
		 */
		public var directionalLock:Boolean;
		
		public var snappingFunction:Function;
		
		
		//----------------------------------
		//  Protected
		//----------------------------------
		/**
		 * Target casted as InteractiveObject
		 * 
		 * @see flash.display.InteractiveObject
		 */
		protected var _interactiveTarget:InteractiveObject;
		protected var _viewportIsFlexComponent:Boolean;
		protected var _stage:Stage;
		protected var _lastDragOffsetX:Number;
		protected var _lastDragOffsetY:Number;
		protected var _lockHorizontal:Boolean;
		protected var _lockVertical:Boolean;
		protected var _directionalLockTimer:Timer = new Timer(600, 1);
		protected var _directionLockTimerStartPoint:Point;
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
		protected var _lastDirection:Point = new Point();
		protected var _cummulativeOffsetX:Number;
		protected var _cummulativeOffsetY:Number;
		/**
		 *  @private
		 *  Used to keep track of whether we should capture the next 
		 *  click event that we receive or whether we should let it dispatch 
		 *  normally.  We capture the click event if a scroll happened.
		 */
		protected var _captureNextClick:Boolean;
		/**
		 *  @private
		 *  The time the scroll started.
		 */
		protected var _startTime:Number;
		/**
		 *  @private
		 *  The list (because we can have multitouch) of InteractiveObjects that were mousedowned/touched on.
		 */
		protected var _touchBeginObjects:Vector.<InteractiveObject> = new Vector.<InteractiveObject>();
		/**
		 *  @private
		 *  Keeps track of the coordinates where the mouse events 
		 *  occurred.  We use this for velocity calculation along 
		 *  with timeHistory.
		 */
		protected var _mouseEventCoordinatesHistory:Vector.<Point>;
		/**
		 *  @private
		 *  Length of items in the mouseEventCoordinatesHistory and 
		 *  timeHistory Vectors since a circular buffer is used to 
		 *  conserve points.
		 */
		protected var _mouseEventLength:uint = 0;
		/**
		 *  @private
		 *  A history of times the last few mouse events occurred.
		 *  We keep HISTORY objects in memory, and we use this mouseEventTimeHistory
		 *  Vector along with mouseEventCoordinatesHistory to determine the velocity
		 *  a user was moving their fingers.
		 */
		protected var _mouseEventTimeHistory:Vector.<int>;
		
		protected var _throwEffect:ThrowEffect;
		/**
		 *  @private
		 *  The final position in the throw effect's horizontal motion path
		 */
		protected var _throwFinalHSP:Number;
		protected var _throwFinalVSP:Number;
		
		/**
		 *  @private
		 *  Indicates whether the previous throw reached one of the maximum
		 *  scroll positions (vsp or hsp) that was in effect at the time. 
		 */
		protected var _throwReachedMaximumScrollPosition:Boolean;
		
		protected var _stageAspectRatio:Number;
		protected var _prevViewportWidth:Number;
		protected var _prevViewportHeight:Number;
		protected var _prevHorizontalPageCount:int;
		protected var _prevVerticalPageCount:int;
		
		
		protected var _currentPageHSP:Number;
		protected var _currentPageVSP:Number;
		
		
		//----------------------------------
		// Flags 
		//----------------------------------
		protected var _inTouchInteraction:Boolean;
		protected var _dragScrollPending:Boolean;
		protected var _preventGestureReset:Boolean;
		
		
		public function TouchScrollManager(viewport:IViewport = null) 
		{
			super();
			
			_mouseEventCoordinatesHistory = new Vector.<Point>(EVENT_HISTORY_LENGTH);
			_mouseEventTimeHistory = new Vector.<int>(EVENT_HISTORY_LENGTH);
			
			panGesture.addEventListener(GestureStateEvent.STATE_CHANGE, panGesture_stateChangeHandler, false, 0, true);
			panGesture.addEventListener(PanGestureEvent.GESTURE_PAN, panGesture_gesturePanHandler, false, 0, true);
			
			_directionalLockTimer.addEventListener(TimerEvent.TIMER, directionalLockTimer_timerHandler);
			
			this.viewport = viewport;
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
			
			uninstallViewport(viewport);			
			_viewport = value;			
			installViewport(viewport);
		}
		
		
		protected var _panGesture:PanGesture;
		public function get panGesture():PanGesture
		{
			return _panGesture ||= new PanGesture();
		}
		
		
		/** @private */
		protected var _explicitScrollBounds:Rectangle;
		protected var _measuredScrollBounds:Rectangle = new Rectangle();
		
		/**
		 * 
		 */
		public function get scrollBounds():Rectangle
		{
			return _explicitScrollBounds ? _explicitScrollBounds.clone() : _measuredScrollBounds.clone();
		}
		public function set scrollBounds(value:Rectangle):void
		{
			if (_explicitScrollBounds == value)
				return;
			
			_explicitScrollBounds = value;
			
			if (viewport)
			{
				checkScrollPosition();
			}
		}
		/**
		 * Same as scrollBounds getter but without clonning. For internal performant use.
		 */
		protected function getScrollBounds():Rectangle
		{
			return _explicitScrollBounds ? _explicitScrollBounds : _measuredScrollBounds;
		}
		
		
		/** @private */
		private var _pagingEnabled:Boolean;
		
		/**
		 *  By default scrolling is pixel based. 
		 *  The final scroll location is any pixel location based on 
		 *  the drag and throw gesture.
		 *  Set <code>pagingEnabled</code> to <code>true</code> to 
		 *  enable page scrolling.
		 *
		 *  <p>The size of the page is determined by the size of the viewport 
		 *  of the scrollable component. 
		 *  You can only scroll a single page at a time, regardless of the scroll gesture.</p>
		 *
		 *  <p>You must scroll at least 50% of the visible area of the component 
		 *  to cause the page to change. 
		 *  If you scroll less than 50%, the component remains on the current page. 
		 *  Alternatively, if the velocity of the scroll is high enough, the next page display. 
		 *  If the velocity is not high enough, the component remains on the current page.</p>
		 *  
		 *  <p>From Apple: If the value of this property is YES, the scroll view stops on
		 *  multiples of the scroll view’s bounds when the user scrolls. The default value is NO.</p>
		 *
		 *  @default false
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
			
			stop();
			
			if (pagingEnabled)
			{
				determinePageScrollPositions();
			}
			else
			{
				_currentPageHSP = _currentPageVSP = NaN;
			}
		}
		
		
//		/** @private */
//		private var _snappingController:SnappingController;
//		
//		/**
//		 * 
//		 */
//		public function get snappingController():SnappingController
//		{
//			return _snappingController;
//		}
//		public function set snappingController(value:SnappingController):void
//		{
//			if (_snappingController == value)
//				return;
//			
//			_snappingController = value;
//			
//			if (_snappingController)
//			{
//				_snappingController.pagingEnabled = pagingEnabled;
//			}
//		}
		
		
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
		 * Wether viewport is currently scrolling (due to touch interaction or throw effect).
		 * This property becomes true once panGesture is recognized. And becomes false once
		 * throw effect ends or, if no throw happens due to low throw velocity,
		 * once touch interaction ends.
		 * 
		 * @see #panGesture
		 * @see #stop()
		 * @see #_throwEffect
		 */
		public function get isScrolling():Boolean
		{
			return _isScrolling;
		}
		
		
		
		
		//--------------------------------------------------------------------------
		//
		// Public methods 
		//
		//--------------------------------------------------------------------------		
		
		public function stop():void
		{
			if (!viewport)
				return;
			
			var wasScrolling:Boolean = isScrolling;
			_inTouchInteraction = false;
			_isScrolling = false;
			_dragScrollPending = false;
			_directionalLockTimer.reset();
			_lockHorizontal = _lockVertical = false;
			
			if (!_preventGestureReset)
			{
				// We don't need any processing to be done anymore
				panGesture.reset();
			}
			
			// don't reset captureNextClick here because touchScrollEnd
			// may be invoked on mouseUp and mouseClick occurs immediately
			// after that, so we want to block this next mouseClick
			
			viewport.removeEventListener(Event.ENTER_FRAME, viewport_enterFrameHandler);
			
			if (_throwEffect && _throwEffect.isPlaying)
			{
				_throwEffect.stop(false);
			}
			
			snapContentScrollPosition();
			
			if (wasScrolling)
			{
				var scrollEndEvent:TouchInteractionEvent = new TouchInteractionEvent(TouchInteractionEvent.TOUCH_INTERACTION_END, true);
				scrollEndEvent.relatedObject = viewport;
				scrollEndEvent.reason = TouchInteractionReason.SCROLL;
				dispatchBubblingEventOnMouseDownedDisplayObject(scrollEndEvent);
				
				dispatchEvent(scrollEndEvent);
			}
			
			_touchBeginObjects.length = 0;
		}
		
		
		public function dispose():void
		{
			viewport = null;
			if (panGesture)
			{
				panGesture.removeEventListener(GestureStateEvent.STATE_CHANGE, panGesture_stateChangeHandler);
				panGesture.removeEventListener(PanGestureEvent.GESTURE_PAN, panGesture_gesturePanHandler);
				panGesture.dispose();
				_panGesture = null;
			}
			if (_directionalLockTimer)
			{
				_directionalLockTimer.stop();
				_directionalLockTimer.removeEventListener(TimerEvent.TIMER, directionalLockTimer_timerHandler);
				_directionalLockTimer = null;
			}
			if (_throwEffect)
			{
				_throwEffect.onEffectCompleteFunction = null;
				_throwEffect.target = null;
				_throwEffect = null;
			}
		}
		
		
		
		
		//--------------------------------------------------------------------------
		//
		// Private methods 
		//
		//--------------------------------------------------------------------------

		protected function installViewport(viewport:IViewport):void
		{
			if (!viewport)
				return;
			
			_interactiveTarget = _viewport as InteractiveObject;
			
			// Flex integration part
			try {
				var flexUIComponentDefinition:Class = getDefinitionByName("mx.core::UIComponent") as Class;
				_viewportIsFlexComponent = (viewport is flexUIComponentDefinition);
			}
			catch (err:Error)
			{
				_viewportIsFlexComponent = false;
			}
			
			
			panGesture.target = viewport;
			
			viewport.clipAndEnableScrolling = true;
			if (!_stage)
			{
				if (viewport.stage)
				{
					_stage = viewport.stage;
				}
				else
				{
					viewport.addEventListener(Event.ADDED_TO_STAGE, viewport_addedToStageHandler);
				}
			}
			
			if (Multitouch.supportsTouchEvents)
			{
				viewport.addEventListener(TouchEvent.TOUCH_BEGIN, viewport_touchBeginHandler);
				
				// capture mouse listeners to help block click and mousedown events.
				// mousedown is blocked when a scroll is in progress
				// click is blocked when a scroll is in progress (or just finished)
				viewport.addEventListener(TouchEvent.TOUCH_BEGIN, viewport_captureTouchHandler, true);
				viewport.addEventListener(TouchEvent.TOUCH_TAP, viewport_captureTouchHandler, true);
			}
			else
			{
				viewport.addEventListener(MouseEvent.MOUSE_DOWN, viewport_touchBeginHandler);
				
				// capture mouse listeners to help block click and mousedown events.
				// mousedown is blocked when a scroll is in progress
				// click is blocked when a scroll is in progress (or just finished)
				viewport.addEventListener(MouseEvent.MOUSE_DOWN, viewport_captureTouchHandler, true);
				viewport.addEventListener(MouseEvent.CLICK, viewport_captureTouchHandler, true);
			}
			
			
			viewport.addEventListener(Event.RESIZE, viewport_resizeHandler);
			viewport.addEventListener(PropertyChangeEvent.PROPERTY_CHANGE, viewport_propertyChangeHandler);
			viewport_resizeHandler();
		}
		
		
		protected function uninstallViewport(viewport:IViewport):void
		{
			if (!viewport)
				return;
			
			stop();
			
			panGesture.target = null;
			
			_interactiveTarget = null;
			
			viewport.removeEventListener(Event.ADDED_TO_STAGE, viewport_addedToStageHandler);
			viewport.removeEventListener(PanGestureEvent.GESTURE_PAN, panGesture_gesturePanHandler);
			viewport.removeEventListener(TouchEvent.TOUCH_BEGIN, viewport_touchBeginHandler);
			viewport.removeEventListener(MouseEvent.MOUSE_DOWN, viewport_touchBeginHandler);
			
			viewport.removeEventListener(MouseEvent.MOUSE_DOWN, viewport_captureTouchHandler, true);
			viewport.removeEventListener(MouseEvent.CLICK, viewport_captureTouchHandler, true);
			viewport.removeEventListener(TouchEvent.TOUCH_BEGIN, viewport_captureTouchHandler, true);
			viewport.removeEventListener(TouchEvent.TOUCH_TAP, viewport_captureTouchHandler, true);
			
			viewport.removeEventListener(Event.RESIZE, viewport_resizeHandler);
			viewport.removeEventListener(PropertyChangeEvent.PROPERTY_CHANGE, viewport_propertyChangeHandler);
			viewport.removeEventListener(FlexEvent.UPDATE_COMPLETE, handleSizeChangeOnUpdateComplete);
		}
		
		
		protected function startScrollWatch():void
		{
			_inTouchInteraction = true;
			_lastDirection.x = _lastDirection.y = 0;
			_lastDragOffsetX = _lastDragOffsetY = 0;
			_touchHSP = viewport.horizontalScrollPosition;
			_touchVSP = viewport.verticalScrollPosition;
			_cummulativeOffsetX = _cummulativeOffsetY = 0;
			
			updateCanScroll();
			
			if (isScrolling)
			{
				adjustCummulativeOffsets();
			}
			
			// this is the point from which all deltas are based.
			_startTime = getTimer();
			
			panGesture.slop = isScrolling ? 0 : slop;
						
			// reset circular buffer index/length
			_mouseEventLength = 0;
			
			if (isScrolling)
			{
				// touch while throw effect playing
					
				if (directionalLock && (_lockHorizontal || _lockVertical))
				{
					// touch while throw effect playing with some direction locked
					
					restartDirectionalLockWatch();
				}
			}
			else
			{
				//TODO: ?
				if (pagingEnabled)
				{
					
				}
			}
			
			_directionalLockTimer.reset();
		}
		
		
		protected function adjustCummulativeOffsets():void
		{
			// We need to adjust _cummulativeOffsetX and _cummulativeOffsetY
			// to preserve correct pull mechanics
			var viewportSize:Number;//viewport width or height
			var pullProgress:Number;// [0.. 1]
			const pullAllowed:Boolean = (maxPull != maxPull || maxPull > 0);
			const scrollBounds:Rectangle = getScrollBounds();
			
			if (pullAllowed && canScrollHorizontally)
			{
				viewportSize = viewport.width;
				if (_touchHSP < scrollBounds.left)
				{
					pullProgress = (scrollBounds.left - _touchHSP) / viewportSize;
					pullProgress = Math.max(1 - Math.pow(1 - Math.min(pullProgress / (maxPull || MAX_PULL_FACTOR), 1), 1 / PULL_TENSION_FACTOR), pullProgress);
					_cummulativeOffsetX = viewportSize * pullProgress + _touchHSP - scrollBounds.left;
				}
				else
				if (_touchHSP > scrollBounds.right)
				{
					pullProgress = (_touchHSP - scrollBounds.right) / viewportSize;
					pullProgress = Math.max(1 - Math.pow(1 - Math.min(pullProgress / (maxPull || MAX_PULL_FACTOR), 1), 1 / PULL_TENSION_FACTOR), pullProgress);
					 _cummulativeOffsetX = -viewportSize * pullProgress + _touchHSP - scrollBounds.right;
				}
			}
			
			if (pullAllowed && canScrollVertically)
			{
				viewportSize = viewport.height;
				if (_touchVSP < scrollBounds.top)
				{
					pullProgress = (scrollBounds.top - _touchVSP) / viewportSize;
					pullProgress = Math.max(1 - Math.pow(1 - Math.min(pullProgress / (maxPull || MAX_PULL_FACTOR), 1), 1 / PULL_TENSION_FACTOR), pullProgress);
					_cummulativeOffsetY = viewportSize * pullProgress + _touchVSP - scrollBounds.top;
				}
				else
				if (_touchVSP > scrollBounds.bottom)
				{
					pullProgress = (_touchVSP - scrollBounds.bottom) / viewportSize;
					pullProgress = Math.max(1 - Math.pow(1 - Math.min(pullProgress / (maxPull || MAX_PULL_FACTOR), 1), 1 / PULL_TENSION_FACTOR), pullProgress);
					 _cummulativeOffsetY = -viewportSize * pullProgress + _touchVSP - scrollBounds.bottom;
				}
			}
		}
		
		
		 /**
		 *  Helper method to dispatch bubbling events on mouseDownDisplayObject.  Since this 
		 *  object can be off the display list, this may be tricky.  Technically, we should 
		 *  grab all the live objects at the time of mouseDown and dispatch events to them 
		 *  manually, but instead, we just use this heuristic, which is dispatch it to 
		 *  mouseDownedDisplayObject.  If it's not inside of scroller OR off the display list,
		 *  then dispatch to scroller as well.
		 * 
		 *  <p>If you absolutely need to know the touch event ended, add event listeners 
		 *  to the mouseDownedDisplayObject directly and don't rely on event 
		 *  bubbling.</p>
		 */
		protected function dispatchBubblingEventOnMouseDownedDisplayObject(event:Event):Boolean
		{
			var eventAccepted:Boolean = true;
			var needToDispatchFromViewport:Boolean = true;
			const viewport:IViewport = this.viewport;
			
			if (_touchBeginObjects.length > 0)
			{
				// dispatch event from all objects, even if some fails (prevented)
				for each (var touchBeginObject:DisplayObject in _touchBeginObjects)
				{
					eventAccepted = eventAccepted && touchBeginObject.dispatchEvent(event);
					if (needToDispatchFromViewport)
					{
						if (touchBeginObject == viewport)
						{
							// viewport itself
							needToDispatchFromViewport = false;
						}
						else if (viewport is DisplayObjectContainer && (viewport as DisplayObjectContainer).contains(touchBeginObject))
						{
							// it will bubble through viewport
							needToDispatchFromViewport = false;
						}
					}
				}
			}
			
			if (needToDispatchFromViewport)
			{
				eventAccepted = eventAccepted && viewport.dispatchEvent(event);
			}
			
			return eventAccepted;
		}
		
		
		protected function performDrag(dx:Number, dy:Number):void
		{
			var localDragDeltas:Point = _interactiveTarget.globalToLocal(new Point(dx, dy)).subtract(_interactiveTarget.globalToLocal(ZERO_POINT));
			dx = localDragDeltas.x;
			dy = localDragDeltas.y;
			
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
			
			var scrollBounds:Rectangle = getScrollBounds();
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
						viewportSize = viewport.width;
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
				viewport.horizontalScrollPosition = newHSP;
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
						viewportSize = viewport.height;
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
				viewport.verticalScrollPosition = newVSP;
			}
		}
		
		
		protected function performThrow(velocityX:Number, velocityY:Number):void
		{
			//TODO: something about text selection. see Flex for more info
			//TODO: something about soft keyboard. see Flex for more info
			
			// If the soft keyboard is up (or about to come up), or
			// we're offscreen for some reason, don't start a throw.
			const preventThrows:Boolean = false;//TEMP
			if (preventThrows || !viewport.stage)
			{
				stop();
				return;
			}
		
			var throwVelocity:Point = new Point(velocityX, velocityY);
			if (velocityX != 0 || velocityY != 0)
			{
				// The velocity values are deltas in the global coordinate space.
				// In order to use them to change the scroll position we must convert
				// them to the scroller's local coordinate space first.
				// This code converts the deltas from global to local.
				//
				// Note that we scale the velocity values up and then back down around the
				// calls to globalToLocal.  This is because the runtime only returns values
				// rounded to the nearest 0.05.  The velocities are small number (<4.0) with
				// lots of precision that we don't want to lose.  The scaling preserves
				// a sufficient level of precision for our purposes.
				throwVelocity.x *= 100000;
				throwVelocity.y *= 100000;
				
				// Because we subtract out the difference between the two coordinate systems' origins,
				// This is essentially just multiplying by a scaling factor.
				throwVelocity = _interactiveTarget.globalToLocal(throwVelocity).subtract(_interactiveTarget.globalToLocal(ZERO_POINT));
				
				throwVelocity.x *= 0.00001;
				throwVelocity.y *= 0.00001;
			}
			
			if (setupThrowEffect(throwVelocity.x, throwVelocity.y))
			{
				_throwEffect.play();
			}
		}
		
		
		/**
		 *  @private
		 *  Set up the effect to be used for the throw animation
		 */
		protected function setupThrowEffect(velocityX:Number, velocityY:Number):Boolean
		{
			if (!_throwEffect)
			{
				_throwEffect = new ThrowEffect(viewport);
				_throwEffect.onEffectCompleteFunction = onThrowEffectComplete;
			}
			
			var scrollBounds:Rectangle = getScrollBounds();
			var minHSP:Number = scrollBounds.left;
			var minVSP:Number = scrollBounds.top;
			var maxHSP:Number = scrollBounds.right;
			var maxVSP:Number = scrollBounds.bottom;
			
			var frictionFactor:Number = this.frictionFactor;
			
			if (pagingEnabled)
			{
				// See whether a page switch is warranted for this touch gesture.
				if (canScrollHorizontally)
				{
					_currentPageHSP = determineNewPageScrollPosition(velocityX, HORIZONTAL_SCROLL_POSITION);
					// "lock" to the current page
					minHSP = maxHSP = _currentPageHSP; 
				}
				if (canScrollVertically)
				{
					_currentPageVSP = determineNewPageScrollPosition(velocityY, VERTICAL_SCROLL_POSITION);
					// "lock" to the current page
					minVSP = maxVSP = _currentPageVSP;					
				}
				
				// Flex team attenuates velocity here,
				// but I think it's better to adjust friction to preserve correct starting velocity.
				frictionFactor *= 0.98;
	        }
	
	        _throwEffect.propertyNameX = canScrollHorizontally ? HORIZONTAL_SCROLL_POSITION : null;
	        _throwEffect.propertyNameY = canScrollVertically ? VERTICAL_SCROLL_POSITION : null;
	        _throwEffect.startingVelocityX = velocityX;
	        _throwEffect.startingVelocityY = velocityY;
	        _throwEffect.startingPositionX = viewport.horizontalScrollPosition;
	        _throwEffect.startingPositionY = viewport.verticalScrollPosition;
	        _throwEffect.minPositionX = minHSP;
	        _throwEffect.minPositionY = minVSP;
	        _throwEffect.maxPositionX = maxHSP;
	        _throwEffect.maxPositionY = maxVSP;
	        _throwEffect.decelerationFactor = frictionFactor;
	        _throwEffect.viewportWidth = viewport.width;
	        _throwEffect.viewportHeight = viewport.height;
			_throwEffect.pull = (maxPull > 0 || maxPull != maxPull);
			_throwEffect.bounce = bounceEnabled;
			_throwEffect.maxBounce = (maxBounce > 0 ? maxBounce : MAX_OVERSHOOT_FACTOR);
	        
	        // In snapping mode, we need to ensure that the final throw position is snapped appropriately.
//	        _throwEffect.finalPositionFilterFunction = snappingFunction == null ? null : getSnappedPosition; 
	        _throwEffect.finalPositionFilterFunction = snappingFunction; 
	        
			_throwReachedMaximumScrollPosition = false;
	        if (_throwEffect.setup())
	        {
				//TODO: _throwReachedMin... ?
	            _throwFinalHSP = _throwEffect.finalPosition.x;
	            if (canScrollHorizontally && _throwFinalHSP == maxHSP)
				{
	                _throwReachedMaximumScrollPosition = true;
				}
	            _throwFinalVSP = _throwEffect.finalPosition.y;
	            if (canScrollVertically && _throwFinalVSP == maxVSP)
				{
	                _throwReachedMaximumScrollPosition = true;
				}
	        }
	        else
	        {
	            stop();
	            return false;
	        }
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
		 *  @private
		 *  Adds the time and mouse coordinates for this event in to 
		 *  our mouse event history so that we can use it later to 
		 *  calculate velocity.
		 * 	
		 *  @return the delta moved between this mouse event and the start
		 *          of the scroll gesture.
		 */
		protected function addMouseEventHistory(dx:Number, dy:Number):Point
		{			
			// either use a Point object already created or use one already created
			// in mouseEventCoordinatesHistory
			var currentPoint:Point;
			var currentIndex:int = (_mouseEventLength % EVENT_HISTORY_LENGTH);
			if (_mouseEventCoordinatesHistory[currentIndex])
			{
				currentPoint = _mouseEventCoordinatesHistory[currentIndex] as Point;
				currentPoint.x = dx;
				currentPoint.y = dy;
			}
			else
			{
				currentPoint = new Point(dx, dy);
				_mouseEventCoordinatesHistory[currentIndex] = currentPoint;
			}
			
			// add time history as well
			_mouseEventTimeHistory[currentIndex] = getTimer();
//			CONFIG::Debug
//			{
//				trace("adding mouses event history:", dx, dy, _mouseEventTimeHistory[currentIndex]);
//			}

			// increment current length if appropriate
			_mouseEventLength++;

			return currentPoint;
		}
		
		
		/**
		 *  @private
		 *  Helper function to calculate the current throwVelocity.
		 *  
		 *  <p>It calculates the velocities and then calculates a weighted 
		 *  average from them.</p>
		 */
		protected function calculateThrowVelocity():Point
		{
			var len:int = (_mouseEventLength > EVENT_HISTORY_LENGTH ? EVENT_HISTORY_LENGTH : _mouseEventLength);

			// we are guarenteed to have 2 items here b/c of mouseDown and a mouseMove

			// if haven't wrapped around, then startIndex = 0.  If we've wrapped around,
			// then startIndex = mouseEventLength % EVENT_HISTORY_LENGTH.  The equation
			// below handles both of those cases
			const startIndex:int = ((_mouseEventLength - len) % EVENT_HISTORY_LENGTH);
			const endIndex:int = ((_mouseEventLength - 1) % EVENT_HISTORY_LENGTH);

			// variables to store a running average
			var weightedSumX:Number = 0;
			var weightedSumY:Number = 0;
			var totalWeight:Number = 0;

			var currentIndex:int = startIndex;
			var previousIndex:int;
			var i:int = 0;
			var j:int = 0;
			var velocityWeight:Number;
			var nextIndex:int;
			var currCoord:Point;
			var prevTime:int;
        	
//			while (currentIndex != endIndex)
			while (i < len)
			{
//				nextIndex = ((currentIndex + 1) % EVENT_HISTORY_LENGTH);
				nextIndex = currentIndex + 1;
				if (nextIndex >= EVENT_HISTORY_LENGTH)
					nextIndex = 0;
				previousIndex = currentIndex - 1;
				if (previousIndex < 0)
					previousIndex += EVENT_HISTORY_LENGTH;
				
				currCoord = _mouseEventCoordinatesHistory[currentIndex] as Point;
				prevTime = (currentIndex == startIndex) ? _startTime : int(_mouseEventTimeHistory[previousIndex]);
				
				// Get dx, dy, and dt
				var dt:int = int(_mouseEventTimeHistory[currentIndex]) - prevTime;
				var dx:Number = currCoord.x;
				var dy:Number = currCoord.y;
				
				const MIN_DT:uint = 20;
				if (dt < MIN_DT)
				{
					dt = MIN_DT;
				}
				// calculate a weighted sum for velocities
				velocityWeight = VELOCITY_WEIGHTS[j++];
				weightedSumX += (dx / dt) * velocityWeight;
				weightedSumY += (dy / dt) * velocityWeight;
				totalWeight += velocityWeight;
				
				currentIndex = nextIndex;
				i++;
			}			
			
			var vel:Point = new Point(0, 0);
			if (totalWeight > 0)
			{
				vel.x = weightedSumX / totalWeight;
		        vel.y = weightedSumY / totalWeight;
			}
			
			CONFIG::Debug
			{
				trace('throwVelocity: ' + (vel));
			}
			return vel;
		}
		
		
		/**
		 *  @private
		 *  Helper function to calculate the velocity of the touch drag
		 *  for its final <code>time</code> milliseconds. 
		 */
		private function calculateFinalDragVelocity(time:int):Point
		{
			// This function is similar to calculateThrowVelocity with the
			// following differences:
			// 1) It iterates backwards through the mouse events.
			// 2) It stops when the specified amount of time is accounted for.
			// 3) It calculates the velocities from the overall deltas with no
			// weighting or averaging.

			// Find the range of mouse events to consider
			var len:int = (_mouseEventLength > EVENT_HISTORY_LENGTH ? EVENT_HISTORY_LENGTH : _mouseEventLength);
			const startIndex:int = ((_mouseEventLength - len) % EVENT_HISTORY_LENGTH);
			const endIndex:int = ((_mouseEventLength - 1) % EVENT_HISTORY_LENGTH);

			// We're going to start at the last event of the drag and iterate
			// backward toward the first.
			var currentIndex:int = endIndex;
			
			var i:int = 0;
			var dt:int = 0;
			var dx:Number = 0;
			var dy:Number = 0;
			var currCoord:Point;
			var prevTime:int;

			// Loop until we've accounted for the desired amount of time or run out of events.
			while (time > 0 && i < len)
			{
				// Find the index of the previous event
				var previousIndex:int = currentIndex - 1;
				if (previousIndex < 0)
					previousIndex += EVENT_HISTORY_LENGTH;

				// Calculate time and position deltas between the two events
				currCoord = _mouseEventCoordinatesHistory[currentIndex] as Point;
				prevTime = (currentIndex == startIndex) ? _startTime : int(_mouseEventTimeHistory[previousIndex]);
				var _dt:int = _mouseEventTimeHistory[currentIndex] - prevTime;
				var _dx:Number = currCoord.x;
				var _dy:Number = currCoord.y;

				// If the deltas exceed our desired time range, interpolate by scaling them
				if (_dt > time)
				{
					var interpFraction:Number = time / _dt;
					_dx *= interpFraction;
					_dy *= interpFraction;
					_dt = time;
				}

				// Subtract the current time delta from the overall desired time range
				time -= _dt;

				// Accumulate the deltas
				dt += _dt;
				dx += _dx;
				dy += _dy;

				// Go to the previous event in the drag
				currentIndex = previousIndex;
				i++;
			}

			if (dt == 0)
				return new Point(0, 0);

			// Create the point representing the velocity values.
			return new Point(dx / dt, dy / dt);
		}
		
		
		protected function updateCanScroll():void
		{
			_canScrollHorizontally = (bounceEnabled && allwaysBounceHorizontal) || scrollBounds.width > 0;
			_canScrollVertically = (bounceEnabled && allwaysBounceVertical) || scrollBounds.height > 0;
		}
		
		
		/**
		 *  Snap the scroll positions to valid values.
		 */
		protected function snapContentScrollPosition(snapHorizontal:Boolean = true, snapVertical:Boolean = true):void
		{
			var scrollBounds:Rectangle = getScrollBounds();
			var pos:Number;
						
			// Note that we only snap the scroll position if content is present. This allows existing scroll position
			// values to be retained before content is added or when it is removed/readded.
			
			if (snapHorizontal && viewport.contentWidth > 0)
			{
				pos = viewport.horizontalScrollPosition;
				// We "manually" (instead of Math.min(Math.max())) check each side
				// because they might be NaN
				if (pos < scrollBounds.left)
				{
					pos = scrollBounds.left;
				}
				if (pos > scrollBounds.right)
				{
					pos = scrollBounds.right;
				}
				
				viewport.horizontalScrollPosition = getSnappedPosition(pos, HORIZONTAL_SCROLL_POSITION);
			}
			if (snapVertical && viewport.contentHeight > 0)
			{
				// We "manually" (instead of Math.min(Math.max())) check each side
				// because they might be NaN
				pos = viewport.verticalScrollPosition;
				if (pos < scrollBounds.top)
				{
					pos = scrollBounds.top;
				}
				if (pos > scrollBounds.bottom)
				{
					pos = scrollBounds.bottom;
				}
				
				viewport.verticalScrollPosition = getSnappedPosition(pos, VERTICAL_SCROLL_POSITION);
			}
		}
		
		
		/**
		 *  This function takes a scroll position and the associated property name, and finds
		 *  the nearest snapped position (i.e. one that satifises the current scrollSnappingMode).
		 */
		protected function getSnappedPosition(position:Number, propertyName:String):Number
		{
			const scrollBounds:Rectangle = getScrollBounds();
			
			var viewportWidth:Number = isNaN(viewport.width) ? 0 : viewport.width;
			var viewportHeight:Number = isNaN(viewport.height) ? 0 : viewport.height;
			
			if (pagingEnabled && snappingFunction == null)
			{
				// If we're in paging mode and no snapping is enabled, then we must snap
				// the position to the beginning of a page.  i.e. a multiple of the 
				// viewport size.
				if (propertyName == VERTICAL_SCROLL_POSITION && viewportHeight != 0)
				{
					position = scrollBounds.top + Math.round(position / viewportHeight) * viewportHeight;
					
					//TODO: Is it neccesary to clip value here or in snapContentScrollPositions() is enough?
				}
				else
				if (propertyName == HORIZONTAL_SCROLL_POSITION && viewportWidth != 0)
				{
					position = scrollBounds.left + Math.round(position / viewportWidth) * viewportWidth;
					
					//TODO: Is it neccesary to clip value here or in snapContentScrollPositions() is enough?
				}
			}
			else if (snappingFunction != null)
			{
				position = snappingFunction(position, propertyName);
			}
			
			return Math.round(position);
		}
		
		
		private function getCurrentPageCount(propertyName:String):int
		{
			var viewportWidth:Number = isNaN(viewport.width) ? 0 : viewport.width;
			var viewportHeight:Number = isNaN(viewport.height) ? 0 : viewport.height;

			var pageCount:int = 0;

			if (propertyName == HORIZONTAL_SCROLL_POSITION && viewportWidth != 0)
			{
				pageCount = Math.ceil(viewport.contentWidth / viewportWidth);
			}
			else
			if (propertyName == VERTICAL_SCROLL_POSITION && viewportHeight != 0)
			{
				pageCount = Math.ceil(viewport.contentHeight / viewportHeight);
			}

			return pageCount;
		}
		
		
		/**
		 * Validates scroll positions (they might be invalid due scrollBounds change).
		 * 
		 * <p>Called on scrollBounds change and on viewport size change.
		 * scrollBounds may change because of explicit setting
		 * or when viewport size or viewport content size changes.<p>
		 */
		protected function checkScrollPosition():void
		{
			if (!_explicitScrollBounds)
			{
				determineScrollBounds();
			}
			
			updateCanScroll();
			
			var scrollBounds:Rectangle = getScrollBounds();
			// Determine the new maximum valid scroll positions
			var minHSP:Number = scrollBounds.left;
			var minVSP:Number = scrollBounds.top;
			var maxHSP:Number = scrollBounds.right;
			var maxVSP:Number = scrollBounds.bottom;
			
			// Determine whether there's been a device orientation change.
			// NB! Unlike in Flex, I don't rely on device orientation concept, but rather treat
			// any stage size change as "orientation change".
			var currAspectRatio:Number = _stage ? _stage.stageWidth / _stage.stageHeight : NaN;
			var orientationChanged:Boolean = _stageAspectRatio != currAspectRatio;
			_stageAspectRatio = currAspectRatio;
			
			var viewportWidth:Number = isNaN(viewport.width) ? 0 : viewport.width;
			var viewportHeight:Number = isNaN(viewport.height) ? 0 : viewport.height;
			
			
			if (_throwEffect && _throwEffect.isPlaying)
			{
				// See whether we possibly need to re-throw because of changed scrollBounds.
				var needRethrow:Boolean;
				
				// See whether we possibly need to re-throw because the final snapped position is
				// no longer snapped.  This can occur when the snapped position was estimated due to virtual
				// layout, and the actual snapped position (i.e. once the relevent elements have been measured)
				// turns out to be different.
				// We also do this when pageScrolling is enabled to make sure we snap to a valid page position
				// after an orientation change - since an orientation change necessarily moves all the page
				// boundaries.
				if (pagingEnabled || snappingFunction != null)
				{
					// NOTE: a lighter-weight way of doing this would be to retain the element
					// at the end of the throw and see whether its bounds have changed.
					if (canScrollHorizontally && getSnappedPosition(_throwFinalHSP, HORIZONTAL_SCROLL_POSITION) != _throwFinalHSP)
					{
						needRethrow = true;
					}
				    
					if (canScrollVertically && getSnappedPosition(_throwFinalVSP, VERTICAL_SCROLL_POSITION) != _throwFinalVSP)
					{
						needRethrow = true;
					}
				}
				
				// Here we check to see whether the current throw has maybe not gone far enough
				// given the new content size. 
				// We don't rethrow for this reason in paging mode, as we don't want to go any further
				// than to the adjacent page.
				else
				{
					//TODO: min?
					if (_throwReachedMaximumScrollPosition && (_throwFinalVSP < maxVSP || _throwFinalHSP < maxHSP))
					{
						needRethrow = true;
					}
					
					if (_throwFinalVSP > maxVSP || _throwFinalVSP < minVSP ||
						_throwFinalHSP > maxHSP || _throwFinalHSP < minHSP)
					{
						needRethrow = true;
					}
				}
				
				
				if (needRethrow)
				{				
					// There's currently a throw animation playing, and it's throwing to a 
					// now-incorrect position.					
					
					if (orientationChanged)
					{
						// The throw end position became invalid because the device
						// orientation changed.  In this case, we just want to stop
						// the throw animation and snap to valid positions.  We don't
						// want to animate to the final position because this may
						// require changing directions relative to the current throw,
						// which looks strange.
						stop();
					}
					else
					{					
						// The size of the content may have changed during the throw.
						// In this case, we'll stop the current animation and start
						// a new one that gets us to the correct position.
						
						// Get the effect's current velocity
	                	var velocity:Point = _throwEffect.getCurrentVelocity();
	
						// Stop the existing throw animation now that we've determined its current velocities.
						// Passing false to prevent effect end notification and therefore stop() execution. 
		                _throwEffect.stop(false);
		                
		                // Now perform a new throw to get us to the right position.
		                if (setupThrowEffect(-velocity.x, -velocity.y))
						{
		                    _throwEffect.play();
						}
					}
				}
			}
			else if (!_inTouchInteraction)
			{
				// No touch interaction is in effect, but the content may be sitting at
				// a scroll position that is now invalid (due to viewport size properties change). 
				// If so, snap the content to a valid position.
				// The most likely reason we get here is that the device orientation changed
				// while the content is stationary (i.e. not in an animated throw).
				
				var snapElementIndex:int = -1;
				if (_prevViewportWidth != viewportWidth || _prevViewportHeight != viewportHeight)
				{
					// The viewport size has changed (most likely due to device orientation change)
					
					if (pagingEnabled && snappingFunction == null)
					{
//						// Paging without item snapping.  We want to snap to the same page, as
//						// long as the number of pages is the same.
//						// The number of pages being different indicates that the relationship
//						// between pages and content is unknown, and it makes no sense to try and
//						// retain the same page.
						// FIXME: !!! it's unclear when to set _prevHorizontalPageCount and _prevVerticalPageCount
						if (true || _prevHorizontalPageCount == getCurrentPageCount(HORIZONTAL_SCROLL_POSITION))
						{
							if (_prevViewportWidth != viewportWidth && _prevViewportWidth > 0)
							{
								snapElementIndex = _currentPageHSP / _prevViewportWidth;
								viewport.horizontalScrollPosition = snapElementIndex * viewportWidth;
								_currentPageHSP = viewport.horizontalScrollPosition;
							}
						}
						if (true || _prevVerticalPageCount == getCurrentPageCount(VERTICAL_SCROLL_POSITION))
						{
							if (_prevViewportHeight != viewportHeight && _prevViewportHeight > 0)
							{
								snapElementIndex = _currentPageVSP / _prevViewportHeight;
								viewport.verticalScrollPosition = snapElementIndex * viewportHeight;
								_currentPageVSP = viewport.verticalScrollPosition;
							}
						}
					}
					if (pagingEnabled && snappingFunction != null)
					{
						//TODO
					}
				}
				
				snapContentScrollPosition();
				
				//new
				if (pagingEnabled)
				{
					determinePageScrollPositions();
				}
			}
			
			_prevViewportWidth = viewportWidth;
			_prevViewportHeight = viewportHeight;
		}
		
		
		protected function determineScrollBounds():void
		{
			//TODO: dispatch some scrollBounds change/update event somewhere?
			
			_measuredScrollBounds.x = 0;
			_measuredScrollBounds.y = 0;
			_measuredScrollBounds.width = 0;
			_measuredScrollBounds.height = 0;
			
			if (!viewport)
				return;
			
			var viewportWidth:Number = isNaN(viewport.width) ? 0 : viewport.width;
			var viewportHeight:Number = isNaN(viewport.height) ? 0 : viewport.height;
			
			_measuredScrollBounds.width = viewport.contentWidth > viewportWidth ?
				viewport.contentWidth - viewportWidth : 0;
			if (pagingEnabled && snappingFunction == null && viewportWidth > 0 && _measuredScrollBounds.width > 0)
			{
				// If the content height isn't an exact multiple of the viewport height,
				// then we make sure the max scroll position allows for a full page (including
				// padding) at the end.
				if (viewport.contentWidth % viewportWidth != 0)
				{
					_measuredScrollBounds.width = viewportWidth * uint(viewport.contentWidth / viewportWidth);
				}
			}
			
			_measuredScrollBounds.height = viewport.contentHeight > viewportHeight ?
				viewport.contentHeight - viewportHeight : 0;
			if (pagingEnabled && snappingFunction == null && viewportHeight > 0 && _measuredScrollBounds.height > 0)
			{
				// If the content height isn't an exact multiple of the viewport height,
				// then we make sure the max scroll position allows for a full page (including
				// padding) at the end.
				if (viewport.contentHeight % viewportHeight != 0)
				{
					_measuredScrollBounds.height = viewportHeight * uint(viewport.contentHeight / viewportHeight);
				}
			}
			
			// We can't pre-calculate exact bounds for the case when snappignFunction is defined,
			// so either be satifsfied with these calculations or set explicit scrollBounds.
		}
		
		
		/**
		 *  This function determines whether a switch to an adjacent page is warranted, given 
		 *  the distance dragged and/or the velocity thrown. 
		 */
		protected function determineNewPageScrollPosition(velocity:Number, propertyName:String):Number
		{
			var position:Number;
			var pagePosition:Number;
			var viewportSize:Number;
			var minSP:Number;
			var maxSP:Number;
			var scrollBounds:Rectangle = getScrollBounds();
			var currPageScrollPosition:Number;
			if (propertyName == VERTICAL_SCROLL_POSITION)
			{
				position = viewport.verticalScrollPosition;
				viewportSize = viewport.height;
				minSP = scrollBounds.top;
				maxSP = scrollBounds.bottom;
				currPageScrollPosition = _currentPageVSP;
			}
			else
			if (propertyName == HORIZONTAL_SCROLL_POSITION)
			{
				position = viewport.horizontalScrollPosition;
				viewportSize = viewport.width;
				minSP = scrollBounds.left;
				maxSP = scrollBounds.right;
				currPageScrollPosition = _currentPageHSP;
			}
			const stationaryOffsetThreshold:Number = viewportSize * 0.5;
			
			// Check both the throw velocity and the drag distance. If either exceeds our threholds, then we switch to the next page.
			if (velocity < -MIN_START_VELOCITY || position >= currPageScrollPosition + stationaryOffsetThreshold)
			{
				// Go to the next page
				// Set the new page scroll position so the throw effect animates the page into place
				pagePosition = Math.min(currPageScrollPosition + viewportSize, maxSP);
			}
			else
			if (velocity > MIN_START_VELOCITY || position <= currPageScrollPosition - stationaryOffsetThreshold)
			{
				// Go to the previous page
				pagePosition = Math.max(currPageScrollPosition - viewportSize, minSP);
			}
			else
			{
				// Snap to the current one
				return currPageScrollPosition;
			}
			
			// Ensure the new page position is snapped appropriately
			pagePosition = getSnappedPosition(pagePosition, propertyName);
			
			return pagePosition;
		}
		
		
		protected function determinePageScrollPositions():void
		{
			_currentPageHSP = viewport ? getSnappedPosition(viewport.horizontalScrollPosition, HORIZONTAL_SCROLL_POSITION) : 0;
			_currentPageVSP = viewport ? getSnappedPosition(viewport.verticalScrollPosition, VERTICAL_SCROLL_POSITION) : 0;
		}
		
		
		protected function handleViewportSizeChange():void
		{
			// The content size has changed, so the current scroll
			// position and/or any in-progress throw may need to be adjusted.
			checkScrollPosition();
			
			if (pagingEnabled && (isNaN(_currentPageHSP) || isNaN(_currentPageVSP)))
			{
				determinePageScrollPositions();
			}
		}
		
		
		protected function restartDirectionalLockWatch():void
		{
			_directionLockTimerStartPoint = panGesture.location;
			_directionalLockTimer.reset();
			_directionalLockTimer.start();
		}
		
		
		protected function onThrowEffectComplete():void
		{
			stop();
		}
		
		
		
		
		//--------------------------------------------------------------------------
		//
		// Event handlers 
		//
		//--------------------------------------------------------------------------
		
		protected function viewport_touchBeginHandler(event:Event):void
		{
			stopThrowEffectOnTouch();
			
			// We want to allow click/tap while it's not scrolling
			_captureNextClick = false;
			
			var touchTarget:InteractiveObject = event.target as InteractiveObject;
			if (_touchBeginObjects.indexOf(touchTarget) == -1)
			{
				_touchBeginObjects.push(touchTarget);
			}
			
			// Since we may have multitouch, this condition helps to call
			// startScrollWatch() only once per touch interaction session.
			if (!_inTouchInteraction)
			{
				startScrollWatch();
			}
		}
		
		
		protected function viewport_captureTouchHandler(event:Event):void 
		{
			switch (event.type)
			{
				case MouseEvent.MOUSE_DOWN:
				case TouchEvent.TOUCH_BEGIN:
					if (!isScrolling)
						return;
					
					// If we get a mouse down when the throw animation is within a few
					// pixels of its final destination, we'll go ahead and stop the
					// touch interaction and allow the event propogation to continue
					// so other handlers can see it.  Otherwise, we'll capture the
					// down event and start watching for the next scroll.
					
					// 5 pixels at 252dpi worked fairly well for this heuristic.
					const THRESHOLD_INCHES:Number = 0.01984;// 5/252
					var captureThreshold:uint = THRESHOLD_INCHES * Capabilities.screenDPI;
					
					// Need to convert the pixel delta to the local coordinate system in
					// order to compare it to a scroll position delta.
					captureThreshold = _interactiveTarget.globalToLocal(new Point(captureThreshold, 0))
						.subtract(_interactiveTarget.globalToLocal(ZERO_POINT)).x;
					
					if (_throwEffect && _throwEffect.isPlaying &&
						Math.abs(viewport.verticalScrollPosition - _throwFinalVSP) <= captureThreshold &&
						Math.abs(viewport.horizontalScrollPosition - _throwFinalHSP) <= captureThreshold)
					{
						// Stop the current throw and allow the event to propogate normally.
						// We must supress panGesture.reset() call because this touch is already
						// registered by gesture (on stage in capture phase) and we should not loose it.
						_preventGestureReset = true;
						stop();
						_preventGestureReset = false;
					}
					else
					{
						// We stop event propagation in capture phase
						// to prevent viewport elements to respond to mouseDown
						// since we already scrolling.
						event.stopImmediatePropagation();
						
						stopThrowEffectOnTouch();
						
						// Since we may have multitouch, this condition helps to call
						// startScrollWatch() only once per touch interaction session.
						if (!_inTouchInteraction)
						{
							startScrollWatch();
						}
					}										
					break;
				
				case MouseEvent.CLICK:
				case TouchEvent.TOUCH_TAP:
					if (!_captureNextClick)
						return;
					
					event.stopImmediatePropagation();
					break;
			}
		}
		
		
		protected function directionalLockTimer_timerHandler(event:TimerEvent):void
		{
			if (_directionLockTimerStartPoint.subtract(panGesture.location).length < Gesture.DEFAULT_SLOP)
			{
				_lockHorizontal = _lockVertical = false;
			}
			else
			{
				restartDirectionalLockWatch();
			}
		}
		
		
		private function viewport_addedToStageHandler(event:Event):void
		{
			var viewport:DisplayObject = event.currentTarget as DisplayObject;
			viewport.removeEventListener(Event.ADDED_TO_STAGE, viewport_addedToStageHandler);
			_stage = viewport.stage;
		}
		
		
		protected function panGesture_stateChangeHandler(event:GestureStateEvent):void
		{
			switch (event.newState)
			{
				case GestureState.CANCELLED:
					stop();
					break;
				case GestureState.FAILED:
					if (isScrolling)
					{
						// Touch came when content was scrolling,
						// but gesture hasn't began (touch hasn't moved enough).
						// Regular throw will be performed (with zero velocity)
						onDragEnd();
					}
					else
					{
						stop();
					}
					break;
			}
		}
		
		
		protected function panGesture_gesturePanHandler(event:PanGestureEvent):void 
		{
			if (event.gestureState == GestureState.BEGAN)
			{
				onDragBegin(event);
			}
			else if (event.gestureState == GestureState.ENDED)
			{
				onDragEnd(event);
				return;
			}
			
			if (event.gestureState != GestureState.ENDED)
			{
				onDragUpdate(event);
			}
		}
		
		
		protected function onDragBegin(event:PanGestureEvent):void
		{
			if (isScrolling)
			{
				viewport.addEventListener(Event.ENTER_FRAME, viewport_enterFrameHandler);
				return;
			}
			
			// Dispatch a cancellable and bubbling event to notify others
			var scrollStartingEvent:TouchInteractionEvent = new TouchInteractionEvent(TouchInteractionEvent.TOUCH_INTERACTION_STARTING, true, true);
			scrollStartingEvent.relatedObject = viewport;
			scrollStartingEvent.reason = TouchInteractionReason.SCROLL;
			var eventAccepted:Boolean = dispatchBubblingEventOnMouseDownedDisplayObject(scrollStartingEvent);
			if (eventAccepted)
			{
				eventAccepted = dispatchEvent(scrollStartingEvent);
			}
			
			// if the event was preventDefaulted(), then stop scrolling scrolling
			if (!eventAccepted)
			{
				stop();
				return;
			}
			
			// if the event has been accepted, we actually start scrolling logic
		
			_isScrolling = true;
			_captureNextClick = true;
			
			viewport.addEventListener(Event.ENTER_FRAME, viewport_enterFrameHandler);
			
			var scrollStartEvent:TouchInteractionEvent = new TouchInteractionEvent(TouchInteractionEvent.TOUCH_INTERACTION_START, true, false);
			scrollStartEvent.relatedObject = viewport;
			scrollStartEvent.reason = TouchInteractionReason.SCROLL;
			dispatchBubblingEventOnMouseDownedDisplayObject(scrollStartEvent);
			
			dispatchEvent(scrollStartEvent);
		}
		
		
		protected function onDragUpdate(event:PanGestureEvent):void
		{
			if (directionalLock && canScrollHorizontally && canScrollVertically)
			{
				if (!_directionalLockTimer.running && !_lockHorizontal && !_lockVertical)
				{
					var angleInRadians:Number = Math.atan2(event.offsetY, event.offsetX);
					var andleInDegrees:Number = angleInRadians * (180 / Math.PI);
					
					const ANGLE:Number = 20;
					if ((-ANGLE < andleInDegrees && andleInDegrees < ANGLE) ||
						(180-ANGLE < andleInDegrees || andleInDegrees < -180+ANGLE))
					{
						_lockHorizontal = true;
					}
					else
					if ((-90-ANGLE < andleInDegrees && andleInDegrees < -90+ANGLE) ||
						(90-ANGLE < andleInDegrees && andleInDegrees < 90+ANGLE))
					{
						_lockVertical = true;
					}
					restartDirectionalLockWatch();
				}
//				else if (!directionalLockTimer.running ||
//					(Math.abs(event.offsetX) >= Gesture.DEFAULT_SLOP && Math.abs(event.offsetY) >= Gesture.DEFAULT_SLOP))
				else if (Math.abs(event.offsetX) >= Gesture.DEFAULT_SLOP || Math.abs(event.offsetY) >= Gesture.DEFAULT_SLOP)
				{
					restartDirectionalLockWatch();
				}				
			}
			
			var dx:Number = _lockVertical ? 0 : event.offsetX;
			var dy:Number = _lockHorizontal ? 0 : event.offsetY;
			
			addMouseEventHistory(dx, dy);
			
			_lastDirection.x = (canScrollHorizontally && _lastDragOffsetX != 0) ? (dx > _lastDragOffsetX ? 1 : -1) : 0;
			_lastDirection.y = (canScrollVertically && _lastDragOffsetY != 0) ? (dy > _lastDragOffsetY ? 1 : -1) : 0;
			
			_dragScrollPending = true;
			
			_lastDragOffsetX += dx;
			_lastDragOffsetY += dy;
		}

		
		protected function onDragEnd(event:PanGestureEvent = null):void 
		{
			viewport.removeEventListener(Event.ENTER_FRAME, viewport_enterFrameHandler);
			_inTouchInteraction = false;
			
			_directionalLockTimer.reset();
			
			if (_dragScrollPending)
			{
				performDrag(_lastDragOffsetX, _lastDragOffsetY);
			}
			_dragScrollPending = false;
			
			// calculate the velocity using a weighted average
			var throwVelocity:Point = calculateThrowVelocity();
			
			if (throwVelocity.length < MIN_START_VELOCITY)
			{
				throwVelocity.x = 0;
				throwVelocity.y = 0;
			}
			else
			{
				// Also calculate the effective velocity for the final 100ms of the drag.
				addMouseEventHistory(0, 0);
        		var finalDragVel:Point = calculateFinalDragVelocity(100);
				CONFIG::Debug
				{
					trace('finalDragVel: ' + (finalDragVel), finalDragVel.length, MIN_START_VELOCITY);
				}		
				// If the gesture appears to have slowed or stopped prior to the mouse up,
				// then force the velocity to zero.
				// Compare the final 100ms of the drag to the minimum value.
				if (finalDragVel.length <= MIN_START_VELOCITY)
				{
					throwVelocity.x = 0;
					throwVelocity.y = 0;
				}
			}
			
			performThrow(throwVelocity.x, throwVelocity.y);
		}

		
		protected function viewport_enterFrameHandler(event:Event):void 
		{
			if (_dragScrollPending)
			{
				performDrag(_lastDragOffsetX, _lastDragOffsetY);
				_lastDragOffsetX = _lastDragOffsetY = 0;
				_dragScrollPending = false;
			}
		}
		
		
		protected function viewport_resizeHandler(event:Event = null):void
		{
			if (event && event is FlexEvent)
			{
				// Flex integration:
				// If the viewport dimensions have changed, then we may need to update the
				// scroll ranges and snap the scroll position per the new viewport size.
				viewport.addEventListener(FlexEvent.UPDATE_COMPLETE, handleSizeChangeOnUpdateComplete);
			}
			else
			{
				handleViewportSizeChange();
			}
		}
		
		
		protected function viewport_propertyChangeHandler(event:Event):void
		{
			var pce:PropertyChangeEvent = event as PropertyChangeEvent;
			if (pce)
			{
				switch (pce.property)
				{
					case "contentWidth":
					case "contentHeight":						
						if (_viewportIsFlexComponent)
						{
							// Flex integration:
							// If the content size changed, then the valid scroll position ranges 
							// may have changed.  In this case, we need to schedule an updateComplete
							// handler to check and potentially correct the scroll positions.
							viewport.addEventListener(FlexEvent.UPDATE_COMPLETE, 
								handleSizeChangeOnUpdateComplete);
						}
						else
						{
							handleViewportSizeChange();
						}
						break;
				}
			}
		}
		
		
		/**
		 *  @private 
		 */
		private function handleSizeChangeOnUpdateComplete(event:Event):void
		{
			if (event && event is FlexEvent)
			{
				viewport.removeEventListener(FlexEvent.UPDATE_COMPLETE, handleSizeChangeOnUpdateComplete);
				handleViewportSizeChange();
			}
		}
	}
}