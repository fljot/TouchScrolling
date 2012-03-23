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
	import flash.display.DisplayObject;


	public class MonsterDebuggerConnector extends AbstractConnector implements ILogMeisterConnector {
		private var _stage : DisplayObject;
		private static const color_debug : uint = 0xa6e22e;
		private static const color_info : uint = 0x66d9ef;
		private static const color_notice : uint = 0xae81ff;
		private static const color_warning : uint = 0xfd971f;
		private static const color_error : uint = 0xFF0A0A;
		private static const color_fatal : uint = 0xFF8000;
		private static const color_critical : uint = 0xf92672;
		private static const color_status : uint = 0x33FF00;

		public function MonsterDebuggerConnector(inStage : DisplayObject) {
			_stage = inStage;
		}

		public function init() : void {
			MonsterDebugger.initialize(_stage);
		}

		public function sendDebug(...args) : void {
			var sender:String = getSender();
			for each (var arg:* in args) {
				MonsterDebugger.trace(sender, args, "", "", color_debug);
			}
		}

		public function sendInfo(...args) : void {
			var sender:String = getSender();
			for each (var arg:* in args) {
				MonsterDebugger.trace(sender, args, "", "", color_info);
			}
		}

		public function sendNotice(...args) : void {
			var sender:String = getSender();
			for each (var arg:* in args) {
				MonsterDebugger.trace(sender, args, "", "", color_notice);
			}
		}

		public function sendWarn(...args) : void {
			var sender:String = getSender();
			for each (var arg:* in args) {
				MonsterDebugger.trace(sender, args, "", "", color_warning);
			}
		}

		public function sendError(...args) : void {
			var sender:String = getSender();
			for each (var arg:* in args) {
				MonsterDebugger.trace(sender, args, "", "", color_error);
			}
		}

		public function sendFatal(...args) : void {
			var sender:String = getSender();
			for each (var arg:* in args) {
				MonsterDebugger.trace(sender, args, "", "", color_fatal);
			}
		}

		public function sendCritical(...args) : void {
			var sender:String = getSender();
			for each (var arg:* in args) {
				MonsterDebugger.trace(sender, args, "", "", color_critical);
			}
		}

		public function sendStatus(...args) : void {
			var sender:String = getSender();
			for each (var arg:* in args) {
				MonsterDebugger.trace(sender, args, "", "", color_status);
			}
		}

		public static function inspect(object : *) : void {
			MonsterDebugger.inspect(object);
		}
	}
}
