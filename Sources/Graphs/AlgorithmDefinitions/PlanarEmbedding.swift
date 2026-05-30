extension IncidenceGraph where Self: VertexListGraph & EdgeListGraph, VertexDescriptor: Hashable {
    /// Computes a planar embedding of the graph using the specified algorithm.
    ///
    /// - Parameter algorithm: The planar embedding algorithm to use.
    /// - Returns: `.planar` with a combinatorial embedding (rotation system) if the graph is
    ///   planar, otherwise `.nonPlanar` with a Kuratowski subgraph certificate.
    @inlinable
    public func planarEmbedding(
        using algorithm: some PlanarEmbeddingAlgorithm<Self>
    ) -> PlanarEmbeddingResult<VertexDescriptor> {
        algorithm.planarEmbedding(in: self, visitor: nil)
    }

    #if !GRAPHS_USES_TRAITS || GRAPHS_ANALYSIS
        /// Computes a planar embedding of the graph using the Left-Right algorithm as the default.
        ///
        /// - Returns: `.planar` with a combinatorial embedding (rotation system) if the graph is
        ///   planar, otherwise `.nonPlanar` with a Kuratowski subgraph certificate.
        @inlinable
        public func planarEmbedding() -> PlanarEmbeddingResult<VertexDescriptor> {
            planarEmbedding(using: .leftRight())
        }
    #endif
}

/// A protocol for algorithms that compute a planar embedding of a graph.
public protocol PlanarEmbeddingAlgorithm<Graph> {
    /// The graph type that this algorithm operates on.
    associatedtype Graph: IncidenceGraph & VertexListGraph & EdgeListGraph where Graph.VertexDescriptor: Hashable
    /// The visitor type for observing algorithm progress.
    associatedtype Visitor

    /// Computes a planar embedding of the graph.
    ///
    /// - Parameters:
    ///   - graph: The graph to embed.
    ///   - visitor: An optional visitor to observe the algorithm progress.
    /// - Returns: The planar embedding result.
    func planarEmbedding(
        in graph: Graph,
        visitor: Visitor?
    ) -> PlanarEmbeddingResult<Graph.VertexDescriptor>
}

extension VisitorWrapper: PlanarEmbeddingAlgorithm
where Base: PlanarEmbeddingAlgorithm, Base.Visitor == Visitor, Visitor: Composable, Visitor.Other == Visitor {
    public typealias Graph = Base.Graph

    @inlinable
    public func planarEmbedding(
        in graph: Base.Graph,
        visitor: Base.Visitor?
    ) -> PlanarEmbeddingResult<Base.Graph.VertexDescriptor> {
        base.planarEmbedding(in: graph, visitor: self.visitor.combined(with: visitor))
    }
}

// MARK: - Result Types

/// The result of a planar embedding algorithm: either a planar embedding or a certificate
/// of non-planarity.
public enum PlanarEmbeddingResult<Vertex: Hashable> {
    /// The graph is planar; carries a combinatorial embedding (rotation system).
    case planar(PlanarEmbedding<Vertex>)
    /// The graph is non-planar; carries a Kuratowski subgraph (a K5 or K3,3 subdivision).
    case nonPlanar(KuratowskiSubgraph<Vertex>)

    /// Whether the graph is planar.
    @inlinable
    public var isPlanar: Bool {
        if case .planar = self { true } else { false }
    }

    /// The planar embedding, if the graph is planar.
    @inlinable
    public var embedding: PlanarEmbedding<Vertex>? {
        if case .planar(let embedding) = self { embedding } else { nil }
    }

    /// The Kuratowski subgraph certificate, if the graph is non-planar.
    @inlinable
    public var kuratowskiSubgraph: KuratowskiSubgraph<Vertex>? {
        if case .nonPlanar(let subgraph) = self { subgraph } else { nil }
    }
}

extension PlanarEmbeddingResult: Sendable where Vertex: Sendable {}

/// A combinatorial planar embedding represented as a rotation system: for each vertex, the
/// clockwise cyclic order of its incident edges (given as the ordered list of neighbors).
public struct PlanarEmbedding<Vertex: Hashable> {
    /// The clockwise neighbor order around each vertex.
    public let rotationSystem: [Vertex: [Vertex]]

    /// For each vertex, the position of each neighbor in its rotation (for O(1) lookups).
    @usableFromInline
    let positions: [Vertex: [Vertex: Int]]

    /// Creates a planar embedding from a rotation system.
    ///
    /// - Parameter rotationSystem: The clockwise neighbor order around each vertex.
    @inlinable
    public init(rotationSystem: [Vertex: [Vertex]]) {
        self.rotationSystem = rotationSystem
        var positions: [Vertex: [Vertex: Int]] = [:]
        positions.reserveCapacity(rotationSystem.count)
        for (vertex, neighbors) in rotationSystem {
            var map: [Vertex: Int] = [:]
            map.reserveCapacity(neighbors.count)
            for (index, neighbor) in neighbors.enumerated() { map[neighbor] = index }
            positions[vertex] = map
        }
        self.positions = positions
    }

    /// The number of vertices in the embedding.
    @inlinable
    public var vertexCount: Int { rotationSystem.count }

    /// The number of undirected edges in the embedding.
    @inlinable
    public var edgeCount: Int {
        rotationSystem.values.reduce(0) { $0 + $1.count } / 2
    }

    /// The clockwise neighbor order around `vertex`.
    @inlinable
    public func neighbors(of vertex: Vertex) -> [Vertex] {
        rotationSystem[vertex] ?? []
    }

    /// The faces of the embedding, each as a cyclic list of vertices on its boundary
    /// (including the outer face).
    @inlinable
    public func faces() -> [[Vertex]] {
        var faces: [[Vertex]] = []
        var visited: Set<DirectedEdge<Vertex>> = []
        for (vertex, neighbors) in rotationSystem {
            for neighbor in neighbors {
                let start = DirectedEdge(from: vertex, to: neighbor)
                guard !visited.contains(start) else { continue }
                var face: [Vertex] = []
                var current = start
                repeat {
                    visited.insert(current)
                    face.append(current.from)
                    current = nextFaceHalfEdge(current)
                } while current != start
                faces.append(face)
            }
        }
        return faces
    }

    /// The number of faces in the embedding.
    @inlinable
    public var faceCount: Int { faces().count }

    /// The outer (unbounded) face — the longest face in a planar embedding of
    /// a connected graph. Returns an empty array for the empty graph.
    @inlinable
    public var outerFace: [Vertex] {
        faces().max(by: { $0.count < $1.count }) ?? []
    }

    /// The Euler characteristic `V - E + F`. Equals 2 for a connected planar graph.
    @inlinable
    public var eulerCharacteristic: Int {
        vertexCount - edgeCount + faceCount
    }

    /// Whether the rotation system is a valid undirected embedding: every neighbor relation
    /// is symmetric.
    @inlinable
    public var isValid: Bool {
        for (vertex, neighbors) in rotationSystem {
            for neighbor in neighbors where positions[neighbor]?[vertex] == nil {
                return false
            }
        }
        return true
    }

    /// Given the half-edge `(from -> to)`, returns the next half-edge `(to -> x)` along the
    /// same face, where `x` is the neighbor counter-clockwise from `from` around `to`.
    @usableFromInline
    func nextFaceHalfEdge(_ edge: DirectedEdge<Vertex>) -> DirectedEdge<Vertex> {
        let rotation = rotationSystem[edge.to] ?? []
        guard !rotation.isEmpty, let index = positions[edge.to]?[edge.from] else {
            return edge
        }
        let ccwIndex = (index - 1 + rotation.count) % rotation.count
        return DirectedEdge(from: edge.to, to: rotation[ccwIndex])
    }
}

extension PlanarEmbedding: Sendable where Vertex: Sendable {}

/// A directed half-edge used internally for face traversal.
@usableFromInline
struct DirectedEdge<Vertex: Hashable>: Hashable {
    @usableFromInline var from: Vertex
    @usableFromInline var to: Vertex
    @inlinable init(from: Vertex, to: Vertex) {
        self.from = from
        self.to = to
    }
}

extension DirectedEdge: Sendable where Vertex: Sendable {}

/// A Kuratowski subgraph: a subdivision of K5 or K3,3 that certifies non-planarity
/// (by Kuratowski's theorem, every non-planar graph contains one).
public struct KuratowskiSubgraph<Vertex: Hashable> {
    /// Which forbidden minor the subgraph is a subdivision of.
    public enum Kind: Sendable {
        /// A subdivision of K5 (the complete graph on five vertices).
        case k5
        /// A subdivision of K3,3 (the complete bipartite graph on 3+3 vertices).
        case k33
    }

    /// Whether this is a K5 or K3,3 subdivision.
    public let kind: Kind
    /// The branch vertices (degree-3+ vertices: 5 for K5, 6 for K3,3).
    public let branchVertices: [Vertex]
    /// The edges of the subgraph, each as a two-element `[u, v]` pair.
    public let edges: [[Vertex]]

    /// Creates a Kuratowski subgraph certificate.
    @inlinable
    public init(kind: Kind, branchVertices: [Vertex], edges: [[Vertex]]) {
        self.kind = kind
        self.branchVertices = branchVertices
        self.edges = edges
    }

    /// The number of edges in the subgraph.
    @inlinable
    public var edgeCount: Int { edges.count }
}

extension KuratowskiSubgraph: Sendable where Vertex: Sendable {}
