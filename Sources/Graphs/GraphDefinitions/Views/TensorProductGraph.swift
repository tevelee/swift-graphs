/// A lazy view of the tensor (categorical) product of two graphs (G × H).
///
/// Two vertices (u₁,v₁) and (u₂,v₂) are connected by a directed edge iff
/// u₁→u₂ ∈ G AND v₁→v₂ ∈ H (both components must move simultaneously).
///
/// No edge data is stored. Edges are computed on demand.
/// Vertex count = G.vertexCount × H.vertexCount.
/// Edge count   = G.edgeCount × H.edgeCount.
public struct TensorProductGraph<G: IncidenceGraph, H: IncidenceGraph>: Graph
where G.VertexDescriptor: Hashable, H.VertexDescriptor: Hashable {
    /// The vertex descriptor is a pair of vertex descriptors from the two factor graphs.
    public typealias VertexDescriptor = Pair<G.VertexDescriptor, H.VertexDescriptor>
    /// The edge descriptor is a simple edge between product vertices.
    public typealias EdgeDescriptor = SimpleEdge<VertexDescriptor>

    @usableFromInline let left: G
    @usableFromInline let right: H

    /// Creates a new tensor product graph from two factor graphs.
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

extension TensorProductGraph: VertexListGraph where G: VertexListGraph, H: VertexListGraph {
    /// A sequence of all vertices in the tensor product graph.
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

    /// Returns a sequence of all vertices in the tensor product.
    @inlinable
    public func vertices() -> Vertices {
        Vertices(leftVertices: Array(left.vertices()), rightVertices: Array(right.vertices()))
    }

    /// The total number of vertices, equal to |V(G)| × |V(H)|.
    @inlinable public var vertexCount: Int { left.vertexCount * right.vertexCount }
}

// MARK: - IncidenceGraph

extension TensorProductGraph: IncidenceGraph {
    /// A sequence of outgoing edges from a vertex in the tensor product graph.
    ///
    /// For (u,v), emits (u,v)→(u',v') for every u→u' ∈ G and every v→v' ∈ H.
    public struct OutgoingEdges: Sequence {
        @usableFromInline let vertex: Pair<G.VertexDescriptor, H.VertexDescriptor>
        @usableFromInline let leftOutgoing: G.OutgoingEdges
        @usableFromInline let rightOutgoing: H.OutgoingEdges
        @usableFromInline let left: G
        @usableFromInline let right: H

        @inlinable
        public init(
            vertex: Pair<G.VertexDescriptor, H.VertexDescriptor>,
            leftOutgoing: G.OutgoingEdges,
            rightOutgoing: H.OutgoingEdges,
            left: G,
            right: H
        ) {
            self.vertex = vertex
            self.leftOutgoing = leftOutgoing
            self.rightOutgoing = rightOutgoing
            self.left = left
            self.right = right
        }

        /// Creates an iterator over outgoing edges from this product vertex.
        @inlinable public func makeIterator() -> Iterator {
            Iterator(
                vertex: vertex,
                leftIter: leftOutgoing.makeIterator(),
                currentLeftDest: nil,
                rightOutgoing: rightOutgoing,
                rightIter: rightOutgoing.makeIterator(),
                left: left,
                right: right
            )
        }

        /// An iterator that yields (u,v)→(u',v') for each pair of outgoing edges u→u' ∈ G and v→v' ∈ H.
        public struct Iterator: IteratorProtocol {
            @usableFromInline let vertex: Pair<G.VertexDescriptor, H.VertexDescriptor>
            @usableFromInline var leftIter: G.OutgoingEdges.Iterator
            @usableFromInline var currentLeftDest: G.VertexDescriptor?
            @usableFromInline let rightOutgoing: H.OutgoingEdges
            @usableFromInline var rightIter: H.OutgoingEdges.Iterator
            @usableFromInline let left: G
            @usableFromInline let right: H

            @inlinable
            public init(
                vertex: Pair<G.VertexDescriptor, H.VertexDescriptor>,
                leftIter: G.OutgoingEdges.Iterator,
                currentLeftDest: G.VertexDescriptor?,
                rightOutgoing: H.OutgoingEdges,
                rightIter: H.OutgoingEdges.Iterator,
                left: G,
                right: H
            ) {
                self.vertex = vertex
                self.leftIter = leftIter
                self.currentLeftDest = currentLeftDest
                self.rightOutgoing = rightOutgoing
                self.rightIter = rightIter
                self.left = left
                self.right = right
            }

            @inlinable
            public mutating func next() -> SimpleEdge<Pair<G.VertexDescriptor, H.VertexDescriptor>>? {
                while true {
                    if currentLeftDest == nil {
                        guard let e = leftIter.next(), let gd = left.destination(of: e) else { return nil }
                        currentLeftDest = gd
                        rightIter = rightOutgoing.makeIterator()
                    }
                    if let gd = currentLeftDest, let e = rightIter.next(), let hd = right.destination(of: e) {
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
        let rightOut = right.outgoingEdges(of: vertex.second)
        return OutgoingEdges(
            vertex: vertex,
            leftOutgoing: left.outgoingEdges(of: vertex.first),
            rightOutgoing: rightOut,
            left: left,
            right: right
        )
    }

    /// Returns the source of a product edge.
    @inlinable public func source(of edge: EdgeDescriptor) -> VertexDescriptor? { edge.source }
    /// Returns the destination of a product edge.
    @inlinable public func destination(of edge: EdgeDescriptor) -> VertexDescriptor? { edge.destination }

    /// The out-degree of a product vertex equals G.outDegree(u) × H.outDegree(v).
    @inlinable public func outDegree(of vertex: VertexDescriptor) -> Int {
        left.outDegree(of: vertex.first) * right.outDegree(of: vertex.second)
    }
}

// MARK: - BidirectionalGraph

extension TensorProductGraph: BidirectionalGraph where G: BidirectionalGraph, H: BidirectionalGraph {
    /// A sequence of incoming edges to a vertex in the tensor product graph.
    ///
    /// For (u,v), emits (u'',v'')→(u,v) for every u''→u ∈ G and every v''→v ∈ H.
    public struct IncomingEdges: Sequence {
        @usableFromInline let vertex: Pair<G.VertexDescriptor, H.VertexDescriptor>
        @usableFromInline let leftIncoming: G.IncomingEdges
        @usableFromInline let rightIncoming: H.IncomingEdges
        @usableFromInline let left: G
        @usableFromInline let right: H

        @inlinable
        public init(
            vertex: Pair<G.VertexDescriptor, H.VertexDescriptor>,
            leftIncoming: G.IncomingEdges,
            rightIncoming: H.IncomingEdges,
            left: G,
            right: H
        ) {
            self.vertex = vertex
            self.leftIncoming = leftIncoming
            self.rightIncoming = rightIncoming
            self.left = left
            self.right = right
        }

        /// Creates an iterator over incoming edges to this product vertex.
        @inlinable public func makeIterator() -> Iterator {
            Iterator(
                vertex: vertex,
                leftIter: leftIncoming.makeIterator(),
                currentLeftSrc: nil,
                rightIncoming: rightIncoming,
                rightIter: rightIncoming.makeIterator(),
                left: left,
                right: right
            )
        }

        /// An iterator that yields (u'',v'')→(u,v) for each pair of incoming edges u''→u ∈ G and v''→v ∈ H.
        public struct Iterator: IteratorProtocol {
            @usableFromInline let vertex: Pair<G.VertexDescriptor, H.VertexDescriptor>
            @usableFromInline var leftIter: G.IncomingEdges.Iterator
            @usableFromInline var currentLeftSrc: G.VertexDescriptor?
            @usableFromInline let rightIncoming: H.IncomingEdges
            @usableFromInline var rightIter: H.IncomingEdges.Iterator
            @usableFromInline let left: G
            @usableFromInline let right: H

            @inlinable
            public init(
                vertex: Pair<G.VertexDescriptor, H.VertexDescriptor>,
                leftIter: G.IncomingEdges.Iterator,
                currentLeftSrc: G.VertexDescriptor?,
                rightIncoming: H.IncomingEdges,
                rightIter: H.IncomingEdges.Iterator,
                left: G,
                right: H
            ) {
                self.vertex = vertex
                self.leftIter = leftIter
                self.currentLeftSrc = currentLeftSrc
                self.rightIncoming = rightIncoming
                self.rightIter = rightIter
                self.left = left
                self.right = right
            }

            @inlinable
            public mutating func next() -> SimpleEdge<Pair<G.VertexDescriptor, H.VertexDescriptor>>? {
                while true {
                    if currentLeftSrc == nil {
                        guard let e = leftIter.next(), let gs = left.source(of: e) else { return nil }
                        currentLeftSrc = gs
                        rightIter = rightIncoming.makeIterator()
                    }
                    if let gs = currentLeftSrc, let e = rightIter.next(), let hs = right.source(of: e) {
                        return SimpleEdge(source: Pair(gs, hs), destination: vertex)
                    }
                    currentLeftSrc = nil
                }
            }
        }
    }

    /// Returns all incoming edges to the given product vertex.
    @inlinable
    public func incomingEdges(of vertex: VertexDescriptor) -> IncomingEdges {
        let rightIn = right.incomingEdges(of: vertex.second)
        return IncomingEdges(
            vertex: vertex,
            leftIncoming: left.incomingEdges(of: vertex.first),
            rightIncoming: rightIn,
            left: left,
            right: right
        )
    }

    /// The in-degree of a product vertex equals G.inDegree(u) × H.inDegree(v).
    @inlinable public func inDegree(of vertex: VertexDescriptor) -> Int {
        left.inDegree(of: vertex.first) * right.inDegree(of: vertex.second)
    }
}

// MARK: - EdgeListGraph

extension TensorProductGraph: EdgeListGraph where G: EdgeListGraph & VertexListGraph, H: EdgeListGraph & VertexListGraph {
    /// A sequence of all edges in the tensor product graph.
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

        /// Creates an iterator over all edges in the tensor product.
        @inlinable public func makeIterator() -> Iterator {
            Iterator(allVertices: allVertices, left: left, right: right)
        }

        /// An iterator that walks each product vertex and yields its outgoing edges.
        public struct Iterator: IteratorProtocol {
            @usableFromInline let allVertices: [Pair<G.VertexDescriptor, H.VertexDescriptor>]
            @usableFromInline let left: G
            @usableFromInline let right: H
            @usableFromInline var vIndex: Int = 0
            @usableFromInline var edgeIter: TensorProductGraph<G, H>.OutgoingEdges.Iterator?

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
                    let rightOut = right.outgoingEdges(of: v.second)
                    let outgoing = TensorProductGraph<G, H>.OutgoingEdges(
                        vertex: v,
                        leftOutgoing: left.outgoingEdges(of: v.first),
                        rightOutgoing: rightOut,
                        left: left,
                        right: right
                    )
                    edgeIter = outgoing.makeIterator()
                }
            }
        }
    }

    /// Returns a sequence of all edges in the tensor product.
    @inlinable
    public func edges() -> Edges {
        Edges(allVertices: Array(vertices()), left: left, right: right)
    }

    /// The total number of edges equals |E(G)| × |E(H)|.
    @inlinable public var edgeCount: Int { left.edgeCount * right.edgeCount }
}

// MARK: - Sendable

extension TensorProductGraph: Sendable where G: Sendable, H: Sendable {}

// MARK: - Convenience

extension IncidenceGraph where VertexDescriptor: Hashable {
    /// Returns a lazy view of the tensor (categorical) product of this graph with another.
    ///
    /// In G × H, vertex (u,v) connects to (u',v') only when both u→u' ∈ G and v→v' ∈ H.
    /// - Complexity: O(1) to create; O(G.outDegree(u) × H.outDegree(v)) per `outgoingEdges(of:)`.
    @inlinable
    public func tensorProduct<H: IncidenceGraph>(with h: H) -> TensorProductGraph<Self, H>
    where H.VertexDescriptor: Hashable {
        TensorProductGraph(left: self, right: h)
    }
}
