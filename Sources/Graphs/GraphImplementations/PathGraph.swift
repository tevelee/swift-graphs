#if !GRAPHS_USES_TRAITS || GRAPHS_GRAPH_FAMILIES

    /// A directed path graph P_n with n vertices connected in a line: 0→1→2→…→(n-1).
    ///
    /// Edges are computed on demand; no edge storage is used, so this type requires O(1)
    /// memory regardless of vertex count.
    public struct PathGraph {
        @usableFromInline
        let n: Int

        /// Creates a directed path graph with `n` vertices (0..<n) and n-1 edges.
        @inlinable
        public init(n: Int) {
            precondition(n >= 0, "PathGraph requires a non-negative vertex count")
            self.n = n
        }
    }

    // MARK: - Graph

    extension PathGraph: Graph {
        public typealias VertexDescriptor = Int
        public typealias EdgeDescriptor = SimpleEdge<Int>
    }

    // MARK: - VertexListGraph

    extension PathGraph: VertexListGraph {
        @inlinable
        public func vertices() -> Range<Int> { 0 ..< n }

        @inlinable
        public var vertexCount: Int { n }
    }

    // MARK: - IncidenceGraph

    extension PathGraph: IncidenceGraph {
        /// A sequence of outgoing edges from a vertex in the path graph.
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

            /// An iterator over outgoing edges from a vertex in the path graph.
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
                    guard !done, source >= 0, source < n - 1 else { return nil }
                    done = true
                    return SimpleEdge(source: source, destination: source + 1)
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
            guard vertex >= 0, vertex < n else { return 0 }
            return vertex < n - 1 ? 1 : 0
        }
    }

    // MARK: - BidirectionalGraph

    extension PathGraph: BidirectionalGraph {
        /// A sequence of incoming edges to a vertex in the path graph.
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

            /// An iterator over incoming edges to a vertex in the path graph.
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
                    guard !done, destination > 0, destination < n else { return nil }
                    done = true
                    return SimpleEdge(source: destination - 1, destination: destination)
                }
            }
        }

        @inlinable
        public func incomingEdges(of vertex: Int) -> IncomingEdges {
            IncomingEdges(destination: vertex, n: n)
        }

        @inlinable
        public func inDegree(of vertex: Int) -> Int {
            guard vertex >= 0, vertex < n else { return 0 }
            return vertex > 0 ? 1 : 0
        }
    }

    // MARK: - EdgeListGraph

    extension PathGraph: EdgeListGraph {
        /// A sequence of all edges in the path graph, in order 0→1, 1→2, …
        public struct Edges: Sequence {
            @usableFromInline let n: Int

            @inlinable
            public init(n: Int) { self.n = n }

            @inlinable
            public func makeIterator() -> Iterator { Iterator(n: n) }

            /// An iterator over all edges in the path graph.
            public struct Iterator: IteratorProtocol {
                @usableFromInline let n: Int
                @usableFromInline var current: Int = 0

                @inlinable
                public init(n: Int) { self.n = n }

                @inlinable
                public mutating func next() -> SimpleEdge<Int>? {
                    guard current < n - 1 else { return nil }
                    let edge = SimpleEdge(source: current, destination: current + 1)
                    current += 1
                    return edge
                }
            }
        }

        @inlinable
        public func edges() -> Edges { Edges(n: n) }

        @inlinable
        public var edgeCount: Int { max(0, n - 1) }
    }

    // MARK: - AdjacencyGraph

    extension PathGraph: AdjacencyGraph {
        /// A sequence of adjacent vertices to a given vertex in the path graph.
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

            /// An iterator over adjacent vertices in the path graph.
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
                    guard !done, vertex >= 0, vertex < n - 1 else { return nil }
                    done = true
                    return vertex + 1
                }
            }
        }

        @inlinable
        public func adjacentVertices(of vertex: Int) -> AdjacentVertices {
            AdjacentVertices(vertex: vertex, n: n)
        }
    }

    // MARK: - EdgeLookupGraph

    extension PathGraph: EdgeLookupGraph {
        /// Returns the directed edge u→v if v == u+1 and both are valid vertices; nil otherwise.
        @inlinable
        public func edge(from source: Int, to destination: Int) -> SimpleEdge<Int>? {
            guard source >= 0, source < n - 1, destination == source + 1 else { return nil }
            return SimpleEdge(source: source, destination: destination)
        }
    }

    extension PathGraph: Sendable {}

#endif
