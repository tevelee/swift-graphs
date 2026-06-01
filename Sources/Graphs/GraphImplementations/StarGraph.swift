#if !GRAPHS_USES_TRAITS || GRAPHS_GRAPH_FAMILIES

    /// A directed star graph S_n with a hub vertex n and n leaf vertices 0..<n.
    ///
    /// The hub vertex is `n` and the leaves are `0..<n`. All directed edges go from the hub to
    /// each leaf; leaves have no outgoing edges. Edges are computed on demand so this type
    /// requires O(1) memory regardless of vertex count.
    public struct StarGraph {
        @usableFromInline
        let n: Int

        /// Creates a directed star graph with `n` leaf vertices (0..<n) and hub vertex `n`.
        /// Total vertices: n+1, total edges: n.
        @inlinable
        public init(n: Int) {
            precondition(n >= 0, "StarGraph requires a non-negative leaf count")
            self.n = n
        }

        /// The hub (center) vertex index.
        @inlinable
        public var center: Int { n }
    }

    // MARK: - Graph

    extension StarGraph: Graph {
        public typealias VertexDescriptor = Int
        public typealias EdgeDescriptor = SimpleEdge<Int>
    }

    // MARK: - VertexListGraph

    extension StarGraph: VertexListGraph {
        @inlinable
        public func vertices() -> Range<Int> { 0 ..< (n + 1) }

        @inlinable
        public var vertexCount: Int { n + 1 }
    }

    // MARK: - IncidenceGraph

    extension StarGraph: IncidenceGraph {
        /// A sequence of outgoing edges from a vertex in the star graph.
        public struct OutgoingEdges: Sequence {
            @usableFromInline let source: Int
            @usableFromInline let n: Int

            @inlinable
            public init(source: Int, n: Int) {
                self.source = source
                self.n = n
            }

            @inlinable
            public func makeIterator() -> Iterator { Iterator(source: source, n: n) }

            /// An iterator over outgoing edges from a vertex in the star graph.
            public struct Iterator: IteratorProtocol {
                @usableFromInline let source: Int
                @usableFromInline let n: Int
                @usableFromInline var leaf: Int = 0

                @inlinable
                public init(source: Int, n: Int) {
                    self.source = source
                    self.n = n
                }

                @inlinable
                public mutating func next() -> SimpleEdge<Int>? {
                    // Only the hub (vertex n) emits edges
                    guard source == n, leaf < n else { return nil }
                    let edge = SimpleEdge(source: source, destination: leaf)
                    leaf += 1
                    return edge
                }
            }
        }

        @inlinable
        public func outgoingEdges(of vertex: Int) -> OutgoingEdges {
            OutgoingEdges(source: vertex, n: n)
        }

        @inlinable
        public func source(of edge: SimpleEdge<Int>) -> Int? { edge.source }

        @inlinable
        public func destination(of edge: SimpleEdge<Int>) -> Int? { edge.destination }

        @inlinable
        public func outDegree(of vertex: Int) -> Int {
            vertex == n ? n : 0
        }
    }

    // MARK: - BidirectionalGraph

    extension StarGraph: BidirectionalGraph {
        /// A sequence of incoming edges to a vertex in the star graph.
        public struct IncomingEdges: Sequence {
            @usableFromInline let destination: Int
            @usableFromInline let n: Int

            @inlinable
            public init(destination: Int, n: Int) {
                self.destination = destination
                self.n = n
            }

            @inlinable
            public func makeIterator() -> Iterator { Iterator(destination: destination, n: n) }

            /// An iterator over incoming edges to a vertex in the star graph.
            public struct Iterator: IteratorProtocol {
                @usableFromInline let destination: Int
                @usableFromInline let n: Int
                @usableFromInline var done: Bool = false

                @inlinable
                public init(destination: Int, n: Int) {
                    self.destination = destination
                    self.n = n
                }

                @inlinable
                public mutating func next() -> SimpleEdge<Int>? {
                    // Only leaf vertices (0..<n) receive an edge from the hub
                    guard !done, destination >= 0, destination < n else { return nil }
                    done = true
                    return SimpleEdge(source: n, destination: destination)
                }
            }
        }

        @inlinable
        public func incomingEdges(of vertex: Int) -> IncomingEdges {
            IncomingEdges(destination: vertex, n: n)
        }

        @inlinable
        public func inDegree(of vertex: Int) -> Int {
            vertex >= 0 && vertex < n ? 1 : 0
        }
    }

    // MARK: - EdgeListGraph

    extension StarGraph: EdgeListGraph {
        /// A sequence of all n directed edges from the hub to each leaf.
        public struct Edges: Sequence {
            @usableFromInline let n: Int

            @inlinable
            public init(n: Int) { self.n = n }

            @inlinable
            public func makeIterator() -> Iterator { Iterator(n: n) }

            /// An iterator over all edges in the star graph.
            public struct Iterator: IteratorProtocol {
                @usableFromInline let n: Int
                @usableFromInline var leaf: Int = 0

                @inlinable
                public init(n: Int) { self.n = n }

                @inlinable
                public mutating func next() -> SimpleEdge<Int>? {
                    guard leaf < n else { return nil }
                    let edge = SimpleEdge(source: n, destination: leaf)
                    leaf += 1
                    return edge
                }
            }
        }

        @inlinable
        public func edges() -> Edges { Edges(n: n) }

        @inlinable
        public var edgeCount: Int { n }
    }

    // MARK: - AdjacencyGraph

    extension StarGraph: AdjacencyGraph {
        /// A sequence of adjacent vertices to a given vertex in the star graph.
        public struct AdjacentVertices: Sequence {
            @usableFromInline let vertex: Int
            @usableFromInline let n: Int

            @inlinable
            public init(vertex: Int, n: Int) {
                self.vertex = vertex
                self.n = n
            }

            @inlinable
            public func makeIterator() -> Iterator { Iterator(vertex: vertex, n: n) }

            /// An iterator over adjacent vertices in the star graph.
            public struct Iterator: IteratorProtocol {
                @usableFromInline let vertex: Int
                @usableFromInline let n: Int
                @usableFromInline var leaf: Int = 0

                @inlinable
                public init(vertex: Int, n: Int) {
                    self.vertex = vertex
                    self.n = n
                }

                @inlinable
                public mutating func next() -> Int? {
                    guard vertex == n, leaf < n else { return nil }
                    let result = leaf
                    leaf += 1
                    return result
                }
            }
        }

        @inlinable
        public func adjacentVertices(of vertex: Int) -> AdjacentVertices {
            AdjacentVertices(vertex: vertex, n: n)
        }
    }

    // MARK: - EdgeLookupGraph

    extension StarGraph: EdgeLookupGraph {
        /// Returns the edge from hub to `destination` if destination is a valid leaf; nil otherwise.
        @inlinable
        public func edge(from source: Int, to destination: Int) -> SimpleEdge<Int>? {
            guard source == n, destination >= 0, destination < n else { return nil }
            return SimpleEdge(source: source, destination: destination)
        }
    }

    extension StarGraph: Sendable {}

#endif
