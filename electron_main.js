// electron-main.js
const { app, BrowserWindow } = require('electron');
const path = require('path');

let mainWindow;

function createMainWindow() {
    mainWindow = new BrowserWindow({
        width: 800,
        height: 600,
        title: 'HIDE',
        icon: path.join(__dirname, 'res/hide.png'),
        show: true,
        webPreferences: {
            nodeIntegration: true,
            contextIsolation: false
        }
    });

    // Загружаем ТОТ ЖЕ app.html, что и в NW.js
    mainWindow.loadFile('app.html');

    // Экспортируем ссылку для доступа из renderer (через @electron/remote)
    // Или используем IPC (см. Вариант 2)
    
    return mainWindow;
}

app.whenReady().then(createMainWindow);