package com.inreflected.animation
{
	import spark.effects.animation.MotionPath;
	/**
	 * @author Pavel fljot
	 */
	public class PathsFollower
	{
		public var target:Object;
		
		public var cachedProgress:Number;
		public var cachedRawProgress:Number;


		public function PathsFollower(target:Object = null)
		{
			this.target = target;
			this.cachedProgress = this.cachedRawProgress = 0;
		}
		
		
		public var motionPaths:Vector.<MotionPath>;


		/** 
		 * Identical to <code>progress</code> except that the value doesn't get re-interpolated between 0 and 1.
		 * <code>rawProgress</code> (and <code>progress</code>) indicates the follower's position along the motion path. 
		 * For example, to place the object on the path at the halfway point, you could set its <code>rawProgress</code> 
		 * to 0.5. You can tween to values that are greater than 1 or less than 0. For example, setting <code>rawProgress</code> 
		 * to 1.2 also sets <code>progress</code> to 0.2 and setting <code>rawProgress</code> to -0.2 is the 
		 * same as setting <code>progress</code> to 0.8. If your goal is to tween the PathFollower around a Circle2D twice 
		 * completely, you could just add 2 to the <code>rawProgress</code> value or use a relative value in the tween, like: <br /><br /><code>
		 * 
		 * TweenLite.to(myFollower, 5, {rawProgress:"2"}); // or myFollower.rawProgress + 2
		 * 
		 * </code><br /><br />
		 * 
		 * Since <code>rawProgress<code> doesn't re-interpolate values to always fitting between 0 and 1, it
		 * can be useful if you need to find out how many times the PathFollower has wrapped.
		 * 
		 * @see #progress
		 **/
		public function get rawProgress():Number
		{
			return this.cachedRawProgress;
		}


		public function set rawProgress(value:Number):void
		{
			this.progress = value;
		}


		/** 
		 * A value between 0 and 1 that indicates the follower's position along the motion path. For example,
		 * to place the object on the path at the halfway point, you would set its <code>progress</code> to 0.5.
		 * You can tween to values that are greater than 1 or less than 0 but the values are simply wrapped. 
		 * So, for example, setting <code>progress</code> to 1.2 is the same as setting it to 0.2 and -0.2 is the 
		 * same as 0.8. If your goal is to tween the PathFollower around a Circle2D twice completely, you could just 
		 * add 2 to the <code>progress</code> value or use a relative value in the tween, like: <br /><br /><code>
		 * 
		 * TweenLite.to(myFollower, 5, {progress:"2"}); // or myFollower.progress + 2
		 * 
		 * </code><br /><br />
		 * 
		 * <code>progress</code> is identical to <code>rawProgress</code> except that <code>rawProgress</code> 
		 * does not get re-interpolated between 0 and 1. For example, if <code>rawProgress</code> 
		 * is set to -3.4, <code>progress</code> would be 0.6. <code>rawProgress<code> can be useful if 
		 * you need to find out how many times the PathFollower has wrapped.
		 * 
		 * @see #rawProgress
		 **/
		public function get progress():Number
		{
			return this.cachedProgress;
		}


		public function set progress(value:Number):void
		{
			if (value > 1)
			{
				this.cachedRawProgress = value;
				this.cachedProgress = value - int(value);
				if (this.cachedProgress == 0)
				{
					this.cachedProgress = 1;
				}
			}
			else if (value < 0)
			{
				this.cachedRawProgress = value;
				this.cachedProgress = value - (int(value) - 1);
			}
			else
			{
				this.cachedRawProgress = int(this.cachedRawProgress) + value;
				this.cachedProgress = value;
			}
			
			for each (var path:MotionPath in motionPaths)
			{
				target[path.property] = path.getValue(cachedProgress);
			}
		}
	}
}