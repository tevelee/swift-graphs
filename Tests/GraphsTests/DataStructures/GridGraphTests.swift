#if !GRAPHS_USES_TRAITS || GRAPHS_GRID_GRAPH
import Testing
@testable import Graphs

struct GridGraphTests {
    @Test func testVerticesAndNeighbors() {
        let g = GridGraph(width: 3, height: 3, allowedDirections: .orthogonal)
        #expect(g.vertexCount == 9)

        let vs = Array(g.vertices())
        #expect(vs.count == 9)
        #expect(vs.first == .init(x: 0, y: 0))
        #expect(vs.last == .init(x: 2, y: 2))

        // Corners have degree 2; edge centers have degree 3
        #expect(g.outDegree(of: .init(x: 0, y: 0)) == 2)   // corner
        #expect(g.outDegree(of: .init(x: 1, y: 0)) == 3)   // top edge center

        // Middle (if existed) would have degree 4; check outgoing edges count from (1,1)
        let degree = Array(g.outgoingEdges(of: .init(x: 1, y: 1))).count
        #expect(degree == 4)
    }
}
#endif
