import XCTest
@testable import Graphs

final class GridGraphTests: XCTestCase {
    func testVerticesAndNeighbors() {
        let g = GridGraph(width: 3, height: 3, allowedDirections: .orthogonal)
        XCTAssertEqual(g.vertexCount, 9)

        let vs = Array(g.vertices())
        XCTAssertEqual(vs.count, 9)
        XCTAssertEqual(vs.first, .init(x: 0, y: 0))
        XCTAssertEqual(vs.last, .init(x: 2, y: 2))

        // Corners have degree 2; edge centers have degree 3
        XCTAssertEqual(g.outDegree(of: .init(x: 0, y: 0)), 2)   // corner
        XCTAssertEqual(g.outDegree(of: .init(x: 1, y: 0)), 3)   // top edge center

        // Middle (if existed) would have degree 4; check outgoing edges count from (1,1)
        let deg = Array(g.outgoingEdges(of: .init(x: 1, y: 1))).count
        XCTAssertEqual(deg, 4)
    }
}


