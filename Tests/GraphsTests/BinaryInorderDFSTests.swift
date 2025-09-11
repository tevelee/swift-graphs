import Testing
@testable import Graphs

struct BinaryInorderDFSTests {
    @Test func testInorderTraversal() {
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
        g.setLeftNeighbor(of: a, to: b)
        g.setRightNeighbor(of: a, to: c)
        g.setLeftNeighbor(of: b, to: d)
        g.setRightNeighbor(of: b, to: e)

        let result = g.traverse(from: a, using: .dfs(order: .inorder))
        #expect(result.vertices == [d, b, e, a, c])
    }
}


