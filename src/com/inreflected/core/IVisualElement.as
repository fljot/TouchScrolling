package com.inreflected.core
{
	import flash.display.Stage;
	import flash.display.DisplayObjectContainer;
	import flash.display.IBitmapDrawable;
	import flash.events.IEventDispatcher;


	/**
	 * @author Pavel fljot
	 */
	public interface IVisualElement extends IEventDispatcher, IBitmapDrawable
	{
		function get x():Number;
		function set x(value:Number):void;
		
		function get y():Number;
		function set y(value:Number):void;
		
		function get width():Number;
		function set width(value:Number):void;
		
		function get height():Number;
		function set height(value:Number):void;
		
		function get alpha():Number;
		function set alpha(value:Number):void;
		
		function get visible():Boolean;
		function set visible(value:Boolean):void;
		
		function get parent():DisplayObjectContainer;
		
		function get stage():Stage;
	}
}