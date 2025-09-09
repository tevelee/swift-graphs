import XCTest
@testable import Graphs

final class BinaryAdjacencyListTests: XCTestCase {
    func testSetChildrenAndNeighbors() {
        var g = AdjacencyList(edgeStorage: BinaryEdgeStorage())

        let a = g.addVertex()
        let b = g.addVertex()
        let c = g.addVertex()
        let d = g.addVertex()
        let e = g.addVertex()

        _ = g.setLeftChild(of: a, to: b)
        _ = g.setRightChild(of: a, to: c)
        _ = g.setLeftChild(of: b, to: d)
        _ = g.setRightChild(of: b, to: e)

        XCTAssertEqual(g.leftNeighbor(of: a), b)
        XCTAssertEqual(g.rightNeighbor(of: a), c)
        XCTAssertEqual(g.leftNeighbor(of: b), d)
        XCTAssertEqual(g.rightNeighbor(of: b), e)

        XCTAssertEqual(g.outDegree(of: a), 2)
        XCTAssertEqual(g.inDegree(of: a), 0)
        XCTAssertEqual(g.outDegree(of: b), 2)
        XCTAssertEqual(g.inDegree(of: b), 1)
        XCTAssertEqual(g.outDegree(of: c), 0)
        XCTAssertEqual(g.inDegree(of: c), 1)
    }

    func testReplacingLeftChild() {
        var g = AdjacencyList(edgeStorage: BinaryEdgeStorage())

        let a = g.addVertex()
        let b = g.addVertex()
        let x = g.addVertex()

        _ = g.setLeftChild(of: a, to: b)
        XCTAssertEqual(g.leftNeighbor(of: a), b)

        _ = g.setLeftChild(of: a, to: x)
        XCTAssertEqual(g.leftNeighbor(of: a), x)
        XCTAssertEqual(g.outDegree(of: a), 1)
    }
}


