#if !GRAPHS_USES_TRAITS || GRAPHS_GRAPH_FAMILIES

    /// The Petersen graph, a canonical 10-vertex 3-regular graph.
    ///
    /// Vertices are `0..<10`. The graph has the following structure:
    /// - Outer 5-cycle: 0↔1↔2↔3↔4↔0
    /// - Inner pentagram: 5↔7↔9↔6↔8↔5
    /// - Spokes: 0↔5, 1↔6, 2↔7, 3↔8, 4↔9
    ///
    /// Both directions of each edge are included, so every vertex has out-degree 3 and
    /// in-degree 3, giving 30 directed edges total (15 undirected edges × 2 directions).
    /// Use `UndirectedGraphView` to work with it as an undirected graph.
    /// Edges are computed on demand; no edge storage is used.
    public struct PetersonGraph {
        /// Creates the Petersen graph.
        @inlinable
        public init() {}

        /// The adjacency list for each vertex (both directions stored).
        @usableFromInline
        static let adjacency: [[Int]] = [
            [1, 4, 5],  // 0: outer cycle neighbors + spoke
            [0, 2, 6],  // 1
            [1, 3, 7],  // 2
            [2, 4, 8],  // 3
            [3, 0, 9],  // 4
            [0, 7, 8],  // 5: inner pentagram neighbors + spoke
            [1, 8, 9],  // 6
            [2, 5, 9],  // 7
            [3, 5, 6],  // 8
            [4, 6, 7],  // 9
        ]
    }

    // MARK: - Graph

    extension PetersonGraph: Graph {
        public typealias VertexDescriptor = Int
        public typealias EdgeDescriptor = SimpleEdge<Int>
    }

    // MARK: - VertexListGraph

    extension PetersonGraph: VertexListGraph {
        @inlinable
        public func vertices() -> Range<Int> { 0 ..< 10 }

        @inlinable
        public var vertexCount: Int { 10 }
    }

    // MARK: - IncidenceGraph

    extension PetersonGraph: IncidenceGraph {
        /// A sequence of outgoing edges from a vertex in the Petersen graph.
        public struct OutgoingEdges: Sequence {
            @usableFromInline let source: Int

            @inlinable
            public init(source: Int) { self.source = source }

            @inlinable
            public func makeIterator() -> Iterator { Iterator(source: source) }

            /// An iterator over outgoing edges from a vertex in the Petersen graph.
            public struct Iterator: IteratorProtocol {
                @usableFromInline let source: Int
                @usableFromInline var index: Int = 0

                @inlinable
                public init(source: Int) { self.source = source }

                @inlinable
                public mutating func next() -> SimpleEdge<Int>? {
                    guard source >= 0, source < 10 else { return nil }
                    let neighbors = PetersonGraph.adjacency[source]
                    guard index < neighbors.count else { return nil }
                    let destination = neighbors[index]
                    index += 1
                    return SimpleEdge(source: source, destination: destination)
                }
            }
        }

        @inlinable
        public func outgoingEdges(of vertex: Int) -> OutgoingEdges {
            OutgoingEdges(source: vertex)
        }

        @inlinable
        public func source(of edge: SimpleEdge<Int>) -> Int? { edge.source }

        @inlinable
        public func destination(of edge: SimpleEdge<Int>) -> Int? { edge.destination }

        @inlinable
        public func outDegree(of vertex: Int) -> Int {
            guard vertex >= 0, vertex < 10 else { return 0 }
            return 3
        }
    }

    // MARK: - BidirectionalGraph

    extension PetersonGraph: BidirectionalGraph {
        /// A sequence of incoming edges to a vertex in the Petersen graph.
        public struct IncomingEdges: Sequence {
            @usableFromInline let destination: Int

            @inlinable
            public init(destination: Int) { self.destination = destination }

            @inlinable
            public func makeIterator() -> Iterator { Iterator(destination: destination) }

            /// An iterator over incoming edges to a vertex in the Petersen graph.
            public struct Iterator: IteratorProtocol {
                @usableFromInline let destination: Int
                @usableFromInline var index: Int = 0

                @inlinable
                public init(destination: Int) { self.destination = destination }

                @inlinable
                public mutating func next() -> SimpleEdge<Int>? {
                    guard destination >= 0, destination < 10 else { return nil }
                    // Because the graph is undirected (both directions stored),
                    // in-neighbors == out-neighbors
                    let neighbors = PetersonGraph.adjacency[destination]
                    guard index < neighbors.count else { return nil }
                    let src = neighbors[index]
                    index += 1
                    return SimpleEdge(source: src, destination: destination)
                }
            }
        }

        @inlinable
        public func incomingEdges(of vertex: Int) -> IncomingEdges {
            IncomingEdges(destination: vertex)
        }

        @inlinable
        public func inDegree(of vertex: Int) -> Int {
            guard vertex >= 0, vertex < 10 else { return 0 }
            return 3
        }
    }

    // MARK: - EdgeListGraph

    extension PetersonGraph: EdgeListGraph {
        /// A sequence of all 30 directed edges (15 undirected edges × 2 directions).
        public struct Edges: Sequence {
            @inlinable
            public init() {}

            @inlinable
            public func makeIterator() -> Iterator { Iterator() }

            /// An iterator over all edges in the Petersen graph.
            public struct Iterator: IteratorProtocol {
                @usableFromInline var vertex: Int = 0
                @usableFromInline var neighborIndex: Int = 0

                @inlinable
                public init() {}

                @inlinable
                public mutating func next() -> SimpleEdge<Int>? {
                    while vertex < 10 {
                        let neighbors = PetersonGraph.adjacency[vertex]
                        if neighborIndex < neighbors.count {
                            let destination = neighbors[neighborIndex]
                            neighborIndex += 1
                            return SimpleEdge(source: vertex, destination: destination)
                        }
                        vertex += 1
                        neighborIndex = 0
                    }
                    return nil
                }
            }
        }

        @inlinable
        public func edges() -> Edges { Edges() }

        @inlinable
        public var edgeCount: Int { 30 }
    }

    // MARK: - AdjacencyGraph

    extension PetersonGraph: AdjacencyGraph {
        /// A sequence of adjacent vertices to a given vertex in the Petersen graph.
        public struct AdjacentVertices: Sequence {
            @usableFromInline let vertex: Int

            @inlinable
            public init(vertex: Int) { self.vertex = vertex }

            @inlinable
            public func makeIterator() -> Iterator { Iterator(vertex: vertex) }

            /// An iterator over adjacent vertices in the Petersen graph.
            public struct Iterator: IteratorProtocol {
                @usableFromInline let vertex: Int
                @usableFromInline var index: Int = 0

                @inlinable
                public init(vertex: Int) { self.vertex = vertex }

                @inlinable
                public mutating func next() -> Int? {
                    guard vertex >= 0, vertex < 10 else { return nil }
                    let neighbors = PetersonGraph.adjacency[vertex]
                    guard index < neighbors.count else { return nil }
                    let result = neighbors[index]
                    index += 1
                    return result
                }
            }
        }

        @inlinable
        public func adjacentVertices(of vertex: Int) -> AdjacentVertices {
            AdjacentVertices(vertex: vertex)
        }
    }

    // MARK: - EdgeLookupGraph

    extension PetersonGraph: EdgeLookupGraph {
        /// Returns the edge u→v if it exists in the Petersen graph; nil otherwise.
        @inlinable
        public func edge(from source: Int, to destination: Int) -> SimpleEdge<Int>? {
            guard source >= 0, source < 10, destination >= 0, destination < 10 else { return nil }
            let neighbors = PetersonGraph.adjacency[source]
            guard neighbors.contains(destination) else { return nil }
            return SimpleEdge(source: source, destination: destination)
        }
    }

    extension PetersonGraph: Sendable {}

#endif
