@testable import Graphs
import Testing

struct SearchDFSOrderTests {
    
    @Test func preorderVisitsParentBeforeChildren() {
        var graph = AdjacencyList()
        
        // Tree structure:
        //     a
        //    / \
        //   b   c
        //  /
        // d
        let a = graph.addVertex()
        let b = graph.addVertex()
        let c = graph.addVertex()
        let d = graph.addVertex()
        
        graph.addEdge(from: a, to: b)
        graph.addEdge(from: a, to: c)
        graph.addEdge(from: b, to: d)
        
        let result = Array(graph.search(from: a, using: .dfs(order: .preorder)))
        #expect(result == [a, b, d, c])
    }
    
    @Test func postorderVisitsChildrenBeforeParent() {
        var graph = AdjacencyList()
        let a = graph.addVertex()
        let b = graph.addVertex()
        let c = graph.addVertex()
        let d = graph.addVertex()
        
        graph.addEdge(from: a, to: b)
        graph.addEdge(from: a, to: c)
        graph.addEdge(from: b, to: d)
        
        let result = Array(graph.search(from: a, using: .dfs(order: .postorder)))
        #expect(result == [d, b, c, a])
    }
    
    @Test func lazyEvaluationStopsEarly() {
        var graph = AdjacencyList()
        let a = graph.addVertex()
        let b = graph.addVertex()
        let c = graph.addVertex()
        let d = graph.addVertex()
        
        graph.addEdge(from: a, to: b)
        graph.addEdge(from: a, to: c)
        graph.addEdge(from: b, to: d)
        
        let result = graph.search(from: a, using: .dfs(order: .preorder)).prefix(2)
        
        let collected = Array(result)
        #expect(collected == [a, b])
    }
    
    @Test func inorderVisitsLeftSubtreeThenRootThenRightSubtree() {
        var graph = AdjacencyList(edgeStore: BinaryEdgeStore())
        
        // Binary tree structure:
        //       a
        //     /   \
        //    b     c
        //   / \
        //  d   e
        let a = graph.addVertex()
        let b = graph.addVertex()
        let c = graph.addVertex()
        let d = graph.addVertex()
        let e = graph.addVertex()
        
        graph.setLeftNeighbor(of: a, to: b)
        graph.setRightNeighbor(of: a, to: c)
        graph.setLeftNeighbor(of: b, to: d)
        graph.setRightNeighbor(of: b, to: e)
        
        let result = Array(graph.search(from: a, using: .dfs(order: .inorder)))
        #expect(result == [d, b, e, a, c])
    }
}
