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
	import flash.system.Capabilities;

	internal class AbstractConnector {
		protected var _senderLineNumber : uint = 7;

		protected function getSender() : String {
			if (!Capabilities.isDebugger) return "";

			try {
				var sender : String = new Error().getStackTrace().split("\n")[_senderLineNumber];

				var senderDetails : Array = sender.match(/at\s([a-zA-Z0-9_\.:]+)[\/|\\]([a-zA-Z0-9_]+)\(\).+:([\d]+)/);

				if (!senderDetails) {
					senderDetails = sender.match(/at\s([a-zA-Z0-9_\.:]+)\(\).+[\/|\\]([a-zA-Z0-9_]+)\.as:([\d]+)/);
				}

				var className : String = senderDetails[1];
				var functionName : String = senderDetails[2];
				var lineNumber : String = senderDetails[3];

				return className + "." + functionName + " (" + lineNumber + ") ";
			} catch (e : Error) {
				return "";
			}
			return "";
		}
	}
}