import Testing

@testable import Graphs

/// Orientation of the ordered triple (a, b, c): +1 ccw, -1 cw, 0 collinear.
private func orientation(_ a: PlanarPoint, _ b: PlanarPoint, _ c: PlanarPoint) -> Int {
    let value = (b.x - a.x) * (c.y - a.y) - (b.y - a.y) * (c.x - a.x)
    if value > 0 { return 1 }
    if value < 0 { return -1 }
    return 0
}

/// Whether the open segments `p1p2` and `p3p4` properly cross (a shared endpoint or
/// collinear touching does not count, so edges meeting at a common vertex are allowed).
private func segmentsProperlyCross(_ p1: PlanarPoint, _ p2: PlanarPoint, _ p3: PlanarPoint, _ p4: PlanarPoint) -> Bool {
    let d1 = orientation(p3, p4, p1)
    let d2 = orientation(p3, p4, p2)
    let d3 = orientation(p1, p2, p3)
    let d4 = orientation(p1, p2, p4)
    let opposite12 = (d1 > 0 && d2 < 0) || (d1 < 0 && d2 > 0)
    let opposite34 = (d3 > 0 && d4 < 0) || (d3 < 0 && d4 > 0)
    return opposite12 && opposite34
}

/// Tests for straight-line planar grid drawing (Chrobak-Payne).
///
/// The defining property of a straight-line planar drawing is that, when every edge is drawn
/// as a segment between its endpoints' coordinates, no two edges cross. These tests verify
/// that property directly (plus integer/distinct coordinates and the grid-size bound), which
/// is a strong end-to-end check on the whole embed -> triangulate -> order -> shift pipeline.
struct PlanarDrawingTests {

    // MARK: - Builders

    private func build(_ vertexCount: Int, _ edges: [(Int, Int)]) -> DefaultAdjacencyList {
        var graph = AdjacencyList()
        let v = (0 ..< vertexCount).map { i in graph.addVertex { $0.label = "\(i)" } }
        for (a, b) in edges {
            graph.addEdge(from: v[a], to: v[b]) { $0.label = "\(a)-\(b)" }
        }
        return graph
    }

    private func triangle() -> DefaultAdjacencyList { build(3, [(0, 1), (1, 2), (2, 0)]) }

    private func octahedron() -> DefaultAdjacencyList {
        let antipode = [1, 0, 3, 2, 5, 4]
        var edges: [(Int, Int)] = []
        for a in 0 ..< 6 {
            for b in (a + 1) ..< 6 where antipode[a] != b { edges.append((a, b)) }
        }
        return build(6, edges)
    }

    private func grid4x4() -> DefaultAdjacencyList {
        var edges: [(Int, Int)] = []
        func idx(_ r: Int, _ c: Int) -> Int { r * 4 + c }
        for r in 0 ..< 4 {
            for c in 0 ..< 4 {
                if c + 1 < 4 { edges.append((idx(r, c), idx(r, c + 1))) }
                if r + 1 < 4 { edges.append((idx(r, c), idx(r + 1, c))) }
            }
        }
        return build(16, edges)
    }

    private func k4() -> DefaultAdjacencyList {
        build(4, [(0, 1), (0, 2), (0, 3), (1, 2), (1, 3), (2, 3)])
    }

    private func petersen() -> DefaultAdjacencyList {
        let edges =
            [(0, 1), (1, 2), (2, 3), (3, 4), (4, 0)]
            + [(0, 5), (1, 6), (2, 7), (3, 8), (4, 9)]
            + [(5, 7), (7, 9), (9, 6), (6, 8), (8, 5)]
        return build(10, edges)
    }

    // MARK: - Validity helper

    private func countCrossings(_ graph: DefaultAdjacencyList, _ drawing: PlanarDrawing<DefaultAdjacencyList.VertexDescriptor>) -> Int {
        let vertices = Array(graph.vertices())
        var edges: [(Int, Int)] = []
        var index: [DefaultAdjacencyList.VertexDescriptor: Int] = [:]
        for (i, vertex) in vertices.enumerated() { index[vertex] = i }

        var seen = Set<Int>()
        let n = vertices.count
        for vertex in vertices {
            for edge in graph.outgoingEdges(of: vertex) {
                guard let other = graph.destination(of: edge) else { continue }
                let i = index[vertex]!
                let j = index[other]!
                let key = i < j ? i * n + j : j * n + i
                if seen.insert(key).inserted { edges.append((i, j)) }
            }
        }

        let points = vertices.map { drawing.position(of: $0)! }
        var crossings = 0
        for a in 0 ..< edges.count {
            for b in (a + 1) ..< edges.count {
                let e1 = edges[a]
                let e2 = edges[b]
                if e1.0 == e2.0 || e1.0 == e2.1 || e1.1 == e2.0 || e1.1 == e2.1 { continue }
                if segmentsProperlyCross(points[e1.0], points[e1.1], points[e2.0], points[e2.1]) {
                    crossings += 1
                }
            }
        }
        return crossings
    }

    private func distinctPointCount(_ graph: DefaultAdjacencyList, _ drawing: PlanarDrawing<DefaultAdjacencyList.VertexDescriptor>) -> (distinct: Int, total: Int) {
        let points = graph.vertices().map { drawing.position(of: $0)! }
        return (Set(points).count, points.count)
    }

    // MARK: - Tests

    @Test func triangleDrawingHasNoCrossings() throws {
        let graph = triangle()
        let drawing = try #require(graph.planarDrawing(using: .chrobakPayne()))
        #expect(countCrossings(graph, drawing) == 0)
    }

    @Test func k4DrawingHasNoCrossings() throws {
        let graph = k4()
        let drawing = try #require(graph.planarDrawing(using: .chrobakPayne()))
        let counts = distinctPointCount(graph, drawing)
        #expect(counts.distinct == counts.total)
        #expect(countCrossings(graph, drawing) == 0)
    }

    @Test func octahedronDrawingHasNoCrossings() throws {
        let graph = octahedron()
        let drawing = try #require(graph.planarDrawing(using: .chrobakPayne()))
        let counts = distinctPointCount(graph, drawing)
        #expect(counts.distinct == counts.total)
        #expect(countCrossings(graph, drawing) == 0)
    }

    @Test func gridDrawingHasNoCrossings() throws {
        let graph = grid4x4()
        let drawing = try #require(graph.planarDrawing(using: .chrobakPayne()))
        let counts = distinctPointCount(graph, drawing)
        #expect(counts.distinct == counts.total)
        #expect(countCrossings(graph, drawing) == 0)
    }

    @Test func drawingFitsWithinChrobakPayneGridBound() throws {
        let graph = octahedron()
        let n = graph.vertexCount
        let drawing = try #require(graph.planarDrawing(using: .chrobakPayne()))
        // Fraysseix-Pach-Pollack / Chrobak-Payne bound: (2n - 4) x (n - 2).
        #expect(drawing.width <= 2 * n - 4)
        #expect(drawing.height <= n - 2)
    }

    @Test func nonPlanarGraphHasNoDrawing() {
        #expect(petersen().planarDrawing(using: .chrobakPayne()) == nil)
    }
}
