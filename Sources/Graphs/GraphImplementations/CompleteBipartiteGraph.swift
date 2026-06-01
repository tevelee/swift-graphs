#if !GRAPHS_USES_TRAITS || GRAPHS_GRAPH_FAMILIES

    /// A directed complete bipartite graph K_{m,n} with m left vertices and n right vertices.
    ///
    /// Left vertices are `0..<m` and right vertices are `m..<(m+n)`. Every left vertex has a
    /// directed edge to every right vertex. Edges are computed on demand so this type requires
    /// O(1) memory regardless of vertex counts.
    public struct CompleteBipartiteGraph {
        @usableFromInline
        let m: Int
        @usableFromInline
        let n: Int

        /// Creates a directed complete bipartite graph K_{m,n}.
        ///
        /// - Parameters:
        ///   - m: The number of left vertices (indices 0..<m).
        ///   - n: The number of right vertices (indices m..<m+n).
        @inlinable
        public init(m: Int, n: Int) {
            precondition(m >= 0, "CompleteBipartiteGraph requires non-negative m")
            precondition(n >= 0, "CompleteBipartiteGraph requires non-negative n")
            self.m = m
            self.n = n
        }
    }

    // MARK: - Graph

    extension CompleteBipartiteGraph: Graph {
        public typealias VertexDescriptor = Int
        public typealias EdgeDescriptor = SimpleEdge<Int>
    }

    // MARK: - VertexListGraph

    extension CompleteBipartiteGraph: VertexListGraph {
        @inlinable
        public func vertices() -> Range<Int> { 0 ..< (m + n) }

        @inlinable
        public var vertexCount: Int { m + n }
    }

    // MARK: - IncidenceGraph

    extension CompleteBipartiteGraph: IncidenceGraph {
        /// A sequence of outgoing edges from a vertex in the complete bipartite graph.
        public struct OutgoingEdges: Sequence {
            @usableFromInline let source: Int
            @usableFromInline let m: Int
            @usableFromInline let n: Int

            @inlinable
            public init(source: Int, m: Int, n: Int) {
                self.source = source
                self.m = m
                self.n = n
            }

            @inlinable
            public func makeIterator() -> Iterator { Iterator(source: source, m: m, n: n) }

            /// An iterator over outgoing edges from a vertex in the complete bipartite graph.
            public struct Iterator: IteratorProtocol {
                @usableFromInline let source: Int
                @usableFromInline let m: Int
                @usableFromInline let n: Int
                @usableFromInline var rightIndex: Int = 0

                @inlinable
                public init(source: Int, m: Int, n: Int) {
                    self.source = source
                    self.m = m
                    self.n = n
                }

                @inlinable
                public mutating func next() -> SimpleEdge<Int>? {
                    // Only left vertices emit edges
                    guard source >= 0, source < m, rightIndex < n else { return nil }
                    let destination = m + rightIndex
                    rightIndex += 1
                    return SimpleEdge(source: source, destination: destination)
                }
            }
        }

        @inlinable
        public func outgoingEdges(of vertex: Int) -> OutgoingEdges {
            OutgoingEdges(source: vertex, m: m, n: n)
        }

        @inlinable
        public func source(of edge: SimpleEdge<Int>) -> Int? { edge.source }

        @inlinable
        public func destination(of edge: SimpleEdge<Int>) -> Int? { edge.destination }

        @inlinable
        public func outDegree(of vertex: Int) -> Int {
            vertex >= 0 && vertex < m ? n : 0
        }
    }

    // MARK: - BidirectionalGraph

    extension CompleteBipartiteGraph: BidirectionalGraph {
        /// A sequence of incoming edges to a vertex in the complete bipartite graph.
        public struct IncomingEdges: Sequence {
            @usableFromInline let destination: Int
            @usableFromInline let m: Int
            @usableFromInline let n: Int

            @inlinable
            public init(destination: Int, m: Int, n: Int) {
                self.destination = destination
                self.m = m
                self.n = n
            }

            @inlinable
            public func makeIterator() -> Iterator { Iterator(destination: destination, m: m, n: n) }

            /// An iterator over incoming edges to a vertex in the complete bipartite graph.
            public struct Iterator: IteratorProtocol {
                @usableFromInline let destination: Int
                @usableFromInline let m: Int
                @usableFromInline let n: Int
                @usableFromInline var leftIndex: Int = 0

                @inlinable
                public init(destination: Int, m: Int, n: Int) {
                    self.destination = destination
                    self.m = m
                    self.n = n
                }

                @inlinable
                public mutating func next() -> SimpleEdge<Int>? {
                    // Only right vertices receive edges
                    guard destination >= m, destination < m + n, leftIndex < m else { return nil }
                    let src = leftIndex
                    leftIndex += 1
                    return SimpleEdge(source: src, destination: destination)
                }
            }
        }

        @inlinable
        public func incomingEdges(of vertex: Int) -> IncomingEdges {
            IncomingEdges(destination: vertex, m: m, n: n)
        }

        @inlinable
        public func inDegree(of vertex: Int) -> Int {
            vertex >= m && vertex < m + n ? m : 0
        }
    }

    // MARK: - EdgeListGraph

    extension CompleteBipartiteGraph: EdgeListGraph {
        /// A sequence of all m*n directed edges from left vertices to right vertices.
        public struct Edges: Sequence {
            @usableFromInline let m: Int
            @usableFromInline let n: Int

            @inlinable
            public init(m: Int, n: Int) {
                self.m = m
                self.n = n
            }

            @inlinable
            public func makeIterator() -> Iterator { Iterator(m: m, n: n) }

            /// An iterator over all edges in the complete bipartite graph.
            public struct Iterator: IteratorProtocol {
                @usableFromInline let m: Int
                @usableFromInline let n: Int
                @usableFromInline var left: Int = 0
                @usableFromInline var right: Int = 0

                @inlinable
                public init(m: Int, n: Int) {
                    self.m = m
                    self.n = n
                }

                @inlinable
                public mutating func next() -> SimpleEdge<Int>? {
                    guard n > 0 else { return nil }
                    guard left < m else { return nil }
                    if right >= n {
                        left += 1
                        right = 0
                    }
                    guard left < m else { return nil }
                    let edge = SimpleEdge(source: left, destination: m + right)
                    right += 1
                    return edge
                }
            }
        }

        @inlinable
        public func edges() -> Edges { Edges(m: m, n: n) }

        @inlinable
        public var edgeCount: Int { m * n }
    }

    // MARK: - AdjacencyGraph

    extension CompleteBipartiteGraph: AdjacencyGraph {
        /// A sequence of adjacent (right) vertices to a given left vertex in the complete bipartite graph.
        public struct AdjacentVertices: Sequence {
            @usableFromInline let vertex: Int
            @usableFromInline let m: Int
            @usableFromInline let n: Int

            @inlinable
            public init(vertex: Int, m: Int, n: Int) {
                self.vertex = vertex
                self.m = m
                self.n = n
            }

            @inlinable
            public func makeIterator() -> Iterator { Iterator(vertex: vertex, m: m, n: n) }

            /// An iterator over adjacent vertices in the complete bipartite graph.
            public struct Iterator: IteratorProtocol {
                @usableFromInline let vertex: Int
                @usableFromInline let m: Int
                @usableFromInline let n: Int
                @usableFromInline var rightIndex: Int = 0

                @inlinable
                public init(vertex: Int, m: Int, n: Int) {
                    self.vertex = vertex
                    self.m = m
                    self.n = n
                }

                @inlinable
                public mutating func next() -> Int? {
                    guard vertex >= 0, vertex < m, rightIndex < n else { return nil }
                    let result = m + rightIndex
                    rightIndex += 1
                    return result
                }
            }
        }

        @inlinable
        public func adjacentVertices(of vertex: Int) -> AdjacentVertices {
            AdjacentVertices(vertex: vertex, m: m, n: n)
        }
    }

    // MARK: - EdgeLookupGraph

    extension CompleteBipartiteGraph: EdgeLookupGraph {
        /// Returns the edge from left vertex `source` to right vertex `destination`; nil otherwise.
        @inlinable
        public func edge(from source: Int, to destination: Int) -> SimpleEdge<Int>? {
            guard source >= 0, source < m else { return nil }
            guard destination >= m, destination < m + n else { return nil }
            return SimpleEdge(source: source, destination: destination)
        }
    }

    extension CompleteBipartiteGraph: Sendable {}

#endif
