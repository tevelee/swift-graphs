#if !GRAPHS_USES_TRAITS || GRAPHS_GENERATION
    /// Watts-Strogatz random graph generation algorithm.
    ///
    /// This algorithm generates small-world networks by starting with a regular
    /// ring lattice and randomly rewiring edges with a given probability.
    ///
    /// - Complexity: O(V * k) where V is the number of vertices and k is the average degree
    public struct WattsStrogatz<
        Graph: MutableGraph
    > where Graph.VertexDescriptor: Hashable {
        /// The vertex type of the graph.
        public typealias Vertex = Graph.VertexDescriptor

        /// An event emitted while generating a Watts-Strogatz graph.
        public enum Event {
            /// A vertex was added.
            case vertexAdded(Vertex)
            /// A ring-lattice edge was created.
            case ringEdgeCreated(source: Vertex, destination: Vertex)
            /// An edge was rewired to a new destination.
            case edgeRewired(source: Vertex, oldDestination: Vertex, newDestination: Vertex)
            /// Rewiring an edge was skipped.
            case rewiringSkipped(source: Vertex, destination: Vertex, reason: String)
        }

        /// Typed selectors for Watts-Strogatz events.
        public enum EventCases {
            /// Selects added vertices.
            public static var vertexAdded: AlgorithmEventCase<Event, Vertex> {
                .init {
                    guard case .vertexAdded(let vertex) = $0 else { return nil }
                    return vertex
                }
            }

            /// Selects ring-lattice edges.
            public static var ringEdgeCreated: AlgorithmEventCase<Event, (source: Vertex, destination: Vertex)> {
                .init {
                    guard case .ringEdgeCreated(let source, let destination) = $0 else { return nil }
                    return (source, destination)
                }
            }

            /// Selects rewired edges.
            public static var edgeRewired: AlgorithmEventCase<Event, (source: Vertex, oldDestination: Vertex, newDestination: Vertex)> {
                .init {
                    guard case .edgeRewired(let source, let oldDestination, let newDestination) = $0 else { return nil }
                    return (source, oldDestination, newDestination)
                }
            }

            /// Selects skipped rewiring attempts.
            public static var rewiringSkipped: AlgorithmEventCase<Event, (source: Vertex, destination: Vertex, reason: String)> {
                .init {
                    guard case .rewiringSkipped(let source, let destination, let reason) = $0 else { return nil }
                    return (source, destination, reason)
                }
            }
        }

        /// The result of the Watts-Strogatz algorithm.
        @usableFromInline
        struct Result {
            @usableFromInline
            let graph: Graph
            @usableFromInline
            let vertices: [Vertex]
            @usableFromInline
            let initialEdges: [(Vertex, Vertex)]
            @usableFromInline
            let rewiredEdges: [(Vertex, Vertex)]
            @usableFromInline
            let rewiringProbability: Double
        }

        /// The target average degree for the generated graph.
        @usableFromInline
        let averageDegree: Double
        /// The probability of rewiring each edge.
        @usableFromInline
        let rewiringProbability: Double

        /// Creates a new Watts-Strogatz algorithm.
        ///
        /// - Parameters:
        ///   - averageDegree: The target average degree for the generated graph
        ///   - rewiringProbability: The probability of rewiring each edge (0.0 to 1.0)
        @inlinable
        public init(averageDegree: Double, rewiringProbability: Double) {
            self.averageDegree = averageDegree
            self.rewiringProbability = rewiringProbability
        }

        /// Appends a random Watts-Strogatz graph to an existing graph.
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
            var vertices: [Vertex] = []
            for _ in 0 ..< vertexCount {
                let vertex = graph.addVertex()
                observation?.receive(.vertexAdded(vertex))
                vertices.append(vertex)
            }

            // Create initial regular ring lattice; store edge descriptors for later rewiring
            let k = Int(averageDegree) / 2
            var initialEdges: [(edgeDescriptor: Graph.EdgeDescriptor, source: Vertex, target: Vertex)] = []
            for i in 0 ..< vertexCount {
                for j in 1 ... max(0, k) {
                    let targetIndex = (i + j) % vertexCount
                    let source = vertices[i]
                    let target = vertices[targetIndex]
                    if let edgeDescriptor = graph.addEdge(from: source, to: target) {
                        observation?.receive(.ringEdgeCreated(source: source, destination: target))
                        initialEdges.append((edgeDescriptor: edgeDescriptor, source: source, target: target))
                    }
                }
            }

            // Rewire edges with probability p: remove the old edge, add a new one
            for initialEdge in initialEdges {
                if Double.random(in: 0 ... 1, using: &generator) < rewiringProbability {
                    let source = initialEdge.source
                    if let randomTarget = vertices.randomElement(using: &generator), randomTarget != source {
                        graph.remove(edge: initialEdge.edgeDescriptor)
                        graph.addEdge(from: source, to: randomTarget)
                        observation?.receive(
                            .edgeRewired(source: source, oldDestination: initialEdge.target, newDestination: randomTarget)
                        )
                    } else {
                        observation?.receive(
                            .rewiringSkipped(source: source, destination: initialEdge.target, reason: "Self-loop avoided or no target")
                        )
                    }
                } else {
                    observation?.receive(
                        .rewiringSkipped(source: initialEdge.source, destination: initialEdge.target, reason: "Probability check failed")
                    )
                }
            }
        }
    }

#endif
