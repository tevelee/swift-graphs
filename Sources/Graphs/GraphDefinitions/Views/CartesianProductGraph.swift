/// A lazy view of the Cartesian product of two graphs (G □ H).
///
/// Two vertices (u₁,v₁) and (u₂,v₂) are connected by a directed edge iff either:
/// - u₁ = u₂ and v₁→v₂ ∈ H  (move in H, stay in G), or
/// - v₁ = v₂ and u₁→u₂ ∈ G  (move in G, stay in H).
///
/// No edge data is stored. Edges are computed on demand in O(outDegree) time.
/// Vertex count = G.vertexCount × H.vertexCount.
/// Edge count   = G.edgeCount × H.vertexCount + H.edgeCount × G.vertexCount.
public struct CartesianProductGraph<G: IncidenceGraph, H: IncidenceGraph>: Graph
where G.VertexDescriptor: Hashable, H.VertexDescriptor: Hashable {
    /// The vertex descriptor is a pair of vertex descriptors from the two factor graphs.
    public typealias VertexDescriptor = Pair<G.VertexDescriptor, H.VertexDescriptor>
    /// The edge descriptor is a simple edge between product vertices.
    public typealias EdgeDescriptor = SimpleEdge<VertexDescriptor>

    @usableFromInline let left: G
    @usableFromInline let right: H

    /// Creates a new Cartesian product graph from two factor graphs.
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

extension CartesianProductGraph: VertexListGraph where G: VertexListGraph, H: VertexListGraph {
    /// A sequence of all vertices in the Cartesian product graph.
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

    /// Returns a sequence of all vertices in the Cartesian product.
    @inlinable
    public func vertices() -> Vertices {
        Vertices(leftVertices: Array(left.vertices()), rightVertices: Array(right.vertices()))
    }

    /// The total number of vertices, equal to |V(G)| × |V(H)|.
    @inlinable public var vertexCount: Int { left.vertexCount * right.vertexCount }
}

// MARK: - IncidenceGraph

extension CartesianProductGraph: IncidenceGraph {
    /// A sequence of outgoing edges from a vertex in the Cartesian product graph.
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

        /// Creates an iterator over outgoing edges from this vertex.
        @inlinable public func makeIterator() -> Iterator {
            Iterator(
                vertex: vertex,
                leftIter: leftOutgoing.makeIterator(),
                rightIter: rightOutgoing.makeIterator(),
                left: left,
                right: right
            )
        }

        /// An iterator that first yields G-moves (keep v, advance u), then H-moves (keep u, advance v).
        public struct Iterator: IteratorProtocol {
            @usableFromInline let vertex: Pair<G.VertexDescriptor, H.VertexDescriptor>
            @usableFromInline var leftIter: G.OutgoingEdges.Iterator
            @usableFromInline var rightIter: H.OutgoingEdges.Iterator
            @usableFromInline let left: G
            @usableFromInline let right: H
            @usableFromInline var inHPhase: Bool = false

            @inlinable
            public init(
                vertex: Pair<G.VertexDescriptor, H.VertexDescriptor>,
                leftIter: G.OutgoingEdges.Iterator,
                rightIter: H.OutgoingEdges.Iterator,
                left: G,
                right: H
            ) {
                self.vertex = vertex
                self.leftIter = leftIter
                self.rightIter = rightIter
                self.left = left
                self.right = right
            }

            @inlinable
            public mutating func next() -> SimpleEdge<Pair<G.VertexDescriptor, H.VertexDescriptor>>? {
                if !inHPhase {
                    while let e = leftIter.next() {
                        if let d = left.destination(of: e) {
                            return SimpleEdge(source: vertex, destination: Pair(d, vertex.second))
                        }
                    }
                    inHPhase = true
                }
                guard let e = rightIter.next(), let d = right.destination(of: e) else { return nil }
                return SimpleEdge(source: vertex, destination: Pair(vertex.first, d))
            }
        }
    }

    /// Returns all outgoing edges from the given product vertex.
    @inlinable
    public func outgoingEdges(of vertex: VertexDescriptor) -> OutgoingEdges {
        OutgoingEdges(
            vertex: vertex,
            leftOutgoing: left.outgoingEdges(of: vertex.first),
            rightOutgoing: right.outgoingEdges(of: vertex.second),
            left: left,
            right: right
        )
    }

    /// Returns the source of a product edge.
    @inlinable public func source(of edge: EdgeDescriptor) -> VertexDescriptor? { edge.source }
    /// Returns the destination of a product edge.
    @inlinable public func destination(of edge: EdgeDescriptor) -> VertexDescriptor? { edge.destination }
    /// Returns the out-degree of a product vertex (sum of out-degrees in both factor graphs).
    @inlinable public func outDegree(of vertex: VertexDescriptor) -> Int {
        left.outDegree(of: vertex.first) + right.outDegree(of: vertex.second)
    }
}

// MARK: - BidirectionalGraph

extension CartesianProductGraph: BidirectionalGraph where G: BidirectionalGraph, H: BidirectionalGraph {
    /// A sequence of incoming edges to a vertex in the Cartesian product graph.
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

        /// Creates an iterator over incoming edges to this vertex.
        @inlinable public func makeIterator() -> Iterator {
            Iterator(
                vertex: vertex,
                leftIter: leftIncoming.makeIterator(),
                rightIter: rightIncoming.makeIterator(),
                left: left,
                right: right
            )
        }

        /// An iterator that first yields G-incoming edges, then H-incoming edges.
        public struct Iterator: IteratorProtocol {
            @usableFromInline let vertex: Pair<G.VertexDescriptor, H.VertexDescriptor>
            @usableFromInline var leftIter: G.IncomingEdges.Iterator
            @usableFromInline var rightIter: H.IncomingEdges.Iterator
            @usableFromInline let left: G
            @usableFromInline let right: H
            @usableFromInline var inHPhase: Bool = false

            @inlinable
            public init(
                vertex: Pair<G.VertexDescriptor, H.VertexDescriptor>,
                leftIter: G.IncomingEdges.Iterator,
                rightIter: H.IncomingEdges.Iterator,
                left: G,
                right: H
            ) {
                self.vertex = vertex
                self.leftIter = leftIter
                self.rightIter = rightIter
                self.left = left
                self.right = right
            }

            @inlinable
            public mutating func next() -> SimpleEdge<Pair<G.VertexDescriptor, H.VertexDescriptor>>? {
                if !inHPhase {
                    while let e = leftIter.next() {
                        if let s = left.source(of: e) {
                            return SimpleEdge(source: Pair(s, vertex.second), destination: vertex)
                        }
                    }
                    inHPhase = true
                }
                guard let e = rightIter.next(), let s = right.source(of: e) else { return nil }
                return SimpleEdge(source: Pair(vertex.first, s), destination: vertex)
            }
        }
    }

    /// Returns all incoming edges to the given product vertex.
    @inlinable
    public func incomingEdges(of vertex: VertexDescriptor) -> IncomingEdges {
        IncomingEdges(
            vertex: vertex,
            leftIncoming: left.incomingEdges(of: vertex.first),
            rightIncoming: right.incomingEdges(of: vertex.second),
            left: left,
            right: right
        )
    }

    /// Returns the in-degree of a product vertex (sum of in-degrees in both factor graphs).
    @inlinable public func inDegree(of vertex: VertexDescriptor) -> Int {
        left.inDegree(of: vertex.first) + right.inDegree(of: vertex.second)
    }
}

// MARK: - EdgeListGraph

extension CartesianProductGraph: EdgeListGraph where G: EdgeListGraph & VertexListGraph, H: EdgeListGraph & VertexListGraph {
    /// A sequence of all edges in the Cartesian product graph.
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

        /// Creates an iterator over all edges in the Cartesian product.
        @inlinable public func makeIterator() -> Iterator {
            Iterator(allVertices: allVertices, left: left, right: right)
        }

        /// An iterator that walks each product vertex and yields its outgoing edges.
        public struct Iterator: IteratorProtocol {
            @usableFromInline let allVertices: [Pair<G.VertexDescriptor, H.VertexDescriptor>]
            @usableFromInline let left: G
            @usableFromInline let right: H
            @usableFromInline var vIndex: Int = 0
            @usableFromInline var edgeIter: CartesianProductGraph<G, H>.OutgoingEdges.Iterator?

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
                    let outgoing = CartesianProductGraph<G, H>.OutgoingEdges(
                        vertex: v,
                        leftOutgoing: left.outgoingEdges(of: v.first),
                        rightOutgoing: right.outgoingEdges(of: v.second),
                        left: left,
                        right: right
                    )
                    edgeIter = outgoing.makeIterator()
                }
            }
        }
    }

    /// Returns a sequence of all edges in the Cartesian product.
    @inlinable
    public func edges() -> Edges {
        Edges(allVertices: Array(vertices()), left: left, right: right)
    }

    /// The total number of edges: |E(G)| × |V(H)| + |E(H)| × |V(G)|.
    @inlinable public var edgeCount: Int {
        left.edgeCount * right.vertexCount + right.edgeCount * left.vertexCount
    }
}

// MARK: - Sendable

extension CartesianProductGraph: Sendable where G: Sendable, H: Sendable {}

// MARK: - Convenience

extension IncidenceGraph where VertexDescriptor: Hashable {
    /// Returns a lazy view of the Cartesian product of this graph with another.
    ///
    /// In G □ H, vertex (u,v) connects to (u',v) when u→u' ∈ G, and to (u,v') when v→v' ∈ H.
    /// - Complexity: O(1) to create; O(outDegree) per `outgoingEdges(of:)` call.
    @inlinable
    public func cartesianProduct<H: IncidenceGraph>(with h: H) -> CartesianProductGraph<Self, H>
    where H.VertexDescriptor: Hashable {
        CartesianProductGraph(left: self, right: h)
    }
}
