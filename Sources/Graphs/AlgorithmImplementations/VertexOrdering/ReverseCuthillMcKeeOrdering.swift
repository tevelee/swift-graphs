#if !GRAPHS_USES_TRAITS || GRAPHS_ANALYSIS
    /// Reverse Cuthill-McKee Ordering algorithm.
    ///
    /// This algorithm reorders the vertices of a graph to reduce the bandwidth of its adjacency matrix.
    /// It uses breadth-first search starting from a vertex with minimum degree, enqueuing adjacent
    /// vertices in order of increasing degree. The reverse ordering often produces better results
    /// with less fill-in during matrix operations.
    ///
    /// - Complexity: O(V + E) where V is the number of vertices and E is the number of edges
    public struct ReverseCuthillMcKeeOrderingAlgorithm<
        Graph: IncidenceGraph & VertexListGraph & BidirectionalGraph
    > where Graph.VertexDescriptor: Hashable {

        /// An event emitted while Reverse Cuthill-McKee ordering advances.
        public enum Event {
            /// Ordering of a connected component started from a vertex.
            case componentStarted(Graph.VertexDescriptor)
            /// A vertex was examined.
            case vertexExamined(Graph.VertexDescriptor)
            /// A vertex was enqueued with its degree.
            case vertexEnqueued(vertex: Graph.VertexDescriptor, degree: Int)
            /// A vertex was dequeued.
            case vertexDequeued(Graph.VertexDescriptor)
        }

        /// Typed selectors for Reverse Cuthill-McKee events.
        public enum EventCases {
            /// Selects component starts.
            public static var componentStarted: AlgorithmEventCase<Event, Graph.VertexDescriptor> {
                .init {
                    guard case .componentStarted(let value) = $0 else { return nil }
                    return value
                }
            }

            /// Selects examined vertices.
            public static var vertexExamined: AlgorithmEventCase<Event, Graph.VertexDescriptor> {
                .init {
                    guard case .vertexExamined(let value) = $0 else { return nil }
                    return value
                }
            }

            /// Selects enqueued vertices and their degrees.
            public static var vertexEnqueued: AlgorithmEventCase<Event, (vertex: Graph.VertexDescriptor, degree: Int)> {
                .init {
                    guard case .vertexEnqueued(let vertex, let degree) = $0 else { return nil }
                    return (vertex, degree)
                }
            }

            /// Selects dequeued vertices.
            public static var vertexDequeued: AlgorithmEventCase<Event, Graph.VertexDescriptor> {
                .init {
                    guard case .vertexDequeued(let value) = $0 else { return nil }
                    return value
                }
            }
        }

        /// Creates a new Reverse Cuthill-McKee Ordering algorithm.
        @inlinable
        public init() {}

        /// Orders vertices using the Reverse Cuthill-McKee algorithm.
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
            var visited = Set<Graph.VertexDescriptor>()
            var ordering: [Graph.VertexDescriptor] = []

            // Process each connected component
            for vertex in graph.vertices() where !visited.contains(vertex) {
                let componentOrdering = cuthillMcKeeForComponent(
                    startingFrom: vertex,
                    in: graph,
                    visited: &visited,
                    observation: observation
                )
                ordering.append(contentsOf: componentOrdering)
            }

            // Reverse the ordering for better bandwidth reduction
            return ordering.reversed()
        }

        @usableFromInline
        func cuthillMcKeeForComponent(
            startingFrom startVertex: Graph.VertexDescriptor,
            in graph: Graph,
            visited: inout Set<Graph.VertexDescriptor>,
            observation: AlgorithmObservation<Event>?
        ) -> [Graph.VertexDescriptor] {
            var ordering: [Graph.VertexDescriptor] = []
            var queue: [Graph.VertexDescriptor] = [startVertex]
            var queueIndex = 0

            observation?.receive(.componentStarted(startVertex))

            while queueIndex < queue.count {
                let currentVertex = queue[queueIndex]
                queueIndex += 1

                if visited.contains(currentVertex) {
                    continue
                }

                visited.insert(currentVertex)
                ordering.append(currentVertex)
                observation?.receive(.vertexExamined(currentVertex))
                observation?.receive(.vertexDequeued(currentVertex))

                // Get neighbors and sort by degree
                let neighbors = graph.successors(of: currentVertex)
                    .filter { !visited.contains($0) }
                    .sorted { graph.outDegree(of: $0) < graph.outDegree(of: $1) }

                // Add neighbors to queue in order of increasing degree
                for neighbor in neighbors where !visited.contains(neighbor) && !queue.contains(neighbor) {
                    queue.append(neighbor)
                    observation?.receive(.vertexEnqueued(vertex: neighbor, degree: graph.outDegree(of: neighbor)))
                }
            }

            return ordering
        }
    }

#endif

#if !GRAPHS_USES_TRAITS || GRAPHS_ANALYSIS
    extension ReverseCuthillMcKeeOrderingAlgorithm.Event: VertexExaminedEvent {
        @inlinable
        public static func examinedVertex(from event: Self) -> Graph.VertexDescriptor? {
            guard case .vertexExamined(let vertex) = event else { return nil }
            return vertex
        }
    }
#endif
