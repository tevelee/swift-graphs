@testable import Graphs
import Testing

struct GraphTests {
    @Test func initial() {
        var graph = AdjacencyList()

        let root = graph.addVertex()
        let a = graph.addVertex()
        let b = graph.addVertex()
        let c = graph.addVertex()
        let d = graph.addVertex()
        let x = graph.addVertex()

        graph.addEdge(from: root, to: a)
        graph.addEdge(from: a, to: b)
        graph.addEdge(from: a, to: c)
        graph.addEdge(from: a, to: d)
        graph.addEdge(from: root, to: x)

        #expect(graph.vertices().count == 6)
        #expect(graph.edges().count == 5)
        #expect(graph.adjacentVertices(of: a) == [b, c, d, root])
        #expect(graph.outEdges(of: a).map(graph.destination) == [b, c, d])
        #expect(graph.inEdges(of: a).map(graph.source) == [root])
        #expect(graph.inEdges(of: root).isEmpty)
    }
}
