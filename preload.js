const { contextBridge } = require('electron');
const $ = require('jquery'); // Загружается из node_modules

contextBridge.exposeInMainWorld('$', $);
contextBridge.exposeInMainWorld('jQuery', $);