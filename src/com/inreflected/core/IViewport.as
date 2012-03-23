package com.inreflected.core
{


	/**
	 * @author Pavel fljot
	 */
	public interface IViewport extends IVisualElement
	{
		function get clipAndEnableScrolling():Boolean;
		function set clipAndEnableScrolling(value:Boolean):void;
		
		function get horizontalScrollPosition():Number;
		function set horizontalScrollPosition(value:Number):void;
		
		function get verticalScrollPosition():Number;
		function set verticalScrollPosition(value:Number):void;
		
		function get contentWidth():Number;
		function get contentHeight():Number;
	}
}