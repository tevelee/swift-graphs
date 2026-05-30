import Testing

@testable import Graphs

/// Randomized self-consistency tests for the Left-Right embedding.
///
/// Without an external oracle we exploit two invariants that any correct implementation
/// must satisfy on every input:
///   * If a *connected* graph is reported planar, its embedding must be a valid rotation
///     system whose faces satisfy Euler's formula `V - E + F = 2`.
///   * If a graph is reported non-planar, the Kuratowski certificate must itself be non-planar.
struct PlanarEmbeddingFuzzTests {

    /// A tiny deterministic LCG so the fuzzing is reproducible.
    private struct LCG: RandomNumberGenerator {
        var state: UInt64
        mutating func next() -> UInt64 {
            state = state &* 6_364_136_223_846_793_005 &+ 1_442_695_040_888_963_407
            return state
        }
    }

    /// Builds a connected random graph: a random spanning tree plus `extra` random chords.
    private func randomConnectedGraph(
        vertexCount n: Int,
        extra: Int,
        using rng: inout LCG
    ) -> DefaultAdjacencyList {
        var graph = AdjacencyList()
        let v = (0 ..< n).map { i in graph.addVertex { $0.label = "\(i)" } }
        var present = Set<Int>()
        func key(_ a: Int, _ b: Int) -> Int { a < b ? a * n + b : b * n + a }

        for i in 1 ..< n {
            let j = Int.random(in: 0 ..< i, using: &rng)
            graph.addEdge(from: v[j], to: v[i]) { $0.label = "" }
            present.insert(key(i, j))
        }
        for _ in 0 ..< extra {
            let a = Int.random(in: 0 ..< n, using: &rng)
            let b = Int.random(in: 0 ..< n, using: &rng)
            guard a != b, present.insert(key(a, b)).inserted else { continue }
            graph.addEdge(from: v[a], to: v[b]) { $0.label = "" }
        }
        return graph
    }

    private func certificateGraph(_ certificate: KuratowskiSubgraph<DefaultAdjacencyList.VertexDescriptor>) -> DefaultAdjacencyList {
        var graph = AdjacencyList()
        var map: [DefaultAdjacencyList.VertexDescriptor: DefaultAdjacencyList.VertexDescriptor] = [:]
        for original in Set(certificate.edges.flatMap { $0 }) {
            map[original] = graph.addVertex { $0.label = "" }
        }
        for edge in certificate.edges {
            graph.addEdge(from: map[edge[0]]!, to: map[edge[1]]!) { $0.label = "" }
        }
        return graph
    }

    @Test func randomGraphsRespectEmbeddingInvariants() {
        var rng = LCG(state: 0x9E37_79B9_7F4A_7C15)
        var planarSeen = 0
        var nonPlanarSeen = 0

        for _ in 0 ..< 400 {
            let n = Int.random(in: 5 ... 9, using: &rng)
            let extra = Int.random(in: 0 ... (n + 3), using: &rng)
            let graph = randomConnectedGraph(vertexCount: n, extra: extra, using: &rng)
            let result = graph.planarEmbedding(using: .leftRight())

            switch result {
            case .planar(let embedding):
                planarSeen += 1
                #expect(embedding.isValid)
                // Connected graph => V - E + F == 2.
                #expect(embedding.eulerCharacteristic == 2)
            case .nonPlanar(let certificate):
                nonPlanarSeen += 1
                #expect(!certificateGraph(certificate).isPlanar(using: .leftRight()))
                #expect(certificate.kind == .k5 || certificate.kind == .k33)
            }
        }

        // Sanity: the corpus should exercise both branches.
        #expect(planarSeen > 0)
        #expect(nonPlanarSeen > 0)
    }

    // MARK: - Drawing fuzz

    @Test func randomPlanarGraphsProduceValidDrawings() {
        var rng = LCG(state: 0xDEADBEEF_CAFEBABE)
        var drawingsSeen = 0

        for _ in 0 ..< 200 {
            let n = Int.random(in: 4 ... 8, using: &rng)
            let extra = Int.random(in: 0 ... n, using: &rng)
            let graph = randomConnectedGraph(vertexCount: n, extra: extra, using: &rng)
            guard let drawing = ChrobakPayneDrawing<DefaultAdjacencyList>().planarDrawing(in: graph, visitor: nil) else {
                let embResult = graph.planarEmbedding(using: .leftRight())
                #expect(!embResult.isPlanar)
                continue
            }
            drawingsSeen += 1

            let points = graph.vertices().map { drawing.position(of: $0)! }
            #expect(Set(points).count == points.count)
            #expect(points.allSatisfy { $0.x >= 0 && $0.y >= 0 })
        }
        #expect(drawingsSeen > 0)
    }
}
