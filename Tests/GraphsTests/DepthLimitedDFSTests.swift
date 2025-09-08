@testable import Graphs
import Testing

struct DepthLimitedDFSTests {
    @Test func depthLimitedDFS_PrunesBeyondLimit() {
        var graph = AdjacencyList()
        let root = graph.addVertex()
        let a = graph.addVertex()
        let b = graph.addVertex()
        let x = graph.addVertex()
        let y = graph.addVertex()

        let ra = graph.addEdge(from: root, to: a)!
        let rb = graph.addEdge(from: root, to: b)!
        _ = graph.addEdge(from: a, to: x)!
        _ = graph.addEdge(from: b, to: y)!

        let result = graph.traverse(from: root, using: .depthLimitedDFS(maxDepth: 1))

        // Only root and its immediate children should be discovered; deeper nodes pruned
        #expect(result.vertices == [root, a, b])
        #expect(result.edges == [ra, rb])
    }

    @Test func depthLimitedDFS_WithZeroLimit_VisitsOnlySource() {
        var graph = AdjacencyList()
        let root = graph.addVertex()
        let a = graph.addVertex()
        let b = graph.addVertex()
        _ = graph.addEdge(from: root, to: a)!
        _ = graph.addEdge(from: root, to: b)!

        let result = graph.traverse(from: root, using: .depthLimitedDFS(maxDepth: 0))

        #expect(result.vertices == [root])
        #expect(result.edges.isEmpty)
    }
}


