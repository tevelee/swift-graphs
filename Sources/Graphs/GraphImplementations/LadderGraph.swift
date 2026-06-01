#if !GRAPHS_USES_TRAITS || GRAPHS_GRAPH_FAMILIES

    /// A directed ladder graph with 2n vertices arranged as two parallel paths joined by rungs.
    ///
    /// The top row is vertices `0..<n` and the bottom row is vertices `n..<2n`.
    /// - Top path edges: i → i+1 for i in 0..<(n-1)
    /// - Bottom path edges: (n+i) → (n+i+1) for i in 0..<(n-1)
    /// - Rung edges: i → n+i for i in 0..<n
    ///
    /// Total vertices: 2n, total edges: 3n-2. Edges are computed on demand so this type
    /// requires O(1) memory regardless of vertex count.
    public struct LadderGraph {
        @usableFromInline
        let n: Int

        /// Creates a directed ladder graph with `n` vertices per rail (2n total vertices).
        /// - Precondition: n >= 1
        @inlinable
        public init(n: Int) {
            precondition(n >= 1, "LadderGraph requires at least 1 vertex per rail")
            self.n = n
        }
    }

    // MARK: - Graph

    extension LadderGraph: Graph {
        public typealias VertexDescriptor = Int
        public typealias EdgeDescriptor = SimpleEdge<Int>
    }

    // MARK: - VertexListGraph

    extension LadderGraph: VertexListGraph {
        @inlinable
        public func vertices() -> Range<Int> { 0 ..< (2 * n) }

        @inlinable
        public var vertexCount: Int { 2 * n }
    }

    // MARK: - IncidenceGraph

    extension LadderGraph: IncidenceGraph {
        /// A sequence of outgoing edges from a vertex in the ladder graph.
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

            /// An iterator over outgoing edges from a vertex in the ladder graph.
            public struct Iterator: IteratorProtocol {
                @usableFromInline let source: Int
                @usableFromInline let n: Int
                // phase 0: path edge, phase 1: rung edge
                @usableFromInline var phase: Int = 0

                @inlinable
                public init(source: Int, n: Int) {
                    self.source = source
                    self.n = n
                }

                @inlinable
                public mutating func next() -> SimpleEdge<Int>? {
                    guard source >= 0, source < 2 * n else { return nil }
                    if phase == 0 {
                        phase = 1
                        // Path edge: top i→i+1 or bottom (n+i)→(n+i+1)
                        if source < n - 1 {
                            return SimpleEdge(source: source, destination: source + 1)
                        } else if source >= n, source < 2 * n - 1 {
                            return SimpleEdge(source: source, destination: source + 1)
                        }
                        // Last vertex in each rail has no path successor; fall through to rung
                    }
                    if phase == 1 {
                        phase = 2
                        // Rung: top vertex i → bottom vertex n+i
                        if source < n {
                            return SimpleEdge(source: source, destination: source + n)
                        }
                    }
                    return nil
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
            guard vertex >= 0, vertex < 2 * n else { return 0 }
            guard vertex < n else {
                // Bottom rail: path edge only (if not last)
                return (vertex < 2 * n - 1) ? 1 : 0
            }
            // Top rail: path edge (if not last) + rung = 1 or 2
            return (vertex < n - 1) ? 2 : 1
        }
    }

    // MARK: - BidirectionalGraph

    extension LadderGraph: BidirectionalGraph {
        /// A sequence of incoming edges to a vertex in the ladder graph.
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

            /// An iterator over incoming edges to a vertex in the ladder graph.
            public struct Iterator: IteratorProtocol {
                @usableFromInline let destination: Int
                @usableFromInline let n: Int
                // phase 0: rung (bottom vertices only), phase 1: path predecessor
                @usableFromInline var phase: Int = 0

                @inlinable
                public init(destination: Int, n: Int) {
                    self.destination = destination
                    self.n = n
                }

                @inlinable
                public mutating func next() -> SimpleEdge<Int>? {
                    guard destination >= 0, destination < 2 * n else { return nil }
                    if phase == 0 {
                        phase = 1
                        // Bottom vertices receive a rung from the corresponding top vertex
                        if destination >= n {
                            return SimpleEdge(source: destination - n, destination: destination)
                        }
                    }
                    if phase == 1 {
                        phase = 2
                        // Top path predecessor: top i receives from i-1 (if i > 0)
                        if destination > 0, destination < n {
                            return SimpleEdge(source: destination - 1, destination: destination)
                        }
                        // Bottom path predecessor: n+i receives from n+i-1 (if i > 0)
                        if destination > n {
                            return SimpleEdge(source: destination - 1, destination: destination)
                        }
                    }
                    return nil
                }
            }
        }

        @inlinable
        public func incomingEdges(of vertex: Int) -> IncomingEdges {
            IncomingEdges(destination: vertex, n: n)
        }

        @inlinable
        public func inDegree(of vertex: Int) -> Int {
            guard vertex >= 0, vertex < 2 * n else { return 0 }
            guard vertex < n else {
                // Bottom rail: rung always + path predecessor (first bottom has none)
                return vertex > n ? 2 : 1
            }
            // Top rail: path predecessor only (first has none)
            return vertex > 0 ? 1 : 0
        }
    }

    // MARK: - EdgeListGraph

    extension LadderGraph: EdgeListGraph {
        /// A sequence of all 3n-2 directed edges: top path, bottom path, then rungs.
        public struct Edges: Sequence {
            @usableFromInline let n: Int

            @inlinable
            public init(n: Int) { self.n = n }

            @inlinable
            public func makeIterator() -> Iterator { Iterator(n: n) }

            /// An iterator over all edges in the ladder graph.
            public struct Iterator: IteratorProtocol {
                @usableFromInline let n: Int
                // 0..<(n-1): top path; (n-1)..<(2n-2): bottom path; (2n-2)..<(3n-2): rungs
                @usableFromInline var index: Int = 0

                @inlinable
                public init(n: Int) { self.n = n }

                @inlinable
                public mutating func next() -> SimpleEdge<Int>? {
                    if index < n - 1 {
                        // Top path: index → index+1
                        let edge = SimpleEdge(source: index, destination: index + 1)
                        index += 1
                        return edge
                    } else if index < 2 * (n - 1) {
                        // Bottom path: (n + i) → (n + i + 1)
                        let i = index - (n - 1)
                        let edge = SimpleEdge(source: n + i, destination: n + i + 1)
                        index += 1
                        return edge
                    } else if index < 3 * n - 2 {
                        // Rungs: i → n+i
                        let i = index - 2 * (n - 1)
                        let edge = SimpleEdge(source: i, destination: n + i)
                        index += 1
                        return edge
                    }
                    return nil
                }
            }
        }

        @inlinable
        public func edges() -> Edges { Edges(n: n) }

        @inlinable
        public var edgeCount: Int { 3 * n - 2 }
    }

    // MARK: - AdjacencyGraph

    extension LadderGraph: AdjacencyGraph {
        /// A sequence of adjacent (successor) vertices to a given vertex in the ladder graph.
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

            /// An iterator over adjacent vertices in the ladder graph.
            public struct Iterator: IteratorProtocol {
                @usableFromInline let vertex: Int
                @usableFromInline let n: Int
                @usableFromInline var phase: Int = 0

                @inlinable
                public init(vertex: Int, n: Int) {
                    self.vertex = vertex
                    self.n = n
                }

                @inlinable
                public mutating func next() -> Int? {
                    guard vertex >= 0, vertex < 2 * n else { return nil }
                    if phase == 0 {
                        phase = 1
                        if vertex < n - 1 { return vertex + 1 }
                        if vertex >= n, vertex < 2 * n - 1 { return vertex + 1 }
                    }
                    if phase == 1 {
                        phase = 2
                        if vertex < n { return vertex + n }
                    }
                    return nil
                }
            }
        }

        @inlinable
        public func adjacentVertices(of vertex: Int) -> AdjacentVertices {
            AdjacentVertices(vertex: vertex, n: n)
        }
    }

    // MARK: - EdgeLookupGraph

    extension LadderGraph: EdgeLookupGraph {
        /// Returns the edge u→v if it exists in the ladder graph; nil otherwise.
        @inlinable
        public func edge(from source: Int, to destination: Int) -> SimpleEdge<Int>? {
            guard source >= 0, source < 2 * n else { return nil }
            // Top path edge
            if source < n - 1, destination == source + 1 {
                return SimpleEdge(source: source, destination: destination)
            }
            // Bottom path edge
            if source >= n, source < 2 * n - 1, destination == source + 1 {
                return SimpleEdge(source: source, destination: destination)
            }
            // Rung
            if source < n, destination == source + n {
                return SimpleEdge(source: source, destination: destination)
            }
            return nil
        }
    }

    extension LadderGraph: Sendable {}

#endif
