#if !GRAPHS_USES_TRAITS || GRAPHS_PATHFINDING
    import OrderedCollections

    extension AllPathsAlgorithm {
        /// Returns a Depth-First Search (DFS) based all-paths algorithm.
        ///
        /// - Parameter maxLength: Optional maximum number of edges per path. Paths longer than
        ///   this are pruned during traversal. Pass `nil` (the default) for no limit.
        @inlinable
        public static func dfs<G>(maxLength: Int? = nil) -> Self where Self == DFSAllPathsAlgorithm<G>, Graph == G {
            .init(maxLength: maxLength)
        }
    }

    /// An algorithm factory that produces a DFS-based sequence of all paths.
    public struct DFSAllPathsAlgorithm<Graph: IncidenceGraph>: AllPathsAlgorithm where Graph.VertexDescriptor: Hashable {
        @usableFromInline
        let maxLength: Int?

        @inlinable
        public init(maxLength: Int? = nil) {
            self.maxLength = maxLength
        }

        @inlinable
        public func allPaths(
            from source: Graph.VertexDescriptor,
            to destination: Graph.VertexDescriptor,
            in graph: Graph
        ) -> DFSAllPaths<Graph> {
            DFSAllPaths(graph: graph, source: source, destination: destination, maxLength: maxLength)
        }
    }

    /// A sequence that lazily finds all simple paths between two vertices using Depth-First Search.
    public struct DFSAllPaths<Graph: IncidenceGraph>: Sequence where Graph.VertexDescriptor: Hashable {
        public typealias Vertex = Graph.VertexDescriptor
        public typealias Edge = Graph.EdgeDescriptor

        @usableFromInline
        let graph: Graph
        @usableFromInline
        let source: Vertex
        @usableFromInline
        let destination: Vertex
        /// Maximum number of edges allowed in any returned path. `nil` means unlimited.
        @usableFromInline
        let maxLength: Int?

        @inlinable
        public init(graph: Graph, source: Vertex, destination: Vertex, maxLength: Int? = nil) {
            self.graph = graph
            self.source = source
            self.destination = destination
            self.maxLength = maxLength
        }

        @inlinable
        public func makeIterator() -> Iterator {
            Iterator(graph: graph, source: source, destination: destination, maxLength: maxLength)
        }

        public struct Iterator: IteratorProtocol {
            @usableFromInline
            let graph: Graph
            @usableFromInline
            let destination: Vertex
            @usableFromInline
            let maxLength: Int?

            // Stack holds the vertex and the iterator for its outgoing edges
            @usableFromInline
            struct StackFrame {
                @usableFromInline
                let vertex: Vertex
                @usableFromInline
                var edges: Graph.OutgoingEdges.Iterator

                @inlinable
                init(vertex: Vertex, edges: Graph.OutgoingEdges.Iterator) {
                    self.vertex = vertex
                    self.edges = edges
                }
            }

            @usableFromInline
            var stack: [StackFrame] = []

            @usableFromInline
            var visited: Set<Vertex> = []

            @usableFromInline
            var pathVertices: [Vertex] = []

            @usableFromInline
            var pathEdges: [Edge] = []

            @inlinable
            public init(graph: Graph, source: Vertex, destination: Vertex, maxLength: Int? = nil) {
                self.graph = graph
                self.destination = destination
                self.maxLength = maxLength

                // Initialize with source
                let edges = graph.outgoingEdges(of: source).makeIterator()
                self.stack.append(StackFrame(vertex: source, edges: edges))
                self.visited.insert(source)
                self.pathVertices.append(source)
            }

            @inlinable
            public mutating func next() -> Path<Vertex, Edge>? {
                while !stack.isEmpty {
                    // Get reference to current frame to mutate iterator
                    let index = stack.count - 1

                    guard let edge = stack[index].edges.next() else {
                        // No more edges for this vertex, backtrack
                        let popped = stack.removeLast()
                        visited.remove(popped.vertex)
                        pathVertices.removeLast()
                        if !pathEdges.isEmpty {
                            pathEdges.removeLast()
                        }
                        continue
                    }

                    guard let neighbor = graph.destination(of: edge) else { continue }

                    let nextEdgeCount = pathEdges.count + 1

                    if neighbor == destination {
                        // Prune paths that would exceed maxLength.
                        if let max = maxLength, nextEdgeCount > max { continue }

                        let path = Path(
                            source: pathVertices.first!,
                            destination: destination,
                            vertices: pathVertices + [destination],
                            edges: pathEdges + [edge]
                        )
                        return path
                    }

                    if !visited.contains(neighbor) {
                        // Don't recurse deeper if we've already saturated the edge budget —
                        // any path through this neighbor needs at least one more edge to
                        // reach destination, which would exceed maxLength.
                        if let max = maxLength, nextEdgeCount >= max { continue }

                        visited.insert(neighbor)
                        pathVertices.append(neighbor)
                        pathEdges.append(edge)
                        let neighborEdges = graph.outgoingEdges(of: neighbor).makeIterator()
                        stack.append(StackFrame(vertex: neighbor, edges: neighborEdges))
                    }
                }

                return nil
            }
        }
    }
#endif
