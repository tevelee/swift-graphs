import Testing

@testable import Graphs

/// Tests for planar embedding extraction (rotation system + faces) and the
/// Kuratowski certificate returned for non-planar graphs.
struct PlanarEmbeddingTests {

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

    private func petersen() -> DefaultAdjacencyList {
        let edges =
            [(0, 1), (1, 2), (2, 3), (3, 4), (4, 0)]
            + [(0, 5), (1, 6), (2, 7), (3, 8), (4, 9)]
            + [(5, 7), (7, 9), (9, 6), (6, 8), (8, 5)]
        return build(10, edges)
    }

    private func k33() -> DefaultAdjacencyList {
        var edges: [(Int, Int)] = []
        for a in 0 ..< 3 { for b in 3 ..< 6 { edges.append((a, b)) } }
        return build(6, edges)
    }

    private func subdividedK5() -> DefaultAdjacencyList {
        var edges: [(Int, Int)] = []
        for a in 0 ..< 5 {
            for b in (a + 1) ..< 5 where !(a == 0 && b == 1) { edges.append((a, b)) }
        }
        edges.append((0, 5))
        edges.append((5, 1))
        return build(6, edges)
    }

    // MARK: - Euler's formula (V - E + F = 2 for connected planar graphs)

    @Test func triangleEmbeddingSatisfiesEuler() throws {
        let result = triangle().planarEmbedding(using: .leftRight())
        #expect(result.isPlanar)
        let embedding = try #require(result.embedding)
        #expect(embedding.isValid)
        #expect(embedding.eulerCharacteristic == 2)  // V=3, E=3, F=2
    }

    @Test func octahedronEmbeddingSatisfiesEuler() throws {
        let result = octahedron().planarEmbedding(using: .leftRight())
        let embedding = try #require(result.embedding)
        #expect(embedding.isValid)
        #expect(embedding.vertexCount == 6)
        #expect(embedding.edgeCount == 12)
        #expect(embedding.faceCount == 8)
        #expect(embedding.eulerCharacteristic == 2)
    }

    @Test func gridEmbeddingSatisfiesEuler() throws {
        let embedding = try #require(grid4x4().planarEmbedding(using: .leftRight()).embedding)
        #expect(embedding.isValid)
        #expect(embedding.eulerCharacteristic == 2)  // V=16, E=24, F=10
    }

    @Test func everyEdgeAppearsInRotationSystem() throws {
        let embedding = try #require(octahedron().planarEmbedding(using: .leftRight()).embedding)
        // Each undirected edge {u,v} must appear in both u's and v's rotation.
        for (vertex, neighbors) in embedding.rotationSystem {
            for neighbor in neighbors {
                #expect(embedding.rotationSystem[neighbor]?.contains(vertex) == true)
            }
        }
    }

    // MARK: - Kuratowski certificate for non-planar graphs

    @Test func petersenReturnsKuratowskiCertificate() throws {
        let result = petersen().planarEmbedding(using: .leftRight())
        #expect(!result.isPlanar)
        let certificate = try #require(result.kuratowskiSubgraph)
        // The certificate must itself be non-planar.
        #expect(!certificateGraph(certificate).isPlanar())
    }

    @Test func k33CertificateIsK33() throws {
        let certificate = try #require(k33().planarEmbedding(using: .leftRight()).kuratowskiSubgraph)
        #expect(certificate.kind == .k33)
        #expect(certificate.branchVertices.count == 6)
    }

    @Test func subdividedK5CertificateIsK5() throws {
        let certificate = try #require(subdividedK5().planarEmbedding(using: .leftRight()).kuratowskiSubgraph)
        #expect(certificate.kind == .k5)
        #expect(certificate.branchVertices.count == 5)
    }

    // Rebuilds a graph from a Kuratowski certificate so its planarity can be re-checked.
    private func certificateGraph(_ certificate: KuratowskiSubgraph<DefaultAdjacencyList.VertexDescriptor>) -> DefaultAdjacencyList {
        var graph = AdjacencyList()
        var map: [DefaultAdjacencyList.VertexDescriptor: DefaultAdjacencyList.VertexDescriptor] = [:]
        let endpoints = Set(certificate.edges.flatMap { $0 })
        for original in endpoints {
            map[original] = graph.addVertex { $0.label = "" }
        }
        for edge in certificate.edges {
            graph.addEdge(from: map[edge[0]]!, to: map[edge[1]]!) { $0.label = "" }
        }
        return graph
    }
}
