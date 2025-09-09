import XCTest
@testable import Graphs

final class BinaryInorderDFSTests: XCTestCase {
    func testInorderTraversal() {
        var g = AdjacencyList(edgeStore: BinaryEdgeStore())

        let a = g.addVertex()
        let b = g.addVertex()
        let c = g.addVertex()
        let d = g.addVertex()
        let e = g.addVertex()

        //       a
        //     /   \
        //    b     c
        //   / \
        //  d   e
        g.setLeftChild(of: a, to: b)
        g.setRightChild(of: a, to: c)
        g.setLeftChild(of: b, to: d)
        g.setRightChild(of: b, to: e)

        let result = g.traverse(from: a, using: .dfs(order: .inorder))
        XCTAssertEqual(result.vertices, [d, b, e, a, c])
    }
}


