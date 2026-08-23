#if !GRAPHS_USES_TRAITS || GRAPHS_OPTIMIZATION
    import OrderedCollections

    /// Hopcroft-Karp algorithm for finding maximum matching in bipartite graphs.
    ///
    /// This algorithm finds the maximum matching by repeatedly finding augmenting paths
    /// and increasing the matching size. It uses BFS to find multiple disjoint augmenting
    /// paths in each iteration, making it more efficient than the basic augmenting path approach.
    ///
    /// - Complexity: O(E * sqrt(V)) where E is the number of edges and V is the number of vertices
    public struct HopcroftKarp<Graph: BipartiteGraph & IncidenceGraph & VertexListGraph> where Graph.VertexDescriptor: Hashable {
        /// The vertex type of the graph.
        public typealias Vertex = Graph.VertexDescriptor
        /// The edge type of the graph.
        public typealias Edge = Graph.EdgeDescriptor

        /// Details about adding an edge's endpoints to the matching.
        public struct MatchingUpdate {
            /// The edge's source endpoint.
            public let source: Vertex
            /// The edge's destination endpoint.
            public let destination: Vertex

            /// Creates matching-update details.
            @inlinable
            public init(source: Vertex, destination: Vertex) {
                self.source = source
                self.destination = destination
            }
        }

        /// An event emitted synchronously while Hopcroft-Karp advances.
        public enum Event {
            /// A vertex was examined during an augmenting-path search.
            case vertexExamined(Vertex)
            /// An edge was examined during an augmenting-path search.
            case edgeExamined(Edge)
            /// An augmenting path was found.
            case augmentingPathFound([Edge])
            /// Matching augmentation along a path started.
            case matchingAugmentationStarted([Edge])
            /// The matching was updated with an edge's endpoints.
            case matchingUpdated(MatchingUpdate)
            /// A search iteration started.
            case iterationStarted(Int)
        }

        /// Typed selectors for Hopcroft-Karp events.
        public enum EventCases {
            /// Selects examined vertices.
            public static var vertexExamined: AlgorithmEventCase<Event, Vertex> {
                .init {
                    guard case .vertexExamined(let value) = $0 else { return nil }
                    return value
                }
            }
            /// Selects examined edges.
            public static var edgeExamined: AlgorithmEventCase<Event, Edge> {
                .init {
                    guard case .edgeExamined(let value) = $0 else { return nil }
                    return value
                }
            }
            /// Selects found augmenting paths.
            public static var augmentingPathFound: AlgorithmEventCase<Event, [Edge]> {
                .init {
                    guard case .augmentingPathFound(let value) = $0 else { return nil }
                    return value
                }
            }
            /// Selects matching augmentations as they start.
            public static var matchingAugmentationStarted: AlgorithmEventCase<Event, [Edge]> {
                .init {
                    guard case .matchingAugmentationStarted(let value) = $0 else { return nil }
                    return value
                }
            }
            /// Selects matching updates.
            public static var matchingUpdated: AlgorithmEventCase<Event, MatchingUpdate> {
                .init {
                    guard case .matchingUpdated(let value) = $0 else { return nil }
                    return value
                }
            }
            /// Selects search iteration starts.
            public static var iterationStarted: AlgorithmEventCase<Event, Int> {
                .init {
                    guard case .iterationStarted(let value) = $0 else { return nil }
                    return value
                }
            }
        }

        /// Creates a new Hopcroft-Karp algorithm.
        @inlinable
        public init() {}

        /// Finds the maximum matching using Hopcroft-Karp algorithm.
        ///
        /// - Parameters:
        ///   - graph: The bipartite graph to find matching in
        ///   - observation: An optional algorithm observation
        /// - Returns: The maximum matching result
        @inlinable
        public func maximumMatching(
            in graph: Graph,
            observation: AlgorithmObservation<Event>? = nil
        ) -> MatchingResult<Vertex, Edge> {
            // Initialize matching
            var matching: [Vertex: Vertex] = [:]
            var matchingEdges: [Edge] = []

            // Get partitions
            let leftVertices = Array(graph.leftPartition())
            let rightVertices = Array(graph.rightPartition())

            var iteration = 0

            // Main algorithm loop
            while true {
                iteration += 1
                observation?.receive(.iterationStarted(iteration))

                // Find all augmenting paths in this iteration
                let augmentingPaths = findAugmentingPaths(
                    in: graph,
                    leftVertices: leftVertices,
                    rightVertices: rightVertices,
                    matching: matching,
                    observation: observation
                )

                // If no augmenting paths found, we have maximum matching
                if augmentingPaths.isEmpty {
                    break
                }

                // Augment the matching with all found paths
                for path in augmentingPaths {
                    observation?.receive(.matchingAugmentationStarted(path))
                    augmentMatching(path, in: graph, matching: &matching, matchingEdges: &matchingEdges, observation: observation)
                }
            }

            // Build result
            let matchedVertices = Set(matching.keys).union(Set(matching.values))
            let allVertices = Set(leftVertices).union(Set(rightVertices))
            let unmatchedVertices = allVertices.subtracting(matchedVertices)

            let matchedLeftVertices = Set(leftVertices).intersection(matchedVertices)
            let matchedRightVertices = Set(rightVertices).intersection(matchedVertices)
            let unmatchedLeftVertices = Set(leftVertices).subtracting(matchedVertices)
            let unmatchedRightVertices = Set(rightVertices).subtracting(matchedVertices)

            return MatchingResult(
                matchingSize: matchingEdges.count,
                matchingEdges: matchingEdges,
                matchedVertices: matchedVertices,
                unmatchedVertices: unmatchedVertices,
                matchedLeftVertices: matchedLeftVertices,
                matchedRightVertices: matchedRightVertices,
                unmatchedLeftVertices: unmatchedLeftVertices,
                unmatchedRightVertices: unmatchedRightVertices,
                partnerMap: matching
            )
        }

        @usableFromInline
        func findAugmentingPaths(
            in graph: Graph,
            leftVertices: [Vertex],
            rightVertices: [Vertex],
            matching: [Vertex: Vertex],
            observation: AlgorithmObservation<Event>?
        ) -> [[Edge]] {
            var augmentingPaths: [[Edge]] = []
            var visited: Set<Vertex> = []

            // Find augmenting paths starting from unmatched left vertices
            for leftVertex in leftVertices where !matching.keys.contains(leftVertex) && !visited.contains(leftVertex) {
                if let path = findAugmentingPath(
                    from: leftVertex,
                    in: graph,
                    matching: matching,
                    visited: &visited,
                    observation: observation
                ) {
                    augmentingPaths.append(path)
                }
            }

            return augmentingPaths
        }

        @usableFromInline
        func findAugmentingPath(
            from start: Vertex,
            in graph: Graph,
            matching: [Vertex: Vertex],
            visited: inout Set<Vertex>,
            observation: AlgorithmObservation<Event>?
        ) -> [Edge]? {
            var queue: [Vertex] = [start]
            var parent: [Vertex: Vertex] = [:]
            var parentEdge: [Vertex: Edge] = [:]
            var found = false

            visited.insert(start)

            while !queue.isEmpty && !found {
                let current = queue.removeFirst()
                observation?.receive(.vertexExamined(current))

                // If this is an unmatched right vertex, we found an augmenting path
                if let partition = graph.partition(of: current), partition == .right && !matching.values.contains(current) {
                    found = true
                    // Reconstruct path
                    var path: [Edge] = []
                    var vertex = current

                    while let parentVertex = parent[vertex], let edge = parentEdge[vertex] {
                        path.append(edge)
                        vertex = parentVertex
                    }

                    path.reverse()
                    observation?.receive(.augmentingPathFound(path))
                    return path
                }

                // Explore neighbors
                for edge in graph.outgoingEdges(of: current) {
                    guard let destination = graph.destination(of: edge) else { continue }
                    observation?.receive(.edgeExamined(edge))

                    if !visited.contains(destination) {
                        visited.insert(destination)
                        parent[destination] = current
                        parentEdge[destination] = edge
                        queue.append(destination)
                    }
                }
            }

            return nil
        }

        @usableFromInline
        func augmentMatching(
            _ path: [Edge],
            in graph: Graph,
            matching: inout [Vertex: Vertex],
            matchingEdges: inout [Edge],
            observation: AlgorithmObservation<Event>?
        ) {
            // Remove existing matching edges that are in the path
            for edge in path {
                if let source = graph.source(of: edge),
                    let destination = graph.destination(of: edge)
                {
                    matching.removeValue(forKey: source)
                    matching.removeValue(forKey: destination)

                    // Remove from matching edges
                    matchingEdges.removeAll { existingEdge in
                        (graph.source(of: existingEdge) == source && graph.destination(of: existingEdge) == destination)
                            || (graph.source(of: existingEdge) == destination && graph.destination(of: existingEdge) == source)
                    }
                }
            }

            // Add new matching edges (alternating pattern)
            for (index, edge) in path.enumerated() where index % 2 == 0 {
                if let source = graph.source(of: edge),
                    let destination = graph.destination(of: edge)
                {
                    matching[source] = destination
                    matching[destination] = source
                    matchingEdges.append(edge)
                    observation?.receive(.matchingUpdated(.init(source: source, destination: destination)))
                }
            }
        }
    }

    extension HopcroftKarp: MatchingAlgorithm {
        public typealias Graph = Graph
    }

    extension MatchingAlgorithm {
        /// Creates a Hopcroft-Karp algorithm.
        ///
        /// - Returns: A Hopcroft-Karp algorithm instance.
        @inlinable
        public static func hopcroftKarp<Graph>() -> Self where Self == HopcroftKarp<Graph> {
            .init()
        }
    }

#endif

#if !GRAPHS_USES_TRAITS || GRAPHS_OPTIMIZATION
    extension HopcroftKarp.Event: VertexExaminedEvent, EdgeExaminedEvent {
        @inlinable
        public static func examinedVertex(from event: Self) -> Graph.VertexDescriptor? {
            guard case .vertexExamined(let vertex) = event else { return nil }
            return vertex
        }

        @inlinable
        public static func examinedEdge(from event: Self) -> Graph.EdgeDescriptor? {
            guard case .edgeExamined(let edge) = event else { return nil }
            return edge
        }
    }
#endif
