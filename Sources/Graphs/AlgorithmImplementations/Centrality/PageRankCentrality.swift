#if !GRAPHS_USES_TRAITS || GRAPHS_ANALYSIS
    import OrderedCollections

    /// PageRank centrality algorithm implementation.
    ///
    /// PageRank measures the importance of vertices based on the structure of incoming links.
    /// It's particularly useful for directed graphs like web graphs, where links represent
    /// endorsements or citations.
    ///
    /// The algorithm uses an iterative approach where each vertex's importance is computed
    /// based on the importance of vertices linking to it. Vertices with no outgoing edges
    /// (dangling nodes) redistribute their rank uniformly to all vertices.
    ///
    /// - Complexity: O(k × (V + E)) where k is the number of iterations until convergence
    public struct PageRankCentralityAlgorithm<Graph: IncidenceGraph & VertexListGraph & BidirectionalGraph>: CentralityAlgorithm
    where Graph.VertexDescriptor: Hashable {
        public typealias Event = PageRankCentrality<Graph>.Event

        /// The damping factor (typically 0.85).
        ///
        /// The damping factor represents the probability that a random surfer will continue
        /// following links rather than jumping to a random vertex. Higher values (closer to 1.0)
        /// give more weight to the link structure, while lower values give more weight to
        /// random jumps.
        public let dampingFactor: Double

        /// The maximum number of iterations.
        ///
        /// The algorithm will stop after this many iterations even if convergence hasn't been reached.
        public let maxIterations: Int

        /// The convergence threshold.
        ///
        /// The algorithm stops when the maximum change in rank between iterations is less than this value.
        public let tolerance: Double

        /// Creates a new PageRank algorithm.
        ///
        /// - Parameters:
        ///   - dampingFactor: The damping factor (default: 0.85)
        ///   - maxIterations: Maximum number of iterations (default: 100)
        ///   - tolerance: Convergence threshold (default: 1e-6)
        @inlinable
        public init(dampingFactor: Double = 0.85, maxIterations: Int = 100, tolerance: Double = 1e-6) {
            self.dampingFactor = dampingFactor
            self.maxIterations = maxIterations
            self.tolerance = tolerance
        }

        @inlinable
        public func centrality(
            in graph: Graph,
            observation: AlgorithmObservation<Event>?
        ) -> CentralityResult<Graph.VertexDescriptor> {
            let pagerank = PageRankCentrality(on: graph, dampingFactor: dampingFactor, maxIterations: maxIterations, tolerance: tolerance)
            return pagerank.compute(observation: observation)
        }
    }

    /// PageRank computation implementation.
    public struct PageRankCentrality<Graph: IncidenceGraph & VertexListGraph & BidirectionalGraph> where Graph.VertexDescriptor: Hashable {
        /// A completed PageRank iteration.
        public struct IterationSnapshot {
            /// The zero-based iteration index.
            public let iteration: Int
            /// Rank values produced by the iteration.
            public let values: [Graph.VertexDescriptor: Double]

            /// Creates an iteration snapshot.
            @inlinable
            public init(iteration: Int, values: [Graph.VertexDescriptor: Double]) {
                self.iteration = iteration
                self.values = values
            }
        }

        /// An event emitted while PageRank is computed.
        public enum Event {
            /// An iteration is about to start.
            case iterationStarted(Int)
            /// An iteration completed with new ranks.
            case iterationFinished(IterationSnapshot)
            /// The computation converged.
            case converged(IterationSnapshot)
        }

        /// Typed selectors for PageRank events.
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
        let dampingFactor: Double
        @usableFromInline
        let maxIterations: Int
        @usableFromInline
        let tolerance: Double

        @inlinable
        public init(on graph: Graph, dampingFactor: Double, maxIterations: Int, tolerance: Double) {
            self.graph = graph
            self.dampingFactor = dampingFactor
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
                return CentralityResult(values: [vertices[0]: 1.0])
            }

            let n = Double(vertices.count)
            var rank = Dictionary(uniqueKeysWithValues: vertices.map { ($0, 1.0 / n) })
            var newRank: [Graph.VertexDescriptor: Double] = [:]

            // Precompute out-degrees for performance
            var outDegrees: [Graph.VertexDescriptor: Int] = [:]
            var danglingNodes: Set<Graph.VertexDescriptor> = []
            for vertex in vertices {
                let outDegree = graph.outDegree(of: vertex)
                outDegrees[vertex] = outDegree
                if outDegree == 0 {
                    danglingNodes.insert(vertex)
                }
            }

            for iteration in 0 ..< maxIterations {
                observation?.receive(.iterationStarted(iteration))

                // Initialize new rank with damping factor (random jump probability)
                let randomJump = (1.0 - dampingFactor) / n
                for vertex in vertices {
                    newRank[vertex] = randomJump
                }

                // Distribute rank from each vertex to its neighbors
                for vertex in vertices {
                    let outDegree = outDegrees[vertex] ?? 0
                    guard outDegree > 0 else { continue }

                    guard let vertexRank = rank[vertex] else { continue }
                    let contribution = dampingFactor * vertexRank / Double(outDegree)

                    for edge in graph.outgoingEdges(of: vertex) {
                        if let neighbor = graph.destination(of: edge) {
                            newRank[neighbor, default: 0.0] += contribution
                        }
                    }
                }

                // Handle dangling nodes: redistribute their rank uniformly
                if !danglingNodes.isEmpty {
                    let danglingRank = danglingNodes.reduce(0.0) { $0 + (rank[$1] ?? 0.0) }
                    let danglingContribution = dampingFactor * danglingRank / n
                    for vertex in vertices {
                        newRank[vertex, default: 0.0] += danglingContribution
                    }
                }

                let snapshot = IterationSnapshot(iteration: iteration, values: newRank)
                observation?.receive(.iterationFinished(snapshot))

                // Check for convergence
                var maxDiff = 0.0
                for vertex in vertices {
                    let newValue = newRank[vertex] ?? 0.0
                    let oldValue = rank[vertex] ?? 0.0
                    let diff = abs(newValue - oldValue)
                    maxDiff = max(maxDiff, diff)
                }

                if maxDiff < tolerance {
                    observation?.receive(.converged(snapshot))
                    return CentralityResult(values: newRank)
                }

                rank = newRank
                newRank = [:]
            }

            return CentralityResult(values: rank)
        }
    }

#endif
