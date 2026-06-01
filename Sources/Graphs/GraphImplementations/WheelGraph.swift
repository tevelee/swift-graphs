#if !GRAPHS_USES_TRAITS || GRAPHS_GRAPH_FAMILIES

    /// A directed wheel graph W_n with n rim vertices (0..<n) and one hub vertex n.
    ///
    /// The hub vertex `n` has directed edges to every rim vertex (spoke edges), and
    /// the rim vertices form a directed cycle 0→1→2→…→(n-1)→0.
    /// Total vertices: n+1, total edges: 2n. Edges are computed on demand so this type
    /// requires O(1) memory.
    public struct WheelGraph {
        @usableFromInline
        let n: Int

        /// Creates a directed wheel graph with `n` rim vertices (0..<n) and hub vertex `n`.
        /// - Precondition: n >= 3 for a geometrically valid wheel
        @inlinable
        public init(n: Int) {
            precondition(n >= 1, "WheelGraph requires at least 1 rim vertex")
            self.n = n
        }

        /// The hub vertex index.
        @inlinable
        public var hub: Int { n }
    }

    // MARK: - Graph

    extension WheelGraph: Graph {
        public typealias VertexDescriptor = Int
        public typealias EdgeDescriptor = SimpleEdge<Int>
    }

    // MARK: - VertexListGraph

    extension WheelGraph: VertexListGraph {
        @inlinable
        public func vertices() -> Range<Int> { 0 ..< (n + 1) }

        @inlinable
        public var vertexCount: Int { n + 1 }
    }

    // MARK: - IncidenceGraph

    extension WheelGraph: IncidenceGraph {
        /// A sequence of outgoing edges from a vertex in the wheel graph.
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

            /// An iterator over outgoing edges from a vertex in the wheel graph.
            public struct Iterator: IteratorProtocol {
                @usableFromInline let source: Int
                @usableFromInline let n: Int
                // For hub: index runs 0..<n (spoke targets)
                // For rim: index 0 = cycle edge, done after that
                @usableFromInline var index: Int = 0

                @inlinable
                public init(source: Int, n: Int) {
                    self.source = source
                    self.n = n
                }

                @inlinable
                public mutating func next() -> SimpleEdge<Int>? {
                    if source == n {
                        // Hub: emit spoke to each rim vertex
                        guard index < n else { return nil }
                        let edge = SimpleEdge(source: source, destination: index)
                        index += 1
                        return edge
                    } else if source >= 0, source < n {
                        // Rim vertex: one cycle edge
                        guard index == 0 else { return nil }
                        index = 1
                        return SimpleEdge(source: source, destination: (source + 1) % n)
                    } else {
                        return nil
                    }
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
            if vertex == n { return n }  // hub → all rim
            if vertex >= 0, vertex < n { return 1 }  // rim → next rim
            return 0
        }
    }

    // MARK: - BidirectionalGraph

    extension WheelGraph: BidirectionalGraph {
        /// A sequence of incoming edges to a vertex in the wheel graph.
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

            /// An iterator over incoming edges to a vertex in the wheel graph.
            public struct Iterator: IteratorProtocol {
                @usableFromInline let destination: Int
                @usableFromInline let n: Int
                // 0 = spoke from hub, 1 = cycle predecessor
                @usableFromInline var phase: Int = 0

                @inlinable
                public init(destination: Int, n: Int) {
                    self.destination = destination
                    self.n = n
                }

                @inlinable
                public mutating func next() -> SimpleEdge<Int>? {
                    guard destination >= 0, destination < n else { return nil }
                    if phase == 0 {
                        phase = 1
                        // Spoke from hub
                        return SimpleEdge(source: n, destination: destination)
                    } else if phase == 1 {
                        phase = 2
                        // Cycle predecessor
                        let predecessor = (destination + n - 1) % n
                        return SimpleEdge(source: predecessor, destination: destination)
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
            // Hub has no incoming edges; rim vertices have 2 (spoke + cycle predecessor)
            if vertex >= 0, vertex < n { return 2 }
            return 0
        }
    }

    // MARK: - EdgeListGraph

    extension WheelGraph: EdgeListGraph {
        /// A sequence of all 2n directed edges: spokes first, then cycle.
        public struct Edges: Sequence {
            @usableFromInline let n: Int

            @inlinable
            public init(n: Int) { self.n = n }

            @inlinable
            public func makeIterator() -> Iterator { Iterator(n: n) }

            /// An iterator over all edges in the wheel graph.
            public struct Iterator: IteratorProtocol {
                @usableFromInline let n: Int
                // 0..<n: spoke edges (hub→rim[i]); n..<2n: cycle edges
                @usableFromInline var index: Int = 0

                @inlinable
                public init(n: Int) { self.n = n }

                @inlinable
                public mutating func next() -> SimpleEdge<Int>? {
                    if index < n {
                        // Spoke: hub → rim[index]
                        let edge = SimpleEdge(source: n, destination: index)
                        index += 1
                        return edge
                    } else if index < 2 * n {
                        // Cycle
                        let rim = index - n
                        let edge = SimpleEdge(source: rim, destination: (rim + 1) % n)
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
        public var edgeCount: Int { 2 * n }
    }

    // MARK: - AdjacencyGraph

    extension WheelGraph: AdjacencyGraph {
        /// A sequence of adjacent (successor) vertices to a given vertex in the wheel graph.
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

            /// An iterator over adjacent vertices in the wheel graph.
            public struct Iterator: IteratorProtocol {
                @usableFromInline let vertex: Int
                @usableFromInline let n: Int
                @usableFromInline var index: Int = 0

                @inlinable
                public init(vertex: Int, n: Int) {
                    self.vertex = vertex
                    self.n = n
                }

                @inlinable
                public mutating func next() -> Int? {
                    if vertex == n {
                        guard index < n else { return nil }
                        let result = index
                        index += 1
                        return result
                    } else if vertex >= 0, vertex < n {
                        guard index == 0 else { return nil }
                        index = 1
                        return (vertex + 1) % n
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

    extension WheelGraph: EdgeLookupGraph {
        /// Returns the edge u→v if it exists in the wheel graph; nil otherwise.
        @inlinable
        public func edge(from source: Int, to destination: Int) -> SimpleEdge<Int>? {
            if source == n {
                // Spoke: hub → rim
                guard destination >= 0, destination < n else { return nil }
                return SimpleEdge(source: source, destination: destination)
            } else if source >= 0, source < n {
                // Cycle edge
                guard destination == (source + 1) % n else { return nil }
                return SimpleEdge(source: source, destination: destination)
            }
            return nil
        }
    }

    extension WheelGraph: Sendable {}

#endif
