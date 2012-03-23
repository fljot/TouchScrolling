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
 *	Thanks to Eric-Paul Lecluse for the help on this connector
 *	Thanks to Riccardo Prandini for the update
 *	
 */
package logmeister.connectors {
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.events.SecurityErrorEvent;
	import flash.events.TimerEvent;
	import flash.net.XMLSocket;
	import flash.system.Capabilities;
	import flash.utils.Timer;

	public class SosMaxConnector extends AbstractConnector implements ILogMeisterConnector {
		private var socket : XMLSocket;
		private var _stack : Array;
		private var _timer : Timer;
		private var _debugger : Boolean;
		private var _isConnected : Boolean;

		public function init() : void {
			socket = new XMLSocket();
			socket.addEventListener(Event.CONNECT, handleOnConnect);
			socket.addEventListener(IOErrorEvent.IO_ERROR, onError);
			socket.addEventListener(SecurityErrorEvent.SECURITY_ERROR, onError);

			_stack = [];
			_timer = new Timer(2000);
			_timer.addEventListener(TimerEvent.TIMER, tryToReconnect);

			connect();
		}

		public function sendStatus(...args) : void {
			sendSOSMessage(String(args), getSender(), "trace");
		}

		public function sendDebug(...args) : void {
			sendSOSMessage(String(args), getSender(), "debug");
		}

		public function sendInfo(...args) : void {
			sendSOSMessage(String(args), getSender(), "info");
		}

		public function sendNotice(...args) : void {
			sendSOSMessage(String(args), getSender(), "warning");
		}

		public function sendWarn(...args) : void {
			sendSOSMessage(String(args), getSender(), "warn");
		}

		public function sendCritical(...args) : void {
			sendSOSMessage(String(args), getSender(), "severe");
		}

		public function sendError(...args) : void {
			sendSOSMessage(String(args), getSender(), "error");
		}

		public function sendFatal(...args) : void {
			sendSOSMessage(String(args), getSender(), "fatal");
		}

		private function connect() : void {
			try {
				socket.connect("localhost", 4444);
			} catch (error : SecurityError) {
				trace("SecurityError in SOSAppender: " + error);
			}
		}

		private function tryToReconnect(event : TimerEvent) : void {
			_timer.removeEventListener(TimerEvent.TIMER, tryToReconnect);
			connect();
		}

		private function onError(event : Event) : void {
			// ignore errors.
			// they only occur when the SOS viewer is not running.
			_timer.start();
		}

		private function handleOnConnect(event : Event) : void {
			_debugger = Capabilities.isDebugger;
			_isConnected = true;
			_timer.stop();

			while (_stack.length) {
				var m : Message = _stack.shift() as Message;
				sendSOSMessage(m.message, m.origin, m.key);
			}
		}

		private function sendSOSMessage(inMessage : String, inOrigin : String, inKey : String = "debug") : void {
			if (_isConnected) {
				try {
					socket.send("!SOS<showMessage key='" + inKey + "'>" + inOrigin + " " + inMessage.replace(/&/g, "&amp;").replace(/\>/gi, "&gt;").replace(/\</gi, "&lt;") + "</showMessage>");
				} catch (e : Error) {
					// ignore error
					trace("no debugger found");
				}
			} else {
				_stack.push(new Message(inMessage, inOrigin, inKey));
				while (_stack.length > 200) {
					_stack.shift();
				}
			}
		}
	}
}
class Message {
	public var key : String;
	public var origin : String;
	public var message : String;

	public function Message(inMessage : String, inOrigin : String, inKey : String) {
		message = inMessage;
		origin = inOrigin;
		key = inKey;
	}
}
