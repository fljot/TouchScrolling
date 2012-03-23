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
	public class FlashConnector extends AbstractConnector implements ILogMeisterConnector {
		public function init() : void {
		}

		public function sendDebug(...args) : void {
			trace("debug    : " + args + " " + getSender());
		}

		public function sendInfo(...args) : void {
			trace("info     : " + args + " " + getSender());
		}

		public function sendNotice(...args) : void {
			trace("notice   : " + args + " " + getSender());
		}

		public function sendWarn(...args) : void {
			trace("warn     : " + args + " " + getSender());
		}

		public function sendError(...args) : void {
			trace("error    : " + args + " " + getSender());
		}

		public function sendFatal(...args) : void {
			trace("fatal    : " + args + " " + getSender());
		}

		public function sendCritical(...args) : void {
			trace("critical : " + args + " " + getSender());
		}

		public function sendStatus(...args) : void {
			trace("status   : " + args + " " + getSender());
		}
	}
}
