import Testing

@testable import Graphs

/// Correctness corpus for planarity testing.
///
/// These graphs are specifically chosen because the *heuristic* planarity testers
/// (edge-count bound + exact-K5/K3,3 structural checks) get them wrong:
/// they pass the `edges <= 3V - 6` necessary condition and are larger than the
/// hard-coded 5/6-vertex pattern checks, yet are non-planar (or are planar graphs
/// with enough edges to look suspicious). A correct linear-time test must classify
/// all of them precisely.
struct PlanarCorrectnessTests {

    // MARK: - Builders

    /// The Petersen graph: 10 vertices, 15 edges, 3-regular, non-planar.
    private func petersen() -> some AdjacencyListProtocol {
        var graph = AdjacencyList()
        let v = (0 ..< 10).map { i in graph.addVertex { $0.label = "\(i)" } }
        let outer = [(0, 1), (1, 2), (2, 3), (3, 4), (4, 0)]
        let spokes = [(0, 5), (1, 6), (2, 7), (3, 8), (4, 9)]
        let inner = [(5, 7), (7, 9), (9, 6), (6, 8), (8, 5)]
        for (a, b) in outer + spokes + inner {
            graph.addEdge(from: v[a], to: v[b]) { $0.label = "\(a)-\(b)" }
        }
        return graph
    }

    /// K5 with one edge subdivided: 6 vertices, 11 edges, non-planar (K5 subdivision).
    /// Passes the `11 <= 3*6-6 = 12` bound and is not exactly 5 vertices.
    private func subdividedK5() -> some AdjacencyListProtocol {
        var graph = AdjacencyList()
        // vertices 0..4 = K5 branch vertices, 5 = subdivision point on edge 0-1
        let v = (0 ..< 6).map { i in graph.addVertex { $0.label = "\(i)" } }
        var edges: [(Int, Int)] = []
        for a in 0 ..< 5 {
            for b in (a + 1) ..< 5 where !(a == 0 && b == 1) {
                edges.append((a, b))
            }
        }
        edges.append((0, 5))  // 0 - x
        edges.append((5, 1))  // x - 1
        for (a, b) in edges {
            graph.addEdge(from: v[a], to: v[b]) { $0.label = "\(a)-\(b)" }
        }
        return graph
    }

    /// K3,3 plus a pendant vertex attached to one node: 7 vertices, 10 edges, non-planar.
    private func k33WithPendant() -> some AdjacencyListProtocol {
        var graph = AdjacencyList()
        let v = (0 ..< 7).map { i in graph.addVertex { $0.label = "\(i)" } }
        // partitions {0,1,2} and {3,4,5}
        for a in 0 ..< 3 {
            for b in 3 ..< 6 {
                graph.addEdge(from: v[a], to: v[b]) { $0.label = "\(a)-\(b)" }
            }
        }
        graph.addEdge(from: v[0], to: v[6]) { $0.label = "pendant" }  // pendant
        return graph
    }

    /// The octahedron: 6 vertices, 12 edges (= 3V-6, maximal planar), planar.
    private func octahedron() -> some AdjacencyListProtocol {
        var graph = AdjacencyList()
        let v = (0 ..< 6).map { i in graph.addVertex { $0.label = "\(i)" } }
        // octahedron = K_{2,2,2}: each vertex adjacent to all but its "antipode"
        // antipodes: (0,1), (2,3), (4,5)
        let antipode = [1, 0, 3, 2, 5, 4]
        for a in 0 ..< 6 {
            for b in (a + 1) ..< 6 where antipode[a] != b {
                graph.addEdge(from: v[a], to: v[b]) { $0.label = "\(a)-\(b)" }
            }
        }
        return graph
    }

    /// A 4x4 grid graph (16 vertices, 24 edges), planar.
    private func grid4x4() -> some AdjacencyListProtocol {
        var graph = AdjacencyList()
        let v = (0 ..< 16).map { i in graph.addVertex { $0.label = "\(i)" } }
        func idx(_ r: Int, _ c: Int) -> Int { r * 4 + c }
        for r in 0 ..< 4 {
            for c in 0 ..< 4 {
                if c + 1 < 4 { graph.addEdge(from: v[idx(r, c)], to: v[idx(r, c + 1)]) { $0.label = "h" } }
                if r + 1 < 4 { graph.addEdge(from: v[idx(r, c)], to: v[idx(r + 1, c)]) { $0.label = "v" } }
            }
        }
        return graph
    }

    // MARK: - Non-planar cases (heuristics get these wrong)

    @Test func petersenIsNonPlanar() {
        #expect(!petersen().isPlanar(using: .leftRight()))
        #expect(!petersen().isPlanar(using: .leftRight()))
    }

    @Test func subdividedK5IsNonPlanar() {
        #expect(!subdividedK5().isPlanar(using: .leftRight()))
        #expect(!subdividedK5().isPlanar(using: .leftRight()))
    }

    @Test func k33WithPendantIsNonPlanar() {
        #expect(!k33WithPendant().isPlanar(using: .leftRight()))
        #expect(!k33WithPendant().isPlanar(using: .leftRight()))
    }

    // MARK: - Planar cases

    @Test func octahedronIsPlanar() {
        #expect(octahedron().isPlanar(using: .leftRight()))
        #expect(octahedron().isPlanar(using: .leftRight()))
    }

    @Test func grid4x4IsPlanar() {
        #expect(grid4x4().isPlanar(using: .leftRight()))
        #expect(grid4x4().isPlanar(using: .leftRight()))
    }
}
