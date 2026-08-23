#if !GRAPHS_USES_TRAITS || GRAPHS_ANALYSIS
    import OrderedCollections

    /// Eigenvector centrality algorithm implementation.
    ///
    /// Eigenvector centrality measures a vertex's importance based on the importance
    /// of its neighbors. A vertex is important if it's connected to other important vertices.
    /// This creates a recursive definition of importance.
    ///
    /// The algorithm uses power iteration to converge to the principal eigenvector of
    /// the adjacency matrix. Vertices with no incoming edges (isolated vertices) have
    /// an eigenvector centrality of 0.
    ///
    /// - Complexity: O(k × (V + E)) where k is the number of iterations until convergence
    public struct EigenvectorCentralityAlgorithm<Graph: IncidenceGraph & VertexListGraph & BidirectionalGraph>: CentralityAlgorithm
    where Graph.VertexDescriptor: Hashable {
        public typealias Event = EigenvectorCentrality<Graph>.Event

        /// The maximum number of iterations.
        ///
        /// The algorithm will stop after this many iterations even if convergence hasn't been reached.
        public let maxIterations: Int

        /// The convergence threshold.
        ///
        /// The algorithm stops when the maximum change in centrality between iterations is less than this value.
        public let tolerance: Double

        /// Creates a new eigenvector centrality algorithm.
        ///
        /// - Parameters:
        ///   - maxIterations: Maximum number of iterations (default: 100)
        ///   - tolerance: Convergence threshold (default: 1e-6)
        @inlinable
        public init(maxIterations: Int = 100, tolerance: Double = 1e-6) {
            self.maxIterations = maxIterations
            self.tolerance = tolerance
        }

        @inlinable
        public func centrality(
            in graph: Graph,
            observation: AlgorithmObservation<Event>?
        ) -> CentralityResult<Graph.VertexDescriptor> {
            let eigenvector = EigenvectorCentrality(on: graph, maxIterations: maxIterations, tolerance: tolerance)
            return eigenvector.compute(observation: observation)
        }
    }

    /// Eigenvector centrality computation implementation using power iteration.
    public struct EigenvectorCentrality<Graph: IncidenceGraph & VertexListGraph & BidirectionalGraph> where Graph.VertexDescriptor: Hashable {
        /// A completed power-iteration step.
        public struct IterationSnapshot {
            /// The zero-based iteration index.
            public let iteration: Int
            /// Centrality values produced by the iteration.
            public let values: [Graph.VertexDescriptor: Double]

            /// Creates an iteration snapshot.
            @inlinable
            public init(iteration: Int, values: [Graph.VertexDescriptor: Double]) {
                self.iteration = iteration
                self.values = values
            }
        }

        /// An event emitted while eigenvector centrality is computed.
        public enum Event {
            /// An iteration is about to start.
            case iterationStarted(Int)
            /// An iteration completed with new values.
            case iterationFinished(IterationSnapshot)
            /// The computation converged.
            case converged(IterationSnapshot)
        }

        /// Typed selectors for eigenvector-centrality events.
        public enum EventCases {
            /// Selects iteration starts.
            public static var iterationStarted: AlgorithmEventCase<Event, Int> {
                .init {
                    guard case .iterationStarted(let iteration) = $0 else { return nil }
                    return iteration
                }
            }

            /// Selects completed iterations.
            public static var iterationFinished: AlgorithmEventCase<Event, IterationSnapshot> {
                .init {
                    guard case .iterationFinished(let snapshot) = $0 else { return nil }
                    return snapshot
                }
            }

            /// Selects convergence.
            public static var converged: AlgorithmEventCase<Event, IterationSnapshot> {
                .init {
                    guard case .converged(let snapshot) = $0 else { return nil }
                    return snapshot
                }
            }
        }

        @usableFromInline
        let graph: Graph
        @usableFromInline
        let maxIterations: Int
        @usableFromInline
        let tolerance: Double

        @inlinable
        public init(on graph: Graph, maxIterations: Int, tolerance: Double) {
            self.graph = graph
            self.maxIterations = maxIterations
            self.tolerance = tolerance
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
                // Eigenvector centrality is 1.0 for single vertex (normalized)
                return CentralityResult(values: [vertices[0]: 1.0])
            }

            // Initialize centrality values
            var centrality = Dictionary(uniqueKeysWithValues: vertices.map { ($0, 1.0) })
            var newCentrality: [Graph.VertexDescriptor: Double] = [:]

            for iteration in 0 ..< maxIterations {
                observation?.receive(.iterationStarted(iteration))

                // Initialize new centrality
                for vertex in vertices {
                    newCentrality[vertex] = 0.0
                }

                // Compute new centrality based on incoming edges (neighbors' importance)
                for vertex in vertices {
                    var sum = 0.0
                    for edge in graph.incomingEdges(of: vertex) {
                        if let neighbor = graph.source(of: edge) {
                            sum += centrality[neighbor] ?? 0.0
                        }
                    }
                    newCentrality[vertex] = sum
                }

                // Normalize by maximum value to prevent overflow
                let maxValue = newCentrality.values.max() ?? 1.0
                if maxValue > 0 {
                    for vertex in vertices {
                        newCentrality[vertex] = newCentrality[vertex, default: 0.0] / maxValue
                    }
                }

                let snapshot = IterationSnapshot(iteration: iteration, values: newCentrality)
                observation?.receive(.iterationFinished(snapshot))

                // Check for convergence
                var maxDiff = 0.0
                for vertex in vertices {
                    let newValue = newCentrality[vertex] ?? 0.0
                    let oldValue = centrality[vertex] ?? 0.0
                    let diff = abs(newValue - oldValue)
                    maxDiff = max(maxDiff, diff)
                }

                if maxDiff < tolerance {
                    observation?.receive(.converged(snapshot))
                    return CentralityResult(values: newCentrality)
                }

                centrality = newCentrality
                newCentrality = [:]
            }

            return CentralityResult(values: centrality)
        }
    }

#endif
