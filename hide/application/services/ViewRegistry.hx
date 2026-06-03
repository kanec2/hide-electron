// hide/application/services/ViewRegistry.hx

package hide.application.services;

import hide.application.dto.ViewDto;
import js.html.Element;
import js.html.NodeList;
import js.Browser;

class ViewRegistry {
    private var views:Array<ViewDto> = [];
    private var factories:Map<String, ViewFactory> = [];

    public function new() {
        // Добавляем стандартные view
        add({ name: "editor", label: "Редактор", description: "Открыть редактор кода", icon: "fa-code", defaultState: {} });
        add({ name: "project", label: "Проект", description: "Показать дерево проекта", icon: "fa-folder", defaultState: {} });
    }

    public function add(view:ViewDto):Void {
        if (find(view.name) != null) throw "View already exists: ${view.name}";
        views.push(view);
    }

    public function registerView(name:String, factory:ViewFactory):Void {
        factories.set(name, factory);
    }

    public function getFactory(name:String):Null<ViewFactory> {
        return factories.get(name);
    }

    public function find(name:String):Null<ViewDto> {
        return views.find(v -> v.name == name);
    }

    public function all():Array<ViewDto> {
        return views.copy();
    }

    public function count():Int {
        return views.length;
    }
}

typedef ViewFactory = {
    function create(container:js.html.Element, state:Dynamic):Dynamic;
}