#if !GRAPHS_USES_TRAITS || GRAPHS_PATHFINDING
    import Collections
    import DequeModule

    /// The Shortest Path Faster Algorithm (SPFA) for finding shortest paths in graphs with negative edge weights.
    ///
    /// SPFA is a queue-based optimization of Bellman-Ford. Instead of iterating over all edges V-1 times,
    /// it maintains a FIFO queue of vertices whose distances were updated, relaxing only their outgoing edges.
    /// Average case O(E), worst case O(VE). Handles negative weights and detects negative cycles.
    public struct SPFA<
        Graph: IncidenceGraph & VertexListGraph,
        Weight: AdditiveArithmetic & Comparable
    >
    where
        Graph.VertexDescriptor: Hashable
    {
        public typealias Vertex = Graph.VertexDescriptor
        public typealias Edge = Graph.EdgeDescriptor
        /// Details about a successful edge relaxation.
        public typealias Relaxation = EdgeRelaxation<Edge, Weight>

        /// An event emitted while SPFA runs.
        public enum Event {
            /// A dequeued vertex was examined.
            case vertexExamined(Vertex)
            /// An outgoing edge was examined.
            case edgeExamined(Edge)
            /// An edge improved its destination's distance.
            case edgeRelaxed(Relaxation)
            /// An edge did not improve its destination's distance.
            case edgeNotRelaxed(Edge)
            /// A vertex exceeded the enqueue limit, indicating a negative cycle.
            case negativeCycleDetected(Vertex)
        }

        /// Selectors for SPFA events.
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
            /// Selects successful edge relaxations.
            public static var edgeRelaxed: AlgorithmEventCase<Event, Relaxation> {
                .init {
                    guard case .edgeRelaxed(let relaxation) = $0 else { return nil }
                    return relaxation
                }
            }
            /// Selects edges that were not relaxed.
            public static var edgeNotRelaxed: AlgorithmEventCase<Event, Edge> {
                .init {
                    guard case .edgeNotRelaxed(let value) = $0 else { return nil }
                    return value
                }
            }
            /// Selects vertices that indicated a negative cycle.
            public static var negativeCycleDetected: AlgorithmEventCase<Event, Vertex> {
                .init {
                    guard case .negativeCycleDetected(let value) = $0 else { return nil }
                    return value
                }
            }
        }

        /// A result from the SPFA algorithm.
        ///
        /// Contains the computed distances, predecessor edges, and whether a negative cycle was detected.
        public struct Result {
            public let distances: [Vertex: Cost<Weight>]
            public let predecessors: [Vertex: Edge?]
            public let hasNegativeCycle: Bool

            @inlinable
            public init(distances: [Vertex: Cost<Weight>], predecessors: [Vertex: Edge?], hasNegativeCycle: Bool) {
                self.distances = distances
                self.predecessors = predecessors
                self.hasNegativeCycle = hasNegativeCycle
            }
        }

        @usableFromInline
        let graph: Graph
        @usableFromInline
        let edgeWeight: CostDefinition<Graph, Weight>

        @inlinable
        public init(
            on graph: Graph,
            edgeWeight: CostDefinition<Graph, Weight>
        ) {
            self.graph = graph
            self.edgeWeight = edgeWeight
        }

        @inlinable
        public func shortestPathsFromSource(_ source: Vertex, observation: AlgorithmObservation<Event>? = nil) -> Result {
            var distances: [Vertex: Cost<Weight>] = [:]
            var predecessors: [Vertex: Edge?] = [:]

            // Initialize distances
            for vertex in graph.vertices() {
                distances[vertex] = .infinite
                predecessors[vertex] = nil
            }
            distances[source] = .finite(.zero)

            var queue: Deque<Vertex> = []
            var inQueue = Set<Vertex>()
            var enqueueCount: [Vertex: Int] = [:]

            queue.enqueue(source)
            inQueue.insert(source)
            enqueueCount[source] = 1

            let vertexCount = graph.vertexCount

            while let vertex = queue.dequeue() {
                inQueue.remove(vertex)
                observation?.receive(.vertexExamined(vertex))

                for edge in graph.outgoingEdges(of: vertex) {
                    guard let destinationVertex = graph.destination(of: edge) else {
                        continue
                    }

                    observation?.receive(.edgeExamined(edge))

                    guard let sourceCost = distances[vertex] else { continue }
                    let weight = edgeWeight.costToExplore(edge, graph)
                    let newCost = sourceCost + weight

                    guard let destinationCost = distances[destinationVertex] else { continue }
                    if newCost < destinationCost {
                        guard case .finite(let relaxedCost) = newCost else {
                            preconditionFailure("An improved SPFA cost must be finite")
                        }
                        distances[destinationVertex] = newCost
                        predecessors[destinationVertex] = edge
                        observation?.receive(.edgeRelaxed(.init(edge: edge, newCost: relaxedCost)))

                        if !inQueue.contains(destinationVertex) {
                            queue.enqueue(destinationVertex)
                            inQueue.insert(destinationVertex)
                            let count = (enqueueCount[destinationVertex] ?? 0) + 1
                            enqueueCount[destinationVertex] = count

                            if count > vertexCount {
                                observation?.receive(.negativeCycleDetected(destinationVertex))
                                return Result(
                                    distances: distances,
                                    predecessors: predecessors,
                                    hasNegativeCycle: true
                                )
                            }
                        }
                    } else {
                        observation?.receive(.edgeNotRelaxed(edge))
                    }
                }
            }

            return Result(
                distances: distances,
                predecessors: predecessors,
                hasNegativeCycle: false
            )
        }

    }

    extension SPFA: AlgorithmObserving {}

    extension SPFA.Event: VertexExaminedEvent, EdgeExaminedEvent, EdgeRelaxedEvent {
        /// Returns the examined vertex carried by the event.
        @inlinable
        public static func examinedVertex(from event: Self) -> Graph.VertexDescriptor? {
            guard case .vertexExamined(let vertex) = event else { return nil }
            return vertex
        }

        /// Returns the examined edge carried by the event.
        @inlinable
        public static func examinedEdge(from event: Self) -> Graph.EdgeDescriptor? {
            guard case .edgeExamined(let edge) = event else { return nil }
            return edge
        }

        /// Returns successful edge-relaxation details carried by the event.
        @inlinable
        public static func relaxation(from event: Self) -> SPFA.Relaxation? {
            guard case .edgeRelaxed(let relaxation) = event else { return nil }
            return relaxation
        }
    }
#endif
