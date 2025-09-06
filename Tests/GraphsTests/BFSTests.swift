@testable import Graphs
import Testing

struct BFSTests {
    @Test func startsAtSourceAndComputesDistancesAndPaths() {
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

        let result = BreadthFirstSearchAlgorithm(on: graph, from: root)
            .prefix { $0.depth() < 3 }
            .reduce(into: nil) { $0 = $1 }

        #expect(result?.depth(of: root) == 0)
        #expect(result?.depth(of: a) == 1)
        #expect(result?.depth(of: c) == 1)
        #expect(result?.depth(of: b) == 2)
        #expect(result?.depth(of: d) == 2)

        #expect(result?.vertices(to: a, in: graph) == [root, a])
        #expect(result?.vertices(to: b, in: graph) == [root, a, b])
        #expect(result?.vertices(to: c, in: graph) == [root, c])
        #expect(result?.vertices(to: d, in: graph) == [root, c, d])
    }

    @Test func visitorReportsDiscoveryThenExaminationInBFSOrder() {
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

        BreadthFirstSearchAlgorithm(on: graph, from: root)
            .withVisitor {
                .init(
                    discoverVertex: { discovered.append($0) },
                    examineVertex: { examined.append($0) }
                )
            }
            .forEach { _ in }

        #expect(discovered == [a, b, c, d, e, f, g])
        #expect(examined == [root, a, b, c, d, e, f, g])
    }

    @Test func traversalWrapperReturnsBFSVertexAndEdgeOrder() {
        var graph = AdjacencyList()
        let root = graph.addVertex()
        let a = graph.addVertex()
        let b = graph.addVertex()
        let c = graph.addVertex()
        let d = graph.addVertex()
        let ra = graph.addEdge(from: root, to: a)
        let rc = graph.addEdge(from: root, to: c)
        let ab = graph.addEdge(from: a, to: b)
        let cd = graph.addEdge(from: c, to: d)

        let result = graph.traverse(from: root, using: .bfs())
        #expect(result.vertices == [root, a, c, b, d])
        #expect(result.edges == [ra, rc, ab, cd])
    }
}


