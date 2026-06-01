#if !GRAPHS_USES_TRAITS || GRAPHS_GRAPH_FAMILIES

    /// A directed cycle graph C_n with n vertices connected in a ring: 0→1→2→…→(n-1)→0.
    ///
    /// Edges are computed on demand; no edge storage is used, so this type requires O(1)
    /// memory regardless of vertex count.
    public struct CycleGraph {
        @usableFromInline
        let n: Int

        /// Creates a directed cycle graph with `n` vertices (0..<n) and n edges.
        /// - Precondition: n >= 1
        @inlinable
        public init(n: Int) {
            precondition(n >= 1, "CycleGraph requires at least 1 vertex")
            self.n = n
        }
    }

    // MARK: - Graph

    extension CycleGraph: Graph {
        public typealias VertexDescriptor = Int
        public typealias EdgeDescriptor = SimpleEdge<Int>
    }

    // MARK: - VertexListGraph

    extension CycleGraph: VertexListGraph {
        @inlinable
        public func vertices() -> Range<Int> { 0 ..< n }

        @inlinable
        public var vertexCount: Int { n }
    }

    // MARK: - IncidenceGraph

    extension CycleGraph: IncidenceGraph {
        /// A sequence of outgoing edges from a vertex in the cycle graph.
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

            /// An iterator over outgoing edges from a vertex in the cycle graph.
            public struct Iterator: IteratorProtocol {
                @usableFromInline let source: Int
                @usableFromInline let n: Int
                @usableFromInline var done: Bool = false

                @inlinable
                public init(source: Int, n: Int) {
                    self.source = source
                    self.n = n
                }

                @inlinable
                public mutating func next() -> SimpleEdge<Int>? {
                    guard !done, source >= 0, source < n else { return nil }
                    done = true
                    return SimpleEdge(source: source, destination: (source + 1) % n)
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
            vertex >= 0 && vertex < n ? 1 : 0
        }
    }

    // MARK: - BidirectionalGraph

    extension CycleGraph: BidirectionalGraph {
        /// A sequence of incoming edges to a vertex in the cycle graph.
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

            /// An iterator over incoming edges to a vertex in the cycle graph.
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
                    guard !done, destination >= 0, destination < n else { return nil }
                    done = true
                    let src = (destination + n - 1) % n
                    return SimpleEdge(source: src, destination: destination)
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

    extension CycleGraph: EdgeListGraph {
        /// A sequence of all n directed edges in the cycle graph.
        public struct Edges: Sequence {
            @usableFromInline let n: Int

            @inlinable
            public init(n: Int) { self.n = n }

            @inlinable
            public func makeIterator() -> Iterator { Iterator(n: n) }

            /// An iterator over all edges in the cycle graph.
            public struct Iterator: IteratorProtocol {
                @usableFromInline let n: Int
                @usableFromInline var current: Int = 0

                @inlinable
                public init(n: Int) { self.n = n }

                @inlinable
                public mutating func next() -> SimpleEdge<Int>? {
                    guard current < n else { return nil }
                    let edge = SimpleEdge(source: current, destination: (current + 1) % n)
                    current += 1
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

    extension CycleGraph: AdjacencyGraph {
        /// A sequence of adjacent vertices to a given vertex in the cycle graph.
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

            /// An iterator over adjacent vertices in the cycle graph.
            public struct Iterator: IteratorProtocol {
                @usableFromInline let vertex: Int
                @usableFromInline let n: Int
                @usableFromInline var done: Bool = false

                @inlinable
                public init(vertex: Int, n: Int) {
                    self.vertex = vertex
                    self.n = n
                }

                @inlinable
                public mutating func next() -> Int? {
                    guard !done, vertex >= 0, vertex < n else { return nil }
                    done = true
                    return (vertex + 1) % n
                }
            }
        }

        @inlinable
        public func adjacentVertices(of vertex: Int) -> AdjacentVertices {
            AdjacentVertices(vertex: vertex, n: n)
        }
    }

    // MARK: - EdgeLookupGraph

    extension CycleGraph: EdgeLookupGraph {
        /// Returns the directed edge u→v if v == (u+1) % n and both are valid; nil otherwise.
        @inlinable
        public func edge(from source: Int, to destination: Int) -> SimpleEdge<Int>? {
            guard source >= 0, source < n, destination == (source + 1) % n else { return nil }
            return SimpleEdge(source: source, destination: destination)
        }
    }

    extension CycleGraph: Sendable {}

#endif
