#if !GRAPHS_USES_TRAITS || GRAPHS_ANALYSIS
    /// Degree centrality algorithm implementation.
    ///
    /// Degree centrality measures the number of connections a vertex has.
    /// It's the simplest centrality measure, counting the out-degree of each vertex.
    ///
    /// For undirected graphs represented as directed graphs (with edges in both directions),
    /// degree centrality counts outgoing edges. For proper normalization, consider using
    /// total degree (in-degree + out-degree) with a `BidirectionalGraph`.
    ///
    /// - Complexity: O(V + E)
    public struct DegreeCentralityAlgorithm<Graph: IncidenceGraph & VertexListGraph>: CentralityAlgorithm where Graph.VertexDescriptor: Hashable {
        public typealias Event = DegreeCentrality<Graph>.Event

        /// Whether to normalize by maximum possible degree.
        ///
        /// When normalized, values are divided by the maximum degree in the graph,
        /// making them comparable across graphs of different sizes.
        public let normalized: Bool

        /// Creates a new degree centrality algorithm.
        ///
        /// - Parameter normalized: Whether to normalize values (default: true)
        @inlinable
        public init(normalized: Bool = true) {
            self.normalized = normalized
        }

        @inlinable
        public func centrality(
            in graph: Graph,
            observation: AlgorithmObservation<Event>?
        ) -> CentralityResult<Graph.VertexDescriptor> {
            let degree = DegreeCentrality(on: graph, normalized: normalized)
            return degree.compute(observation: observation)
        }
    }

    /// Degree centrality computation implementation.
    public struct DegreeCentrality<Graph: IncidenceGraph & VertexListGraph> where Graph.VertexDescriptor: Hashable {
        /// An event emitted while degree centrality is computed.
        public enum Event {
            /// A vertex is about to be examined.
            case vertexExamined(Graph.VertexDescriptor)
            /// The degree of a vertex was computed.
            case degreeComputed(vertex: Graph.VertexDescriptor, degree: Int)
        }

        /// Typed selectors for degree-centrality events.
        public enum EventCases {
            /// Selects examined vertices.
            public static var vertexExamined: AlgorithmEventCase<Event, Graph.VertexDescriptor> {
                .init {
                    guard case .vertexExamined(let vertex) = $0 else { return nil }
                    return vertex
                }
            }

            /// Selects computed vertex degrees.
            public static var degreeComputed: AlgorithmEventCase<Event, (vertex: Graph.VertexDescriptor, degree: Int)> {
                .init {
                    guard case .degreeComputed(let vertex, let degree) = $0 else { return nil }
                    return (vertex, degree)
                }
            }
        }

        @usableFromInline
        let graph: Graph
        @usableFromInline
        let normalized: Bool

        @inlinable
        public init(on graph: Graph, normalized: Bool) {
            self.graph = graph
            self.normalized = normalized
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

            var degree: [Graph.VertexDescriptor: Double] = [:]
            var maxDegree = 0

            for vertex in vertices {
                observation?.receive(.vertexExamined(vertex))
                let deg = graph.outDegree(of: vertex)
                degree[vertex] = Double(deg)
                maxDegree = max(maxDegree, deg)
                observation?.receive(.degreeComputed(vertex: vertex, degree: deg))
            }

            // Normalize if requested
            if normalized && maxDegree > 0 {
                let maxDegreeDouble = Double(maxDegree)
                for vertex in vertices {
                    degree[vertex] = degree[vertex, default: 0.0] / maxDegreeDouble
                }
            }

            return CentralityResult(values: degree)
        }
    }

#endif

#if !GRAPHS_USES_TRAITS || GRAPHS_ANALYSIS
    extension DegreeCentrality.Event: VertexExaminedEvent {
        @inlinable
        public static func examinedVertex(from event: Self) -> Graph.VertexDescriptor? {
            guard case .vertexExamined(let vertex) = event else { return nil }
            return vertex
        }
    }
#endif
