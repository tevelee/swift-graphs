#if !GRAPHS_USES_TRAITS || GRAPHS_GRAPH_FAMILIES

    /// A directed hypercube graph Q_d (d-dimensional Boolean lattice).
    ///
    /// Vertices are integers `0..<(1<<d)` representing d-bit binary strings. There is a directed
    /// edge from `u` to `v` iff `v = u | (1 << k)` for some bit position `k` (i.e. v has exactly
    /// one more bit set than u). This gives a directed acyclic graph. When used with
    /// `UndirectedGraphView`, you get the standard undirected hypercube.
    ///
    /// - For dimension d, there are 2^d vertices and d * 2^(d-1) directed edges.
    /// - Edges are computed on demand; no edge storage is used, so this type requires O(1) memory.
    public struct HypercubeGraph {
        @usableFromInline
        let dimension: Int

        /// Creates a d-dimensional hypercube graph with `2^d` vertices and `d * 2^(d-1)` edges.
        @inlinable
        public init(dimension d: Int) {
            precondition(d >= 0, "HypercubeGraph requires a non-negative dimension")
            precondition(d < Int.bitWidth - 1, "HypercubeGraph dimension \(d) would overflow Int on this platform (max \(Int.bitWidth - 2))")
            self.dimension = d
        }
    }

    // MARK: - Graph

    extension HypercubeGraph: Graph {
        public typealias VertexDescriptor = Int
        public typealias EdgeDescriptor = SimpleEdge<Int>
    }

    // MARK: - VertexListGraph

    extension HypercubeGraph: VertexListGraph {
        @inlinable
        public func vertices() -> Range<Int> { 0 ..< (1 << dimension) }

        @inlinable
        public var vertexCount: Int { 1 << dimension }
    }

    // MARK: - IncidenceGraph

    extension HypercubeGraph: IncidenceGraph {
        /// A sequence of outgoing edges from a vertex in the hypercube graph.
        public struct OutgoingEdges: Sequence {
            @usableFromInline let source: Int
            @usableFromInline let dimension: Int

            @inlinable
            public init(source: Int, dimension: Int) {
                self.source = source
                self.dimension = dimension
            }

            @inlinable
            public func makeIterator() -> Iterator { Iterator(source: source, dimension: dimension) }

            /// An iterator over outgoing edges from a vertex in the hypercube graph.
            public struct Iterator: IteratorProtocol {
                @usableFromInline let source: Int
                @usableFromInline let dimension: Int
                @usableFromInline var bit: Int = 0

                @inlinable
                public init(source: Int, dimension: Int) {
                    self.source = source
                    self.dimension = dimension
                }

                @inlinable
                public mutating func next() -> SimpleEdge<Int>? {
                    while bit < dimension {
                        let mask = 1 << bit
                        bit += 1
                        // Only emit edge when we're flipping a 0-bit to 1 (upward direction)
                        if source & mask == 0 {
                            return SimpleEdge(source: source, destination: source | mask)
                        }
                    }
                    return nil
                }
            }
        }

        @inlinable
        public func outgoingEdges(of vertex: Int) -> OutgoingEdges {
            OutgoingEdges(source: vertex, dimension: dimension)
        }

        @inlinable
        public func source(of edge: SimpleEdge<Int>) -> Int? { edge.source }

        @inlinable
        public func destination(of edge: SimpleEdge<Int>) -> Int? { edge.destination }

        @inlinable
        public func outDegree(of vertex: Int) -> Int {
            guard vertex >= 0, vertex < (1 << dimension) else { return 0 }
            // Number of 0-bits in vertex (positions we can flip to 1)
            return dimension - vertex.nonzeroBitCount
        }
    }

    // MARK: - BidirectionalGraph

    extension HypercubeGraph: BidirectionalGraph {
        /// A sequence of incoming edges to a vertex in the hypercube graph.
        public struct IncomingEdges: Sequence {
            @usableFromInline let destination: Int
            @usableFromInline let dimension: Int

            @inlinable
            public init(destination: Int, dimension: Int) {
                self.destination = destination
                self.dimension = dimension
            }

            @inlinable
            public func makeIterator() -> Iterator { Iterator(destination: destination, dimension: dimension) }

            /// An iterator over incoming edges to a vertex in the hypercube graph.
            public struct Iterator: IteratorProtocol {
                @usableFromInline let destination: Int
                @usableFromInline let dimension: Int
                @usableFromInline var bit: Int = 0

                @inlinable
                public init(destination: Int, dimension: Int) {
                    self.destination = destination
                    self.dimension = dimension
                }

                @inlinable
                public mutating func next() -> SimpleEdge<Int>? {
                    while bit < dimension {
                        let mask = 1 << bit
                        bit += 1
                        // Only receive edge from a vertex with one fewer set bit (downward direction)
                        if destination & mask != 0 {
                            let src = destination & ~mask
                            return SimpleEdge(source: src, destination: destination)
                        }
                    }
                    return nil
                }
            }
        }

        @inlinable
        public func incomingEdges(of vertex: Int) -> IncomingEdges {
            IncomingEdges(destination: vertex, dimension: dimension)
        }

        @inlinable
        public func inDegree(of vertex: Int) -> Int {
            guard vertex >= 0, vertex < (1 << dimension) else { return 0 }
            // Number of 1-bits (positions we can flip from 1 to 0 for incoming)
            return vertex.nonzeroBitCount
        }
    }

    // MARK: - EdgeListGraph

    extension HypercubeGraph: EdgeListGraph {
        /// A sequence of all d * 2^(d-1) directed edges in the hypercube.
        public struct Edges: Sequence {
            @usableFromInline let dimension: Int

            @inlinable
            public init(dimension: Int) { self.dimension = dimension }

            @inlinable
            public func makeIterator() -> Iterator { Iterator(dimension: dimension) }

            /// An iterator over all edges in the hypercube graph.
            public struct Iterator: IteratorProtocol {
                @usableFromInline let dimension: Int
                @usableFromInline var vertex: Int = 0
                @usableFromInline var bit: Int = 0

                @inlinable
                public init(dimension: Int) { self.dimension = dimension }

                @inlinable
                public mutating func next() -> SimpleEdge<Int>? {
                    let total = 1 << dimension
                    while vertex < total {
                        while bit < dimension {
                            let mask = 1 << bit
                            bit += 1
                            if vertex & mask == 0 {
                                return SimpleEdge(source: vertex, destination: vertex | mask)
                            }
                        }
                        vertex += 1
                        bit = 0
                    }
                    return nil
                }
            }
        }

        @inlinable
        public func edges() -> Edges { Edges(dimension: dimension) }

        @inlinable
        public var edgeCount: Int {
            guard dimension > 0 else { return 0 }
            return dimension * (1 << (dimension - 1))
        }
    }

    // MARK: - AdjacencyGraph

    extension HypercubeGraph: AdjacencyGraph {
        /// A sequence of adjacent (successor) vertices to a given vertex in the hypercube.
        public struct AdjacentVertices: Sequence {
            @usableFromInline let vertex: Int
            @usableFromInline let dimension: Int

            @inlinable
            public init(vertex: Int, dimension: Int) {
                self.vertex = vertex
                self.dimension = dimension
            }

            @inlinable
            public func makeIterator() -> Iterator { Iterator(vertex: vertex, dimension: dimension) }

            /// An iterator over adjacent vertices in the hypercube graph.
            public struct Iterator: IteratorProtocol {
                @usableFromInline let vertex: Int
                @usableFromInline let dimension: Int
                @usableFromInline var bit: Int = 0

                @inlinable
                public init(vertex: Int, dimension: Int) {
                    self.vertex = vertex
                    self.dimension = dimension
                }

                @inlinable
                public mutating func next() -> Int? {
                    while bit < dimension {
                        let mask = 1 << bit
                        bit += 1
                        if vertex & mask == 0 {
                            return vertex | mask
                        }
                    }
                    return nil
                }
            }
        }

        @inlinable
        public func adjacentVertices(of vertex: Int) -> AdjacentVertices {
            AdjacentVertices(vertex: vertex, dimension: dimension)
        }
    }

    // MARK: - EdgeLookupGraph

    extension HypercubeGraph: EdgeLookupGraph {
        /// Returns the edge u→v if their XOR is a power of 2 with v > u (i.e. v has one more set bit); nil otherwise.
        @inlinable
        public func edge(from source: Int, to destination: Int) -> SimpleEdge<Int>? {
            guard source >= 0, source < (1 << dimension) else { return nil }
            guard destination >= 0, destination < (1 << dimension) else { return nil }
            let xor = source ^ destination
            // xor must be a power of 2 AND destination must have the bit set (upward direction)
            guard xor != 0, (xor & (xor - 1)) == 0, destination & xor != 0 else { return nil }
            return SimpleEdge(source: source, destination: destination)
        }
    }

    extension HypercubeGraph: Sendable {}

#endif
