#if !GRAPHS_USES_TRAITS || GRAPHS_PATHFINDING
    /// Johnson's algorithm for computing shortest paths between all pairs of vertices.
    ///
    /// Johnson's algorithm is a method for finding shortest paths between all pairs of vertices
    /// in a sparse graph. It works by reweighting the graph to eliminate negative edges,
    /// then running Dijkstra's algorithm from each vertex.
    ///
    /// - Complexity: O(V² log V + VE) where V is the number of vertices and E is the number of edges
    public struct Johnson<
        Graph: IncidenceGraph & VertexListGraph,
        Weight: AdditiveArithmetic & Comparable
    >
    where
        Graph.VertexDescriptor: Hashable,
        Weight: Numeric,
        Weight.Magnitude == Weight
    {
        /// The vertex type of the graph.
        public typealias Vertex = Graph.VertexDescriptor
        /// The edge type of the graph.
        public typealias Edge = Graph.EdgeDescriptor

        public struct EdgeReweighting {
            public let edge: Edge
            public let weight: Weight

            @inlinable
            public init(edge: Edge, weight: Weight) {
                self.edge = edge
                self.weight = weight
            }
        }

        public enum Event {
            case vertexExamined(Vertex)
            case edgeExamined(Edge)
            case edgeReweighted(EdgeReweighting)
            case dijkstraStarted(Vertex)
            case dijkstraCompleted(Vertex)
            case negativeCycleDetected
        }

        public enum EventCases {
            public static var vertexExamined: AlgorithmEventCase<Event, Vertex> {
                .init {
                    guard case .vertexExamined(let value) = $0 else { return nil }
                    return value
                }
            }
            public static var edgeExamined: AlgorithmEventCase<Event, Edge> {
                .init {
                    guard case .edgeExamined(let value) = $0 else { return nil }
                    return value
                }
            }
            public static var edgeReweighted: AlgorithmEventCase<Event, EdgeReweighting> {
                .init {
                    guard case .edgeReweighted(let value) = $0 else { return nil }
                    return value
                }
            }
            public static var dijkstraStarted: AlgorithmEventCase<Event, Vertex> {
                .init {
                    guard case .dijkstraStarted(let value) = $0 else { return nil }
                    return value
                }
            }
            public static var dijkstraCompleted: AlgorithmEventCase<Event, Vertex> {
                .init {
                    guard case .dijkstraCompleted(let value) = $0 else { return nil }
                    return value
                }
            }
            public static var negativeCycleDetected: AlgorithmEventCase<Event, Void> {
                .init {
                    guard case .negativeCycleDetected = $0 else { return nil }
                    return ()
                }
            }
        }

        @usableFromInline
        let edgeWeight: CostDefinition<Graph, Weight>

        /// Creates a new Johnson algorithm instance.
        ///
        /// - Parameter edgeWeight: The cost definition for edge weights.
        @inlinable
        public init(
            edgeWeight: CostDefinition<Graph, Weight>
        ) {
            self.edgeWeight = edgeWeight
        }

        /// Computes shortest paths between all pairs of vertices.
        ///
        /// - Parameters:
        ///   - graph: The graph to compute shortest paths for.
        ///   - observation: An optional observation of the algorithm's progress.
        /// - Returns: The shortest paths between all pairs of vertices.
        @inlinable
        public func shortestPathsForAllPairs(in graph: Graph, observation: AlgorithmObservation<Event>? = nil) -> AllPairsShortestPaths<Vertex, Edge, Weight> {
            let reweightingValues = computeReweightingValues(in: graph)

            guard !reweightingValues.isEmpty else {
                observation?.receive(.negativeCycleDetected)
                return AllPairsShortestPaths(distances: [:], predecessors: [:])
            }

            let vertices = Array(graph.vertices())
            var allDistances: [Vertex: [Vertex: Cost<Weight>]] = [:]
            var allPredecessors: [Vertex: [Vertex: Edge?]] = [:]

            for source in vertices {
                allDistances[source] = [:]
                allPredecessors[source] = [:]
                for destination in vertices {
                    allDistances[source]?[destination] = source == destination ? .finite(.zero) : .infinite
                    allPredecessors[source]?[destination] = nil
                }
            }
            for source in vertices {
                observation?.receive(.dijkstraStarted(source))

                let dijkstra = Dijkstra(
                    on: graph,
                    from: source,
                    edgeWeight: createReweightedCostDefinition(reweightingValues: reweightingValues)
                )

                // Process all vertices and get the final result
                var lastResult: Dijkstra<Graph, Weight>.Result?
                for result in dijkstra {
                    lastResult = result
                }

                guard let result = lastResult else {
                    observation?.receive(.dijkstraCompleted(source))
                    continue
                }

                // Extract distances and predecessors from property map
                for destination in vertices {
                    let cost = result.propertyMap[destination][result.distanceProperty]
                    switch cost {
                        case .infinite:
                            continue  // Keep as infinite
                        case .finite(let distance):
                            let sourceReweighting = reweightingValues[source] ?? .zero
                            let destinationReweighting = reweightingValues[destination] ?? .zero
                            let adjustedDistance = distance - sourceReweighting + destinationReweighting
                            allDistances[source]?[destination] = .finite(adjustedDistance)
                    }

                    let predecessor = result.propertyMap[destination][result.predecessorEdgeProperty]
                    allPredecessors[source]?[destination] = predecessor
                }

                observation?.receive(.dijkstraCompleted(source))
            }

            return AllPairsShortestPaths(
                distances: allDistances,
                predecessors: allPredecessors
            )
        }

        /// Computes reweighting values for the graph.
        ///
        /// - Parameter graph: The graph to compute reweighting values for.
        /// - Returns: A dictionary mapping vertices to their reweighting values.
        @usableFromInline
        func computeReweightingValues(in graph: Graph) -> [Vertex: Weight] {
            let vertices = Array(graph.vertices())
            var distances: [Vertex: Cost<Weight>] = [:]

            for vertex in vertices {
                distances[vertex] = .infinite
            }

            for iteration in 0 ..< vertices.count {
                var wasRelaxed = false

                if iteration == 0 {
                    for vertex in vertices {
                        if (distances[vertex] ?? .infinite) > .finite(.zero) {
                            distances[vertex] = .finite(.zero)
                            wasRelaxed = true
                        }
                    }
                }

                for source in vertices {
                    for edge in graph.outgoingEdges(of: source) {
                        guard let destination = graph.destination(of: edge) else { continue }

                        let sourceCost = distances[source] ?? .infinite
                        let weight = edgeWeight.costToExplore(edge, graph)
                        let newCost = sourceCost + weight

                        let destinationCost = distances[destination] ?? .infinite
                        if newCost < destinationCost {
                            distances[destination] = newCost
                            wasRelaxed = true
                        }
                    }
                }

                if !wasRelaxed { break }
            }

            for source in vertices {
                for edge in graph.outgoingEdges(of: source) {
                    guard let destination = graph.destination(of: edge) else { continue }

                    let sourceCost = distances[source] ?? .infinite
                    let weight = edgeWeight.costToExplore(edge, graph)
                    let newCost = sourceCost + weight

                    let destinationCost = distances[destination] ?? .infinite
                    if newCost < destinationCost {
                        return [:]
                    }
                }
            }

            return Dictionary(
                uniqueKeysWithValues:
                    vertices.compactMap { vertex in
                        guard case .finite(let weight) = distances[vertex] else { return nil }
                        return (vertex, weight)
                    }
            )
        }

        /// Creates a reweighted cost definition.
        ///
        /// - Parameter reweightingValues: The reweighting values for vertices.
        /// - Returns: A cost definition that applies reweighting.
        @usableFromInline
        func createReweightedCostDefinition(reweightingValues: [Vertex: Weight]) -> CostDefinition<Graph, Weight> {
            return CostDefinition { edge, graph in
                guard let source = graph.source(of: edge),
                    let destination = graph.destination(of: edge)
                else {
                    return .zero
                }

                let originalWeight = self.edgeWeight.costToExplore(edge, graph)
                let sourceReweighting = reweightingValues[source] ?? .zero
                let destinationReweighting = reweightingValues[destination] ?? .zero
                return originalWeight + sourceReweighting - destinationReweighting
            }
        }
    }

    extension Johnson: ShortestPathsForAllPairsAlgorithm {
        @inlinable
        public func shortestPathsForAllPairs(in graph: Graph) -> AllPairsShortestPaths<Vertex, Edge, Weight> {
            shortestPathsForAllPairs(in: graph, observation: nil)
        }
    }

    extension Johnson: AlgorithmObserving {}
#endif

#if !GRAPHS_USES_TRAITS || GRAPHS_PATHFINDING
    extension Johnson.Event: VertexExaminedEvent, EdgeExaminedEvent {
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
