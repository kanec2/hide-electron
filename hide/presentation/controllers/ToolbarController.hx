// hide/presentation/controllers/ToolbarController.hx (полная замена)
package hide.presentation.controllers;
import hide.application.services.MenuService;
import hide.shared.types.IEventBus;
import js.html.Element;
import hx.injection.Service;

class ToolbarController implements Service {
    private var menuService:MenuService;
    private var eventBus:IEventBus;
    private var container:Null<Element>;
    private var isPlaying:Bool = false;
    private var isPaused:Bool = false;
    
    public function new(menuService:MenuService, eventBus:IEventBus) {
        this.menuService = menuService;
        this.eventBus = eventBus;
    }

    public function setContainer(el:Element):Void {
        this.container = el;
        render();
        attachEvents();
    }

    private function render():Void {
        if (container == null) return;
        container.innerHTML = '';
        container.style.cssText = 'display:flex; align-items:center; justify-content:center; gap:8px; padding:6px 12px; background:#2a2a2a; border-bottom:1px solid #1a1a1a; height:36px;';
        
        // === ЛЕВАЯ ГРУППА ===
        var leftGroup = createGroup();
        leftGroup.appendChild(createToolButton('📁', 'assets', 'Project Browser'));
        leftGroup.appendChild(createToolButton('🎬', 'scene', 'Scene View'));
        container.appendChild(leftGroup);
        
        // === ЦЕНТРАЛЬНАЯ ГРУППА: Play Controls ===
        var centerGroup = createGroup();
        centerGroup.style.cssText = 'display:flex; align-items:center; gap:4px; background:#1a1a1a; padding:4px 8px; border-radius:4px;';
        
        var playBtn = createPlayButton('▶', 'play', 'Play (Ctrl+P)');
        var pauseBtn = createToolButton('⏸', 'pause', 'Pause (Ctrl+Shift+P)');
        pauseBtn.style.opacity = '0.5';
        var stepBtn = createToolButton('⏭', 'step', 'Step (Ctrl+Alt+P)');
        stepBtn.style.opacity = '0.5';
        
        centerGroup.appendChild(playBtn);
        centerGroup.appendChild(pauseBtn);
        centerGroup.appendChild(stepBtn);
        container.appendChild(centerGroup);
        
        // === ПРАВАЯ ГРУППА ===
        var rightGroup = createGroup();
        rightGroup.style.marginLeft = 'auto';
        rightGroup.appendChild(createToolButton('🔍', 'search', 'Search'));
        rightGroup.appendChild(createToolButton('⚙️', 'settings', 'Settings'));
        container.appendChild(rightGroup);
    }
    
    private function createGroup():Element {
        var g = js.Browser.document.createElement('div');
        g.style.cssText = 'display:flex; align-items:center; gap:4px;';
        return g;
    }
    
    private function createToolButton(icon:String, action:String, title:String):Element {
        var btn = js.Browser.document.createElement('button');
        btn.setAttribute('data-action', action);
        btn.title = title;
        btn.innerHTML = icon;
        btn.style.cssText = 'background:transparent; border:none; color:#ccc; font-size:16px; padding:4px 8px; border-radius:3px; cursor:pointer; transition:background 0.15s;';
        btn.addEventListener('mouseover', function(_) btn.style.background = '#3a3a3a');
        btn.addEventListener('mouseout', function(_) btn.style.background = 'transparent');
        return btn;
    }
    
    private function createPlayButton(icon:String, action:String, title:String):Element {
        var btn = createToolButton(icon, action, title);
        btn.style.cssText += ' background:#2d5c8a; color:#fff; border-radius:4px;';
        btn.addEventListener('mouseover', function(_) btn.style.background = '#3a6c9a');
        btn.addEventListener('mouseout', function(_) btn.style.background = '#2d5c8a');
        return btn;
    }

    private function attachEvents():Void {
        if (container == null) return;
        
        container.addEventListener('click', function(e:js.html.MouseEvent) {
            var target = cast(e.target, js.html.Element);
            var btn = target.closest('button[data-action]');
            if (btn == null) return;
            
            var action = btn.getAttribute('data-action');
            switch (action) {
                case 'play':
                    isPlaying = !isPlaying;
                    isPaused = false;
                    btn.innerHTML = isPlaying ? '⏹' : '▶';
                    btn.title = isPlaying ? 'Stop (Ctrl+P)' : 'Play (Ctrl+P)';
                    btn.style.background = isPlaying ? '#8a2d2d' : '#2d5c8a';
                    trace('▶ Play mode: ' + isPlaying);
                    // TODO: eventBus.publish(new PlayStateChanged(isPlaying));
                    
                case 'pause':
                    if (!isPlaying) return;
                    isPaused = !isPaused;
                    btn.style.opacity = isPaused ? '1' : '0.5';
                    btn.style.background = isPaused ? '#8a6c2d' : 'transparent';
                    trace('⏸ Paused: ' + isPaused);
                    
                case 'step':
                    if (!isPlaying || !isPaused) return;
                    trace('⏭ Step forward');
                    
                default:
                    trace('Toolbar action: ' + action);
            }
        });
    }

    public function dispose():Void {}
}