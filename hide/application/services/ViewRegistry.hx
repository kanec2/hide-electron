// hide/application/services/ViewRegistry.hx

package hide.application.services;

import hide.domain.services.IViewFactory;
import hide.application.dto.ViewDto;
import hx.injection.*;
import Lambda;
class ViewRegistry implements Service {
    private var views:Array<ViewDto> = [];
    private var viewFactories:Map<String, IViewFactory> = [];
    private var onFactoryRegistered:Null<String->IViewFactory->Void>;

    public function setFactoryRegistrationCallback(cb:String->IViewFactory->Void):Void {
        this.onFactoryRegistered = cb;
    }

    public function registerViewFactory(name:String, factory:IViewFactory):Void {
        viewFactories.set(name, factory);
        if (onFactoryRegistered != null) {
            onFactoryRegistered(name, factory); // ← Уведомляем Layout Engine
        }
    }
    
    public function new() {
        //add({ name: "editor", label: "Редактор", description: "Открыть редактор кода", icon: "fa-code", defaultState: {} });
        //add({ name: "project", label: "Проект", description: "Показать дерево проекта", icon: "fa-folder", defaultState: {} });
    }

    public function getFactory(name:String):Null<IViewFactory> {
        return viewFactories.get(name);
    }


    public function add(view:ViewDto):Void {
        if (find(view.name) != null) throw "View already exists: ${view.name}";
        views.push(view);
    }

    public function find(name:String):Null<ViewDto> {
        return Lambda.find(views, function(v) return v.name == name);
    }

    public function all():Array<ViewDto> {
        return views.copy();
    }

    public function count():Int {
        return views.length;
    }
}