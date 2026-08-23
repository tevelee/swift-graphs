#if !GRAPHS_USES_TRAITS || GRAPHS_ANALYSIS
    /// Smallest Last Vertex Ordering algorithm.
    ///
    /// This algorithm orders vertices by repeatedly removing the vertex with the smallest degree
    /// and placing it last in the sequence. This ordering is particularly effective for graph
    /// coloring algorithms as it tends to reduce the number of colors needed.
    ///
    /// - Complexity: O(V²) where V is the number of vertices
    public struct SmallestLastVertexOrderingAlgorithm<
        Graph: IncidenceGraph & VertexListGraph & BidirectionalGraph
    > where Graph.VertexDescriptor: Hashable {

        /// An event emitted while smallest-last vertex ordering advances.
        public enum Event {
            /// A vertex was examined.
            case vertexExamined(Graph.VertexDescriptor)
            /// A vertex was removed with its current degree.
            case vertexRemoved(vertex: Graph.VertexDescriptor, degree: Int)
            /// A vertex's degree was updated.
            case degreeUpdated(vertex: Graph.VertexDescriptor, oldDegree: Int, newDegree: Int)
        }

        /// Typed selectors for smallest-last ordering events.
        public enum EventCases {
            /// Selects examined vertices.
            public static var vertexExamined: AlgorithmEventCase<Event, Graph.VertexDescriptor> {
                .init {
                    guard case .vertexExamined(let value) = $0 else { return nil }
                    return value
                }
            }

            /// Selects removed vertices and their degrees.
            public static var vertexRemoved: AlgorithmEventCase<Event, (vertex: Graph.VertexDescriptor, degree: Int)> {
                .init {
                    guard case .vertexRemoved(let vertex, let degree) = $0 else { return nil }
                    return (vertex, degree)
                }
            }

            /// Selects vertex-degree updates.
            public static var degreeUpdated: AlgorithmEventCase<Event, (vertex: Graph.VertexDescriptor, oldDegree: Int, newDegree: Int)> {
                .init {
                    guard case .degreeUpdated(let vertex, let oldDegree, let newDegree) = $0 else { return nil }
                    return (vertex, oldDegree, newDegree)
                }
            }
        }

        /// Creates a new Smallest Last Vertex Ordering algorithm.
        @inlinable
        public init() {}

        /// Orders vertices using the Smallest Last Vertex algorithm.
        ///
        /// - Parameters:
        ///   - graph: The graph to order vertices for
        ///   - observation: An optional algorithm observation.
        /// - Returns: An array of vertex descriptors in the computed order
        @inlinable
        public func orderVertices(
            in graph: Graph,
            observation: AlgorithmObservation<Event>? = nil
        ) -> [Graph.VertexDescriptor] {
            var remainingVertices = Set(graph.vertices())
            var degrees: [Graph.VertexDescriptor: Int] = [:]
            var ordering: [Graph.VertexDescriptor] = []

            // Initialize degrees and create deterministic vertex ordering
            let vertexList = graph.vertices()
            for vertex in vertexList {
                degrees[vertex] = graph.degree(of: vertex)
            }

            // Process vertices in reverse order (smallest degree first)
            while !remainingVertices.isEmpty {
                // Find vertex with minimum degree (use deterministic tie-breaking)
                let minDegree = degrees.values.min() ?? 0
                let minDegreeVertices = vertexList.filter { remainingVertices.contains($0) && degrees[$0] == minDegree }

                // If there are ties, choose the first one in vertex list order (deterministic)
                guard let vertexToRemove = minDegreeVertices.first else {
                    preconditionFailure("minDegreeVertices should not be empty - there should always be vertices with minimum degree")
                }

                observation?.receive(.vertexExamined(vertexToRemove))
                observation?.receive(.vertexRemoved(vertex: vertexToRemove, degree: minDegree))

                // Remove vertex from remaining set
                remainingVertices.remove(vertexToRemove)
                degrees.removeValue(forKey: vertexToRemove)

                // Add to ordering (we'll reverse at the end)
                ordering.append(vertexToRemove)

                // Update degrees of neighbors
                for neighbor in graph.successors(of: vertexToRemove) where remainingVertices.contains(neighbor) {
                    let oldDegree = degrees[neighbor] ?? 0
                    let newDegree = oldDegree - 1
                    degrees[neighbor] = newDegree
                    observation?.receive(.degreeUpdated(vertex: neighbor, oldDegree: oldDegree, newDegree: newDegree))
                }
            }

            // Reverse to get smallest-last ordering
            return ordering.reversed()
        }
    }

#endif

#if !GRAPHS_USES_TRAITS || GRAPHS_ANALYSIS
    extension SmallestLastVertexOrderingAlgorithm.Event: VertexExaminedEvent {
        @inlinable
        public static func examinedVertex(from event: Self) -> Graph.VertexDescriptor? {
            guard case .vertexExamined(let vertex) = event else { return nil }
            return vertex
        }
    }
#endif
