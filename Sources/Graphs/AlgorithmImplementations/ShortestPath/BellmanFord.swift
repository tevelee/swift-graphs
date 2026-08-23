#if !GRAPHS_USES_TRAITS || GRAPHS_PATHFINDING
    /// The Bellman-Ford algorithm for finding shortest paths in graphs with negative edge weights.
    ///
    /// Bellman-Ford can handle graphs with negative edge weights and detects negative cycles.
    /// It has a time complexity of O(VE) where V is the number of vertices and E is the number of edges.
    public struct BellmanFord<
        Graph: IncidenceGraph & EdgeListGraph & VertexListGraph,
        Weight: AdditiveArithmetic & Comparable
    >
    where
        Graph.VertexDescriptor: Hashable
    {
        public typealias Vertex = Graph.VertexDescriptor
        public typealias Edge = Graph.EdgeDescriptor
        /// Details about a successful edge relaxation.
        public typealias Relaxation = EdgeRelaxation<Edge, Weight>

        /// An event emitted while Bellman-Ford runs.
        public enum Event {
            /// A vertex was examined during initialization.
            case vertexExamined(Vertex)
            /// An edge was examined for relaxation.
            case edgeExamined(Edge)
            /// An edge improved its destination's distance.
            case edgeRelaxed(Relaxation)
            /// An edge did not improve its destination's distance.
            case edgeNotRelaxed(Edge)
            /// An edge demonstrated a reachable negative cycle.
            case negativeCycleDetected(Edge)
            /// A relaxation iteration was completed.
            case relaxationIterationCompleted(Int)
        }

        /// Selectors for Bellman-Ford events.
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
            /// Selects detected negative-cycle edges.
            public static var negativeCycleDetected: AlgorithmEventCase<Event, Edge> {
                .init {
                    guard case .negativeCycleDetected(let value) = $0 else { return nil }
                    return value
                }
            }
            /// Selects completed relaxation iteration indices.
            public static var relaxationIterationCompleted: AlgorithmEventCase<Event, Int> {
                .init {
                    guard case .relaxationIterationCompleted(let value) = $0 else { return nil }
                    return value
                }
            }
        }

        /// A result from the Bellman-Ford algorithm.
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
                observation?.receive(.vertexExamined(vertex))
                distances[vertex] = .infinite
                predecessors[vertex] = nil
            }
            distances[source] = .finite(.zero)

            let vertices = Array(graph.vertices())
            for iteration in 0 ..< vertices.count - 1 {
                var wasRelaxed = false

                for edge in graph.edges() {
                    guard let sourceVertex = graph.source(of: edge),
                        let destinationVertex = graph.destination(of: edge)
                    else {
                        continue
                    }

                    observation?.receive(.edgeExamined(edge))

                    guard let sourceCost = distances[sourceVertex] else { continue }
                    let weight = edgeWeight.costToExplore(edge, graph)
                    let newCost = sourceCost + weight

                    guard let destinationCost = distances[destinationVertex] else { continue }
                    if newCost < destinationCost {
                        guard case .finite(let relaxedCost) = newCost else {
                            preconditionFailure("An improved Bellman-Ford cost must be finite")
                        }
                        distances[destinationVertex] = newCost
                        predecessors[destinationVertex] = edge
                        wasRelaxed = true
                        observation?.receive(.edgeRelaxed(.init(edge: edge, newCost: relaxedCost)))
                    } else {
                        observation?.receive(.edgeNotRelaxed(edge))
                    }
                }

                observation?.receive(.relaxationIterationCompleted(iteration))
                if !wasRelaxed { break }
            }

            var hasNegativeCycle = false
            for edge in graph.edges() {
                guard let sourceVertex = graph.source(of: edge),
                    let destinationVertex = graph.destination(of: edge)
                else {
                    continue
                }

                observation?.receive(.edgeExamined(edge))

                guard let sourceCost = distances[sourceVertex] else { continue }
                let weight = edgeWeight.costToExplore(edge, graph)
                let newCost = sourceCost + weight

                guard let destinationCost = distances[destinationVertex] else { continue }
                if newCost < destinationCost {
                    hasNegativeCycle = true
                    observation?.receive(.negativeCycleDetected(edge))
                    break
                }
            }

            return Result(
                distances: distances,
                predecessors: predecessors,
                hasNegativeCycle: hasNegativeCycle
            )
        }

        @inlinable
        public func shortestPath(from source: Vertex, to destination: Vertex, observation: AlgorithmObservation<Event>? = nil) -> Path<Vertex, Edge>? {
            let result = shortestPathsFromSource(source, observation: observation)

            guard !result.hasNegativeCycle else {
                return nil
            }

            guard case .finite = result.distances[destination] else {
                return nil
            }

            var currentVertex = destination
            var pathVertices: [Vertex] = [destination]
            var pathEdges: [Edge] = []

            while let edge = result.predecessors[currentVertex] {
                guard let validEdge = edge else { break }
                pathEdges.insert(validEdge, at: 0)
                guard let predecessor = graph.source(of: validEdge) else { break }
                pathVertices.insert(predecessor, at: 0)
                currentVertex = predecessor
                if predecessor == source { break }
            }

            // Only add source if it's not already the first vertex
            if pathVertices.first != source {
                pathVertices.insert(source, at: 0)
            }

            return Path(
                source: source,
                destination: destination,
                vertices: pathVertices,
                edges: pathEdges
            )
        }
    }

    extension BellmanFord: ShortestPathAlgorithm {
        @inlinable
        public func shortestPath(
            from source: Vertex,
            to destination: Vertex,
            in graph: Graph,
            observation: AlgorithmObservation<Event>?
        ) -> Path<Vertex, Edge>? {
            shortestPath(from: source, to: destination, observation: observation)
        }
    }

    extension BellmanFord: AlgorithmObserving {}

    extension BellmanFord.Event: VertexExaminedEvent, EdgeExaminedEvent, EdgeRelaxedEvent {
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
        public static func relaxation(from event: Self) -> BellmanFord.Relaxation? {
            guard case .edgeRelaxed(let relaxation) = event else { return nil }
            return relaxation
        }
    }
#endif
