import Testing

@testable import Graphs

struct ProductGraphTests {

    // MARK: - Pair

    @Test func pairEquality() {
        let p1 = Pair(1, "a")
        let p2 = Pair(1, "a")
        let p3 = Pair(2, "a")
        #expect(p1 == p2)
        #expect(p1 != p3)
    }

    @Test func pairHashable() {
        let p1 = Pair(1, 2)
        let p2 = Pair(1, 2)
        let p3 = Pair(2, 1)
        var set = Set<Pair<Int, Int>>()
        set.insert(p1)
        set.insert(p2)
        #expect(set.count == 1)
        set.insert(p3)
        #expect(set.count == 2)
    }

    @Test func pairDescription() {
        let p = Pair(3, "x")
        #expect(p.description == "(3, x)")
    }

    // MARK: - Helpers

    /// P₂: directed path 0→1 (two vertices, one edge)
    func makeP2() -> (graph: DefaultAdjacencyList, v0: DefaultAdjacencyList.VertexDescriptor, v1: DefaultAdjacencyList.VertexDescriptor) {
        var g = DefaultAdjacencyList()
        let v0 = g.addVertex()
        let v1 = g.addVertex()
        g.addEdge(from: v0, to: v1)
        return (g, v0, v1)
    }

    /// Fan graph: v0 has two outgoing edges to v1 and v2; v1, v2 have no outgoing edges.
    func makeFan() -> (
        graph: DefaultAdjacencyList, v0: DefaultAdjacencyList.VertexDescriptor, v1: DefaultAdjacencyList.VertexDescriptor,
        v2: DefaultAdjacencyList.VertexDescriptor
    ) {
        var g = DefaultAdjacencyList()
        let v0 = g.addVertex()
        let v1 = g.addVertex()
        let v2 = g.addVertex()
        g.addEdge(from: v0, to: v1)
        g.addEdge(from: v0, to: v2)
        return (g, v0, v1, v2)
    }

    // MARK: - Cartesian Product

    @Test func cartesianProductVertexCount() {
        let (g, _, _) = makeP2()
        let (h, _, _) = makeP2()
        let product = g.cartesianProduct(with: h)
        #expect(product.vertexCount == 4)
    }

    @Test func cartesianProductEdgeCount() {
        let (g, _, _) = makeP2()
        let (h, _, _) = makeP2()
        let product = g.cartesianProduct(with: h)
        // G.edgeCount(1) × H.vertexCount(2) + H.edgeCount(1) × G.vertexCount(2) = 4
        #expect(product.edgeCount == 4)
    }

    @Test func cartesianProductOutDegree() {
        let (g, gv0, _) = makeP2()
        let (h, hv0, hv1) = makeP2()
        let product = g.cartesianProduct(with: h)
        // (gv0, hv0): outgoing to (gv1, hv0) and (gv0, hv1) → degree 2
        #expect(product.outDegree(of: Pair(gv0, hv0)) == 2)
        // (gv1, hv1): no outgoing in G or H → degree 0
        let gv1 = g.vertices()[1]
        #expect(product.outDegree(of: Pair(gv1, hv1)) == 0)
        // (gv1, hv0): no G-move (gv1 has no outgoing), H-move → degree 1
        #expect(product.outDegree(of: Pair(gv1, hv0)) == 1)
    }

    @Test func cartesianProductOutgoingEdges() {
        let (g, gv0, gv1) = makeP2()
        let (h, hv0, hv1) = makeP2()
        let product = g.cartesianProduct(with: h)
        let dests = Set(product.outgoingEdges(of: Pair(gv0, hv0)).compactMap { product.destination(of: $0) })
        #expect(dests == [Pair(gv1, hv0), Pair(gv0, hv1)])
    }

    @Test func cartesianProductVertices() {
        let (g, gv0, gv1) = makeP2()
        let (h, hv0, hv1) = makeP2()
        let product = g.cartesianProduct(with: h)
        let verts = Set(product.vertices())
        #expect(verts == [Pair(gv0, hv0), Pair(gv0, hv1), Pair(gv1, hv0), Pair(gv1, hv1)])
    }

    @Test func cartesianProductEdgeList() {
        let (g, gv0, gv1) = makeP2()
        let (h, hv0, hv1) = makeP2()
        let product = g.cartesianProduct(with: h)
        // Represent each edge as a Pair of Pairs so it is Hashable
        let edges = Set(product.edges().map { Pair($0.source, $0.destination) })
        let expected:
            Set<
                Pair<
                    Pair<DefaultAdjacencyList.VertexDescriptor, DefaultAdjacencyList.VertexDescriptor>,
                    Pair<DefaultAdjacencyList.VertexDescriptor, DefaultAdjacencyList.VertexDescriptor>
                >
            > = [
                Pair(Pair(gv0, hv0), Pair(gv1, hv0)),
                Pair(Pair(gv0, hv0), Pair(gv0, hv1)),
                Pair(Pair(gv0, hv1), Pair(gv1, hv1)),
                Pair(Pair(gv1, hv0), Pair(gv1, hv1)),
            ]
        #expect(edges == expected)
    }

    @Test func cartesianProductBidirectional() {
        let (g, gv0, gv1) = makeP2()
        let (h, hv0, hv1) = makeP2()
        let product = g.cartesianProduct(with: h)
        // (gv1, hv1) has incoming from (gv0, hv1) and (gv1, hv0)
        let srcs = Set(product.incomingEdges(of: Pair(gv1, hv1)).compactMap { product.source(of: $0) })
        #expect(srcs == [Pair(gv0, hv1), Pair(gv1, hv0)])
        #expect(product.inDegree(of: Pair(gv1, hv1)) == 2)
    }

    @Test func cartesianProductEmptyRightFactor() {
        let (g, _, _) = makeP2()
        let emptyGraph = AdjacencyList()
        let product = g.cartesianProduct(with: emptyGraph)
        #expect(product.vertexCount == 0)
        #expect(Array(product.vertices()).isEmpty)
        #expect(product.edgeCount == 0)
    }

    // MARK: - Tensor Product

    @Test func tensorProductVertexCount() {
        let (g, _, _) = makeP2()
        let (h, _, _) = makeP2()
        #expect(g.tensorProduct(with: h).vertexCount == 4)
    }

    @Test func tensorProductEdgeCount() {
        let (g, _, _) = makeP2()
        let (h, _, _) = makeP2()
        // G.edgeCount(1) × H.edgeCount(1) = 1
        #expect(g.tensorProduct(with: h).edgeCount == 1)
    }

    @Test func tensorProductOutgoingEdges() {
        let (g, gv0, gv1) = makeP2()
        let (h, hv0, hv1) = makeP2()
        let product = g.tensorProduct(with: h)
        // (gv0, hv0): both can move → destination (gv1, hv1)
        let dests00 = Set(product.outgoingEdges(of: Pair(gv0, hv0)).compactMap { product.destination(of: $0) })
        #expect(dests00 == [Pair(gv1, hv1)])
        // (gv0, hv1): hv1 has no outgoing → no tensor edges
        let dests01 = Array(product.outgoingEdges(of: Pair(gv0, hv1)))
        #expect(dests01.isEmpty)
        // (gv1, hv0): gv1 has no outgoing → no tensor edges
        let dests10 = Array(product.outgoingEdges(of: Pair(gv1, hv0)))
        #expect(dests10.isEmpty)
    }

    @Test func tensorProductBidirectional() {
        let (g, gv0, gv1) = makeP2()
        let (h, hv0, hv1) = makeP2()
        let product = g.tensorProduct(with: h)
        let srcs = Set(product.incomingEdges(of: Pair(gv1, hv1)).compactMap { product.source(of: $0) })
        #expect(srcs == [Pair(gv0, hv0)])
    }

    @Test func tensorProductOutDegree() {
        let (g, gv0, gv1) = makeP2()
        let (h, hv0, hv1) = makeP2()
        let product = g.tensorProduct(with: h)
        // outDegree = G.outDegree × H.outDegree
        #expect(product.outDegree(of: Pair(gv0, hv0)) == 1)  // 1×1
        #expect(product.outDegree(of: Pair(gv0, hv1)) == 0)  // 1×0
        #expect(product.outDegree(of: Pair(gv1, hv0)) == 0)  // 0×1
        #expect(product.outDegree(of: Pair(gv1, hv1)) == 0)  // 0×0
    }

    @Test func tensorProductInDegree() {
        let (g, gv0, gv1) = makeP2()
        let (h, hv0, hv1) = makeP2()
        let product = g.tensorProduct(with: h)
        // inDegree = G.inDegree × H.inDegree
        #expect(product.inDegree(of: Pair(gv1, hv1)) == 1)  // 1×1
        #expect(product.inDegree(of: Pair(gv0, hv0)) == 0)  // 0×0
        #expect(product.inDegree(of: Pair(gv0, hv1)) == 0)  // 0×1
        #expect(product.inDegree(of: Pair(gv1, hv0)) == 0)  // 1×0
    }

    @Test func tensorProductEdgeList() {
        let (g, gv0, gv1) = makeP2()
        let (h, hv0, hv1) = makeP2()
        let product = g.tensorProduct(with: h)
        let edges = product.edges().map { Pair($0.source, $0.destination) }
        // Only one edge: (gv0,hv0) → (gv1,hv1)
        #expect(edges == [Pair(Pair(gv0, hv0), Pair(gv1, hv1))])
    }

    @Test func tensorProductEmptyFactor() {
        let (g, _, _) = makeP2()
        let emptyGraph = AdjacencyList()
        let product = g.tensorProduct(with: emptyGraph)
        #expect(product.vertexCount == 0)
        #expect(Array(product.vertices()).isEmpty)
        #expect(product.edgeCount == 0)
    }

    // MARK: - Strong Product

    @Test func strongProductVertexCount() {
        let (g, _, _) = makeP2()
        let (h, _, _) = makeP2()
        #expect(g.strongProduct(with: h).vertexCount == 4)
    }

    @Test func strongProductEdgeCount() {
        let (g, _, _) = makeP2()
        let (h, _, _) = makeP2()
        // 1×2 + 1×2 + 1×1 = 5
        #expect(g.strongProduct(with: h).edgeCount == 5)
    }

    @Test func strongProductOutgoingEdgesFromOrigin() {
        let (g, gv0, gv1) = makeP2()
        let (h, hv0, hv1) = makeP2()
        let product = g.strongProduct(with: h)
        // (gv0, hv0) should reach (gv1,hv0), (gv0,hv1), (gv1,hv1)
        let dests = Set(product.outgoingEdges(of: Pair(gv0, hv0)).compactMap { product.destination(of: $0) })
        #expect(dests == [Pair(gv1, hv0), Pair(gv0, hv1), Pair(gv1, hv1)])
    }

    @Test func strongProductOutDegree() {
        let (g, gv0, gv1) = makeP2()
        let (h, hv0, hv1) = makeP2()
        let product = g.strongProduct(with: h)
        #expect(product.outDegree(of: Pair(gv0, hv0)) == 3)  // 1+1+1
        #expect(product.outDegree(of: Pair(gv1, hv1)) == 0)  // 0+0+0
        #expect(product.outDegree(of: Pair(gv0, hv1)) == 1)  // 1+0+0 (only Cartesian-G)
        #expect(product.outDegree(of: Pair(gv1, hv0)) == 1)  // 0+1+0 (only Cartesian-H)
    }

    @Test func strongProductVertices() {
        let (g, gv0, gv1) = makeP2()
        let (h, hv0, hv1) = makeP2()
        let product = g.strongProduct(with: h)
        let verts = Set(product.vertices())
        #expect(verts == [Pair(gv0, hv0), Pair(gv0, hv1), Pair(gv1, hv0), Pair(gv1, hv1)])
    }

    @Test func strongProductEdgeList() {
        let (g, gv0, gv1) = makeP2()
        let (h, hv0, hv1) = makeP2()
        let product = g.strongProduct(with: h)
        let edges = Set(product.edges().map { Pair($0.source, $0.destination) })
        let expected:
            Set<
                Pair<
                    Pair<DefaultAdjacencyList.VertexDescriptor, DefaultAdjacencyList.VertexDescriptor>,
                    Pair<DefaultAdjacencyList.VertexDescriptor, DefaultAdjacencyList.VertexDescriptor>
                >
            > = [
                Pair(Pair(gv0, hv0), Pair(gv1, hv0)),  // Cartesian-G
                Pair(Pair(gv0, hv0), Pair(gv0, hv1)),  // Cartesian-H
                Pair(Pair(gv0, hv0), Pair(gv1, hv1)),  // Tensor
                Pair(Pair(gv0, hv1), Pair(gv1, hv1)),  // Cartesian-G
                Pair(Pair(gv1, hv0), Pair(gv1, hv1)),  // Cartesian-H
            ]
        #expect(edges == expected)
    }

    @Test func strongProductEmptyFactor() {
        let (g, _, _) = makeP2()
        let emptyGraph = AdjacencyList()
        let product = g.strongProduct(with: emptyGraph)
        #expect(product.vertexCount == 0)
        #expect(Array(product.vertices()).isEmpty)
        #expect(product.edgeCount == 0)
    }

    @Test func strongProductBidirectional() {
        let (g, gv0, gv1) = makeP2()
        let (h, hv0, hv1) = makeP2()
        let product = g.strongProduct(with: h)
        // (gv1, hv1) has incoming from: (gv0,hv1) [Cartesian-G], (gv1,hv0) [Cartesian-H], (gv0,hv0) [Tensor]
        let srcs = Set(product.incomingEdges(of: Pair(gv1, hv1)).compactMap { product.source(of: $0) })
        #expect(srcs == [Pair(gv0, hv1), Pair(gv1, hv0), Pair(gv0, hv0)])
        #expect(product.inDegree(of: Pair(gv1, hv1)) == 3)  // 1+1+1×1
        #expect(product.inDegree(of: Pair(gv0, hv0)) == 0)  // 0+0+0×0
    }

    // MARK: - Lexicographic Product

    @Test func lexicographicProductVertexCount() {
        let (g, _, _) = makeP2()
        let (h, _, _) = makeP2()
        #expect(g.lexicographicProduct(with: h).vertexCount == 4)
    }

    @Test func lexicographicProductEdgeCount() {
        let (g, _, _) = makeP2()
        let (h, _, _) = makeP2()
        // G.edgeCount(1) × H.vertexCount²(4) + G.vertexCount(2) × H.edgeCount(1) = 6
        #expect(g.lexicographicProduct(with: h).edgeCount == 6)
    }

    @Test func lexicographicProductOutgoingEdgesGMove() {
        let (g, gv0, gv1) = makeP2()
        let (h, hv0, hv1) = makeP2()
        let product = g.lexicographicProduct(with: h)
        // (gv0, hv0): G moves (gv0→gv1 fans to all H-vertices) + H moves (h0→h1)
        let dests = Set(product.outgoingEdges(of: Pair(gv0, hv0)).compactMap { product.destination(of: $0) })
        #expect(dests == [Pair(gv1, hv0), Pair(gv1, hv1), Pair(gv0, hv1)])
    }

    @Test func lexicographicProductOutgoingEdgesNoGMove() {
        let (g, _, gv1) = makeP2()
        let (h, hv0, hv1) = makeP2()
        let product = g.lexicographicProduct(with: h)
        // (gv1, hv0): gv1 has no outgoing in G, so only H-edge: (gv1,hv0)→(gv1,hv1)
        let dests = Set(product.outgoingEdges(of: Pair(gv1, hv0)).compactMap { product.destination(of: $0) })
        #expect(dests == [Pair(gv1, hv1)])
    }

    @Test func lexicographicProductOutDegree() {
        let (g, gv0, gv1) = makeP2()
        let (h, hv0, hv1) = makeP2()
        let product = g.lexicographicProduct(with: h)
        // outDegree = G.outDegree × H.vertexCount + H.outDegree
        #expect(product.outDegree(of: Pair(gv0, hv0)) == 1 * 2 + 1)  // 3
        #expect(product.outDegree(of: Pair(gv0, hv1)) == 1 * 2 + 0)  // 2
        #expect(product.outDegree(of: Pair(gv1, hv0)) == 0 * 2 + 1)  // 1
        #expect(product.outDegree(of: Pair(gv1, hv1)) == 0 * 2 + 0)  // 0
    }

    @Test func lexicographicProductEdgeList() {
        let (g, gv0, gv1) = makeP2()
        let (h, hv0, hv1) = makeP2()
        let product = g.lexicographicProduct(with: h)
        let edges = Set(product.edges().map { Pair($0.source, $0.destination) })
        let expected:
            Set<
                Pair<
                    Pair<DefaultAdjacencyList.VertexDescriptor, DefaultAdjacencyList.VertexDescriptor>,
                    Pair<DefaultAdjacencyList.VertexDescriptor, DefaultAdjacencyList.VertexDescriptor>
                >
            > = [
                Pair(Pair(gv0, hv0), Pair(gv1, hv0)),
                Pair(Pair(gv0, hv0), Pair(gv1, hv1)),
                Pair(Pair(gv0, hv0), Pair(gv0, hv1)),
                Pair(Pair(gv0, hv1), Pair(gv1, hv0)),
                Pair(Pair(gv0, hv1), Pair(gv1, hv1)),
                Pair(Pair(gv1, hv0), Pair(gv1, hv1)),
            ]
        #expect(edges == expected)
    }

    @Test func lexicographicProductBidirectional() {
        let (g, gv0, gv1) = makeP2()
        let (h, hv0, hv1) = makeP2()
        let product = g.lexicographicProduct(with: h)
        // Incoming to (gv1, hv1):
        //   Phase 1 (G-incoming gv0→gv1, all H-vertices): (gv0,hv0)→(gv1,hv1) and (gv0,hv1)→(gv1,hv1)
        //   Phase 2 (H-incoming hv0→hv1, G stays gv1): (gv1,hv0)→(gv1,hv1)
        let srcs = Set(product.incomingEdges(of: Pair(gv1, hv1)).compactMap { product.source(of: $0) })
        #expect(srcs == [Pair(gv0, hv0), Pair(gv0, hv1), Pair(gv1, hv0)])
        #expect(product.inDegree(of: Pair(gv1, hv1)) == 3)  // 1×2 + 1
        #expect(product.inDegree(of: Pair(gv0, hv0)) == 0)  // 0×2 + 0
    }

    @Test func lexicographicProductEmptyFactor() {
        let (g, _, _) = makeP2()
        let emptyGraph = AdjacencyList()
        let product = g.lexicographicProduct(with: emptyGraph)
        #expect(product.vertexCount == 0)
        #expect(Array(product.vertices()).isEmpty)
        #expect(product.edgeCount == 0)
    }

    // MARK: - Multi-edge regression tests

    /// Verifies that all G-move edges are yielded when a vertex has more than one outgoing G-edge.
    /// Regression for premature G-phase exit that could drop edges after the first.
    @Test func cartesianProductAllGMovesEmittedWhenMultipleOutgoing() {
        let (g, gv0, gv1, gv2) = makeFan()
        let (h, hv0, _) = makeP2()
        let product = g.cartesianProduct(with: h)
        // (gv0, hv0) has G-moves to (gv1,hv0) and (gv2,hv0), plus H-move to (gv0,hv1)
        let dests = Set(product.outgoingEdges(of: Pair(gv0, hv0)).compactMap { product.destination(of: $0) })
        #expect(dests.count == 3)
        #expect(dests.contains(Pair(gv1, hv0)))
        #expect(dests.contains(Pair(gv2, hv0)))
    }

    @Test func cartesianProductAllIncomingEmittedWhenMultipleSources() {
        let (g, gv0, gv1, gv2) = makeFan()
        let (h, _, hv1) = makeP2()
        let product = g.cartesianProduct(with: h)
        // (gv1, hv1) has G-incoming from (gv0,hv1); (gv2, hv1) has G-incoming from (gv0,hv1)
        // Let's check that both (gv1,hv0) and (gv2,hv0) have in-degree 1 from G-moves
        let srcs1 = Set(product.incomingEdges(of: Pair(gv1, hv1)).compactMap { product.source(of: $0) })
        #expect(srcs1.contains(Pair(gv0, hv1)))
        let srcs2 = Set(product.incomingEdges(of: Pair(gv2, hv1)).compactMap { product.source(of: $0) })
        #expect(srcs2.contains(Pair(gv0, hv1)))
    }

    /// Verifies all three phases (Cartesian-G, Cartesian-H, Tensor) emit all expected edges
    /// when the G-factor has multiple outgoing edges. Regression for premature phase advancement.
    @Test func strongProductAllPhasesEmittedWhenMultipleOutgoing() {
        let (g, gv0, gv1, gv2) = makeFan()
        let (h, hv0, hv1) = makeP2()
        let product = g.strongProduct(with: h)
        // From (gv0, hv0):
        //   Cartesian-G: (gv0,hv0)→(gv1,hv0) and (gv0,hv0)→(gv2,hv0)
        //   Cartesian-H: (gv0,hv0)→(gv0,hv1)
        //   Tensor:      (gv0,hv0)→(gv1,hv1) and (gv0,hv0)→(gv2,hv1)
        let dests = Set(product.outgoingEdges(of: Pair(gv0, hv0)).compactMap { product.destination(of: $0) })
        #expect(dests.count == 5)
        #expect(dests.contains(Pair(gv1, hv0)))  // Cartesian-G
        #expect(dests.contains(Pair(gv2, hv0)))  // Cartesian-G (second edge — was dropped before fix)
        #expect(dests.contains(Pair(gv0, hv1)))  // Cartesian-H
        #expect(dests.contains(Pair(gv1, hv1)))  // Tensor
        #expect(dests.contains(Pair(gv2, hv1)))  // Tensor
        #expect(product.outDegree(of: Pair(gv0, hv0)) == 5)
    }

    @Test func strongProductEdgeCountWithFanGraph() {
        let (g, _, _, _) = makeFan()
        let (h, _, _) = makeP2()
        let product = g.strongProduct(with: h)
        // g: 3 vertices, 2 edges; h: 2 vertices, 1 edge
        // Cartesian: 2×2 + 1×3 = 7; Tensor: 2×1 = 2; total = 9
        #expect(product.edgeCount == 9)
        let iteratedEdgeCount = product.edges().reduce(0) { count, _ in count + 1 }
        #expect(iteratedEdgeCount == product.edgeCount)
    }

    // MARK: - Integration

    #if !GRAPHS_USES_TRAITS || GRAPHS_PATHFINDING
        @Test func shortestPathOnCartesianProductGrid() {
            // Build a directed 4-vertex path: 0→1→2→3
            var p4 = AdjacencyList()
            let row = (0 ..< 4).map { _ in p4.addVertex() }
            for i in 0 ..< 3 { p4.addEdge(from: row[i], to: row[i + 1]) }

            // P₄ □ P₄ = directed 4×4 grid (moves right or down only)
            let grid = p4.cartesianProduct(with: p4)
            let src = Pair(row[0], row[0])  // top-left corner
            let dst = Pair(row[3], row[3])  // bottom-right corner

            // Dijkstra with uniform cost — all edges weight 1
            let result = grid.shortestPath(from: src, to: dst, using: .dijkstra(weight: .uniform(1.0)))
            // Manhattan distance from (0,0) to (3,3) on a directed grid = 6 hops
            #expect(result?.edges.count == 6)
            #expect(result?.vertices.first == src)
            #expect(result?.vertices.last == dst)
        }
    #endif

    #if !GRAPHS_USES_TRAITS || GRAPHS_COMPLETE_GRAPH
        @Test func hypercubeVertexAndEdgeCount() {
            // 3-dimensional hypercube Q₃ = K₂ □ K₂ □ K₂
            // K₂ = CompleteGraph(count: 2): 2 vertices, 2 directed edges (0→1 and 1→0)
            let k2 = CompleteGraph(count: 2)
            // Each Cartesian step: vertexCount doubles, edgeCount = prev×2 + 2×prev
            let q2 = k2.cartesianProduct(with: k2)  // 4 vertices, 8 edges
            let q3 = q2.cartesianProduct(with: k2)  // 8 vertices, 24 edges

            #expect(q3.vertexCount == 8)
            // Each of 8 vertices has out-degree 3 (one per dimension, bidirectional)
            // Total directed edges = 8 × 3 = 24
            #expect(q3.edgeCount == 24)
        }
    #endif
}
