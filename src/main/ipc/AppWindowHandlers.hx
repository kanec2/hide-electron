package src.main.ipc;

import electron.main.IpcMain;
import electron.IpcMainEvent;
import electron.main.App;
import electron.main.BrowserWindow;
import electron.main.Dialog;

class AppWindowHandlers {
    public static function setup(mainWindow:BrowserWindow):Void {
        // App commands
        IpcMain.on("app:quit", function(event:IpcMainEvent) App.quit());
        IpcMain.on("app:reload", function(event:IpcMainEvent) if (mainWindow != null) mainWindow.reload());
        IpcMain.on("app:getAppDataPath", function(event:IpcMainEvent) event.returnValue = App.getPath("userData"));
        
        // Window management
        IpcMain.on("window:setTitle", function(event:IpcMainEvent, title:String) {
            if (mainWindow != null) mainWindow.setTitle(title);
            event.returnValue = null;
        });
        IpcMain.on("window:maximize", function(event:IpcMainEvent) {
            if (mainWindow != null) mainWindow.maximize();
            event.returnValue = null;
        });
        IpcMain.on("window:minimize", function(event:IpcMainEvent) {
            if (mainWindow != null) mainWindow.minimize();
            event.returnValue = null;
        });
        IpcMain.on("window:unmaximize", function(event:IpcMainEvent) {
            if (mainWindow != null) mainWindow.unmaximize();
            event.returnValue = null;
        });
        IpcMain.on("window:enterFullscreen", function(event:IpcMainEvent) {
            if (mainWindow != null) mainWindow.setFullScreen(true);
            event.returnValue = null;
        });
        IpcMain.on("window:leaveFullscreen", function(event:IpcMainEvent) {
            if (mainWindow != null) mainWindow.setFullScreen(false);
            event.returnValue = null;
        });
        IpcMain.on("window:open", function(event:IpcMainEvent, data:Dynamic) {
            var url:String = data.url;
            if (url.indexOf("?subView=") != -1) {
                event.sender.send("window:open:subview", { url: url });
                return;
            }
            var child = new BrowserWindow({
                width: data.options.width != null ? data.options.width : 800,
                height: data.options.height != null ? data.options.height : 600,
                title: data.options.title != null ? data.options.title : "Hide",
                parent: mainWindow,
                webPreferences: { nodeIntegration: true, contextIsolation: false }
            });
            child.loadFile(url);
        });

        // Dialogs
        IpcMain.handle("dialog:showOpen", function(event:IpcMainEvent, options:Dynamic) {
            return Dialog.showOpenDialog(mainWindow, options);
        });
        IpcMain.handle("dialog:showSave", function(event:IpcMainEvent, options:Dynamic) {
            return Dialog.showSaveDialog(mainWindow, options);
        });
        IpcMain.handle("dialog:showDirectory", function(event:IpcMainEvent, options:Dynamic) {
            options.properties = ["openDirectory", "createDirectory"];
            return Dialog.showOpenDialog(mainWindow, options);
        });

        // Menu
        IpcMain.on("menu:build", function(event:IpcMainEvent, menuData:Dynamic) {
            trace("[AppWindow] 📥 Received menu data (placeholder)");
        });
    }
}