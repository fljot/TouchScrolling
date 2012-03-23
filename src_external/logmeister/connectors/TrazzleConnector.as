/*
 *	LogMeister for ActionScript 3.0
 *	Copyright © 2011 Base42.nl
 *	All rights reserved.
 *	
 *	http://github.com/base42/LogMeister
 * 
 * Permission is hereby granted, free of charge, to any person obtaining
 * a copy of this software and associated documentation files (the
 * "Software"), to deal in the Software without restriction, including
 * without limitation the rights to use, copy, modify, merge, publish,
 * distribute, sublicense, and/or sell copies of the Software, and to
 * permit persons to whom the Software is furnished to do so, subject to
 * the following conditions:
 * 
 * The above copyright notice and this permission notice shall be
 * included in all copies or substantial portions of the Software.
 * 
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
 * EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
 * MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
 * NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
 * LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
 * OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
 * WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 *	
 *	Logmeister version 1.8.2
 *	
 */
package logmeister.connectors {
	import flash.display.BitmapData;
	import flash.display.DisplayObject;
	import flash.display.Stage;


	public class TrazzleConnector extends AbstractConnector implements ILogMeisterConnector {
		private var _stage : Stage;
		private var _title : String;
		private var _monitorPerformance : Boolean;

		public function TrazzleConnector(inStage : Stage, inTitle : String, inMonitorPerformance : Boolean = true) {
			_monitorPerformance = inMonitorPerformance;
			_stage = inStage;
			_title = inTitle;
		}

		public function init() : void {
			zz_init(_stage, _title);
			if (_monitorPerformance) zz_monitor(true);
		}

		public function sendDebug(... args) : void {
			send("d " + args);
		}

		public function sendInfo(... args) : void {
			send("i " + args);
		}

		public function sendNotice(... args) : void {
			send("n " + args);
		}

		public function sendWarn(... args) : void {
			send("e " + args);
		}

		public function sendError(... args) : void {
			send("e " + args);
		}

		public function sendFatal(... args) : void {
			send("f " + args);
		}

		public function sendCritical(... args) : void {
			send("c " + args);
		}

		public function sendStatus(... args) : void {
			send("s " + args);
		}

		public static function logDisplayObject(inDisplayObject : DisplayObject, inTransparent : Boolean = true, inFillColor : uint = 0xffffff) : void {
			var bd : BitmapData = new BitmapData(inDisplayObject.width, inDisplayObject.height, inTransparent, inTransparent ? 0x00000000 : inFillColor);
			bd.draw(inDisplayObject);
			TrazzleLogger.instance().logBitmapData(bd);
		}

		private function send(...rest) : void {
			TrazzleLogger.instance().log(rest.toString(), 5);
		}

		public static function getMenu() : StatusBar {
			return StatusBar.systemStatusBar();
		}
	}
}