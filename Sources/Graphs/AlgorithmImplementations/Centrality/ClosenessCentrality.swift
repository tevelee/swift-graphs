#if !GRAPHS_USES_TRAITS || GRAPHS_ANALYSIS
    import OrderedCollections

    /// Closeness centrality algorithm implementation.
    ///
    /// Closeness centrality measures how close a vertex is to all other vertices in the graph.
    /// It's computed as the inverse of the sum of shortest path distances to all other vertices.
    /// Vertices with high closeness can reach all other vertices quickly.
    ///
    /// For disconnected graphs, vertices that cannot reach all other vertices have
    /// a closeness of 0.0.
    ///
    /// - Complexity: O(V × (V + E)) for unweighted graphs
    public struct ClosenessCentralityAlgorithm<Graph: IncidenceGraph & VertexListGraph>: CentralityAlgorithm where Graph.VertexDescriptor: Hashable {
        public typealias Event = ClosenessCentrality<Graph>.Event

        /// Creates a new closeness centrality algorithm.
        @inlinable
        public init() {}

        @inlinable
        public func centrality(
            in graph: Graph,
            observation: AlgorithmObservation<Event>?
        ) -> CentralityResult<Graph.VertexDescriptor> {
            let closeness = ClosenessCentrality(on: graph)
            return closeness.compute(observation: observation)
        }
    }

    /// Closeness centrality computation implementation.
    public struct ClosenessCentrality<Graph: IncidenceGraph & VertexListGraph> where Graph.VertexDescriptor: Hashable {
        /// An event emitted while closeness centrality is computed.
        public enum Event {
            /// A source vertex is about to be examined.
            case vertexExamined(Graph.VertexDescriptor)
            /// A shortest-path distance was computed.
            case distanceComputed(source: Graph.VertexDescriptor, destination: Graph.VertexDescriptor, distance: Int)
        }

        /// Typed selectors for closeness-centrality events.
        public enum EventCases {
            /// Selects examined source vertices.
            public static var vertexExamined: AlgorithmEventCase<Event, Graph.VertexDescriptor> {
                .init {
                    guard case .vertexExamined(let vertex) = $0 else { return nil }
                    return vertex
                }
            }

            /// Selects computed distances.
            public static var distanceComputed: AlgorithmEventCase<Event, (source: Graph.VertexDescriptor, destination: Graph.VertexDescriptor, distance: Int)>
            {
                .init {
                    guard case .distanceComputed(let source, let destination, let distance) = $0 else { return nil }
                    return (source, destination, distance)
                }
            }
        }

        @usableFromInline
        let graph: Graph

        @inlinable
        public init(on graph: Graph) {
            self.graph = graph
        }

        @inlinable
        public func compute(
            observation: AlgorithmObservation<Event>? = nil
        ) -> CentralityResult<Graph.VertexDescriptor> {
            let vertices = Array(graph.vertices())

            // Handle empty graph
            guard !vertices.isEmpty else {
                return CentralityResult(values: [:])
            }

            // Handle single vertex graph
            guard vertices.count > 1 else {
                // Closeness is undefined for a single vertex, return 0
                return CentralityResult(values: [vertices[0]: 0.0])
            }

            var closeness: [Graph.VertexDescriptor: Double] = [:]
            let n = Double(vertices.count)

            for vertex in vertices {
                observation?.receive(.vertexExamined(vertex))

                // BFS to compute distances from this vertex
                var distances: [Graph.VertexDescriptor: Int] = [:]
                var queue: [Graph.VertexDescriptor] = [vertex]
                distances[vertex] = 0

                while !queue.isEmpty {
                    let v = queue.removeFirst()

                    for edge in graph.outgoingEdges(of: v) {
                        guard let w = graph.destination(of: edge) else { continue }

                        if distances[w] == nil {
                            guard let vDistance = distances[v] else { continue }
                            let wDistance = vDistance + 1
                            distances[w] = wDistance
                            queue.append(w)
                            observation?.receive(.distanceComputed(source: vertex, destination: w, distance: wDistance))
                        }
                    }
                }

                // Compute closeness: (n-1) / sum of distances
                // If vertex cannot reach all other vertices, closeness is 0
                let reachableCount = distances.count
                if reachableCount < vertices.count {
                    // Disconnected: cannot reach all vertices
                    closeness[vertex] = 0.0
                } else {
                    let totalDistance = distances.values.reduce(0, +)
                    if totalDistance > 0 {
                        closeness[vertex] = (n - 1.0) / Double(totalDistance)
                    } else {
                        // All distances are 0 (shouldn't happen, but handle it)
                        closeness[vertex] = 0.0
                    }
                }
            }

            return CentralityResult(values: closeness)
        }
    }

#endif

#if !GRAPHS_USES_TRAITS || GRAPHS_ANALYSIS
    extension ClosenessCentrality.Event: VertexExaminedEvent {
        @inlinable
        public static func examinedVertex(from event: Self) -> Graph.VertexDescriptor? {
            guard case .vertexExamined(let vertex) = event else { return nil }
            return vertex
        }
    }
#endif
