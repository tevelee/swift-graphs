/// A lazy view of the lexicographic (composition) product of two graphs (G[H]).
///
/// Two vertices (u₁,v₁) and (u₂,v₂) are connected by a directed edge iff:
/// - u₁→u₂ ∈ G (regardless of v₁, v₂), OR
/// - u₁ = u₂ AND v₁→v₂ ∈ H.
///
/// Requires `H: VertexListGraph` because each G-edge fans out to every H-vertex as a destination.
///
/// No edge data is stored. Edges are computed on demand.
/// Vertex count = G.vertexCount × H.vertexCount.
/// Edge count   = G.edgeCount × H.vertexCount² + G.vertexCount × H.edgeCount.
public struct LexicographicProductGraph<G: IncidenceGraph, H: IncidenceGraph & VertexListGraph>: Graph
where G.VertexDescriptor: Hashable, H.VertexDescriptor: Hashable {
    /// The vertex descriptor is a pair of vertex descriptors from the two factor graphs.
    public typealias VertexDescriptor = Pair<G.VertexDescriptor, H.VertexDescriptor>
    /// The edge descriptor is a simple edge between product vertices.
    public typealias EdgeDescriptor = SimpleEdge<VertexDescriptor>

    @usableFromInline let left: G
    @usableFromInline let right: H
    @usableFromInline let rightVertices: [H.VertexDescriptor]

    /// Creates a new lexicographic product graph from two factor graphs.
    ///
    /// - Parameters:
    ///   - left: The first factor graph (G)
    ///   - right: The second factor graph (H)
    @inlinable
    public init(left: G, right: H) {
        self.left = left
        self.right = right
        self.rightVertices = Array(right.vertices())
    }
}

// MARK: - VertexListGraph

extension LexicographicProductGraph: VertexListGraph where G: VertexListGraph {
    /// A sequence of all vertices in the lexicographic product graph.
    public struct Vertices: Sequence {
        @usableFromInline let leftVertices: [G.VertexDescriptor]
        @usableFromInline let rightVertices: [H.VertexDescriptor]

        @inlinable
        public init(leftVertices: [G.VertexDescriptor], rightVertices: [H.VertexDescriptor]) {
            self.leftVertices = leftVertices
            self.rightVertices = rightVertices
        }

        /// Creates an iterator over all product vertices.
        @inlinable public func makeIterator() -> Iterator { Iterator(leftVertices: leftVertices, rightVertices: rightVertices) }

        /// An iterator that yields all pairs (u, v) with u ∈ G and v ∈ H.
        public struct Iterator: IteratorProtocol {
            @usableFromInline let leftVertices: [G.VertexDescriptor]
            @usableFromInline let rightVertices: [H.VertexDescriptor]
            @usableFromInline var leftIndex: Int = 0
            @usableFromInline var rightIndex: Int = 0

            @inlinable
            public init(leftVertices: [G.VertexDescriptor], rightVertices: [H.VertexDescriptor]) {
                self.leftVertices = leftVertices
                self.rightVertices = rightVertices
            }

            @inlinable
            public mutating func next() -> Pair<G.VertexDescriptor, H.VertexDescriptor>? {
                guard leftIndex < leftVertices.count, rightIndex < rightVertices.count else { return nil }
                let result = Pair(leftVertices[leftIndex], rightVertices[rightIndex])
                rightIndex += 1
                if rightIndex >= rightVertices.count {
                    rightIndex = 0
                    leftIndex += 1
                }
                return result
            }
        }
    }

    /// Returns a sequence of all vertices in the lexicographic product.
    @inlinable
    public func vertices() -> Vertices {
        Vertices(leftVertices: Array(left.vertices()), rightVertices: rightVertices)
    }

    /// The total number of vertices, equal to |V(G)| × |V(H)|.
    @inlinable public var vertexCount: Int { left.vertexCount * right.vertexCount }
}

// MARK: - IncidenceGraph

extension LexicographicProductGraph: IncidenceGraph {
    /// A sequence of outgoing edges from a vertex in the lexicographic product graph.
    ///
    /// Emits edges in two phases:
    /// - Phase 1 (G-move): for each u→u' in G.outgoing(u), emit (u,v)→(u',v') for every v' ∈ H.vertices.
    /// - Phase 2 (H-move): for each v→v' in H.outgoing(v), emit (u,v)→(u,v').
    public struct OutgoingEdges: Sequence {
        @usableFromInline let vertex: Pair<G.VertexDescriptor, H.VertexDescriptor>
        @usableFromInline let leftOutgoing: G.OutgoingEdges
        @usableFromInline let rightOutgoing: H.OutgoingEdges
        @usableFromInline let hAllVertices: [H.VertexDescriptor]
        @usableFromInline let left: G
        @usableFromInline let right: H

        @inlinable
        public init(
            vertex: Pair<G.VertexDescriptor, H.VertexDescriptor>,
            leftOutgoing: G.OutgoingEdges,
            rightOutgoing: H.OutgoingEdges,
            hAllVertices: [H.VertexDescriptor],
            left: G,
            right: H
        ) {
            self.vertex = vertex
            self.leftOutgoing = leftOutgoing
            self.rightOutgoing = rightOutgoing
            self.hAllVertices = hAllVertices
            self.left = left
            self.right = right
        }

        /// Creates an iterator over outgoing edges from this product vertex.
        @inlinable public func makeIterator() -> Iterator {
            Iterator(
                vertex: vertex,
                leftIter: leftOutgoing.makeIterator(),
                currentLeftDest: nil,
                hAllVertices: hAllVertices,
                hVertexIndex: 0,
                rightIter: rightOutgoing.makeIterator(),
                left: left,
                right: right,
                inHPhase: false
            )
        }

        /// An iterator that yields lexicographic product edges in two phases: G-move fan-out, then H-move.
        public struct Iterator: IteratorProtocol {
            @usableFromInline let vertex: Pair<G.VertexDescriptor, H.VertexDescriptor>
            @usableFromInline var leftIter: G.OutgoingEdges.Iterator
            @usableFromInline var currentLeftDest: G.VertexDescriptor?
            @usableFromInline let hAllVertices: [H.VertexDescriptor]
            @usableFromInline var hVertexIndex: Int
            @usableFromInline var rightIter: H.OutgoingEdges.Iterator
            @usableFromInline let left: G
            @usableFromInline let right: H
            @usableFromInline var inHPhase: Bool

            @inlinable
            public init(
                vertex: Pair<G.VertexDescriptor, H.VertexDescriptor>,
                leftIter: G.OutgoingEdges.Iterator,
                currentLeftDest: G.VertexDescriptor?,
                hAllVertices: [H.VertexDescriptor],
                hVertexIndex: Int,
                rightIter: H.OutgoingEdges.Iterator,
                left: G,
                right: H,
                inHPhase: Bool
            ) {
                self.vertex = vertex
                self.leftIter = leftIter
                self.currentLeftDest = currentLeftDest
                self.hAllVertices = hAllVertices
                self.hVertexIndex = hVertexIndex
                self.rightIter = rightIter
                self.left = left
                self.right = right
                self.inHPhase = inHPhase
            }

            @inlinable
            public mutating func next() -> SimpleEdge<Pair<G.VertexDescriptor, H.VertexDescriptor>>? {
                // Phase 1: for each G-edge, fan out to all H-vertices
                if !inHPhase {
                    while true {
                        if currentLeftDest == nil {
                            guard let e = leftIter.next(), let gd = left.destination(of: e) else { break }
                            currentLeftDest = gd
                            hVertexIndex = 0
                        }
                        if let gd = currentLeftDest, hVertexIndex < hAllVertices.count {
                            let hv = hAllVertices[hVertexIndex]
                            hVertexIndex += 1
                            return SimpleEdge(source: vertex, destination: Pair(gd, hv))
                        }
                        currentLeftDest = nil
                    }
                    inHPhase = true
                }
                // Phase 2: same G-vertex, move in H
                guard let e = rightIter.next(), let d = right.destination(of: e) else { return nil }
                return SimpleEdge(source: vertex, destination: Pair(vertex.first, d))
            }
        }
    }

    /// Returns all outgoing edges from the given product vertex.
    ///
    /// - Complexity: O(1) to create (uses pre-cached H-vertex array); O(G.outDegree(u) × H.vertexCount + H.outDegree(v)) to iterate.
    @inlinable
    public func outgoingEdges(of vertex: VertexDescriptor) -> OutgoingEdges {
        OutgoingEdges(
            vertex: vertex,
            leftOutgoing: left.outgoingEdges(of: vertex.first),
            rightOutgoing: right.outgoingEdges(of: vertex.second),
            hAllVertices: rightVertices,
            left: left,
            right: right
        )
    }

    /// Returns the source of a product edge.
    @inlinable public func source(of edge: EdgeDescriptor) -> VertexDescriptor? { edge.source }
    /// Returns the destination of a product edge.
    @inlinable public func destination(of edge: EdgeDescriptor) -> VertexDescriptor? { edge.destination }

    /// The out-degree equals G.outDegree(u) × H.vertexCount + H.outDegree(v).
    @inlinable public func outDegree(of vertex: VertexDescriptor) -> Int {
        left.outDegree(of: vertex.first) * right.vertexCount + right.outDegree(of: vertex.second)
    }
}

// MARK: - BidirectionalGraph

extension LexicographicProductGraph: BidirectionalGraph where G: BidirectionalGraph, H: BidirectionalGraph {
    /// A sequence of incoming edges to a product vertex.
    ///
    /// Phase 1: for each u''→u in G, emit (u'',v'')→(u,v) for every v'' in H.vertices.
    /// Phase 2: for each v''→v in H, emit (u,v'')→(u,v).
    public struct IncomingEdges: Sequence {
        @usableFromInline let vertex: Pair<G.VertexDescriptor, H.VertexDescriptor>
        @usableFromInline let leftIncoming: G.IncomingEdges
        @usableFromInline let rightIncoming: H.IncomingEdges
        @usableFromInline let hAllVertices: [H.VertexDescriptor]
        @usableFromInline let left: G
        @usableFromInline let right: H

        @inlinable public init(
            vertex: Pair<G.VertexDescriptor, H.VertexDescriptor>,
            leftIncoming: G.IncomingEdges,
            rightIncoming: H.IncomingEdges,
            hAllVertices: [H.VertexDescriptor],
            left: G,
            right: H
        ) {
            self.vertex = vertex
            self.leftIncoming = leftIncoming
            self.rightIncoming = rightIncoming
            self.hAllVertices = hAllVertices
            self.left = left
            self.right = right
        }

        /// Creates an iterator over this sequence.
        @inlinable public func makeIterator() -> Iterator {
            Iterator(
                vertex: vertex,
                leftIter: leftIncoming.makeIterator(),
                currentLeftSrc: nil,
                hAllVertices: hAllVertices,
                hVertexIndex: 0,
                rightIter: rightIncoming.makeIterator(),
                left: left,
                right: right,
                inHPhase: false
            )
        }

        /// An iterator over incoming edges of a lexicographic product vertex.
        public struct Iterator: IteratorProtocol {
            @usableFromInline let vertex: Pair<G.VertexDescriptor, H.VertexDescriptor>
            @usableFromInline var leftIter: G.IncomingEdges.Iterator
            @usableFromInline var currentLeftSrc: G.VertexDescriptor?
            @usableFromInline let hAllVertices: [H.VertexDescriptor]
            @usableFromInline var hVertexIndex: Int
            @usableFromInline var rightIter: H.IncomingEdges.Iterator
            @usableFromInline let left: G
            @usableFromInline let right: H
            @usableFromInline var inHPhase: Bool

            @inlinable public init(
                vertex: Pair<G.VertexDescriptor, H.VertexDescriptor>,
                leftIter: G.IncomingEdges.Iterator,
                currentLeftSrc: G.VertexDescriptor?,
                hAllVertices: [H.VertexDescriptor],
                hVertexIndex: Int,
                rightIter: H.IncomingEdges.Iterator,
                left: G,
                right: H,
                inHPhase: Bool
            ) {
                self.vertex = vertex
                self.leftIter = leftIter
                self.currentLeftSrc = currentLeftSrc
                self.hAllVertices = hAllVertices
                self.hVertexIndex = hVertexIndex
                self.rightIter = rightIter
                self.left = left
                self.right = right
                self.inHPhase = inHPhase
            }

            @inlinable
            public mutating func next() -> SimpleEdge<Pair<G.VertexDescriptor, H.VertexDescriptor>>? {
                if !inHPhase {
                    while true {
                        if currentLeftSrc == nil {
                            guard let e = leftIter.next(), let gs = left.source(of: e) else { break }
                            currentLeftSrc = gs
                            hVertexIndex = 0
                        }
                        if let gs = currentLeftSrc, hVertexIndex < hAllVertices.count {
                            let hv = hAllVertices[hVertexIndex]
                            hVertexIndex += 1
                            return SimpleEdge(source: Pair(gs, hv), destination: vertex)
                        }
                        currentLeftSrc = nil
                    }
                    inHPhase = true
                }
                guard let e = rightIter.next(), let s = right.source(of: e) else { return nil }
                return SimpleEdge(source: Pair(vertex.first, s), destination: vertex)
            }
        }
    }

    /// Returns all incoming edges to a product vertex.
    ///
    /// - Complexity: O(1) to create; O(G.inDegree(u) × H.vertexCount + H.inDegree(v)) to iterate.
    @inlinable
    public func incomingEdges(of vertex: VertexDescriptor) -> IncomingEdges {
        IncomingEdges(
            vertex: vertex,
            leftIncoming: left.incomingEdges(of: vertex.first),
            rightIncoming: right.incomingEdges(of: vertex.second),
            hAllVertices: rightVertices,
            left: left,
            right: right
        )
    }

    /// The in-degree equals G.inDegree(u) × H.vertexCount + H.inDegree(v).
    @inlinable public func inDegree(of vertex: VertexDescriptor) -> Int {
        left.inDegree(of: vertex.first) * right.vertexCount + right.inDegree(of: vertex.second)
    }
}

// MARK: - EdgeListGraph

extension LexicographicProductGraph: EdgeListGraph where G: EdgeListGraph & VertexListGraph, H: EdgeListGraph {
    /// A sequence of all edges in the lexicographic product graph.
    public struct Edges: Sequence {
        @usableFromInline let allVertices: [Pair<G.VertexDescriptor, H.VertexDescriptor>]
        @usableFromInline let hAllVertices: [H.VertexDescriptor]
        @usableFromInline let left: G
        @usableFromInline let right: H

        @inlinable
        public init(
            allVertices: [Pair<G.VertexDescriptor, H.VertexDescriptor>],
            hAllVertices: [H.VertexDescriptor],
            left: G,
            right: H
        ) {
            self.allVertices = allVertices
            self.hAllVertices = hAllVertices
            self.left = left
            self.right = right
        }

        /// Creates an iterator over all edges in the lexicographic product.
        @inlinable public func makeIterator() -> Iterator {
            Iterator(allVertices: allVertices, hAllVertices: hAllVertices, left: left, right: right)
        }

        /// An iterator that walks each product vertex and yields its outgoing edges.
        public struct Iterator: IteratorProtocol {
            @usableFromInline let allVertices: [Pair<G.VertexDescriptor, H.VertexDescriptor>]
            @usableFromInline let hAllVertices: [H.VertexDescriptor]
            @usableFromInline let left: G
            @usableFromInline let right: H
            @usableFromInline var vIndex: Int = 0
            @usableFromInline var edgeIter: LexicographicProductGraph<G, H>.OutgoingEdges.Iterator?

            @inlinable
            public init(
                allVertices: [Pair<G.VertexDescriptor, H.VertexDescriptor>],
                hAllVertices: [H.VertexDescriptor],
                left: G,
                right: H
            ) {
                self.allVertices = allVertices
                self.hAllVertices = hAllVertices
                self.left = left
                self.right = right
            }

            @inlinable
            public mutating func next() -> SimpleEdge<Pair<G.VertexDescriptor, H.VertexDescriptor>>? {
                while true {
                    if var iter = edgeIter, let edge = iter.next() {
                        edgeIter = iter
                        return edge
                    }
                    guard vIndex < allVertices.count else { return nil }
                    let v = allVertices[vIndex]
                    vIndex += 1
                    let outgoing = LexicographicProductGraph<G, H>.OutgoingEdges(
                        vertex: v,
                        leftOutgoing: left.outgoingEdges(of: v.first),
                        rightOutgoing: right.outgoingEdges(of: v.second),
                        hAllVertices: hAllVertices,
                        left: left,
                        right: right
                    )
                    edgeIter = outgoing.makeIterator()
                }
            }
        }
    }

    /// Returns a sequence of all edges in the lexicographic product.
    @inlinable
    public func edges() -> Edges {
        Edges(
            allVertices: Array(vertices()),
            hAllVertices: rightVertices,
            left: left,
            right: right
        )
    }

    /// The total number of edges equals |E(G)| × |V(H)|² + |V(G)| × |E(H)|.
    @inlinable public var edgeCount: Int {
        let hv = right.vertexCount
        return left.edgeCount * hv * hv + left.vertexCount * right.edgeCount
    }
}

// MARK: - Sendable

extension LexicographicProductGraph: Sendable where G: Sendable, H: Sendable, H.VertexDescriptor: Sendable {}

// MARK: - Convenience

extension IncidenceGraph where VertexDescriptor: Hashable {
    /// Returns a lazy view of the lexicographic product of this graph with another.
    ///
    /// In G[H], vertex (u,v) connects to (u',v') when u→u' ∈ G (any v') or (u=u' and v→v' ∈ H).
    /// `H` must conform to `VertexListGraph` because each G-edge fans out to all H-vertices.
    /// - Complexity: O(|V(H)|) to create (materializes H vertex list once); O(G.outDegree(u) × H.vertexCount + H.outDegree(v)) per `outgoingEdges(of:)`.
    @inlinable
    public func lexicographicProduct<H: IncidenceGraph & VertexListGraph>(with h: H) -> LexicographicProductGraph<Self, H>
    where H.VertexDescriptor: Hashable {
        LexicographicProductGraph(left: self, right: h)
    }
}
