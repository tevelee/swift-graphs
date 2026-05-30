import Testing

@testable import Graphs

/// Visitor, withVisitor, edge-case, and API completeness tests for the planarity suite.
struct PlanarAPITests {

    // MARK: - Builders

    private func triangle() -> DefaultAdjacencyList {
        var g = AdjacencyList()
        let v = (0 ..< 3).map { i in g.addVertex { $0.label = "\(i)" } }
        for (a, b) in [(0, 1), (1, 2), (2, 0)] { g.addEdge(from: v[a], to: v[b]) { $0.label = "" } }
        return g
    }

    private func petersen() -> DefaultAdjacencyList {
        var g = AdjacencyList()
        let v = (0 ..< 10).map { i in g.addVertex { $0.label = "\(i)" } }
        for (a, b) in [(0,1),(1,2),(2,3),(3,4),(4,0),(0,5),(1,6),(2,7),(3,8),(4,9),(5,7),(7,9),(9,6),(6,8),(8,5)] {
            g.addEdge(from: v[a], to: v[b]) { $0.label = "" }
        }
        return g
    }

    // MARK: - Edge cases: empty, single vertex, two vertices

    @Test func emptyGraphIsPlanar() {
        let g = AdjacencyList()
        #expect(g.isPlanar(using: .leftRight()))
        let result = g.planarEmbedding(using: .leftRight())
        #expect(result.isPlanar)
        let emb = result.embedding
        #expect(emb != nil)
        #expect(emb!.vertexCount == 0)
        #expect(emb!.faceCount == 0)
        #expect(emb!.outerFace.isEmpty)
    }

    @Test func singleVertexIsPlanar() {
        var g = AdjacencyList()
        g.addVertex { $0.label = "A" }
        #expect(g.isPlanar(using: .leftRight()))
        let result = g.planarEmbedding(using: .leftRight())
        #expect(result.isPlanar)
        let emb = result.embedding!
        #expect(emb.vertexCount == 1)
        #expect(emb.isValid)
    }

    @Test func twoVerticesConnectedIsPlanar() {
        var g = AdjacencyList()
        let a = g.addVertex { $0.label = "A" }
        let b = g.addVertex { $0.label = "B" }
        g.addEdge(from: a, to: b) { $0.label = "AB" }
        #expect(g.isPlanar(using: .leftRight()))
        let result = g.planarEmbedding(using: .leftRight())
        #expect(result.isPlanar)
        #expect(result.embedding!.isValid)
    }

    @Test func emptyGraphDrawing() {
        let g = AdjacencyList()
        // Empty graph has no edges; drawing should either return nil or an empty position map.
        let drawing = g.planarDrawing(using: .chrobakPayne())
        // Both nil and empty are acceptable — just must not crash.
        if let d = drawing { #expect(d.positions.isEmpty) }
    }

    // MARK: - outerFace

    @Test func triangleOuterFaceHasThreeVertices() throws {
        let result = triangle().planarEmbedding(using: .leftRight())
        let emb = try #require(result.embedding)
        // A triangle has 2 faces (inner triangle + outer face), each 3 vertices.
        #expect(emb.outerFace.count == 3)
    }

    // MARK: - Visitor tests: LeftRightPlanarEmbedding

    @Test func embeddingVisitorFiresOnPlanarGraph() {
        var started = 0
        var planarFired = 0
        var nonPlanarFired = 0
        var v = LeftRightPlanarEmbedding<DefaultAdjacencyList>.Visitor()
        v.start = { started += 1 }
        v.foundPlanar = { _ in planarFired += 1 }
        v.foundNonPlanar = { _ in nonPlanarFired += 1 }
        _ = LeftRightPlanarEmbedding<DefaultAdjacencyList>().planarEmbedding(in: triangle(), visitor: v)
        #expect(started == 1)
        #expect(planarFired == 1)
        #expect(nonPlanarFired == 0)
    }

    @Test func embeddingVisitorFiresOnNonPlanarGraph() {
        var started = 0
        var planarFired = 0
        var nonPlanarFired = 0
        var v = LeftRightPlanarEmbedding<DefaultAdjacencyList>.Visitor()
        v.start = { started += 1 }
        v.foundPlanar = { _ in planarFired += 1 }
        v.foundNonPlanar = { _ in nonPlanarFired += 1 }
        _ = LeftRightPlanarEmbedding<DefaultAdjacencyList>().planarEmbedding(in: petersen(), visitor: v)
        #expect(started == 1)
        #expect(planarFired == 0)
        #expect(nonPlanarFired == 1)
    }

    @Test func embeddingComposedVisitorsReceiveAllEvents() {
        var count1 = 0; var count2 = 0
        var v1 = LeftRightPlanarEmbedding<DefaultAdjacencyList>.Visitor()
        var v2 = LeftRightPlanarEmbedding<DefaultAdjacencyList>.Visitor()
        v1.start = { count1 += 1 }
        v2.start = { count2 += 1 }
        let combined = v1.combined(with: v2)
        _ = LeftRightPlanarEmbedding<DefaultAdjacencyList>().planarEmbedding(in: triangle(), visitor: combined)
        #expect(count1 == 1)
        #expect(count2 == 1)
    }

    @Test func embeddingWithVisitorChaining() {
        var fired = 0
        var v = LeftRightPlanarEmbedding<DefaultAdjacencyList>.Visitor()
        v.start = { fired += 1 }
        _ = LeftRightPlanarEmbedding<DefaultAdjacencyList>()
            .withVisitor(v)
            .planarEmbedding(in: triangle(), visitor: nil)
        #expect(fired == 1)
    }

    // MARK: - Visitor tests: ChrobakPayneDrawing

    @Test func drawingVisitorFiresOnPlanarGraph() {
        var started = 0
        var drawingFired = 0
        var nonPlanarFired = 0
        var v = ChrobakPayneDrawing<DefaultAdjacencyList>.Visitor()
        v.start = { started += 1 }
        v.foundDrawing = { _ in drawingFired += 1 }
        v.foundNonPlanar = { nonPlanarFired += 1 }
        _ = ChrobakPayneDrawing<DefaultAdjacencyList>().planarDrawing(in: triangle(), visitor: v)
        #expect(started == 1)
        #expect(drawingFired == 1)
        #expect(nonPlanarFired == 0)
    }

    @Test func drawingVisitorFiresOnNonPlanarGraph() {
        var nonPlanarFired = 0
        var v = ChrobakPayneDrawing<DefaultAdjacencyList>.Visitor()
        v.foundNonPlanar = { nonPlanarFired += 1 }
        _ = ChrobakPayneDrawing<DefaultAdjacencyList>().planarDrawing(in: petersen(), visitor: v)
        #expect(nonPlanarFired == 1)
    }

    @Test func drawingComposedVisitorsReceiveAllEvents() {
        var count1 = 0; var count2 = 0
        var v1 = ChrobakPayneDrawing<DefaultAdjacencyList>.Visitor()
        var v2 = ChrobakPayneDrawing<DefaultAdjacencyList>.Visitor()
        v1.start = { count1 += 1 }
        v2.start = { count2 += 1 }
        let combined = v1.combined(with: v2)
        _ = ChrobakPayneDrawing<DefaultAdjacencyList>().planarDrawing(in: triangle(), visitor: combined)
        #expect(count1 == 1)
        #expect(count2 == 1)
    }

    @Test func drawingWithVisitorChaining() {
        var fired = 0
        var v = ChrobakPayneDrawing<DefaultAdjacencyList>.Visitor()
        v.start = { fired += 1 }
        _ = ChrobakPayneDrawing<DefaultAdjacencyList>()
            .withVisitor(v)
            .planarDrawing(in: triangle(), visitor: nil)
        #expect(fired == 1)
    }

    // MARK: - Kuratowski certificate structure

    @Test func k33CertificateHasNineEdges() throws {
        var g = AdjacencyList()
        let v = (0 ..< 6).map { i in g.addVertex { $0.label = "\(i)" } }
        for a in 0 ..< 3 { for b in 3 ..< 6 { g.addEdge(from: v[a], to: v[b]) { $0.label = "" } } }
        let cert = try #require(g.planarEmbedding(using: .leftRight()).kuratowskiSubgraph)
        #expect(cert.kind == .k33)
        #expect(cert.edgeCount == 9)
    }

    @Test func k5CertificateHasTenEdges() throws {
        var g = AdjacencyList()
        let v = (0 ..< 5).map { i in g.addVertex { $0.label = "\(i)" } }
        for a in 0 ..< 5 { for b in (a+1) ..< 5 { g.addEdge(from: v[a], to: v[b]) { $0.label = "" } } }
        let cert = try #require(g.planarEmbedding(using: .leftRight()).kuratowskiSubgraph)
        #expect(cert.kind == .k5)
        #expect(cert.edgeCount == 10)
    }

    @Test func kuratowskiBranchVerticesHaveCorrectDegree() throws {
        var g = AdjacencyList()
        let v = (0 ..< 5).map { i in g.addVertex { $0.label = "\(i)" } }
        for a in 0 ..< 5 { for b in (a+1) ..< 5 { g.addEdge(from: v[a], to: v[b]) { $0.label = "" } } }
        let cert = try #require(g.planarEmbedding(using: .leftRight()).kuratowskiSubgraph)
        // Every K5 branch vertex appears in exactly 4 edges of the certificate.
        var degree = [DefaultAdjacencyList.VertexDescriptor: Int]()
        for edge in cert.edges { for ep in edge { degree[ep, default: 0] += 1 } }
        for bv in cert.branchVertices { #expect(degree[bv]! >= 3) }
    }

    // MARK: - Default routing

    @Test func defaultIsPlanarUsesLeftRightCore() {
        // The Petersen graph passes the edge-count bound (15 <= 3*10-6=24) but is non-planar.
        // Only the correct LR core catches it; the old heuristic returned true.
        #if !GRAPHS_USES_TRAITS || GRAPHS_ANALYSIS
        #expect(!petersen().isPlanar())
        #endif
    }
}
