#if !GRAPHS_USES_TRAITS || GRAPHS_GENERATION
    /// Erdos-Renyi random graph generation algorithm.
    ///
    /// This algorithm generates random graphs where each possible edge is included
    /// with a fixed probability p, independently of other edges.
    ///
    /// - Complexity: O(V²) where V is the number of vertices
    public struct ErdosRenyi<
        Graph: MutableGraph
    > where Graph.VertexDescriptor: Hashable {
        /// The vertex type of the graph.
        public typealias Vertex = Graph.VertexDescriptor

        /// An event emitted while generating an Erdos-Renyi graph.
        public enum Event {
            /// A vertex was added.
            case vertexAdded(Vertex)
            /// An edge was added between two vertices.
            case edgeAdded(source: Vertex, destination: Vertex)
            /// A possible edge was skipped.
            case edgeSkipped(source: Vertex, destination: Vertex, reason: String)
            /// A possible edge is about to be considered.
            case vertexPairExamined(Vertex, Vertex)
        }

        /// Typed selectors for Erdos-Renyi events.
        public enum EventCases {
            /// Selects added vertices.
            public static var vertexAdded: AlgorithmEventCase<Event, Vertex> {
                .init {
                    guard case .vertexAdded(let vertex) = $0 else { return nil }
                    return vertex
                }
            }

            /// Selects added edges.
            public static var edgeAdded: AlgorithmEventCase<Event, (source: Vertex, destination: Vertex)> {
                .init {
                    guard case .edgeAdded(let source, let destination) = $0 else { return nil }
                    return (source, destination)
                }
            }

            /// Selects skipped edges.
            public static var edgeSkipped: AlgorithmEventCase<Event, (source: Vertex, destination: Vertex, reason: String)> {
                .init {
                    guard case .edgeSkipped(let source, let destination, let reason) = $0 else { return nil }
                    return (source, destination, reason)
                }
            }

            /// Selects examined vertex pairs.
            public static var vertexPairExamined: AlgorithmEventCase<Event, (Vertex, Vertex)> {
                .init {
                    guard case .vertexPairExamined(let first, let second) = $0 else { return nil }
                    return (first, second)
                }
            }
        }

        /// The result of the Erdos-Renyi algorithm.
        @usableFromInline
        struct Result {
            @usableFromInline
            let graph: Graph
            @usableFromInline
            let vertices: [Vertex]
            @usableFromInline
            let edges: [(Vertex, Vertex)]
            @usableFromInline
            let edgeProbability: Double
        }

        /// The probability of including each possible edge.
        @usableFromInline
        let edgeProbability: Double

        /// Creates a new Erdos-Renyi algorithm.
        ///
        /// - Parameter edgeProbability: The probability of including each possible edge (0.0 to 1.0)
        @inlinable
        public init(edgeProbability: Double) {
            self.edgeProbability = edgeProbability
        }

        /// Appends a random Erdos-Renyi graph to an existing graph.
        ///
        /// - Parameters:
        ///   - graph: The graph to append to (modified in place)
        ///   - vertexCount: The number of vertices to add
        ///   - generator: The random number generator to use
        ///   - observation: An optional observation of algorithm progress.
        @inlinable
        public func appendRandomGraph<RNG: RandomNumberGenerator>(
            into graph: inout Graph,
            vertexCount: Int,
            using generator: inout RNG,
            observation: AlgorithmObservation<Event>? = nil
        ) {
            guard vertexCount > 0 else { return }

            // Add vertices
            var newVertices: [Vertex] = []
            for _ in 0 ..< vertexCount {
                let v = graph.addVertex()
                observation?.receive(.vertexAdded(v))
                newVertices.append(v)
            }

            // Add edges with probability p among the newly added vertices
            for i in 0 ..< newVertices.count {
                for j in (i + 1) ..< newVertices.count {
                    observation?.receive(.vertexPairExamined(newVertices[i], newVertices[j]))
                    if Double.random(in: 0 ... 1, using: &generator) < edgeProbability {
                        graph.addEdge(from: newVertices[i], to: newVertices[j])
                        observation?.receive(.edgeAdded(source: newVertices[i], destination: newVertices[j]))
                    } else {
                        observation?.receive(
                            .edgeSkipped(source: newVertices[i], destination: newVertices[j], reason: "Probability check failed")
                        )
                    }
                }
            }
        }
    }

#endif
