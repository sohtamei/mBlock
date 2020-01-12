package cc.makeblock.mbot.ui.parts
{
	import flash.display.NativeMenu;
	import flash.display.NativeMenuItem;
	import flash.display.Stage;
	import flash.events.Event;
	import flash.filesystem.File;
	import flash.net.URLRequest;
	import flash.net.navigateToURL;
	
//	import cc.makeblock.mbot.uiwidgets.DynamicCompiler;
//	import cc.makeblock.mbot.uiwidgets.errorreport.ErrorReportFrame;
//	import cc.makeblock.mbot.uiwidgets.extensionMgr.ExtensionUtil;
	import cc.makeblock.media.MediaManager;
	import cc.makeblock.menu.MenuUtil;
	import cc.makeblock.menu.SystemMenu;
	import cc.makeblock.updater.AppUpdater;
	
	import extensions.ArduinoManager;
	import extensions.ConnectionManager;
	import extensions.DeviceManager;
	import extensions.ExtensionManager;
	
	import org.aswing.AsWingUtils;
	
	import translation.Translator;
	
	import util.ApplicationManager;
	import util.SharedObjectManager;

	import cc.makeblock.mbot.util.PopupUtil;

	public class TopSystemMenu extends SystemMenu
	{
		public function TopSystemMenu(stage:Stage, path:String)
		{
			super(stage, path);
			
			getNativeMenu().getItemByName("File").submenu.addEventListener(Event.DISPLAYING, __onInitFielMenu);
			getNativeMenu().getItemByName("Edit").submenu.addEventListener(Event.DISPLAYING, __onInitEditMenu);
			getNativeMenu().getItemByName("Connect").submenu.addEventListener(Event.DISPLAYING, __onShowConnect);
		//	getNativeMenu().getItemByName("Boards").submenu.addEventListener(Event.DISPLAYING, __onShowBoards);
			getNativeMenu().getItemByName("Extensions").submenu.addEventListener(Event.DISPLAYING, __onInitExtMenu);
			getNativeMenu().getItemByName("Language").submenu.addEventListener(Event.DISPLAYING, __onShowLanguage);
			
			register("File", __onFile);
			register("Edit", __onEdit);
			register("Connect", __onConnect);
		//	register("Boards", __onSelectBoard);
			register("Help", __onHelp);

		//	register("Manage Extensions", ExtensionUtil.OnManagerExtension);
		//	register("Restore Extensions", ExtensionUtil.OnLoadExtension);
			register("Clear Cache", ArduinoManager.sharedManager().clearTempFiles);
		}
		public function changeLang():void
		{
			MenuUtil.ForEach(getNativeMenu(), changeLangImpl);
		}
		
		private function changeLangImpl(item:NativeMenuItem):*
		{
			var index:int = getNativeMenu().getItemIndex(item);
			if(0 <= index && index < defaultMenuCount){
				return true;
			}
			if(item.name.indexOf("serial_") == 0){
				return;
			}
			var p:NativeMenuItem = MenuUtil.FindParentItem(item);
			if(p != null && p.name == "Extensions"){
				if(p.submenu.getItemIndex(item) > 4){
					return true;
				}
			}
			setItemLabel(item);
/*
			if(item.name == "Boards"){
				setItemLabel(item.submenu.getItemByName("Others"));
				return true;
			}
*/
			if(item.name == "Language"){
				item = MenuUtil.FindItem(item.submenu, "set font size");
				setItemLabel(item);
				return true;
			}
		}
		
		private function setItemLabel(item:NativeMenuItem):void
		{
			var newLabel:String = Translator.map(item.name);
			if(item.label != newLabel){
				item.label = newLabel;
			}
		}
		
		private function __onFile(item:NativeMenuItem):void
		{
			switch(item.name)
			{
				case "New":
					Main.app.createNewProject();
					break;
				case "Load Project":
					Main.app.runtime.selectProjectFile();
					break;
				case "Save Project":
					Main.app.saveFile();
					break;
				case "Save Project As":
					Main.app.exportProjectToFile();
					break;
				case "Undo Revert":
					Main.app.undoRevert();
					break;
				case "Revert":
					Main.app.revertToOriginalProject();
					break;
				case "Import Image":
					MediaManager.getInstance().importImage();
					break;
				case "Export Image":
					MediaManager.getInstance().exportImage();
					break;
			}
		}
		
		private function __onEdit(item:NativeMenuItem):void
		{
			switch(item.name){
				case "Undelete":
					Main.app.runtime.undelete();
					break;
				case "Hide stage layout":
					Main.app.toggleHideStage();
					break;
/*
				case "Small stage layout":
					Main.app.toggleSmallStage();
					break;
				case "Turbo mode":
					Main.app.toggleTurboMode();
					break;
*/
				case "Arduino mode":
					Main.app.changeToArduinoMode();
					break;
			}
			Main.app.track("/OpenEdit");
		}
		
		private function __onConnect(menuItem:NativeMenuItem):void
		{
			var key:String;
			if(menuItem.data){
				key = menuItem.data.@action;
			}else{
				key = menuItem.name;
			}
		/*
			if("upgrade_custom_firmware" == key){
				var panel:DynamicCompiler = new DynamicCompiler();
				panel.show();
				AsWingUtils.centerLocate(panel);
			}else{
		*/
				ConnectionManager.sharedManager().onConnect(key);
		//	}
		}
		
		private function __onShowLanguage(evt:Event):void
		{
			var languageMenu:NativeMenu = evt.target as NativeMenu;
			if(languageMenu.numItems <= 2){
				for each (var entry:Array in Translator.languages) {
					var item:NativeMenuItem = languageMenu.addItemAt(new NativeMenuItem(entry[1]), languageMenu.numItems-2);
					item.name = entry[0];
					item.checked = Translator.currentLang==entry[0];
				}
				languageMenu.addEventListener(Event.SELECT, __onLanguageSelect);
			}else{
				for each(item in languageMenu.items){
					if(item.isSeparator){
						break;
					}
					MenuUtil.setChecked(item, Translator.currentLang==item.name);
				}
			}
			try{
				var fontItem:NativeMenuItem = languageMenu.items[languageMenu.numItems-1];
				for each(item in fontItem.submenu.items){
					MenuUtil.setChecked(item, Translator.currentFontSize==int(item.label));
				}
			}catch(e:Error){
				
			}
		}
		
		private function __onMicrosoftSettingSelect(item:NativeMenuItem):void
		{
			Main.app.openMicrosoftCognitiveSetting(Translator.map("Microsoft Cognitive Services"));
		}
		private function __onLanguageSelect(evt:Event):void
		{
			var item:NativeMenuItem = evt.target as NativeMenuItem;
			if(item.name == "setFontSize"){
				Translator.setFontSize(int(item.label));
			}else{
				Translator.setLanguage(item.name);
			}
		}
		
		private function __onInitFielMenu(evt:Event):void
		{
			var menu:NativeMenu = evt.target as NativeMenu;
			
		//	MenuUtil.setEnable(menu.getItemByName("Undo Revert"), Main.app.canUndoRevert());
		//	MenuUtil.setEnable(menu.getItemByName("Revert"), Main.app.canRevert());
			
			Main.app.track("/OpenFile");
		}
		
		private function __onInitEditMenu(evt:Event):void
		{
			var menu:NativeMenu = evt.target as NativeMenu;
			MenuUtil.setEnable(menu.getItemByName("Undelete"),				Main.app.runtime.canUndelete());
			MenuUtil.setChecked(menu.getItemByName("Hide stage layout"),	Main.app.stageIsHided);
//			MenuUtil.setChecked(menu.getItemByName("Small stage layout"),	!Main.app.stageIsHided && Main.app.stageIsContracted);
//			MenuUtil.setChecked(menu.getItemByName("Turbo mode"),			Main.app.interp.turboMode);
			MenuUtil.setChecked(menu.getItemByName("Arduino mode"),			Main.app.stageIsArduino);
			Main.app.track("/OpenEdit");
		}
		
		private var initConnectMenuItemCount:int = -1;

		private function __onShowConnect(evt:Event):void
		{
			var menu:NativeMenu = evt.target as NativeMenu;
//			var subMenu:NativeMenu = new NativeMenu();
			
			if(initConnectMenuItemCount < 0){
				initConnectMenuItemCount = menu.numItems;
			}
			while(menu.numItems > initConnectMenuItemCount){
				menu.removeItemAt(menu.numItems-1);
			}

			var enabled:Boolean = Main.app.extensionManager.checkExtensionEnabled();
			var arr:Array = ConnectionManager.sharedManager().portlist;
			if(arr.length==0)
			{
				var nullItem:NativeMenuItem = new NativeMenuItem(Translator.map("no serial port"));
				nullItem.enabled = false;
				nullItem.name = "serial_"+"null";
				menu.addItem(nullItem);
			}
			else
			{
				for(var i:int=0;i<arr.length;i++){
					var item:NativeMenuItem = menu.addItem(new NativeMenuItem(Translator.map("Connect to Robot") + "(" + arr[i] + ")"));
					item.name = "serial_"+arr[i];
					
					item.enabled = enabled;
					item.checked = ConnectionManager.sharedManager().selectPort==arr[i] && ConnectionManager.sharedManager().isConnected;
				}
			}
			
//			menu.getItemByName("Serial Port").submenu = subMenu;
			
			var canReset:Boolean = ConnectionManager.sharedManager().isConnected;
			MenuUtil.FindItem(getNativeMenu(), "Reset Default Program").enabled = canReset;
			MenuUtil.FindItem(getNativeMenu(), "Upgrade Firmware").enabled = canReset;
		}

		private function __onSelectBoard(menuItem:NativeMenuItem):void
		{
			DeviceManager.sharedManager().onSelectBoard(menuItem.name);
		}
		
		private function __onShowBoards(evt:Event):void
		{
			var menu:NativeMenu = evt.target as NativeMenu;
			for each(var item:NativeMenuItem in menu.items){
				if(item.enabled){
					MenuUtil.setChecked(item, DeviceManager.sharedManager().checkCurrentBoard(item.name));
				}
			}
		}
		
		private var initExtMenuItemCount:int = -1;
		
		private function __onInitExtMenu(evt:Event):void
		{
			var menuItem:NativeMenu = evt.target as NativeMenu;
			var list:Array = Main.app.extensionManager.extensionList;
			if(list.length==0){
				Main.app.extensionManager.copyLocalFiles();
				SharedObjectManager.sharedManager().setObject("first-launch",false);
			}
			if(initExtMenuItemCount < 0){
				initExtMenuItemCount = menuItem.numItems;
			}
			while(menuItem.numItems > initExtMenuItemCount){
				menuItem.removeItemAt(menuItem.numItems-1);
			}
			list = Main.app.extensionManager.extensionList;
//			var subMenu:NativeMenu = menuItem;
			for(var i:int=0;i<list.length;i++){
				var extName:String = list[i].extensionName;
				var subMenuItem:NativeMenuItem = menuItem.addItem(new NativeMenuItem(Translator.map(extName)));
				subMenuItem.name = extName;
				subMenuItem.label = Translator.map(extName);
				subMenuItem.checked = Main.app.extensionManager.checkExtensionSelected(extName);
				register(extName, __onExtensions);
			}
		}
		
		private function __onExtensions(menuItem:NativeMenuItem):void
		{
			Main.app.extensionManager.onSelectExtension(menuItem.name);
		}
		
		private function __onHelp(menuItem:NativeMenuItem):void
		{
			var path:String = menuItem.data.@url;
			if(path){
				navigateToURL(new URLRequest(path),"_blank");
			}else{
				path = menuItem.data.@url_en;
				if(path){
					if(Translator.currentLang == "zh_CN" || Translator.currentLang == "zh_TW"){
						path = menuItem.data.@url_cn;
					}
					navigateToURL(new URLRequest(path),"_blank");
				}
			}
			
			switch(menuItem.name)
			{
				case "Share Your Project":
					Main.app.track("/OpenShare/");
					break;
				case "FAQ":
					Main.app.track("/OpenFaq/");
					break;
				default:
					Main.app.track("/OpenHelp/"+menuItem.data.@key);
			}
			
			switch(menuItem.data.@key.toString()){
				case "check_app_update":
					AppUpdater.getInstance().start(true);
					break;
//				case "upload_bug":
//					ErrorReportFrame.OpenSendWindow("");
//					break;
			}
		}
	}
}