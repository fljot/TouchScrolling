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
package logmeister {
	import logmeister.connectors.ILogMeisterConnector;

	import flash.utils.getQualifiedClassName;

	public class LogMeister {
		public static const VERSION : String = "version 1.8.2";
		private static var loggers : Array = new Array();
		// what's enabled
		private static var _debug : Boolean = true;
		private static var _info : Boolean = true;
		private static var _notice : Boolean = true;
		private static var _status : Boolean = true;
		private static var _warn : Boolean = true;
		private static var _critical : Boolean = true;
		private static var _error : Boolean = true;
		private static var _fatal : Boolean = true;

		/*
		 * Enable or disable certain log levels
		 */
		public static function enableMessages(debug : Boolean, info : Boolean, notice : Boolean, status : Boolean, warn : Boolean, critical : Boolean, error : Boolean, fatal : Boolean) : void {
			_debug = debug;
			_info = info;
			_notice = notice;
			_status = status;
			_warn = warn;
			_critical = critical;
			_error = error;
			_fatal = fatal;
		}

		/*
		 * Add an Array of loggers for examples see the connectors package
		 */
		public static function addLoggers(loggers : Array) : void {
			for each (var logger : ILogMeisterConnector in loggers) {
				addLogger(logger);
			}
		}

		/*
		 * Add a logger connector (@see ILogMeisterConnector), a logger cannot be added twice
		 */
		public static function addLogger(inLogger : ILogMeisterConnector) : void {
			for each (var logger : ILogMeisterConnector in loggers) {
				if (getQualifiedClassName(logger) == getQualifiedClassName(inLogger)) {
					// ignore double added loggers
					return;
				}
			}

			inLogger.init();
			loggers.push(inLogger);
		}

		/*
		 * Clear the list of active Loggers, after this statement you will not recieve any debug messages
		 */
		public static function clearLoggers() : void {
			loggers = new Array();
		}

		NSLogMeister static function debug(... args) : void {
			if (!_debug) return;
			for each (var logger : ILogMeisterConnector in loggers) {
				logger.sendDebug.apply(null, args);
			}
		}

		NSLogMeister static function info(... args) : void {
			if (!_info) return;
			for each (var logger : ILogMeisterConnector in loggers) {
				logger.sendInfo.apply(null, args);
			}
		}

		NSLogMeister static function notice(... args) : void {
			if (!_notice) return;
			for each (var logger : ILogMeisterConnector in loggers) {
				logger.sendNotice.apply(null, args);
			}
		}

		NSLogMeister static function warn(... args) : void {
			if (!_warn) return;
			for each (var logger : ILogMeisterConnector in loggers) {
				logger.sendWarn.apply(null, args);
			}
		}

		NSLogMeister static function error(... args) : void {
			if (!_error) return;
			for each (var logger : ILogMeisterConnector in loggers) {
				logger.sendError.apply(null, args);
			}
		}

		NSLogMeister static function fatal(... args) : void {
			if (!_fatal) return;
			for each (var logger : ILogMeisterConnector in loggers) {
				logger.sendFatal.apply(null, args);
			}
		}

		NSLogMeister static function critical(... args) : void {
			if (!_critical) return;
			for each (var logger : ILogMeisterConnector in loggers) {
				logger.sendCritical.apply(null, args);
			}
		}

		NSLogMeister static function status(... args) : void {
			if (!_status) return;
			for each (var logger : ILogMeisterConnector in loggers) {
				logger.sendStatus.apply(null, args);
			}
		}
	}
}
