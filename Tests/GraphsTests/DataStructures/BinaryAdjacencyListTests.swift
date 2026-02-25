#if !GRAPHS_USES_TRAITS || GRAPHS_SPECIALIZED_STORAGE
import Testing
@testable import Graphs

struct BinaryAdjacencyListTests {
    @Test func testSetChildrenAndNeighbors() {
        var g = AdjacencyList(edgeStore: BinaryEdgeStore())

        let a = g.addVertex()
        let b = g.addVertex()
        let c = g.addVertex()
        let d = g.addVertex()
        let e = g.addVertex()

        g.setLeftNeighbor(of: a, to: b)
        g.setRightNeighbor(of: a, to: c)
        g.setLeftNeighbor(of: b, to: d)
        g.setRightNeighbor(of: b, to: e)

        #expect(g.leftNeighbor(of: a) == b)
        #expect(g.rightNeighbor(of: a) == c)
        #expect(g.leftNeighbor(of: b) == d)
        #expect(g.rightNeighbor(of: b) == e)

        #expect(g.outDegree(of: a) == 2)
        #expect(g.inDegree(of: a) == 0)
        #expect(g.outDegree(of: b) == 2)
        #expect(g.inDegree(of: b) == 1)
        #expect(g.outDegree(of: c) == 0)
        #expect(g.inDegree(of: c) == 1)
    }

    @Test func testReplacingLeftChild() {
        var g = AdjacencyList(edgeStore: BinaryEdgeStore())

        let a = g.addVertex()
        let b = g.addVertex()
        let x = g.addVertex()

        g.setLeftNeighbor(of: a, to: b)
        #expect(g.leftNeighbor(of: a) == b)

        g.setLeftNeighbor(of: a, to: x)
        #expect(g.leftNeighbor(of: a) == x)
        #expect(g.outDegree(of: a) == 1)
    }
}
#endif
