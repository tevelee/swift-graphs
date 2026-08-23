#if !GRAPHS_USES_TRAITS || GRAPHS_PATHFINDING
    /// Uniform Cost Search algorithm for finding shortest paths from a source vertex.
    ///
    /// Uniform Cost Search is a search algorithm that explores vertices in order of their
    /// cost from the source. It guarantees finding the shortest path in weighted graphs.
    ///
    /// - Complexity: O(E + V log V) where E is the number of edges and V is the number of vertices
    public struct UniformCostSearch<
        Graph: IncidenceGraph,
        Weight: Numeric & Comparable
    >
    where
        Graph.VertexDescriptor: Hashable,
        Weight.Magnitude == Weight
    {
        /// The vertex type of the graph.
        public typealias Vertex = Graph.VertexDescriptor
        /// The edge type of the graph.
        public typealias Edge = Graph.EdgeDescriptor
        /// Details about a successful edge relaxation.
        public typealias Relaxation = EdgeRelaxation<Edge, Weight>

        /// An event emitted while uniform-cost search runs.
        public enum Event {
            /// A vertex was removed from the priority queue for examination.
            case vertexExamined(Vertex)
            /// An outgoing edge was examined.
            case edgeExamined(Edge)
            /// An edge improved its destination's distance.
            case edgeRelaxed(Relaxation)
            /// An edge did not improve its destination's distance.
            case edgeNotRelaxed(Edge)
            /// A vertex and all of its outgoing edges were finished.
            case vertexFinished(Vertex)
        }

        /// Selectors for uniform-cost search events.
        public enum EventCases {
            /// Selects examined vertices.
            public static var vertexExamined: AlgorithmEventCase<Event, Vertex> {
                .init {
                    guard case .vertexExamined(let vertex) = $0 else { return nil }
                    return vertex
                }
            }
            /// Selects examined edges.
            public static var edgeExamined: AlgorithmEventCase<Event, Edge> {
                .init {
                    guard case .edgeExamined(let edge) = $0 else { return nil }
                    return edge
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
                    guard case .edgeNotRelaxed(let edge) = $0 else { return nil }
                    return edge
                }
            }
            /// Selects finished vertices.
            public static var vertexFinished: AlgorithmEventCase<Event, Vertex> {
                .init {
                    guard case .vertexFinished(let vertex) = $0 else { return nil }
                    return vertex
                }
            }
        }

        /// The result of a uniform cost search iteration.
        public struct Result {
            /// The vertex type of the graph.
            public typealias Vertex = Graph.VertexDescriptor
            /// The edge type of the graph.
            public typealias Edge = Graph.EdgeDescriptor
            /// The source vertex from which shortest paths were computed.
            public let source: Vertex
            /// The current vertex being examined.
            public let currentVertex: Vertex
            /// The distance property type.
            public let distanceProperty: any VertexProperty<Cost<Weight>>.Type
            /// The predecessor edge property type.
            public let predecessorEdgeProperty: any VertexProperty<Edge?>.Type
            /// The property map containing distances and predecessors.
            public let propertyMap: any PropertyMap<Vertex, VertexPropertyValues>

            /// Creates a new result.
            @inlinable
            public init(
                source: Vertex,
                currentVertex: Vertex,
                distanceProperty: any VertexProperty<Cost<Weight>>.Type,
                predecessorEdgeProperty: any VertexProperty<Edge?>.Type,
                propertyMap: any PropertyMap<Vertex, VertexPropertyValues>
            ) {
                self.source = source
                self.currentVertex = currentVertex
                self.distanceProperty = distanceProperty
                self.predecessorEdgeProperty = predecessorEdgeProperty
                self.propertyMap = propertyMap
            }
        }

        /// A priority queue item for uniform cost search.
        public struct PriorityItem {
            /// The vertex type of the graph.
            public typealias Vertex = Graph.VertexDescriptor
            /// The vertex.
            public let vertex: Vertex
            /// The cost to reach this vertex.
            public let cost: Cost<Weight>

            /// Creates a new priority item.
            @inlinable
            public init(vertex: Vertex, cost: Cost<Weight>) {
                self.vertex = vertex
                self.cost = cost
            }
        }

        @usableFromInline
        let graph: Graph
        @usableFromInline
        let source: Vertex
        @usableFromInline
        let edgeWeight: CostDefinition<Graph, Weight>

        /// Creates a new uniform cost search algorithm instance.
        ///
        /// - Parameters:
        ///   - graph: The graph to search in.
        ///   - source: The source vertex.
        ///   - edgeWeight: The cost definition for edge weights.
        @inlinable
        public init(
            on graph: Graph,
            from source: Vertex,
            edgeWeight: CostDefinition<Graph, Weight>
        ) {
            self.graph = graph
            self.source = source
            self.edgeWeight = edgeWeight
        }

        /// Creates an iterator for the uniform cost search.
        ///
        /// - Parameter observation: An optional observation of the algorithm's progress.
        /// - Returns: An iterator for the search.
        @inlinable
        public func makeIterator(observation: AlgorithmObservation<Event>?) -> Iterator {
            Iterator(
                graph: graph,
                source: source,
                edgeWeight: edgeWeight,
                observation: observation
            )
        }

        /// An iterator for uniform cost search.
        public struct Iterator {
            @usableFromInline
            let graph: Graph
            @usableFromInline
            let source: Vertex
            @usableFromInline
            let edgeWeight: CostDefinition<Graph, Weight>
            @usableFromInline
            let observation: AlgorithmObservation<Event>?
            @usableFromInline
            var queue = PriorityQueue<PriorityItem>()
            @usableFromInline
            var visited: Set<Vertex> = []

            @usableFromInline
            var propertyMap: DictionaryPropertyMap<Vertex, VertexPropertyValues>
            @usableFromInline
            let distanceProperty: any VertexProperty<Cost>.Type = DistanceProperty<Weight>.self
            @usableFromInline
            let predecessorEdgeProperty: any VertexProperty<Edge?>.Type = PredecessorEdgeProperty<Edge>.self

            /// Creates a new iterator.
            ///
            /// - Parameters:
            ///   - graph: The graph to search in.
            ///   - source: The source vertex.
            ///   - edgeWeight: The cost definition for edge weights.
            ///   - observation: An optional algorithm observation.
            @inlinable
            public init(
                graph: Graph,
                source: Vertex,
                edgeWeight: CostDefinition<Graph, Weight>,
                observation: AlgorithmObservation<Event>? = nil
            ) {
                self.graph = graph
                self.source = source
                self.edgeWeight = edgeWeight
                self.observation = observation
                self.propertyMap = graph.makeVertexPropertyMap()

                // UCS only initializes the source node, not all nodes
                propertyMap[source][distanceProperty] = .finite(.zero)
                self.queue.enqueue(.init(vertex: source, cost: .finite(.zero)))
            }

            /// Gets the next result from the search.
            ///
            /// - Returns: The next result, or `nil` if the search is complete.
            @inlinable
            public mutating func next() -> Result? {
                var currentVertex: Vertex?
                while let popped = queue.dequeue() {
                    if visited.contains(popped.vertex) { continue }
                    let stored = propertyMap[popped.vertex][distanceProperty]
                    if popped.cost != stored { continue }
                    currentVertex = popped.vertex
                    break
                }

                guard let currentVertex else { return nil }

                observation?.receive(.vertexExamined(currentVertex))

                let currentCost = propertyMap[currentVertex][distanceProperty]
                for edge in graph.outgoingEdges(of: currentVertex) {
                    observation?.receive(.edgeExamined(edge))

                    guard let destination = graph.destination(of: edge) else { continue }
                    if visited.contains(destination) { continue }

                    let weight = edgeWeight.costToExplore(edge, graph)
                    let newCost = currentCost + weight

                    // UCS: Only add to queue if we haven't seen this vertex before or found a better path
                    let destinationCost = propertyMap[destination][distanceProperty]
                    if newCost < destinationCost {
                        guard case .finite(let relaxedCost) = newCost else {
                            preconditionFailure("An improved uniform-cost search cost must be finite")
                        }
                        propertyMap[destination][distanceProperty] = newCost
                        propertyMap[destination][predecessorEdgeProperty] = edge
                        queue.enqueue(.init(vertex: destination, cost: newCost))
                        observation?.receive(.edgeRelaxed(.init(edge: edge, newCost: relaxedCost)))
                    } else {
                        observation?.receive(.edgeNotRelaxed(edge))
                    }
                }

                visited.insert(currentVertex)
                observation?.receive(.vertexFinished(currentVertex))

                return Result(
                    source: source,
                    currentVertex: currentVertex,
                    distanceProperty: distanceProperty,
                    predecessorEdgeProperty: predecessorEdgeProperty,
                    propertyMap: propertyMap
                )
            }
        }

    }

    extension UniformCostSearch.Iterator: IteratorProtocol {}

    extension UniformCostSearch: Sequence {
        @inlinable
        public func makeIterator() -> Iterator {
            makeIterator(observation: nil)
        }
    }

    extension UniformCostSearch.PriorityItem: Equatable {
        @inlinable
        public static func == (lhs: Self, rhs: Self) -> Bool {
            lhs.vertex == rhs.vertex
        }
    }

    extension UniformCostSearch.PriorityItem: Comparable {
        @inlinable
        public static func < (lhs: Self, rhs: Self) -> Bool {
            lhs.cost < rhs.cost
        }
    }

    extension UniformCostSearch.Result {
        /// Gets the current distance.
        ///
        /// - Returns: The current distance.
        @inlinable
        public func currentDistance() -> Weight {
            switch distance(of: currentVertex) {
                case .finite(let value):
                    return value
                case .infinite:
                    assertionFailure("The currently examined vertex should always be reachable")
                    return .zero
            }
        }

        /// Gets the predecessor vertex.
        ///
        /// - Parameter graph: The graph.
        /// - Returns: The predecessor vertex.
        @inlinable
        public func predecessor(in graph: some IncidenceGraph<Vertex, Edge>) -> Vertex {
            predecessor(of: currentVertex, in: graph).unwrap(
                orReport: "The currently examined vertex should always have a predecessor"
            )
        }

        /// Gets the predecessor edge.
        ///
        /// - Returns: The predecessor edge.
        @inlinable
        public func predecessorEdge() -> Edge {
            predecessorEdge(of: currentVertex).unwrap(
                orReport: "The currently examined vertex should always have a predecessor edge"
            )
        }

        /// Gets the vertices in the current path.
        ///
        /// - Parameter graph: The graph.
        /// - Returns: The vertices in the current path.
        @inlinable
        public func vertices(in graph: some IncidenceGraph<Vertex, Edge>) -> [Vertex] {
            vertices(to: currentVertex, in: graph)
        }

        /// Gets the edges in the current path.
        ///
        /// - Parameter graph: The graph.
        /// - Returns: The edges in the current path.
        @inlinable
        public func edges(in graph: some IncidenceGraph<Vertex, Edge>) -> [Edge] {
            edges(to: currentVertex, in: graph)
        }

        /// Gets the current path.
        ///
        /// - Parameter graph: The graph.
        /// - Returns: The current path.
        @inlinable
        public func path(in graph: some IncidenceGraph<Vertex, Edge>) -> [(vertex: Vertex, edge: Edge)] {
            path(to: currentVertex, in: graph)
        }

        /// Gets the distance to a vertex.
        ///
        /// - Parameter vertex: The vertex.
        /// - Returns: The distance to the vertex.
        @inlinable
        public func distance(of vertex: Vertex) -> Cost<Weight> {
            propertyMap[vertex][distanceProperty]
        }

        /// Gets the predecessor of a vertex.
        ///
        /// - Parameters:
        ///   - vertex: The vertex.
        ///   - graph: The graph.
        /// - Returns: The predecessor vertex, if one exists.
        @inlinable
        public func predecessor(of vertex: Vertex, in graph: some IncidenceGraph<Vertex, Edge>) -> Vertex? {
            predecessorEdge(of: vertex).flatMap(graph.source)
        }

        /// Gets the predecessor edge of a vertex.
        ///
        /// - Parameter vertex: The vertex.
        /// - Returns: The predecessor edge, if one exists.
        @inlinable
        public func predecessorEdge(of vertex: Vertex) -> Edge? {
            propertyMap[vertex][predecessorEdgeProperty]
        }

        /// Gets the vertices to a destination.
        ///
        /// - Parameters:
        ///   - destination: The destination vertex.
        ///   - graph: The graph.
        /// - Returns: The vertices to the destination.
        @inlinable
        public func vertices(to destination: Vertex, in graph: some IncidenceGraph<Vertex, Edge>) -> [Vertex] {
            [source] + path(to: destination, in: graph).map(\.vertex)
        }

        /// Gets the edges to a destination.
        ///
        /// - Parameters:
        ///   - destination: The destination vertex.
        ///   - graph: The graph.
        /// - Returns: The edges to the destination.
        @inlinable
        public func edges(to destination: Vertex, in graph: some IncidenceGraph<Vertex, Edge>) -> [Edge] {
            path(to: destination, in: graph).map(\.edge)
        }

        /// Gets the path to a destination.
        ///
        /// - Parameters:
        ///   - destination: The destination vertex.
        ///   - graph: The graph.
        /// - Returns: The path to the destination.
        @inlinable
        public func path(to destination: Vertex, in graph: some IncidenceGraph<Vertex, Edge>) -> [(vertex: Vertex, edge: Edge)] {
            var currentVertex = destination
            var result: [(Vertex, Edge)] = []
            while let predecessorEdge = predecessorEdge(of: currentVertex) {
                result.insert((currentVertex, predecessorEdge), at: 0)
                guard let predecessor = graph.source(of: predecessorEdge) else { break }
                currentVertex = predecessor
            }
            return result
        }

        /// Checks if there is a path to a vertex.
        ///
        /// - Parameter vertex: The vertex.
        /// - Returns: `true` if there is a path, `false` otherwise.
        @inlinable
        public func hasPath(to vertex: Vertex) -> Bool {
            propertyMap[vertex][distanceProperty] != .infinite
        }
    }

    extension UniformCostSearch: AlgorithmObservationSequence {}

    extension UniformCostSearch.Event: VertexExaminedEvent, EdgeExaminedEvent, EdgeRelaxedEvent {
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
        public static func relaxation(from event: Self) -> UniformCostSearch.Relaxation? {
            guard case .edgeRelaxed(let relaxation) = event else { return nil }
            return relaxation
        }
    }

    extension UniformCostSearch.Result: ShortestPathResult {}

    extension UniformCostSearch.PriorityItem: Sendable where Vertex: Sendable, Weight: Sendable {}
#endif
