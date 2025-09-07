@testable import Graphs
import Testing

struct DFSTests {
    @Test func reconstructsPathsFromPredecessorEdges() {
        var graph = AdjacencyList()
        let root = graph.addVertex()
        let a = graph.addVertex()
        let b = graph.addVertex()
        let c = graph.addVertex()
        let d = graph.addVertex()
        graph.addEdge(from: root, to: a)
        graph.addEdge(from: root, to: c)
        graph.addEdge(from: a, to: b)
        graph.addEdge(from: c, to: d)

        let last = DepthFirstSearchAlgorithm(on: graph, from: root).reduce(into: nil) { $0 = $1 }
        #expect(last?.vertices(to: a, in: graph) == [root, a])
        #expect(last?.vertices(to: b, in: graph) == [root, a, b])
        #expect(last?.vertices(to: c, in: graph) == [root, c])
        #expect(last?.vertices(to: d, in: graph) == [root, c, d])
    }

    @Test func visitorSeesPreorderOfVertices() {
        var graph = AdjacencyList()
        let root = graph.addVertex()
        let a = graph.addVertex()
        let b = graph.addVertex()
        let c = graph.addVertex()
        let d = graph.addVertex()
        let e = graph.addVertex()
        let f = graph.addVertex()
        let g = graph.addVertex()
        graph.addEdge(from: root, to: a)
        graph.addEdge(from: root, to: b)
        graph.addEdge(from: a, to: c)
        graph.addEdge(from: a, to: d)
        graph.addEdge(from: b, to: d)
        graph.addEdge(from: b, to: e)
        graph.addEdge(from: c, to: f)
        graph.addEdge(from: d, to: f)
        graph.addEdge(from: d, to: g)
        graph.addEdge(from: e, to: g)

        var discovered = graph.makeVertexCollection { Array() }
        var examined = graph.makeVertexCollection { Array() }
        DepthFirstSearchAlgorithm(on: graph, from: root)
            .withVisitor {
                .init(
                    discoverVertex: { discovered.append($0) },
                    examineVertex: { examined.append($0) }
                )
            }
            .forEach { _ in }
        #expect(discovered == [root, a, c, f, d, g, b, e])
        #expect(examined == [root, a, c, f, d, g, b, e])
    }

    @Test func traversalWrapperReturnsVerticesPreorderAndEdgesInAdjacencyOrder() {
        var graph = AdjacencyList()
        let root = graph.addVertex()
        let a = graph.addVertex()
        let b = graph.addVertex()
        let c = graph.addVertex()
        let d = graph.addVertex()
        let ra = graph.addEdge(from: root, to: a)!
        let rc = graph.addEdge(from: root, to: c)!
        let ab = graph.addEdge(from: a, to: b)!
        let cd = graph.addEdge(from: c, to: d)!

        let result = graph.traverse(from: root, using: .dfs())
        #expect(result.vertices == [root, a, b, c, d])
        #expect(result.edges == [ra, rc, ab, cd])
    }

    @Test func traversalWrapperReturnsVerticesPostorderAndEdgesInAdjacencyOrder() {
        var graph = AdjacencyList()
        let root = graph.addVertex()
        let a = graph.addVertex()
        let b = graph.addVertex()
        let c = graph.addVertex()
        let d = graph.addVertex()
        let ra = graph.addEdge(from: root, to: a)!
        let rc = graph.addEdge(from: root, to: c)!
        let ab = graph.addEdge(from: a, to: b)!
        let cd = graph.addEdge(from: c, to: d)!

        let result = graph.traverse(from: root, using: .dfs(order: .postorder))
        #expect(result.vertices == [b, a, d, c, root])
        #expect(result.edges == [ra, rc, ab, cd])
    }

    @Test func classificationDetectsBackEdgesInCycles() {
        var graph = AdjacencyList()
        let a = graph.addVertex()
        let b = graph.addVertex()
        let c = graph.addVertex()
        graph.addEdge(from: a, to: b)
        graph.addEdge(from: b, to: c)
        graph.addEdge(from: c, to: a)

        var backEdges = graph.makeEdgeCollection { Array() }
        var treeEdges = graph.makeEdgeCollection { Array() }
        DepthFirstSearchAlgorithm(on: graph, from: a)
            .withVisitor {
                .init(
                    treeEdge: { treeEdges.append($0) },
                    backEdge: { backEdges.append($0) }
                )
            }
            .forEach { _ in }

        #expect(backEdges.count == 1)
        #expect(treeEdges.count == 2)
    }
}


