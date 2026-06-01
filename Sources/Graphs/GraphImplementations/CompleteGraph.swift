#if !GRAPHS_USES_TRAITS || GRAPHS_GRAPH_FAMILIES

    /// A complete directed graph (K_n) on a fixed vertex set.
    ///
    /// Every ordered pair of distinct vertices is connected by a directed edge. With n vertices
    /// the graph has n*(n-1) directed edges. No edge storage is used — edges are computed on
    /// demand, so this type requires O(n) memory regardless of vertex count.
    ///
    /// - Note: This is a directed complete graph (every u→v and v→u both exist). To work with
    ///   it as undirected, wrap it in `UndirectedGraphView`.
    public struct CompleteGraph<Vertex: Hashable> {
        @usableFromInline
        let verticesStore: [Vertex]
        @usableFromInline
        let vertexSet: Set<Vertex>

        /// Creates a complete graph over the given vertices. Duplicate values are silently ignored,
        /// preserving first-seen order.
        @inlinable
        public init(vertices: some Sequence<Vertex>) {
            var seen = Set<Vertex>()
            var store: [Vertex] = []
            for v in vertices where seen.insert(v).inserted {
                store.append(v)
            }
            self.verticesStore = store
            self.vertexSet = seen
        }
    }

    extension CompleteGraph where Vertex == Int {
        /// Creates a complete graph with integer vertices `0..<n`.
        @inlinable
        public init(count n: Int) {
            self.init(vertices: 0 ..< n)
        }
    }

    // MARK: - Graph

    extension CompleteGraph: Graph {
        public typealias VertexDescriptor = Vertex
        public typealias EdgeDescriptor = SimpleEdge<Vertex>
    }

    // MARK: - VertexListGraph

    extension CompleteGraph: VertexListGraph {
        @inlinable
        public func vertices() -> [Vertex] { verticesStore }

        @inlinable
        public var vertexCount: Int { verticesStore.count }
    }

    // MARK: - IncidenceGraph

    extension CompleteGraph: IncidenceGraph {
        /// A sequence of all outgoing edges from a single source vertex.
        public struct OutgoingEdges: Sequence {
            @usableFromInline let source: Vertex
            @usableFromInline let vertices: [Vertex]

            @inlinable
            public init(source: Vertex, vertices: [Vertex]) {
                self.source = source
                self.vertices = vertices
            }

            @inlinable
            public func makeIterator() -> Iterator { Iterator(source: source, vertices: vertices) }

            public struct Iterator: IteratorProtocol {
                @usableFromInline let source: Vertex
                @usableFromInline let vertices: [Vertex]
                @usableFromInline var index: Int = 0

                @inlinable
                public init(source: Vertex, vertices: [Vertex]) {
                    self.source = source
                    self.vertices = vertices
                }

                @inlinable
                public mutating func next() -> SimpleEdge<Vertex>? {
                    while index < vertices.count {
                        let destination = vertices[index]
                        index += 1
                        if destination != source {
                            return SimpleEdge(source: source, destination: destination)
                        }
                    }
                    return nil
                }
            }
        }

        @inlinable
        public func outgoingEdges(of vertex: Vertex) -> OutgoingEdges {
            OutgoingEdges(source: vertex, vertices: verticesStore)
        }

        @inlinable
        public func source(of edge: SimpleEdge<Vertex>) -> Vertex? { edge.source }

        @inlinable
        public func destination(of edge: SimpleEdge<Vertex>) -> Vertex? { edge.destination }

        @inlinable
        public func outDegree(of vertex: Vertex) -> Int {
            vertexSet.contains(vertex) ? verticesStore.count - 1 : 0
        }
    }

    // MARK: - BidirectionalGraph

    extension CompleteGraph: BidirectionalGraph {
        /// A sequence of all incoming edges to a single destination vertex.
        public struct IncomingEdges: Sequence {
            @usableFromInline let destination: Vertex
            @usableFromInline let vertices: [Vertex]

            @inlinable
            public init(destination: Vertex, vertices: [Vertex]) {
                self.destination = destination
                self.vertices = vertices
            }

            @inlinable
            public func makeIterator() -> Iterator { Iterator(destination: destination, vertices: vertices) }

            public struct Iterator: IteratorProtocol {
                @usableFromInline let destination: Vertex
                @usableFromInline let vertices: [Vertex]
                @usableFromInline var index: Int = 0

                @inlinable
                public init(destination: Vertex, vertices: [Vertex]) {
                    self.destination = destination
                    self.vertices = vertices
                }

                @inlinable
                public mutating func next() -> SimpleEdge<Vertex>? {
                    while index < vertices.count {
                        let src = vertices[index]
                        index += 1
                        if src != destination {
                            return SimpleEdge(source: src, destination: destination)
                        }
                    }
                    return nil
                }
            }
        }

        @inlinable
        public func incomingEdges(of vertex: Vertex) -> IncomingEdges {
            IncomingEdges(destination: vertex, vertices: verticesStore)
        }

        @inlinable
        public func inDegree(of vertex: Vertex) -> Int {
            vertexSet.contains(vertex) ? verticesStore.count - 1 : 0
        }
    }

    // MARK: - EdgeListGraph

    extension CompleteGraph: EdgeListGraph {
        /// A sequence of all n*(n-1) directed edges in row-major order.
        public struct Edges: Sequence {
            @usableFromInline let vertices: [Vertex]

            @inlinable
            public init(vertices: [Vertex]) { self.vertices = vertices }

            @inlinable
            public func makeIterator() -> Iterator { Iterator(vertices: vertices) }

            public struct Iterator: IteratorProtocol {
                @usableFromInline let vertices: [Vertex]
                @usableFromInline var sourceIndex: Int = 0
                @usableFromInline var destIndex: Int = 0

                @inlinable
                public init(vertices: [Vertex]) { self.vertices = vertices }

                @inlinable
                public mutating func next() -> SimpleEdge<Vertex>? {
                    while sourceIndex < vertices.count {
                        if destIndex < vertices.count {
                            let src = vertices[sourceIndex]
                            let dst = vertices[destIndex]
                            destIndex += 1
                            if src != dst {
                                return SimpleEdge(source: src, destination: dst)
                            }
                        } else {
                            sourceIndex += 1
                            destIndex = 0
                        }
                    }
                    return nil
                }
            }
        }

        @inlinable
        public func edges() -> Edges { Edges(vertices: verticesStore) }

        @inlinable
        public var edgeCount: Int {
            let n = verticesStore.count
            return n * (n - 1)
        }
    }

    // MARK: - AdjacencyGraph

    extension CompleteGraph: AdjacencyGraph {
        /// A sequence of all vertices adjacent to a given vertex (every other vertex).
        public struct AdjacentVertices: Sequence {
            @usableFromInline let vertex: Vertex
            @usableFromInline let vertices: [Vertex]

            @inlinable
            public init(vertex: Vertex, vertices: [Vertex]) {
                self.vertex = vertex
                self.vertices = vertices
            }

            @inlinable
            public func makeIterator() -> Iterator { Iterator(vertex: vertex, vertices: vertices) }

            public struct Iterator: IteratorProtocol {
                @usableFromInline let vertex: Vertex
                @usableFromInline let vertices: [Vertex]
                @usableFromInline var index: Int = 0

                @inlinable
                public init(vertex: Vertex, vertices: [Vertex]) {
                    self.vertex = vertex
                    self.vertices = vertices
                }

                @inlinable
                public mutating func next() -> Vertex? {
                    while index < vertices.count {
                        let v = vertices[index]
                        index += 1
                        if v != vertex { return v }
                    }
                    return nil
                }
            }
        }

        @inlinable
        public func adjacentVertices(of vertex: Vertex) -> AdjacentVertices {
            AdjacentVertices(vertex: vertex, vertices: verticesStore)
        }
    }

    // MARK: - EdgeLookupGraph

    extension CompleteGraph: EdgeLookupGraph {
        /// Returns the edge from `source` to `destination` if both vertices are in the graph
        /// and are distinct; returns `nil` for self-loops or unknown vertices.
        @inlinable
        public func edge(from source: Vertex, to destination: Vertex) -> SimpleEdge<Vertex>? {
            guard source != destination else { return nil }
            guard vertexSet.contains(source) && vertexSet.contains(destination) else { return nil }
            return SimpleEdge(source: source, destination: destination)
        }
    }

    extension CompleteGraph: Sendable where Vertex: Sendable {}

#endif
