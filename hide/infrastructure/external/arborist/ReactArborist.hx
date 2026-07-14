// hide/infrastructure/external/ReactArborist.hx
package hide.infrastructure.external.arborist;

import react.ReactComponent;
import react.ReactMacro.jsx;

@:jsRequire("react-arborist", "Tree") 
extern class ReactArborist extends ReactComponentOfProps<TreeProps<Dynamic>> {}