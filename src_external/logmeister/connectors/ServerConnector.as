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
	import flash.net.URLLoader;
	import flash.net.URLRequest;
	import flash.net.URLRequestMethod;
	import flash.net.URLVariables;

	public class ServerConnector extends AbstractConnector implements ILogMeisterConnector {
		public var serverPath : String;
		public var projectId : String;
		public var logLevels : String;
		public var buildInfo : String;

		/*	
		 * @param inServerPath:String path where to post logs
		 * @param inLogLevels:String list of debug levels. @example fec sends fatal, error and critical
		 * @param inProjectId:String id of the project.
		 * @param inBuildInfo:String the actual build information
		 */
		public function ServerConnector(inServerPath : String, inLogLevels : String, inProjectId : uint, inBuildInfo : String) {
			serverPath = inServerPath;
			projectId = inProjectId.toString();
			logLevels = inLogLevels;
			buildInfo = inBuildInfo;
		}

		public function init() : void {
		}

		public function sendDebug(...args : *) : void {
			sendToServer("debug", args);
		}

		public function sendInfo(...args : *) : void {
			sendToServer("info", args);
		}

		public function sendNotice(...args : *) : void {
			sendToServer("notice", args);
		}

		public function sendWarn(...args : *) : void {
			sendToServer("warning", args);
		}

		public function sendError(...args : *) : void {
			sendToServer("error", args);
		}

		public function sendFatal(...args : *) : void {
			sendToServer("fatal", args);
		}

		public function sendCritical(...args : *) : void {
			sendToServer("critical", args);
		}

		public function sendStatus(...args : *) : void {
			sendToServer("status", args);
		}

		private function sendToServer(level : String, ...args) : void {
			if (logLevels.indexOf(level) == -1) return;

			var loader : URLLoader = new URLLoader();
			var request : URLRequest = new URLRequest(serverPath);

			var errs : Array = new Error().getStackTrace().match(/\[([^\]]+)/gi);
			var leni : uint = errs.length;
			for (var i : uint = 0;i < leni;i++) {
				errs[i] = String(errs[i]).substring(1, String(errs[i]).length);
			}

			errs.shift();
			errs.shift();
			errs.shift();

			var vars : URLVariables = new URLVariables();
			vars["data[Log][project_id]"] = projectId;
			vars["data[Log][level]"] = level;
			vars["data[Log][stacktrace]"] = errs.join("\n");
			vars["data[Log][build_info]"] = buildInfo;
			vars["data[Log][message]"] = args;

			request.data = vars;
			request.method = URLRequestMethod.POST;
			loader.load(request);
		}
	}
}
