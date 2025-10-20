@testable import Graphs
import Testing

struct EdgeStorageBackendsTests {
    @Test func cooAdjacencyList_basic() {
        var g = AdjacencyList(edgeStore: COOEdgeStorage().cacheInOutEdges())

        let u = g.addVertex()
        let v = g.addVertex()
        let w = g.addVertex()

        let uv = g.addEdge(from: u, to: v)!
        let uw = g.addEdge(from: u, to: w)!

        #expect(g.edgeCount == 2)
        #expect(Array(g.outgoingEdges(of: u)) == [uv, uw])
        #expect(Array(g.incomingEdges(of: v)) == [uv])
        #expect(Array(g.incomingEdges(of: w)) == [uw])
    }

    @Test func csrAdjacencyList_basic() {
        var g = AdjacencyList(edgeStore: CSREdgeStorage().cacheInOutEdges())
        
        let a = g.addVertex()
        let b = g.addVertex()
        let c = g.addVertex()
        
        g.addEdge(from: a, to: b)
        g.addEdge(from: a, to: c)
        g.addEdge(from: c, to: b)

        #expect(g.vertexCount == 3)
        #expect(g.edgeCount == 3)

        // Degrees and incidence
        #expect(g.outDegree(of: a) == 2)
        #expect(g.inDegree(of: b) == 2)
    }
}


