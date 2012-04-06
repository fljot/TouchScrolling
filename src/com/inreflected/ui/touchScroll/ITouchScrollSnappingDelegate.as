package com.inreflected.ui.touchScroll
{
	/**
	 * @author Pavel fljot
	 */
	public interface ITouchScrollSnappingDelegate
	{
		function getSnappedPosition(position:Number, propertyName:String):Number;
		function getSnappedPositionOnResize(position:Number, propertyName:String, prevViewportSize:Number):Number;
	}
}