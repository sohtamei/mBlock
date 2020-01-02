package extensions
{
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.filesystem.File;
	import flash.net.URLRequest;
	import flash.net.navigateToURL;
	import flash.utils.ByteArray;
	
	import cc.makeblock.interpreter.BlockInterpreter;
	
	import util.ApplicationManager;

	public class ConnectionManager extends EventDispatcher
	{
		private static var _instance:ConnectionManager;
		public var extensionName:String = "";
		public function ConnectionManager()
		{
		}
		public static function sharedManager():ConnectionManager{
			if(_instance==null){
				_instance = new ConnectionManager;
			}
			return _instance;
		}
		public function onConnect(name:String):void{
			switch(name){
/*
				case "view_source":{
					SerialManager.sharedManager().openSource();
					break;
				}
*/
				case "upgrade_firmware":{
					SerialManager.sharedManager().upgrade(File.applicationDirectory.nativePath + "/tools/hex/remoconRobo_monitor.hex");
				//	SerialManager.sharedManager().upgrade(ApplicationManager.sharedManager().documents.nativePath + "/mBlock/tools/hex/remoconRobo_monitor.hex");
					break;
				}
				case "reset_program":{
					SerialManager.sharedManager().upgrade(File.applicationDirectory.nativePath + "/tools/hex/remoconRobo.hex");
				//	SerialManager.sharedManager().upgrade(ApplicationManager.sharedManager().documents.resolvePath("mBlock/tools/hex/remoconRobo.hex").nativePath);
					break;
				}
/*
				case "driver":{
					MBlock.app.track("/OpenSerial/InstallDriver");
					var fileDriver:File;
					if(ApplicationManager.sharedManager().system==ApplicationManager.MAC_OS){
//						navigateToURL(new URLRequest("https://github.com/Makeblock-official/Makeblock-USB-Driver"));
						fileDriver = new File(File.applicationDirectory.nativePath+"/drivers/Arduino Driver.pkg");
						fileDriver.openWithDefaultApplication();
					}else{
						fileDriver = new File(File.applicationDirectory.nativePath+"/drivers/Driver_for_Windows.exe");
						fileDriver.openWithDefaultApplication();
					}
					break;
				}
*/
				default:{
					BlockInterpreter.Instance.stopAllThreads();
					if(name.indexOf("serial_")>-1){
						MBlock.app.track("/Connect/Serial");
						SerialManager.sharedManager().connect(name.split("serial_").join(""));
					}
				}
			}
		}
		public function open(port:String,baud:uint=115200):Boolean{
			MBlock.app.track("connection:"+port);
			if(port){
				return SerialManager.sharedManager().open(port,baud);
			}
			return false;
		}
		public function onClose(port:String):void{
			SerialDevice.sharedDevice().clear(port);
			if(!SerialDevice.sharedDevice().connected){
				MBlock.app.topBarPart.setDisconnectedTitle();
			}else{
				MBlock.app.topBarPart.setConnectedTitle("Connect");
			}
			BlockInterpreter.Instance.stopAllThreads();
			this.dispatchEvent(new Event(Event.CLOSE));
		}
		public function onRemoved(extName:String = ""):void{
			extensionName = extName;
			this.dispatchEvent(new Event(Event.REMOVED));
		}
		public function onOpen(port:String):void{
			SerialDevice.sharedDevice().port = port;
			this.dispatchEvent(new Event(Event.CONNECT));
		}
		public function onReOpen():void{
			if(SerialDevice.sharedDevice().port!=""){
				this.dispatchEvent(new Event(Event.CONNECT));
			}
		}
		private var _bytes:ByteArray;
		
		public function onReceived(bytes:ByteArray):void{
			_bytes = bytes;
			MBlock.app.scriptsPart.onSerialDataReceived(bytes);
			this.dispatchEvent(new Event(Event.CHANGE));
		}
		public function sendBytes(bytes:ByteArray):void{
			if(SerialManager.sharedManager().isConnected){
				SerialManager.sharedManager().sendBytes(bytes);
			}
			bytes.clear();
		}
		public function readBytes():ByteArray{
			if(_bytes){
				return _bytes;
			}
			return new ByteArray;
		}
	}
}