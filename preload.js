const { contextBridge } = require('electron');
const $ = require('jquery'); // Загружается из node_modules

contextBridge.exposeInMainWorld('$', $);
contextBridge.exposeInMainWorld('jQuery', $);
/*
// Экспортируем путь к Monaco CSS
contextBridge.exposeInMainWorld('monacoAssets', {
    cssPath: 'file:///' + path.join(__dirname, 'node_modules', 'monaco-editor', 'min', 'vs', 'editor', 'editor.main.css').split('\\').join('/'),
    monacoPath: path.join(__dirname, 'node_modules', 'monaco-editor')
}); */