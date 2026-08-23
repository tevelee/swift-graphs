#if !GRAPHS_USES_TRAITS || GRAPHS_CONNECTIVITY
    import OrderedCollections

    /// Union-Find based connected components algorithm.
    ///
    /// This algorithm finds connected components using the Union-Find data structure.
    /// It processes edges to union vertices and then groups them by their root.
    ///
    /// - Complexity: O(V + E α(V)) where V is the number of vertices, E is the number of edges, and α is the inverse Ackermann function
    public struct UnionFindConnectedComponents<Graph: IncidenceGraph & VertexListGraph> where Graph.VertexDescriptor: Hashable {
        /// The vertex type of the graph.
        public typealias Vertex = Graph.VertexDescriptor
        /// The edge type of the graph.
        public typealias Edge = Graph.EdgeDescriptor

        public enum Event {
            case vertexDiscovered(Vertex)
            case edgeExamined(Edge)
            case componentFinished([Vertex])
        }

        public enum EventCases {
            public static var vertexDiscovered: AlgorithmEventCase<Event, Vertex> {
                .init {
                    guard case .vertexDiscovered(let value) = $0 else { return nil }
                    return value
                }
            }
            public static var edgeExamined: AlgorithmEventCase<Event, Edge> {
                .init {
                    guard case .edgeExamined(let value) = $0 else { return nil }
                    return value
                }
            }
            public static var componentFinished: AlgorithmEventCase<Event, [Vertex]> {
                .init {
                    guard case .componentFinished(let value) = $0 else { return nil }
                    return value
                }
            }
        }

        /// The graph to find connected components in.
        @usableFromInline
        let graph: Graph

        /// Creates a new Union-Find connected components algorithm.
        ///
        /// - Parameter graph: The graph to find connected components in
        @inlinable
        public init(on graph: Graph) {
            self.graph = graph
        }

        /// Finds connected components using Union-Find.
        ///
        /// - Parameter observation: An optional observation of the algorithm progress
        /// - Returns: The connected components result
        @inlinable
        public func connectedComponents(
            observation: AlgorithmObservation<Event>? = nil
        ) -> ConnectedComponentsResult<Vertex> {
            var parent: [Vertex: Vertex] = [:]
            var rank: [Vertex: Int] = [:]

            // Initialize Union-Find data structure
            for vertex in graph.vertices() {
                parent[vertex] = vertex
                rank[vertex] = 0
            }

            // Find function with path compression
            func find(_ vertex: Vertex) -> Vertex {
                guard var currentParent = parent[vertex] else { return vertex }
                if currentParent != vertex {
                    currentParent = find(currentParent)
                    parent[vertex] = currentParent
                }
                return currentParent
            }

            // Union function with union by rank
            func union(_ x: Vertex, _ y: Vertex) {
                let rootX = find(x)
                let rootY = find(y)

                if rootX == rootY { return }

                guard let rankX = rank[rootX], let rankY = rank[rootY] else { return }

                if rankX < rankY {
                    parent[rootX] = rootY
                } else if rankX > rankY {
                    parent[rootY] = rootX
                } else {
                    parent[rootY] = rootX
                    rank[rootX] = rankX + 1
                }
            }

            // Process all edges to build connected components
            for vertex in graph.vertices() {
                observation?.receive(.vertexDiscovered(vertex))

                for edge in graph.outgoingEdges(of: vertex) {
                    observation?.receive(.edgeExamined(edge))

                    guard let destination = graph.destination(of: edge) else { continue }
                    union(vertex, destination)
                }
            }

            // Group vertices by their root parent
            var components: [Vertex: [Vertex]] = [:]
            for vertex in graph.vertices() {
                let root = find(vertex)
                components[root, default: []].append(vertex)
            }

            // Convert to array of arrays and publish completion events.
            let result = Array(components.values)
            for component in result {
                observation?.receive(.componentFinished(component))
            }

            return ConnectedComponentsResult(components: result)
        }
    }

    extension UnionFindConnectedComponents: ConnectedComponentsAlgorithm {
        @inlinable
        public func connectedComponents(
            in graph: Graph,
            observation: AlgorithmObservation<Event>?
        ) -> ConnectedComponentsResult<Graph.VertexDescriptor> {
            connectedComponents(observation: observation)
        }
    }
#endif

#if !GRAPHS_USES_TRAITS || GRAPHS_CONNECTIVITY
    extension UnionFindConnectedComponents.Event: VertexDiscoveredEvent, EdgeExaminedEvent {
        @inlinable
        public static func discoveredVertex(from event: Self) -> Graph.VertexDescriptor? {
            guard case .vertexDiscovered(let vertex) = event else { return nil }
            return vertex
        }

        @inlinable
        public static func examinedEdge(from event: Self) -> Graph.EdgeDescriptor? {
            guard case .edgeExamined(let edge) = event else { return nil }
            return edge
        }
    }
#endif
