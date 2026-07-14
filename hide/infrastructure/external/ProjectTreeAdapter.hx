package hide.infrastructure.external;

import hide.application.services.ProjectTreeService.TreeNode;
import hide.infrastructure.external.arborist.*;

class ProjectTreeAdapter {
    /**
     * Преобразует плоский список узлов в древовидную структуру для Arborist.
     * @param nodes Список узлов от ProjectTreeService
     * @return Массив ArboristNode
     */
    public static function toArboristNodes(nodes:Array<TreeNode>):Array<ArboristNode> {
        return [for (node in nodes) {
            id: node.path,
            name: node.name,
            isLeaf: !node.isDirectory,
            // ✅ КРИТИЧНО: Для папок создаем пустой массив, для файлов - null
            children: node.isDirectory ? [] : null, 
            isLoading: false,
            isLoaded: false,
            path: node.path,
            relativePath: node.relativePath,
            extension: node.extension
        }];
    }
}