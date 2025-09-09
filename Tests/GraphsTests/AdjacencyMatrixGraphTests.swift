@testable import Graphs
import Testing

struct AdjacencyMatrixTests {
    @Test func addsVerticesAndEdges_countsAndAdjacency() {
        var g = AdjacencyMatrix()

        let u = g.addVertex()
        let v = g.addVertex()
        let w = g.addVertex()

        let uv = g.addEdge(from: u, to: v)!
        let uw = g.addEdge(from: u, to: w)!

        #expect(g.vertexCount == 3)
        #expect(g.edgeCount == 2)
        #expect(g.edge(from: u, to: v) == uv)
        #expect(g.edge(from: u, to: w) == uw)
        #expect(g.edge(from: v, to: u) == nil)
    }

    @Test func incidenceAndDegrees() {
        var g = AdjacencyMatrix()
        let a = g.addVertex()
        let b = g.addVertex()
        let c = g.addVertex()

        let ab = g.addEdge(from: a, to: b)!
        let ac = g.addEdge(from: a, to: c)!
        let cb = g.addEdge(from: c, to: b)!

        #expect(g.outDegree(of: a) == 2)
        #expect(g.inDegree(of: b) == 2)

        #expect(Array(g.outgoingEdges(of: a)) == [ab, ac])
        #expect(Array(g.incomingEdges(of: b)) == [ab, cb])

        // adjacency (neighbors) should include outgoing and incoming
        let neighborsOfB = g.adjacentVertices(of: b)
        #expect(neighborsOfB.contains(a))
        #expect(neighborsOfB.contains(c))
    }

    @Test func removeVertexAndEdge() {
        var g = AdjacencyMatrix()
        let x = g.addVertex()
        let y = g.addVertex()
        _ = g.addEdge(from: x, to: y)!
        #expect(g.edgeCount == 1)

        if let e = g.edge(from: x, to: y) {
            g.remove(edge: e)
        }
        #expect(g.edgeCount == 0)

        g.remove(vertex: y)
        #expect(g.vertexCount == 1)
    }
}


