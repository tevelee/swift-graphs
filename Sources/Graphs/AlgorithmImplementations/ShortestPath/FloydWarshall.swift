#if !GRAPHS_USES_TRAITS || GRAPHS_PATHFINDING
    /// Floyd-Warshall algorithm for computing shortest paths between all pairs of vertices.
    ///
    /// The Floyd-Warshall algorithm is a dynamic programming algorithm that finds shortest paths
    /// between all pairs of vertices in a weighted graph. It can handle negative edge weights
    /// but cannot detect negative cycles.
    ///
    /// - Complexity: O(V³) where V is the number of vertices
    public struct FloydWarshall<
        Graph: IncidenceGraph & VertexListGraph,
        Weight: AdditiveArithmetic & Comparable
    >
    where
        Graph.VertexDescriptor: Hashable
    {
        /// The vertex type of the graph.
        public typealias Vertex = Graph.VertexDescriptor
        /// The edge type of the graph.
        public typealias Edge = Graph.EdgeDescriptor

        /// A distance-table update reported by Floyd-Warshall.
        public struct DistanceUpdate {
            /// The path source.
            public let source: Vertex
            /// The path destination.
            public let destination: Vertex
            /// The improved distance.
            public let distance: Cost<Weight>

            /// Creates a distance-update payload.
            @inlinable
            public init(source: Vertex, destination: Vertex, distance: Cost<Weight>) {
                self.source = source
                self.destination = destination
                self.distance = distance
            }
        }

        /// An event emitted while Floyd-Warshall runs.
        public enum Event {
            /// A vertex was examined.
            case vertexExamined(Vertex)
            /// An edge was examined.
            case edgeExamined(Edge)
            /// A distance-table entry was updated.
            case distanceUpdated(DistanceUpdate)
            /// An intermediate-vertex iteration was completed.
            case intermediateVertexCompleted(Int)
        }

        /// Selectors for Floyd-Warshall events.
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
            /// Selects distance updates.
            public static var distanceUpdated: AlgorithmEventCase<Event, DistanceUpdate> {
                .init {
                    guard case .distanceUpdated(let value) = $0 else { return nil }
                    return value
                }
            }
            /// Selects completed intermediate-vertex indices.
            public static var intermediateVertexCompleted: AlgorithmEventCase<Event, Int> {
                .init {
                    guard case .intermediateVertexCompleted(let value) = $0 else { return nil }
                    return value
                }
            }
        }

        @usableFromInline
        let graph: Graph
        @usableFromInline
        let edgeWeight: CostDefinition<Graph, Weight>

        /// Creates a new Floyd-Warshall algorithm instance.
        ///
        /// - Parameters:
        ///   - graph: The graph to compute shortest paths for.
        ///   - edgeWeight: The cost definition for edge weights.
        @inlinable
        public init(
            on graph: Graph,
            edgeWeight: CostDefinition<Graph, Weight>
        ) {
            self.graph = graph
            self.edgeWeight = edgeWeight
        }

        /// Computes shortest paths between all pairs of vertices.
        ///
        /// - Parameter observation: An optional observation of the algorithm's progress.
        /// - Returns: The shortest paths between all pairs of vertices.
        @inlinable
        public func shortestPathsForAllPairs(observation: AlgorithmObservation<Event>? = nil) -> AllPairsShortestPaths<Vertex, Edge, Weight> {
            let vertices = Array(graph.vertices())
            let vertexCount = vertices.count

            var distances: [Vertex: [Vertex: Cost<Weight>]] = [:]
            var predecessors: [Vertex: [Vertex: Edge?]] = [:]

            for source in vertices {
                distances[source] = [:]
                predecessors[source] = [:]
                for destination in vertices {
                    distances[source]?[destination] = source == destination ? .finite(.zero) : .infinite
                    predecessors[source]?[destination] = nil
                }
            }

            for source in vertices {
                observation?.receive(.vertexExamined(source))
                for edge in graph.outgoingEdges(of: source) {
                    guard let destination = graph.destination(of: edge) else { continue }
                    observation?.receive(.edgeExamined(edge))
                    let weight = edgeWeight.costToExplore(edge, graph)
                    distances[source]?[destination] = .finite(weight)
                    predecessors[source]?[destination] = edge
                    observation?.receive(.distanceUpdated(.init(source: source, destination: destination, distance: .finite(weight))))
                }
            }

            for intermediateIndex in 0 ..< vertexCount {
                let intermediateVertex = vertices[intermediateIndex]
                observation?.receive(.vertexExamined(intermediateVertex))

                for sourceIndex in 0 ..< vertexCount {
                    let sourceVertex = vertices[sourceIndex]
                    for destinationIndex in 0 ..< vertexCount {
                        let destinationVertex = vertices[destinationIndex]

                        let currentDistance = distances[sourceVertex]?[destinationVertex] ?? .infinite
                        let sourceToIntermediate = distances[sourceVertex]?[intermediateVertex] ?? .infinite
                        let intermediateToDestination = distances[intermediateVertex]?[destinationVertex] ?? .infinite
                        let newDistance = sourceToIntermediate + intermediateToDestination

                        if newDistance < currentDistance {
                            distances[sourceVertex]?[destinationVertex] = newDistance
                            let intermediatePredecessor = predecessors[intermediateVertex]?[destinationVertex]
                            predecessors[sourceVertex]?[destinationVertex] = intermediatePredecessor
                            observation?.receive(.distanceUpdated(.init(source: sourceVertex, destination: destinationVertex, distance: newDistance)))
                        }
                    }
                }

                observation?.receive(.intermediateVertexCompleted(intermediateIndex))
            }

            return AllPairsShortestPaths(
                distances: distances,
                predecessors: predecessors
            )
        }
    }

    extension FloydWarshall: ShortestPathsForAllPairsAlgorithm {
        @inlinable
        public func shortestPathsForAllPairs(in graph: Graph, observation: AlgorithmObservation<Event>?) -> AllPairsShortestPaths<Vertex, Edge, Weight> {
            shortestPathsForAllPairs(observation: observation)
        }
    }

    extension FloydWarshall: AlgorithmObserving {}

    extension FloydWarshall {
        /// Creates a new Floyd-Warshall algorithm instance.
        ///
        /// - Parameters:
        ///   - graph: The graph to compute shortest paths for.
        ///   - edgeWeight: The cost definition for edge weights.
        /// - Returns: A new Floyd-Warshall algorithm instance.
        @inlinable
        public static func create<G: IncidenceGraph & VertexListGraph, W: AdditiveArithmetic & Comparable>(
            on graph: G,
            edgeWeight: CostDefinition<G, W>
        ) -> FloydWarshall<G, W> where G.VertexDescriptor: Hashable {
            FloydWarshall<G, W>(on: graph, edgeWeight: edgeWeight)
        }
    }
#endif

#if !GRAPHS_USES_TRAITS || GRAPHS_PATHFINDING
    extension FloydWarshall.Event: VertexExaminedEvent, EdgeExaminedEvent {
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
