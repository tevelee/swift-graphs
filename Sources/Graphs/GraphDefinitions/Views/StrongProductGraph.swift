/// A lazy view of the strong product of two graphs (G ⊠ H).
///
/// Two vertices (u₁,v₁) and (u₂,v₂) are connected by a directed edge iff
/// (u₁ = u₂ OR u₁→u₂ ∈ G) AND (v₁ = v₂ OR v₁→v₂ ∈ H), excluding the self-pair.
/// On simple graphs this equals the union of Cartesian and Tensor product edges.
///
/// No edge data is stored. Edges are computed on demand.
/// Vertex count = G.vertexCount × H.vertexCount.
/// Edge count   = G.edgeCount × H.vertexCount + H.edgeCount × G.vertexCount + G.edgeCount × H.edgeCount.
public struct StrongProductGraph<G: IncidenceGraph, H: IncidenceGraph>: Graph
where G.VertexDescriptor: Hashable, H.VertexDescriptor: Hashable {
    /// The vertex descriptor is a pair of vertex descriptors from the two factor graphs.
    public typealias VertexDescriptor = Pair<G.VertexDescriptor, H.VertexDescriptor>
    /// The edge descriptor is a simple edge between product vertices.
    public typealias EdgeDescriptor = SimpleEdge<VertexDescriptor>

    @usableFromInline let left: G
    @usableFromInline let right: H

    /// Creates a new strong product graph from two factor graphs.
    ///
    /// - Parameters:
    ///   - left: The first factor graph (G)
    ///   - right: The second factor graph (H)
    @inlinable
    public init(left: G, right: H) {
        self.left = left
        self.right = right
    }
}

// MARK: - VertexListGraph

extension StrongProductGraph: VertexListGraph where G: VertexListGraph, H: VertexListGraph {
    /// A sequence of all vertices in the strong product graph.
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

    /// Returns a sequence of all vertices in the strong product.
    @inlinable
    public func vertices() -> Vertices {
        Vertices(leftVertices: Array(left.vertices()), rightVertices: Array(right.vertices()))
    }

    /// The total number of vertices, equal to |V(G)| × |V(H)|.
    @inlinable public var vertexCount: Int { left.vertexCount * right.vertexCount }
}

// MARK: - IncidenceGraph

extension StrongProductGraph: IncidenceGraph {
    /// A sequence of outgoing edges from a vertex in the strong product graph.
    ///
    /// Emits edges in three phases:
    /// - Phase 0 (Cartesian-G): left component moves, right fixed.
    /// - Phase 1 (Cartesian-H): left fixed, right component moves.
    /// - Phase 2 (Tensor): both components move simultaneously.
    public struct OutgoingEdges: Sequence {
        @usableFromInline let vertex: Pair<G.VertexDescriptor, H.VertexDescriptor>
        @usableFromInline let leftOutgoing1: G.OutgoingEdges  // Cartesian-G phase
        @usableFromInline let rightOutgoing1: H.OutgoingEdges  // Cartesian-H phase
        @usableFromInline let leftOutgoing2: G.OutgoingEdges  // Tensor outer
        @usableFromInline let rightOutgoing2: H.OutgoingEdges  // Tensor inner reset template
        @usableFromInline let left: G
        @usableFromInline let right: H

        @inlinable
        public init(
            vertex: Pair<G.VertexDescriptor, H.VertexDescriptor>,
            leftOutgoing1: G.OutgoingEdges,
            rightOutgoing1: H.OutgoingEdges,
            leftOutgoing2: G.OutgoingEdges,
            rightOutgoing2: H.OutgoingEdges,
            left: G,
            right: H
        ) {
            self.vertex = vertex
            self.leftOutgoing1 = leftOutgoing1
            self.rightOutgoing1 = rightOutgoing1
            self.leftOutgoing2 = leftOutgoing2
            self.rightOutgoing2 = rightOutgoing2
            self.left = left
            self.right = right
        }

        /// Creates an iterator over outgoing edges from this product vertex.
        @inlinable public func makeIterator() -> Iterator {
            Iterator(
                vertex: vertex,
                leftIter1: leftOutgoing1.makeIterator(),
                rightIter1: rightOutgoing1.makeIterator(),
                leftIter2: leftOutgoing2.makeIterator(),
                currentLeftDest: nil,
                rightOutgoing2: rightOutgoing2,
                rightIter2: rightOutgoing2.makeIterator(),
                left: left,
                right: right,
                phase: 0
            )
        }

        /// An iterator that yields strong product edges in three phases: Cartesian-G, Cartesian-H, then Tensor.
        public struct Iterator: IteratorProtocol {
            @usableFromInline let vertex: Pair<G.VertexDescriptor, H.VertexDescriptor>
            @usableFromInline var leftIter1: G.OutgoingEdges.Iterator
            @usableFromInline var rightIter1: H.OutgoingEdges.Iterator
            @usableFromInline var leftIter2: G.OutgoingEdges.Iterator
            @usableFromInline var currentLeftDest: G.VertexDescriptor?
            @usableFromInline let rightOutgoing2: H.OutgoingEdges
            @usableFromInline var rightIter2: H.OutgoingEdges.Iterator
            @usableFromInline let left: G
            @usableFromInline let right: H
            @usableFromInline var phase: Int  // 0 = Cartesian-G, 1 = Cartesian-H, 2 = Tensor

            @inlinable
            public init(
                vertex: Pair<G.VertexDescriptor, H.VertexDescriptor>,
                leftIter1: G.OutgoingEdges.Iterator,
                rightIter1: H.OutgoingEdges.Iterator,
                leftIter2: G.OutgoingEdges.Iterator,
                currentLeftDest: G.VertexDescriptor?,
                rightOutgoing2: H.OutgoingEdges,
                rightIter2: H.OutgoingEdges.Iterator,
                left: G,
                right: H,
                phase: Int
            ) {
                self.vertex = vertex
                self.leftIter1 = leftIter1
                self.rightIter1 = rightIter1
                self.leftIter2 = leftIter2
                self.currentLeftDest = currentLeftDest
                self.rightOutgoing2 = rightOutgoing2
                self.rightIter2 = rightIter2
                self.left = left
                self.right = right
                self.phase = phase
            }

            @inlinable
            public mutating func next() -> SimpleEdge<Pair<G.VertexDescriptor, H.VertexDescriptor>>? {
                if phase == 0 {
                    while let e = leftIter1.next() {
                        if let d = left.destination(of: e) {
                            return SimpleEdge(source: vertex, destination: Pair(d, vertex.second))
                        }
                    }
                    phase = 1
                }
                if phase == 1 {
                    while let e = rightIter1.next() {
                        if let d = right.destination(of: e) {
                            return SimpleEdge(source: vertex, destination: Pair(vertex.first, d))
                        }
                    }
                    phase = 2
                }
                // Phase 2: Tensor — both components move
                while true {
                    if currentLeftDest == nil {
                        guard let e = leftIter2.next(), let gd = left.destination(of: e) else { return nil }
                        currentLeftDest = gd
                        rightIter2 = rightOutgoing2.makeIterator()
                    }
                    if let gd = currentLeftDest, let e = rightIter2.next(), let hd = right.destination(of: e) {
                        return SimpleEdge(source: vertex, destination: Pair(gd, hd))
                    }
                    currentLeftDest = nil
                }
            }
        }
    }

    /// Returns all outgoing edges from the given product vertex.
    @inlinable
    public func outgoingEdges(of vertex: VertexDescriptor) -> OutgoingEdges {
        OutgoingEdges(
            vertex: vertex,
            leftOutgoing1: left.outgoingEdges(of: vertex.first),
            rightOutgoing1: right.outgoingEdges(of: vertex.second),
            leftOutgoing2: left.outgoingEdges(of: vertex.first),
            rightOutgoing2: right.outgoingEdges(of: vertex.second),
            left: left,
            right: right
        )
    }

    /// Returns the source of a product edge.
    @inlinable public func source(of edge: EdgeDescriptor) -> VertexDescriptor? { edge.source }
    /// Returns the destination of a product edge.
    @inlinable public func destination(of edge: EdgeDescriptor) -> VertexDescriptor? { edge.destination }

    /// The out-degree of a product vertex equals G.outDegree(u) + H.outDegree(v) + G.outDegree(u) × H.outDegree(v).
    @inlinable public func outDegree(of vertex: VertexDescriptor) -> Int {
        let gd = left.outDegree(of: vertex.first)
        let hd = right.outDegree(of: vertex.second)
        return gd + hd + gd * hd
    }
}

// MARK: - BidirectionalGraph

extension StrongProductGraph: BidirectionalGraph where G: BidirectionalGraph, H: BidirectionalGraph {
    /// A sequence of incoming edges to a product vertex.
    ///
    /// Emits edges in three phases: Cartesian-G (left source varies, right fixed),
    /// Cartesian-H (left fixed, right source varies), then Tensor (both sources vary).
    public struct IncomingEdges: Sequence {
        @usableFromInline let vertex: Pair<G.VertexDescriptor, H.VertexDescriptor>
        @usableFromInline let leftIncoming1: G.IncomingEdges  // Cartesian-G phase
        @usableFromInline let rightIncoming1: H.IncomingEdges  // Cartesian-H phase
        @usableFromInline let leftIncoming2: G.IncomingEdges  // Tensor outer
        @usableFromInline let rightIncoming2: H.IncomingEdges  // Tensor inner reset template
        @usableFromInline let left: G
        @usableFromInline let right: H

        @inlinable public init(
            vertex: Pair<G.VertexDescriptor, H.VertexDescriptor>,
            leftIncoming1: G.IncomingEdges,
            rightIncoming1: H.IncomingEdges,
            leftIncoming2: G.IncomingEdges,
            rightIncoming2: H.IncomingEdges,
            left: G,
            right: H
        ) {
            self.vertex = vertex
            self.leftIncoming1 = leftIncoming1
            self.rightIncoming1 = rightIncoming1
            self.leftIncoming2 = leftIncoming2
            self.rightIncoming2 = rightIncoming2
            self.left = left
            self.right = right
        }

        /// Creates an iterator over this sequence.
        @inlinable public func makeIterator() -> Iterator {
            Iterator(
                vertex: vertex,
                leftIter1: leftIncoming1.makeIterator(),
                rightIter1: rightIncoming1.makeIterator(),
                leftIter2: leftIncoming2.makeIterator(),
                currentLeftSrc: nil,
                rightIncoming2: rightIncoming2,
                rightIter2: rightIncoming2.makeIterator(),
                left: left,
                right: right,
                phase: 0
            )
        }

        /// An iterator over incoming edges of a strong product vertex.
        public struct Iterator: IteratorProtocol {
            @usableFromInline let vertex: Pair<G.VertexDescriptor, H.VertexDescriptor>
            @usableFromInline var leftIter1: G.IncomingEdges.Iterator
            @usableFromInline var rightIter1: H.IncomingEdges.Iterator
            @usableFromInline var leftIter2: G.IncomingEdges.Iterator
            @usableFromInline var currentLeftSrc: G.VertexDescriptor?
            @usableFromInline let rightIncoming2: H.IncomingEdges
            @usableFromInline var rightIter2: H.IncomingEdges.Iterator
            @usableFromInline let left: G
            @usableFromInline let right: H
            @usableFromInline var phase: Int

            @inlinable public init(
                vertex: Pair<G.VertexDescriptor, H.VertexDescriptor>,
                leftIter1: G.IncomingEdges.Iterator,
                rightIter1: H.IncomingEdges.Iterator,
                leftIter2: G.IncomingEdges.Iterator,
                currentLeftSrc: G.VertexDescriptor?,
                rightIncoming2: H.IncomingEdges,
                rightIter2: H.IncomingEdges.Iterator,
                left: G,
                right: H,
                phase: Int
            ) {
                self.vertex = vertex
                self.leftIter1 = leftIter1
                self.rightIter1 = rightIter1
                self.leftIter2 = leftIter2
                self.currentLeftSrc = currentLeftSrc
                self.rightIncoming2 = rightIncoming2
                self.rightIter2 = rightIter2
                self.left = left
                self.right = right
                self.phase = phase
            }

            @inlinable
            public mutating func next() -> SimpleEdge<Pair<G.VertexDescriptor, H.VertexDescriptor>>? {
                if phase == 0 {
                    while let e = leftIter1.next() {
                        if let s = left.source(of: e) {
                            return SimpleEdge(source: Pair(s, vertex.second), destination: vertex)
                        }
                    }
                    phase = 1
                }
                if phase == 1 {
                    while let e = rightIter1.next() {
                        if let s = right.source(of: e) {
                            return SimpleEdge(source: Pair(vertex.first, s), destination: vertex)
                        }
                    }
                    phase = 2
                }
                while true {
                    if currentLeftSrc == nil {
                        guard let e = leftIter2.next(), let gs = left.source(of: e) else { return nil }
                        currentLeftSrc = gs
                        rightIter2 = rightIncoming2.makeIterator()
                    }
                    if let gs = currentLeftSrc, let e = rightIter2.next(), let hs = right.source(of: e) {
                        return SimpleEdge(source: Pair(gs, hs), destination: vertex)
                    }
                    currentLeftSrc = nil
                }
            }
        }
    }

    /// Returns all incoming edges to a product vertex.
    ///
    /// - Complexity: O(1) to create; O(G.inDegree(u) + H.inDegree(v) + G.inDegree(u) × H.inDegree(v)) to iterate.
    @inlinable
    public func incomingEdges(of vertex: VertexDescriptor) -> IncomingEdges {
        IncomingEdges(
            vertex: vertex,
            leftIncoming1: left.incomingEdges(of: vertex.first),
            rightIncoming1: right.incomingEdges(of: vertex.second),
            leftIncoming2: left.incomingEdges(of: vertex.first),
            rightIncoming2: right.incomingEdges(of: vertex.second),
            left: left,
            right: right
        )
    }

    /// The in-degree equals G.inDegree(u) + H.inDegree(v) + G.inDegree(u) × H.inDegree(v).
    @inlinable public func inDegree(of vertex: VertexDescriptor) -> Int {
        let gi = left.inDegree(of: vertex.first)
        let hi = right.inDegree(of: vertex.second)
        return gi + hi + gi * hi
    }
}

// MARK: - EdgeListGraph

extension StrongProductGraph: EdgeListGraph where G: EdgeListGraph & VertexListGraph, H: EdgeListGraph & VertexListGraph {
    /// A sequence of all edges in the strong product graph.
    public struct Edges: Sequence {
        @usableFromInline let allVertices: [Pair<G.VertexDescriptor, H.VertexDescriptor>]
        @usableFromInline let left: G
        @usableFromInline let right: H

        @inlinable
        public init(allVertices: [Pair<G.VertexDescriptor, H.VertexDescriptor>], left: G, right: H) {
            self.allVertices = allVertices
            self.left = left
            self.right = right
        }

        /// Creates an iterator over all edges in the strong product.
        @inlinable public func makeIterator() -> Iterator {
            Iterator(allVertices: allVertices, left: left, right: right)
        }

        /// An iterator that walks each product vertex and yields its outgoing edges.
        public struct Iterator: IteratorProtocol {
            @usableFromInline let allVertices: [Pair<G.VertexDescriptor, H.VertexDescriptor>]
            @usableFromInline let left: G
            @usableFromInline let right: H
            @usableFromInline var vIndex: Int = 0
            @usableFromInline var edgeIter: StrongProductGraph<G, H>.OutgoingEdges.Iterator?

            @inlinable
            public init(allVertices: [Pair<G.VertexDescriptor, H.VertexDescriptor>], left: G, right: H) {
                self.allVertices = allVertices
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
                    let outgoing = StrongProductGraph<G, H>.OutgoingEdges(
                        vertex: v,
                        leftOutgoing1: left.outgoingEdges(of: v.first),
                        rightOutgoing1: right.outgoingEdges(of: v.second),
                        leftOutgoing2: left.outgoingEdges(of: v.first),
                        rightOutgoing2: right.outgoingEdges(of: v.second),
                        left: left,
                        right: right
                    )
                    edgeIter = outgoing.makeIterator()
                }
            }
        }
    }

    /// Returns a sequence of all edges in the strong product.
    @inlinable
    public func edges() -> Edges {
        Edges(allVertices: Array(vertices()), left: left, right: right)
    }

    /// The total number of edges equals |E(G)| × |V(H)| + |E(H)| × |V(G)| + |E(G)| × |E(H)|.
    @inlinable public var edgeCount: Int {
        let ge = left.edgeCount
        let he = right.edgeCount
        let gv = left.vertexCount
        let hv = right.vertexCount
        return ge * hv + he * gv + ge * he
    }
}

// MARK: - Sendable

extension StrongProductGraph: Sendable where G: Sendable, H: Sendable {}

// MARK: - Convenience

extension IncidenceGraph where VertexDescriptor: Hashable {
    /// Returns a lazy view of the strong product of this graph with another.
    ///
    /// In G ⊠ H, vertex (u,v) connects to (u',v') when either or both components move (never self).
    /// Equals the union of the Cartesian and Tensor products on simple graphs.
    /// - Complexity: O(1) to create; O(G.outDegree(u) + H.outDegree(v) + G.outDegree(u) × H.outDegree(v)) per `outgoingEdges(of:)`.
    @inlinable
    public func strongProduct<H: IncidenceGraph>(with h: H) -> StrongProductGraph<Self, H>
    where H.VertexDescriptor: Hashable {
        StrongProductGraph(left: self, right: h)
    }
}
