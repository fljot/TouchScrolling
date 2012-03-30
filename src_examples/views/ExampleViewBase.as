package views
{
	import flash.events.TimerEvent;
	import flash.utils.Timer;
	import flash.utils.setTimeout;
	import model.ExamplesModel;
	import spark.components.Button;
	import spark.components.Group;
	import spark.components.Scroller;
	import spark.components.View;
	import spark.events.ViewNavigatorEvent;
	import spark.layouts.VerticalLayout;
	import mx.core.FlexGlobals;
	import mx.events.FlexEvent;
	import mx.events.ResizeEvent;
	import flash.display.DisplayObject;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.system.Capabilities;


	/**
	 * @author Pavel fljot
	 */
	public class ExampleViewBase extends View
	{
		public static const DEMO_BUTTON_CLICK:String = "demoButtonClick";
		
		private var backButton:Button;
		private var demoButton:Button;
		
		protected static var app:DisplayObject;
		
		[Bindable]
		protected var dataModel:ExamplesModel;
		private var resizeTimer:Timer;
		
		
		public function ExampleViewBase()
		{
			super();
			
			app = FlexGlobals.topLevelApplication as DisplayObject;
			
			if (Capabilities.manufacturer.toLowerCase().indexOf("android") == -1)
			{
				backButton = new Button();
				backButton.label = "Back";
				navigationContent = [backButton];
			}
			
			if (!(this is HomeView))
			{
				demoButton = new Button();
				demoButton.label = "Back to demo";
				actionContent = [demoButton];
			}
			
			resizeTimer = new Timer(10, 1);
			resizeTimer.addEventListener(TimerEvent.TIMER, resizeTimerHandler);
			
			addEventListener(ResizeEvent.RESIZE, resizeHandler);
			addEventListener(FlexEvent.INITIALIZE, initializeHandler);
			addEventListener(ViewNavigatorEvent.VIEW_ACTIVATE, viewActivateHandler);
			addEventListener(ViewNavigatorEvent.VIEW_DEACTIVATE, viewDeactivateHandler);
		}
		
		
		protected function init():void
		{
			if (this.hasOwnProperty("settings"))
			{
				var settingsGroup:Group = this["settings"] as Group;
				var layout:VerticalLayout = new VerticalLayout();
				layout.paddingTop = 10;
				layout.paddingBottom = 10;
				layout.paddingLeft = 10;
				layout.paddingRight = 10;
				settingsGroup.layout = layout;
			}
		}


		protected function onViewActivate():void
		{
			if (!dataModel && data)
			{
				dataModel = data as ExamplesModel;
//				
//				if (dataModel.lastViewTitle)
//				{
//					title = dataModel.lastViewTitle;
//				}
			}
			if (this is HomeView)
			{
				app.alpha = 1;
				app.visible = true;
			}
			else
			{
				app.visible = false;				
			}
		}
		
		
		protected function onViewDeactivate():void
		{
			
		}
		
		
		protected function onResize(width:Number, height:Number):void
		{
			if (this.hasOwnProperty("scroller"))
			{
				var scroller:Scroller = this["scroller"] as Scroller;
				if (scroller && scroller.viewport)
				{
					scroller.viewport.horizontalScrollPosition = 0;
					scroller.viewport.verticalScrollPosition = 0;
				}
			}
		}
		
		
		private function viewActivateHandler(event:ViewNavigatorEvent):void
		{
			if (backButton)
			{
				backButton.addEventListener(MouseEvent.CLICK, backButton_clickHandler);
			}
			if (demoButton)
			{
				demoButton.addEventListener(MouseEvent.CLICK, demoButton_clickHandler);
			}
			
			onViewActivate();
			
			onResize(width, height);
		}
		
		
		private function demoButton_clickHandler(event:MouseEvent):void
		{
			dispatchEvent(new Event(DEMO_BUTTON_CLICK, true));
		}
		
		
		private function viewDeactivateHandler(event:ViewNavigatorEvent):void
		{
			if (backButton)
			{
				backButton.removeEventListener(MouseEvent.CLICK, backButton_clickHandler);
			}
			if (demoButton)
			{
				demoButton.removeEventListener(MouseEvent.CLICK, demoButton_clickHandler);
			}
			
			onViewDeactivate();
		}
		
		
		private function backButton_clickHandler(event:MouseEvent):void
		{
			backButton.removeEventListener(MouseEvent.CLICK, backButton_clickHandler);
			navigator.popView();
		}
		
		
		private function initializeHandler(event:FlexEvent):void
		{
			removeEventListener(FlexEvent.INITIALIZE, initializeHandler);
			init();
		}
		
		
		private function resizeHandler(event:ResizeEvent):void
		{
			// because on iPad stage.stageWidth/stageHeight still gives wrong values for some reason
			resizeTimer.reset();
			resizeTimer.start();
		}


		private function resizeTimerHandler(event:TimerEvent):void
		{
			onResize(width, height);
		}
	}
}