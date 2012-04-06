package com.inreflected.ui.touchScroll
{
	import com.inreflected.animation.PathsFollower;
	import flash.events.Event;
	import flash.events.IEventDispatcher;
	import flash.geom.Point;
	import flash.utils.getTimer;
	import spark.effects.animation.Keyframe;
	import spark.effects.animation.MotionPath;
	import spark.effects.easing.IEaser;
	import spark.effects.easing.Power;
	import spark.effects.easing.Sine;

	/**
	 * @author Pavel fljot
	 */
	public class ThrowEffect
	{		
		/**
	     *  @private
	     *  The duration of the overshoot effect when a throw "bounces" against the end of the list.
	     */
	    protected static const THROW_OVERSHOOT_TIME:int = 250;
	    
	    /**
		 *  @private
		 *  The duration of the settle effect when a throw "bounces" against the end of the list.
		 */
		protected static const THROW_SETTLE_TIME:int = 300;//600
	    
		/**
		 *  @private
		 *  The exponent used in the easer function for the main part of the throw animation. 
		 */
		protected static const THROW_CURVE_EXPONENT:Number = 3.0;
	    
	    /**
	     *  @private
	     *  The exponent used in the easer function for the "overshoot" portion 
	     *  of the throw animation.
	     */
	    protected static const OVERSHOOT_CURVE_EXPONENT:Number = 2.0;
		
	    /**
	     *  @private
	     */
	    protected static const STOP_VELOCITY:Number = 0.01;//px per ms
	    
	    /**
	     *  @private
	     *  The name of the property to be animated for each axis.
	     *  Setting to null indicates that there is to be no animation
	     *  along that axis. 
	     */
	    public var propertyNameX:String = null;
	    public var propertyNameY:String = null;
	
	    /**
	     *  @private
	     *  The initial velocity of the throw animation.
	     */
	    public var startingVelocityX:Number = 0;
	    public var startingVelocityY:Number = 0;
	
	    /**
	     *  @private
	     *  The starting values for the animated properties.
	     */
	    public var startingPositionX:Number = 0;
	    public var startingPositionY:Number = 0;
	
	    /**
	     *  @private
	     *  The minimum values for the animated properties.
	     */
	    public var minPositionX:Number = 0;
	    public var minPositionY:Number = 0;
	
	    /**
	     *  @private
	     *  The maximum values for the animated properties.
	     */
	    public var maxPositionX:Number = 0;
	    public var maxPositionY:Number = 0;
	
	    /**
	     *  @private
	     *  The rate of deceleration to apply to the velocity.
	     */
	    public var decelerationRate:Number;
		
		public var pull:Boolean;
		public var bounce:Boolean;
		public var maxBounce:Number;
		
		public var viewportWidth:Number;
		public var viewportHeight:Number;
	    
	    /**
	     *  @private
	     *  The final calculated values for the animated properties.
	     */
	    public var finalPosition:Point;
	    
	    /**
	     *  @private
	     *  This is a callback that, when installed by the client, will be invoked
	     *  with the final position of the throw in case the client needs to alter it
	     *  prior to the animation beginning. 
	     */
	    public var finalPositionFilterFunction:Function;
		
		public var onEffectCompleteFunction:Function;
	    
	    /**
	     *  @private
	     *  Set to true when the effect is only being used to snap an element into position
	     *  and the initial velocity is zero.
	     */
	    public var isSnapping:Boolean = false;
	
	    /**
	     *  @private
	     *  The motion paths for X and Y axes
	     */
	    protected var horizontalMP:MotionPath = null;
	    protected var verticalMP:MotionPath = null;
		
	
		protected var _effectFollower:PathsFollower = new PathsFollower();
		protected var _effectStartTime:uint;
		
		
		public function ThrowEffect(target:IEventDispatcher = null)
		{
			this.target = target;
		}
		
		
		/** @private */
		private var _target:IEventDispatcher;
		
		/**
		 * 
		 */
		public function get target():IEventDispatcher
		{
			return _target;
		}
		public function set target(value:IEventDispatcher):void
		{
			if (_target == value)
				return;
			
			uninstallTarget(target);
			_target = value;
			installTarget(target);
		}
		
		
		/** @private */
		protected var _duration:uint;
		
		/**
		 * 
		 */
		public function get duration():uint
		{
			return _duration;
		}
		
		
		/** @private */
		private var _isPlaying:Boolean;
		
		/**
		 * 
		 */
		public function get isPlaying():Boolean
		{
			return _isPlaying;
		}
		
		
		//--------------------------------------------------------------------------
		//
		//  Public methods
		//
		//--------------------------------------------------------------------------
		
		public function play():void
		{
			if (target && !isPlaying)
			{
				_isPlaying = true;
				_effectStartTime = getTimer();
				target.addEventListener(Event.ENTER_FRAME, target_enterFrameHandler);
			}
		}
		
		
		/**
		 *  @private
		 *  Once all the animation variables are set (velocity, position, etc.), call this
		 *  function to build the motion paths that describe the throw animation.
		 */
		public function setup():Boolean
		{
			var throwEffectMotionPaths:Vector.<MotionPath> = new Vector.<MotionPath>();
			isSnapping = false;
			
			var lastKeyFrameIndex:uint;
			
			var horizontalTime:Number = 0;
			var finalHSP:Number = startingPositionX;
			horizontalMP = null;
			if (propertyNameX)
			{
				horizontalMP = createThrowMotionPath(
					propertyNameX,
					startingVelocityX,
					startingPositionX,
					minPositionX,
					maxPositionX,
					viewportWidth
				);
				
				if (horizontalMP)
				{
					throwEffectMotionPaths.push(horizontalMP);
					lastKeyFrameIndex = horizontalMP.keyframes.length - 1;
					horizontalTime = horizontalMP.keyframes[lastKeyFrameIndex].time;
					finalHSP = Number(horizontalMP.keyframes[lastKeyFrameIndex].value);
				}
			}
			
			var verticalTime:Number = 0;
			var finalVSP:Number = startingPositionY;
			verticalMP = null;
			if (propertyNameY)
			{				
				verticalMP = createThrowMotionPath(
					propertyNameY,
					startingVelocityY,
					startingPositionY,
					minPositionY,
					maxPositionY,
					viewportHeight
				);
				
				if (verticalMP)
				{
					throwEffectMotionPaths.push(verticalMP);
					lastKeyFrameIndex = verticalMP.keyframes.length - 1;
					verticalTime = verticalMP.keyframes[lastKeyFrameIndex].time;
					finalVSP = Number(verticalMP.keyframes[lastKeyFrameIndex].value);
				}
			}
			
			if (horizontalMP || verticalMP)
			{
				// Fix motion paths to have visually independent durations for axis tweens
				if (horizontalMP && verticalMP)
				{
					if (horizontalTime < verticalTime)
					{
						addKeyframe(horizontalMP, verticalTime, finalHSP, new Power());
					}
					else if (verticalTime < horizontalTime)
					{
						addKeyframe(verticalMP, horizontalTime, finalVSP, new Power());
					}
				}
			
				_duration = Math.max(horizontalTime, verticalTime);
				_effectFollower.motionPaths = throwEffectMotionPaths;
				_effectFollower.progress = 0;
				finalPosition = new Point(finalHSP, finalVSP);
				return true;
			}
			
			return false;
		}
		
		
		public function stop(notifyComplete:Boolean = true):void
		{
			if (target && _isPlaying)
			{
				target.removeEventListener(Event.ENTER_FRAME, target_enterFrameHandler);
				_isPlaying = false;
				if (notifyComplete)
				{
					onEffectCompleteFunction();
				}
			}
		}
		
		
		/**
		 *  @private
		 *  Calculates the current velocities of the in-progress throw animation   
		 */
		public function getCurrentVelocity():Point
		{
			var effectDuration:Number = this.duration;
			
			// Get the current position of the existing throw animation
			var effectTime:Number = _effectFollower.progress * effectDuration || 0;			
			
			var velX:Number = horizontalMP ? getMotionPathCurrentVelocity(horizontalMP, effectTime, effectDuration) : 0;
			var velY:Number = verticalMP ? getMotionPathCurrentVelocity(verticalMP, effectTime, effectDuration) : 0;
			
			return new Point(velX, velY);
		}
		
		
		
		
		//--------------------------------------------------------------------------
		//
		//  Private methods
		//
		//--------------------------------------------------------------------------
		
		protected function installTarget(target:Object):void
		{
			_effectFollower.target = target;
		}
		
		
		protected function uninstallTarget(target:Object):void
		{
			if (!target)
				return;
			
			stop(false);
			_effectFollower.target = null;
		}
		
		
		/**
		 *  @private
		 */
		protected function calculateThrowEffectTime(velocity:Number, decelerationRate:Number):int
		{
			// This calculates the effect duration based on a deceleration factor that is applied evenly over time.
			// We decay the velocity by the deceleration factor until it is less than 0.01/ms, which is rounded to zero pixels.
			// We want to solve for "time" in this equasion: velocity*(decel^time)-0.01 = 0.
			// Note that we are only calculating an effect duration here.  The actual curve of our throw velocity is determined by
			// the exponential easing function we use between animation keyframes.
			
			// The condition has pure mathematical purpose: not to have negative time.
			var absVelocity:Number = velocity > 0 ? velocity : -velocity;
			var time:int = absVelocity <= STOP_VELOCITY ? 0 : Math.log(STOP_VELOCITY / absVelocity) / Math.log(decelerationRate);

			return time;
		}
		
		
		/**
		 *  @private
		 *  A utility function to add a new keyframe to the motion path and return the frame time.  
		 */
		protected function addKeyframe(motionPath:MotionPath, time:Number, position:Number, easer:IEaser):Number
		{
			var keyframe:Keyframe = new Keyframe(time, position);
			keyframe.easer = easer;
			motionPath.keyframes.push(keyframe);
			return time;
		}
		
		
		/**
		 *  @private
		 *  This function builds a motion path that reflects the starting conditions (position, velocity)
		 *  and exhibits overshoot/settle/snap effects (aka bounce/pull) according to the min/max boundaries.
		 */
		protected function createThrowMotionPath(propertyName:String, velocity:Number, position:Number, minPosition:Number, maxPosition:Number, viewportSize:Number):MotionPath
		{
			var motionPath:MotionPath = new MotionPath(propertyName);
			motionPath.keyframes = Vector.<Keyframe>([new Keyframe(0, position)]);
			var nowTime:Number = 0;
			var effectTime:Number;
			var alignedPosition:Number;
			
			// First, we handle the case where the velocity is zero (finger wasn't significantly moving when lifted).
			// Ordinarily, we do nothing in this case, but if the list is currently scrolled past its end (i.e. "pulled"),
			// we need to have the animation move it back so none of the empty space is visible.
			if (velocity == 0)
			{
				if (position < minPosition || position > maxPosition)
				{
					// Velocity is zero and we're past the end of the list.  We want the
					// list to "snap" back to its resting position at the end.  We use a
					// cubic easer curve so the snap has high initial velocity and
					// gradually decelerates toward the resting point.
					position = position < minPosition ? minPosition : maxPosition;
					
					if (finalPositionFilterFunction != null)
					{
						position = finalPositionFilterFunction(position, propertyName);
					}
					
					//FIXME: why not alignedPosition and isSnapping = true?
					
					nowTime = addKeyframe(motionPath, nowTime + THROW_SETTLE_TIME, position, new Power(0, THROW_CURVE_EXPONENT));
				}
				else
				{
					// See if we need to snap into alignment
					alignedPosition = position;
					
					if (finalPositionFilterFunction != null)
					{
						alignedPosition = finalPositionFilterFunction(position, propertyName);
					}
					
					if (alignedPosition == position)
						return null;
					
					isSnapping = true;
					nowTime = addKeyframe(motionPath, nowTime + THROW_SETTLE_TIME, alignedPosition, new Power(0, THROW_CURVE_EXPONENT));
				}
			}
			
			// Each iteration of this loop adds one of more keyframes to the motion path and then
			// updates the velocity and position values.  Once the velocity has decayed to zero,
			// the motion path is complete.
			while (velocity != 0.0)
			{
				if ((position <= minPosition && velocity > 0) || (position >= maxPosition && velocity < 0))
				{
					// We're past the end of the list
					// <upd>OR exatly at the edge (in order to unclide maxPull logic)</upd>
					// and the velocity is directed further beyond
					// the end. In this case we want to overshoot the end of the list and then
					// settle back to it.
					
					// The throw is STARTED beyond the end / on the edge
					const throwJustStartedBeyondBounds:Boolean = (effectTime != effectTime);//faster isNaN
					
					if (throwJustStartedBeyondBounds)
					{
						if (!pull && (position == minPosition || position == maxPosition))
						{
							// no throw applied
							return null;
						}
						
						// so we want to minimize overshoot and effect time (but not totally)
						// to have something more close to regular settle effect.
						velocity *= 0.1;
					}
					
					
					if (bounce || throwJustStartedBeyondBounds)
					{
						var settlePosition:Number = position < minPosition ? minPosition : maxPosition;
						
						if (finalPositionFilterFunction != null)
						{
							settlePosition = finalPositionFilterFunction(settlePosition, propertyName);
						}
						
						var bounceDecelerationRate:Number = decelerationRate * 0.97;
						var overshootTime:uint = calculateThrowEffectTime(velocity, bounceDecelerationRate);
						if (overshootTime > THROW_OVERSHOOT_TIME)
						{
							overshootTime = THROW_OVERSHOOT_TIME;
						}
						
						// OVERSHOOT_CURVE_EXPONENT is the default initial slope of the easer function we use for the overshoot.
						// This calculation scales the y axis (distance) of the overshoot so the actual slope matches the velocity.
						var overshootPosition:Number = Math.round(position - ((velocity / OVERSHOOT_CURVE_EXPONENT) * overshootTime));
						
						var maxOvershootDistance:Number = maxBounce * viewportSize;
						if (!isNaN(effectTime))
						{
							// we don't want to limit overshootPosition since throw has started beyond edge
							// basically it's just a pull, not bounce
							overshootPosition = Math.min(Math.max(minPosition - maxOvershootDistance, overshootPosition), maxPosition + maxOvershootDistance);
							//TODO: adjust time maybe?
						}
						
						nowTime = addKeyframe(motionPath, nowTime + overshootTime, overshootPosition, new Power(0, OVERSHOOT_CURVE_EXPONENT));
						nowTime = addKeyframe(motionPath, nowTime + THROW_SETTLE_TIME, settlePosition, new Sine(0.25));
					}
					
					// Clear the velocity to indicate that the motion path is complete.
					velocity = 0;
				}
				else
				{
					// Here we're going to do a "normal" throw.
					effectTime = calculateThrowEffectTime(velocity, decelerationRate);
					
					var minVelocity:Number;
					if (position < minPosition || position > maxPosition)
					{
						// The throw is starting beyond the end of the list.  We need to enforce a minimum velocity
						// to make sure the throw makes it all the way back to the end (i.e. doesn't leave any blank area
						// exposed) and does so within THROW_SETTLE_TIME.  THROW_SETTLE_TIME needs to be consistently
						// adhered to in all cases where the tension of being beyond the end acts on the scroll position.
						
						// The minimum velocity is that which gets us back to the end position in exactly THROW_SETTLE_TIME milliseconds.
						minVelocity = ((position - (position < minPosition ? minPosition : maxPosition)) /
							THROW_SETTLE_TIME) * THROW_CURVE_EXPONENT;
						if (Math.abs(velocity) < Math.abs(minVelocity))
						{
							velocity = minVelocity;
							effectTime = THROW_SETTLE_TIME;
						}
					}
					
					// The easer function we use is 1-((1-x)^THROW_CURVE_EXPONENT), which has an initial slope of THROW_CURVE_EXPONENT.
					// The x axis is scaled according to the throw duration we calculated above, so now we need
					// to determine the correct y-axis scaling (i.e. throw distance) such that the initial
					// slope matches the specified throw velocity.
					var finalPosition:Number = Math.round(position - ((velocity / THROW_CURVE_EXPONENT) * effectTime));
					
					if (finalPosition < minPosition || finalPosition > maxPosition)
					{
						// The throw is going to hit the end of the list.  In this case we need to clip the
						// deceleration curve at the appropriate point.  We want the curve to look exactly as
						// it would if we were allowing the throw to go beyond the end of the list.  But the
						// keyframe we add here will stop exactly at the end.  The subsequent loop iteration
						// will add keyframes that describe the overshoot & settle behavior.
						
						var endPosition:Number = finalPosition < minPosition ? minPosition : maxPosition;
						
						// since easing function is f(t) = start + (final - start) * e(t)
						// e(t) = Math.pow(1 - t/throwEffectTime, THROW_CURVE_EXPONENT) =OR= (1 - t/throwEffectTime)^THROW_CURVE_EXPONENT
						// We want to solve for t when e(t) = finalPosition
						// t = throwEffectTime*(1-(Math.pow(1-((endPosition-position)/(finalVSP-position)),1/THROW_CURVE_EXPONENT)));
						var partialTime:Number = effectTime * (1 - (Math.pow(1 - ((endPosition - position) / (finalPosition - position)), 1 / THROW_CURVE_EXPONENT)));
						if (partialTime != partialTime)//isNaN
						{
							// I experienced NaN (or some Infinity?) once
							// some weird values combination endPosition, position, finalPosition
							partialTime = effectTime;
						}
						
						// PartialExponentialCurve creates a portion of the throw easer curve, but scaled up to fill the
						// specified duration.
						nowTime = addKeyframe(motionPath, nowTime + partialTime, endPosition, new PartialExponentialCurve(THROW_CURVE_EXPONENT, partialTime / effectTime));
						
						// Set the position just past the end of the list for the next loop iteration.
						if (finalPosition < minPosition)
							position = minPosition - 1;
						if (finalPosition > maxPosition)
							position = maxPosition + 1;
						
						// Set the velocity for the next loop iteration.  Make sure it matches the actual velocity in effect when the
						// throw reaches the end of the list.
						//
						// The easer function we use for the throw is 1-((1-x)^b), the derivative of which is
						// b*(1-x)^(b-1) where b = THROW_CURVE_EXPONENT
						// (Flex team used some hardcoded coefficients formula)
						// Since the slope of a curve function at any point x (i.e. f(x)) is the value of the derivative at x (i.e. f'(x)),
						// we can use this to determine the velocity of the throw at the point it reached the beginning of the bounce.
						var x:Number = partialTime / effectTime;
						var y:Number = THROW_CURVE_EXPONENT * Math.pow(1 - x, THROW_CURVE_EXPONENT - 1); 
						velocity = -y * (finalPosition - position) / effectTime;
					}
					else
					{
						// This is the simplest case.  The throw both begins and ends on the list (i.e. not past the
						// end of the list).  We create a single keyframe and clear the velocity to indicate that the
						// motion path is complete.
						
						// Flex team also says:
						// <quote>
						// Note that we only use the first 62% of the actual deceleration curve, and stop the motion
						// path at that point.  That's the point in time at which most throws animations get to within
						// a single pixel of their final destination.  Since scrolling is done at whole pixel 
						// boundaries, there's no point in letting the rest of the animation play out, and stopping it 
						// allows us to release the mouse capture earlier for a better user experience.
//	                    const CURVE_PORTION:Number = 0.62;
//	                    nowTime = addKeyframe(
//	                        motionPath, nowTime + (effectTime*CURVE_PORTION), finalPosition, 
//	                        new PartialExponentialCurve(THROW_CURVE_EXPONENT, CURVE_PORTION));
//	                    velocity = 0;
						// </quote>
						// but that's a bullshit because they still use incorrect double easing.
						
						if (isNaN(finalPosition))
						{
							throw new Error("");
						}
						if (finalPositionFilterFunction != null)
						{
							finalPosition = finalPositionFilterFunction(finalPosition, propertyName);
						}
						
						nowTime = addKeyframe(motionPath, nowTime + effectTime, finalPosition, new Power(0, THROW_CURVE_EXPONENT));
						velocity = 0;
					}
				}
			}
			return motionPath;
		}
		
		
		/**
		 *  @private
		 *  Helper function for getCurrentVelocity.  
		 */
		private function getMotionPathCurrentVelocity(mp:MotionPath, currentTime:Number, totalTime:Number):Number
		{
			// Determine the fraction of the effect that has already played.
			var fraction:Number = currentTime / totalTime;
			
			// Now we need to determine the effective velocity at the effect's current position.
			// Here we use a "poor man's" approximation that doesn't require us to know any of the
			// derivative functions associated with the motion path.  We sample the position at two
			// time values very close together and assume the velocity slope is a straight line
			// between them.  The smaller the distance between the two time values, the closer the
			// result will be to the "instantaneous" velocity.
			const TINY_DELTA_TIME:Number = 0.00001;
			var value1:Number = Number(mp.getValue(fraction));
			var value2:Number = Number(mp.getValue(fraction + (TINY_DELTA_TIME / totalTime)));
			return (value2 - value1) / TINY_DELTA_TIME;
		}
		
		
		private function target_enterFrameHandler(event:Event):void
		{
			var progress:Number = (getTimer() - _effectStartTime) / _duration;
			_effectFollower.progress = progress < 1 ? progress : 1;
			if (_effectFollower.progress == 1)
			{
				stop();
			}
		}
	}
}
import spark.effects.easing.EaseInOutBase;

    
/**
 *  @private
 *  A custom ease-out-only easer class which animates along a specified 
 *  portion of an exponential curve.  
 */
class PartialExponentialCurve extends EaseInOutBase
{
    private var _xscale:Number;
    private var _ymult:Number;
    private var _exponent:Number;
    
    
    public function PartialExponentialCurve(exponent:Number, xscale:Number)
    {
        super(0);
        
        _exponent = exponent;
        _xscale = xscale;
        _ymult = 1 / (1 - Math.pow(1 - _xscale, _exponent));
    }
    
    override protected function easeOut(fraction:Number):Number
    {
        return _ymult * (1 - Math.pow(1 - fraction*_xscale, _exponent)); 
    }
}