#if !GRAPHS_USES_TRAITS || GRAPHS_ANALYSIS
    import OrderedCollections

    /// Louvain algorithm for community detection.
    ///
    /// This algorithm detects communities by optimizing modularity through
    /// iterative local optimization and graph coarsening.
    ///
    /// - Complexity: O(n log n) in typical cases
    public struct LouvainCommunityDetection<Graph: IncidenceGraph & VertexListGraph & EdgeListGraph>
    where Graph.VertexDescriptor: Hashable {
        /// The vertex type of the graph.
        public typealias Vertex = Graph.VertexDescriptor
        /// The edge type of the graph.
        public typealias Edge = Graph.EdgeDescriptor

        /// An event emitted while Louvain community detection advances.
        public enum Event {
            /// A phase started.
            case phaseStarted(Int)
            /// A vertex moved to another community.
            case vertexMoved(vertex: Vertex, community: Int)
            /// Modularity improved to the supplied value.
            case modularityImproved(Double)
            /// An iteration completed with the supplied modularity.
            case iterationCompleted(phase: Int, modularity: Double)
        }

        /// Typed selectors for Louvain events.
        public enum EventCases {
            /// Selects phase starts.
            public static var phaseStarted: AlgorithmEventCase<Event, Int> {
                .init {
                    guard case .phaseStarted(let value) = $0 else { return nil }
                    return value
                }
            }

            /// Selects vertex moves.
            public static var vertexMoved: AlgorithmEventCase<Event, (vertex: Vertex, community: Int)> {
                .init {
                    guard case .vertexMoved(let vertex, let community) = $0 else { return nil }
                    return (vertex, community)
                }
            }

            /// Selects modularity improvements.
            public static var modularityImproved: AlgorithmEventCase<Event, Double> {
                .init {
                    guard case .modularityImproved(let value) = $0 else { return nil }
                    return value
                }
            }

            /// Selects completed iterations.
            public static var iterationCompleted: AlgorithmEventCase<Event, (phase: Int, modularity: Double)> {
                .init {
                    guard case .iterationCompleted(let phase, let modularity) = $0 else { return nil }
                    return (phase, modularity)
                }
            }
        }

        /// The graph to detect communities in.
        @usableFromInline
        let graph: Graph

        /// Resolution parameter (default: 1.0).
        @usableFromInline
        let resolution: Double

        /// Creates a new Louvain community detection algorithm.
        ///
        /// - Parameters:
        ///   - graph: The graph to detect communities in
        ///   - resolution: Resolution parameter for modularity optimization
        @inlinable
        public init(on graph: Graph, resolution: Double = 1.0) {
            self.graph = graph
            self.resolution = resolution
        }

        /// Detects communities using the Louvain method.
        ///
        /// - Parameter observation: An optional algorithm observation.
        /// - Returns: The community detection result
        @inlinable
        public func detectCommunities(
            observation: AlgorithmObservation<Event>? = nil
        ) -> CommunityDetectionResult<Vertex> {
            // Initialize each vertex in its own community
            var communities: [Vertex: Int] = [:]
            for (index, vertex) in graph.vertices().enumerated() {
                communities[vertex] = index
            }

            var phase = 0
            var improved = true
            var currentModularity = 0.0

            while improved {
                observation?.receive(.phaseStarted(phase))
                improved = false

                // First phase: local optimization
                for vertex in graph.vertices() {
                    guard let currentCommunity = communities[vertex] else { continue }
                    let neighbors = graph.successors(of: vertex)

                    // Find best community to move to
                    var bestCommunity = currentCommunity
                    var bestModularityGain = 0.0

                    let neighborCommunities = Set(neighbors.compactMap { communities[$0] })

                    for neighborCommunity in neighborCommunities {
                        let gain = modularityGain(
                            vertex: vertex,
                            from: currentCommunity,
                            to: neighborCommunity,
                            communities: communities
                        )

                        if gain > bestModularityGain {
                            bestModularityGain = gain
                            bestCommunity = neighborCommunity
                        }
                    }

                    if bestCommunity != currentCommunity {
                        communities[vertex] = bestCommunity
                        observation?.receive(.vertexMoved(vertex: vertex, community: bestCommunity))
                        currentModularity += bestModularityGain
                        improved = true
                    }
                }

                observation?.receive(.iterationCompleted(phase: phase, modularity: currentModularity))
                observation?.receive(.modularityImproved(currentModularity))
                phase += 1
            }

            // Group vertices by community
            let communityGroups = Dictionary(grouping: communities.keys) { communities[$0] ?? -1 }
            let finalCommunities = communityGroups.values.map { Array($0) }

            return CommunityDetectionResult(
                communities: finalCommunities,
                modularity: currentModularity
            )
        }

        @usableFromInline
        func modularityGain(
            vertex: Vertex,
            from: Int,
            to: Int,
            communities: [Vertex: Int]
        ) -> Double {
            // Simplified modularity gain calculation
            // In practice, this would consider edge weights and degrees
            let neighbors = graph.successors(of: vertex)
            let edgesToCommunity = neighbors.filter { communities[$0] == to }.count
            let edgesFromCommunity = neighbors.filter { communities[$0] == from }.count
            return Double(edgesToCommunity - edgesFromCommunity) * resolution
        }
    }

    extension LouvainCommunityDetection: CommunityDetectionAlgorithm {
        @inlinable
        public func detectCommunities(
            in graph: Graph,
            observation: AlgorithmObservation<Event>?
        ) -> CommunityDetectionResult<Graph.VertexDescriptor> {
            detectCommunities(observation: observation)
        }
    }
#endif
