package extensions
{
	import flash.events.Event;
	import flash.filesystem.File;
	import flash.html.HTMLLoader;
	import flash.utils.ByteArray;
	import flash.utils.Endian;
	
	import cc.makeblock.interpreter.RemoteCallMgr;
	import cc.makeblock.util.FileUtil;
	
	import org.aswing.JOptionPane;
	
	public class JavaScriptEngine
	{
		private const _htmlLoader:HTMLLoader = new HTMLLoader();
		private var _ext:Object;
		private var _name:String = "";
		public function JavaScriptEngine(name:String="")
		{
			_name = name;
			_htmlLoader.placeLoadStringContentInApplicationSandbox = true;
		}
		private function register(name:String,descriptor:Object,ext:Object,param:Object):void{
			_ext = ext;
			if(_ext._getStatus().msg.indexOf("disconnected")>-1 && ConnectionManager.sharedManager().isConnected)
			{
				onConnected(null);
			}
			Main.app.track("registed:"+_ext._getStatus().msg);
		}
		public function get connected():Boolean{
			if(_ext){
				return _ext._getStatus().status==2;
			}
			return false;
		}
		public function get msg():String{
			if(_ext){
				return _ext._getStatus().msg;
			}
			return "Disconnected";
		}
		public function call(method:String,param:Array,ext:ScratchExtension):void{
			if(!connected) return;	// debug

			var handler:Function = _ext[method];
			if(null == handler){
				Main.app.track(method + " not provide!");
				responseValue();
				return;
			}
			try{
				if(handler.length > param.length){
					handler.apply(null, [0].concat(param));
				}else{
					handler.apply(null, param);
				}
			}catch(error:Error) {
				Main.app.track(error.getStackTrace());
			}
		}
		/*
		public function requestValue(method:String, param:Array, ext:ScratchExtension, nextID:int):void
		{
			if(connected){
				getValue(method,[nextID].concat(param),ext);
			}
		}
		public function getValue(method:String,param:Array,ext:ScratchExtension):*{
			if(!this.connected){
				return false;
			}
			for(var i:uint=0;i<param.length;i++){
				param[i] = ext.getValue(param[i]);
			}
			return _ext[method].apply(null, param);
		}
		public function closeDevice():void{
			if(_ext){
				_ext._shutdown();
			}
		}
		*/
		private function onConnected(evt:Event):void{
			if(_ext){
				var dev:ConnectionManager = ConnectionManager.sharedManager();
				_ext._deviceConnected(dev, dev.checkDevName);
				Main.app.track("register:"+_name);
			}
		}
		private function onClosed(evt:Event):void{
			if(_ext){
				var dev:ConnectionManager = ConnectionManager.sharedManager();
				_ext._deviceRemoved(dev);
				Main.app.track("unregister:"+_name);
			}
		}
		private function onRemoved(evt:Event):void{
			if(_ext/*&&ConnectionManager.sharedManager().extensionName==_name*/){
				ConnectionManager.sharedManager().removeEventListener(Event.CONNECT,onConnected);
				ConnectionManager.sharedManager().removeEventListener(Event.REMOVED,onRemoved);
				ConnectionManager.sharedManager().removeEventListener(Event.CLOSE,onClosed);
				var dev:ConnectionManager = ConnectionManager.sharedManager();
				_ext._deviceRemoved(dev);
				_ext = null;
			}
		}
		public function loadJS(path:String):void{
			var html:String = "var ScratchExtensions = {};" +
				"ScratchExtensions.register = function(name,desc,ext,param){" +
				"	try{			" +
				"		callRegister(name,desc,ext,param);		" +
				"	}catch(err){			" +
				"		setTimeout(ScratchExtensions.register,10,name,desc,ext,param);	" +
				"	}	" +
				"};";
//			html += FileUtil.ReadString(File.applicationDirectory.resolvePath("js/AIRAliases.js"));
			html += FileUtil.ReadString(new File(path));
			_htmlLoader.window.eval(html);
			_htmlLoader.window.callRegister		= register;
			_htmlLoader.window.parseFloat		= readFloat;
			_htmlLoader.window.parseShort		= readShort;
			_htmlLoader.window.parseDouble		= readDouble;
			_htmlLoader.window.float2array		= float2array;
			_htmlLoader.window.short2array		= short2array;
			_htmlLoader.window.int2array		= int2array;
			_htmlLoader.window.string2array 	= string2array;
			_htmlLoader.window.array2string		= array2string;
			_htmlLoader.window.responseValue	= responseValue;
			_htmlLoader.window.responseValue2	= responseValue2;
			_htmlLoader.window.trace			= trace;
			_htmlLoader.window.interruptThread	= interruptThread;
			_htmlLoader.window.air				= {"trace":trace};
			_htmlLoader.window.updateDevName	= updateDevName;
			ConnectionManager.sharedManager().addEventListener(Event.CONNECT,onConnected);
			ConnectionManager.sharedManager().addEventListener(Event.REMOVED,onRemoved);
			ConnectionManager.sharedManager().addEventListener(Event.CLOSE,onClosed);
		}
		private function responseValue(...args):void{
			if(args.length < 2){
				RemoteCallMgr.Instance.onPacketRecv();
			}else if(args[0] == 0x80){
			//	Main.app.runtime.mbotButtonPressed.notify(Boolean(args[1]));
			}else{
				RemoteCallMgr.Instance.onPacketRecv(args[1]);
			}
		}
		private function responseValue2(...args):void{
			if(args.length < 2){
				RemoteCallMgr.Instance.onPacketRecv2();
			}else{
				RemoteCallMgr.Instance.onPacketRecv2(args[1]);
			}
		}
		
		static private function interruptThread(msg:String):void
		{
			RemoteCallMgr.Instance.interruptThread();
			JOptionPane.showMessageDialog("", msg);
		}
		
		static private function readFloat(bytes:Array):Number{
			if(bytes.length < 4){
				return 0;
			}
			for(var i:int=0; i<4; ++i){
				tempBytes[i] = bytes[i];
			}
			tempBytes.position = 0;
			return tempBytes.readFloat();
		}
		static private function readDouble(bytes:Array):Number{
			return readFloat(bytes);
		}
		static private function readShort(bytes:Array):Number{
			if(bytes.length < 2){
				return 0;
			}
			for(var i:int=0; i<2; ++i){
				tempBytes[i] = bytes[i];
			}
			tempBytes.position = 0;
			return tempBytes.readShort();
		}
		static private function float2array(v:Number):Array{
			tempBytes.position = 0;
			tempBytes.writeFloat(v);
			return [tempBytes[0], tempBytes[1], tempBytes[2], tempBytes[3]];
		}
		static private function short2array(v:Number):Array{
			tempBytes.position = 0;
			tempBytes.writeShort(v);
			return [tempBytes[0], tempBytes[1]];
		}
		static private function int2array(v:Number):Array{
			tempBytes.position = 0;
			tempBytes.writeInt(v);
			return [tempBytes[0], tempBytes[1], tempBytes[2], tempBytes[3]];
		}
		static private function string2array(v:String):Array{
			tempBytes.position = 0;
			tempBytes.writeUTFBytes(v);
			var array:Array = [];
			for(var i:int=0;i<tempBytes.position;i++){
				array[i] = tempBytes[i];
			}
			return array;
		}
		static private function array2string(bytes:Array):String{
			for(var i:int=0;i<bytes.length;i++){
				tempBytes[i] = bytes[i];
			}
			tempBytes.position = 0;
			return tempBytes.readUTFBytes(bytes.length);
		}
		static private function trace(msg:String):void
		{
			Main.app.track(msg);
		}
		static private function updateDevName(name:String):void{
			Main.app.topBarPart.versionText.text = name;
		}
		static private const tempBytes:ByteArray = new ByteArray();
		tempBytes.endian = Endian.LITTLE_ENDIAN;
	}
}