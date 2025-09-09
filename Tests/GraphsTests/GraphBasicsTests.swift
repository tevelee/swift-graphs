@testable import Graphs
import Testing

struct GraphBasicsTests {
    @Test func addsVerticesAndEdges_countsAndAdjacency() {
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
    }

    @Test func inAndoutgoingEdgesRespectInsertionOrder() {
        var graph = AdjacencyList()
        let u = graph.addVertex()
        let v = graph.addVertex()
        let w = graph.addVertex()

        let uv = graph.addEdge(from: u, to: v)!
        let uw = graph.addEdge(from: u, to: w)!

        #expect(graph.outgoingEdges(of: u) == [uv, uw])
        #expect(graph.incomingEdges(of: v) == [uv])
        #expect(graph.incomingEdges(of: w) == [uw])
    }
}


