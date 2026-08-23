#if !GRAPHS_USES_TRAITS || GRAPHS_PATHFINDING
    /// Bidirectional Dijkstra's algorithm for finding shortest paths between two vertices.
    ///
    /// Bidirectional Dijkstra's algorithm searches from both the source and destination
    /// simultaneously, meeting in the middle. This can be more efficient than standard
    /// Dijkstra's algorithm for point-to-point shortest path queries.
    ///
    /// - Complexity: O(E log V) where E is the number of edges and V is the number of vertices
    public struct BidirectionalDijkstra<
        Graph: IncidenceGraph & BidirectionalGraph,
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

        public struct DirectedVertex {
            public let vertex: Vertex
            public let direction: Direction

            @inlinable
            public init(vertex: Vertex, direction: Direction) {
                self.vertex = vertex
                self.direction = direction
            }
        }

        public struct DirectedEdge {
            public let edge: Edge
            public let direction: Direction

            @inlinable
            public init(edge: Edge, direction: Direction) {
                self.edge = edge
                self.direction = direction
            }
        }

        /// Details about a successful directional edge relaxation.
        public struct Relaxation {
            /// The relaxed edge.
            public let edge: Edge
            /// The search frontier that relaxed the edge.
            public let direction: Direction
            /// The edge destination's new cost in that search frontier.
            public let newCost: Weight

            /// Creates directional edge-relaxation details.
            @inlinable
            public init(edge: Edge, direction: Direction, newCost: Weight) {
                self.edge = edge
                self.direction = direction
                self.newCost = newCost
            }
        }

        public struct Meeting {
            public let vertex: Vertex
            public let distance: Cost<Weight>

            @inlinable
            public init(vertex: Vertex, distance: Cost<Weight>) {
                self.vertex = vertex
                self.distance = distance
            }
        }

        public enum Event {
            case vertexExamined(DirectedVertex)
            case edgeExamined(DirectedEdge)
            case edgeRelaxed(Relaxation)
            case edgeNotRelaxed(DirectedEdge)
            case meetingFound(Meeting)
        }

        public enum EventCases {
            public static var vertexExamined: AlgorithmEventCase<Event, DirectedVertex> {
                .init {
                    guard case .vertexExamined(let value) = $0 else { return nil }
                    return value
                }
            }
            public static var edgeExamined: AlgorithmEventCase<Event, DirectedEdge> {
                .init {
                    guard case .edgeExamined(let value) = $0 else { return nil }
                    return value
                }
            }
            public static var edgeRelaxed: AlgorithmEventCase<Event, Relaxation> {
                .init {
                    guard case .edgeRelaxed(let value) = $0 else { return nil }
                    return value
                }
            }
            public static var edgeNotRelaxed: AlgorithmEventCase<Event, DirectedEdge> {
                .init {
                    guard case .edgeNotRelaxed(let value) = $0 else { return nil }
                    return value
                }
            }
            public static var meetingFound: AlgorithmEventCase<Event, Meeting> {
                .init {
                    guard case .meetingFound(let value) = $0 else { return nil }
                    return value
                }
            }
        }

        /// The direction of search in bidirectional Dijkstra.
        public enum Direction {
            /// Forward search from source to destination.
            case forward
            /// Backward search from destination to source.
            case backward
        }

        /// The result of a bidirectional Dijkstra search.
        public struct Result {
            /// The shortest path, if one exists.
            public let path: Path<Vertex, Edge>?
            /// The total distance of the shortest path.
            public let totalDistance: Cost<Weight>
            /// The vertex where the forward and backward searches met.
            public let meetingVertex: Vertex?

            /// Creates a new result.
            @inlinable
            public init(path: Path<Vertex, Edge>?, totalDistance: Cost<Weight>, meetingVertex: Vertex?) {
                self.path = path
                self.totalDistance = totalDistance
                self.meetingVertex = meetingVertex
            }
        }

        @usableFromInline
        let graph: Graph
        @usableFromInline
        let edgeWeight: CostDefinition<Graph, Weight>

        /// A priority queue item for bidirectional Dijkstra.
        public struct PriorityItem {
            /// The vertex.
            public let vertex: Vertex
            /// The cost to reach this vertex.
            public let cost: Cost<Weight>
            /// The search direction.
            public let direction: Direction

            /// Creates a new priority item.
            @inlinable
            public init(vertex: Vertex, cost: Cost<Weight>, direction: Direction) {
                self.vertex = vertex
                self.cost = cost
                self.direction = direction
            }
        }

        /// Creates a new bidirectional Dijkstra algorithm instance.
        ///
        /// - Parameters:
        ///   - graph: The graph to search in.
        ///   - edgeWeight: The cost definition for edge weights.
        @inlinable
        public init(
            on graph: Graph,
            edgeWeight: CostDefinition<Graph, Weight>
        ) {
            self.graph = graph
            self.edgeWeight = edgeWeight
        }

        /// Finds the shortest path between two vertices.
        ///
        /// - Parameters:
        ///   - source: The source vertex.
        ///   - destination: The destination vertex.
        ///   - observation: An optional observation of the algorithm's progress.
        /// - Returns: The shortest path result.
        @inlinable
        public func shortestPath(from source: Vertex, to destination: Vertex, observation: AlgorithmObservation<Event>? = nil) -> Result {
            var forwardDistances: [Vertex: Cost<Weight>] = [:]
            var backwardDistances: [Vertex: Cost<Weight>] = [:]
            var forwardPredecessors: [Vertex: Edge?] = [:]
            var backwardPredecessors: [Vertex: Edge?] = [:]
            var forwardVisited: Set<Vertex> = []
            var backwardVisited: Set<Vertex> = []

            var queue = PriorityQueue<PriorityItem>()

            // Initialize
            forwardDistances[source] = .finite(.zero)
            backwardDistances[destination] = .finite(.zero)
            forwardPredecessors[source] = nil
            backwardPredecessors[destination] = nil

            queue.enqueue(PriorityItem(vertex: source, cost: .finite(.zero), direction: .forward))
            queue.enqueue(PriorityItem(vertex: destination, cost: .finite(.zero), direction: .backward))

            var bestDistance: Cost<Weight> = .infinite
            var meetingVertex: Vertex?

            while let item = queue.dequeue() {
                let currentVertex = item.vertex
                let currentCost = item.cost
                let direction = item.direction

                if direction == .forward && forwardVisited.contains(currentVertex) { continue }
                if direction == .backward && backwardVisited.contains(currentVertex) { continue }

                let storedCost = direction == .forward ? forwardDistances[currentVertex] : backwardDistances[currentVertex]
                if currentCost != storedCost { continue }

                if direction == .forward {
                    forwardVisited.insert(currentVertex)
                } else {
                    backwardVisited.insert(currentVertex)
                }

                observation?.receive(.vertexExamined(.init(vertex: currentVertex, direction: direction)))

                if direction == .forward && backwardVisited.contains(currentVertex) {
                    let backwardCost = backwardDistances[currentVertex] ?? .infinite
                    if case .finite(let currentWeight) = currentCost,
                        case .finite(let backwardWeight) = backwardCost
                    {
                        let totalCost = currentWeight + backwardWeight
                        if case .finite(let bestWeight) = bestDistance {
                            if totalCost < bestWeight {
                                bestDistance = .finite(totalCost)
                                meetingVertex = currentVertex
                                observation?.receive(.meetingFound(.init(vertex: currentVertex, distance: bestDistance)))
                            }
                        } else {
                            bestDistance = .finite(totalCost)
                            meetingVertex = currentVertex
                            observation?.receive(.meetingFound(.init(vertex: currentVertex, distance: bestDistance)))
                        }
                    }
                } else if direction == .backward && forwardVisited.contains(currentVertex) {
                    let forwardCost = forwardDistances[currentVertex] ?? .infinite
                    if case .finite(let currentWeight) = currentCost,
                        case .finite(let forwardWeight) = forwardCost
                    {
                        let totalCost = forwardWeight + currentWeight
                        if case .finite(let bestWeight) = bestDistance {
                            if totalCost < bestWeight {
                                bestDistance = .finite(totalCost)
                                meetingVertex = currentVertex
                                observation?.receive(.meetingFound(.init(vertex: currentVertex, distance: bestDistance)))
                            }
                        } else {
                            bestDistance = .finite(totalCost)
                            meetingVertex = currentVertex
                            observation?.receive(.meetingFound(.init(vertex: currentVertex, distance: bestDistance)))
                        }
                    }
                }

                if direction == .forward {
                    exploreForward(
                        from: currentVertex,
                        currentCost: currentCost,
                        distances: &forwardDistances,
                        predecessors: &forwardPredecessors,
                        queue: &queue,
                        observation: observation
                    )
                } else {
                    exploreBackward(
                        from: currentVertex,
                        currentCost: currentCost,
                        distances: &backwardDistances,
                        predecessors: &backwardPredecessors,
                        queue: &queue,
                        observation: observation
                    )
                }
            }

            let path = meetingVertex.map {
                reconstructPath(
                    from: source,
                    to: destination,
                    meetingVertex: $0,
                    forwardPredecessors: forwardPredecessors,
                    backwardPredecessors: backwardPredecessors
                )
            }

            return Result(
                path: path,
                totalDistance: bestDistance,
                meetingVertex: meetingVertex
            )
        }

        /// Explores forward from a vertex.
        ///
        /// - Parameters:
        ///   - currentVertex: The current vertex.
        ///   - currentCost: The current cost to reach the vertex.
        ///   - distances: The distances dictionary to update.
        ///   - predecessors: The predecessors dictionary to update.
        ///   - queue: The priority queue to add new items to.
        ///   - observation: An optional algorithm observation.
        @usableFromInline
        func exploreForward(
            from currentVertex: Vertex,
            currentCost: Cost<Weight>,
            distances: inout [Vertex: Cost<Weight>],
            predecessors: inout [Vertex: Edge?],
            queue: inout PriorityQueue<PriorityItem>,
            observation: AlgorithmObservation<Event>?
        ) {
            for edge in graph.outgoingEdges(of: currentVertex) {
                guard let neighbor = graph.destination(of: edge) else { continue }

                observation?.receive(.edgeExamined(.init(edge: edge, direction: .forward)))

                let weight = edgeWeight.costToExplore(edge, graph)
                let newCost = currentCost + weight

                let currentBestCost = distances[neighbor] ?? .infinite
                if newCost < currentBestCost {
                    guard case .finite(let relaxedCost) = newCost else {
                        preconditionFailure("An improved bidirectional Dijkstra cost must be finite")
                    }
                    distances[neighbor] = newCost
                    predecessors[neighbor] = edge
                    queue.enqueue(PriorityItem(vertex: neighbor, cost: newCost, direction: .forward))
                    observation?.receive(
                        .edgeRelaxed(.init(edge: edge, direction: .forward, newCost: relaxedCost))
                    )
                } else {
                    observation?.receive(.edgeNotRelaxed(.init(edge: edge, direction: .forward)))
                }
            }
        }

        /// Explores backward from a vertex.
        ///
        /// - Parameters:
        ///   - currentVertex: The current vertex.
        ///   - currentCost: The current cost to reach the vertex.
        ///   - distances: The distances dictionary to update.
        ///   - predecessors: The predecessors dictionary to update.
        ///   - queue: The priority queue to add new items to.
        ///   - observation: An optional algorithm observation.
        @usableFromInline
        func exploreBackward(
            from currentVertex: Vertex,
            currentCost: Cost<Weight>,
            distances: inout [Vertex: Cost<Weight>],
            predecessors: inout [Vertex: Edge?],
            queue: inout PriorityQueue<PriorityItem>,
            observation: AlgorithmObservation<Event>?
        ) {
            for edge in graph.incomingEdges(of: currentVertex) {
                guard let neighbor = graph.source(of: edge) else { continue }

                observation?.receive(.edgeExamined(.init(edge: edge, direction: .backward)))

                let weight = edgeWeight.costToExplore(edge, graph)
                let newCost = currentCost + weight

                let currentBestCost = distances[neighbor] ?? .infinite
                if newCost < currentBestCost {
                    guard case .finite(let relaxedCost) = newCost else {
                        preconditionFailure("An improved bidirectional Dijkstra cost must be finite")
                    }
                    distances[neighbor] = newCost
                    predecessors[neighbor] = edge
                    queue.enqueue(PriorityItem(vertex: neighbor, cost: newCost, direction: .backward))
                    observation?.receive(
                        .edgeRelaxed(.init(edge: edge, direction: .backward, newCost: relaxedCost))
                    )
                } else {
                    observation?.receive(.edgeNotRelaxed(.init(edge: edge, direction: .backward)))
                }
            }
        }

        /// Reconstructs the shortest path from the meeting point.
        ///
        /// - Parameters:
        ///   - source: The source vertex.
        ///   - destination: The destination vertex.
        ///   - meetingVertex: The vertex where the searches met.
        ///   - forwardPredecessors: The forward predecessors.
        ///   - backwardPredecessors: The backward predecessors.
        /// - Returns: The reconstructed path.
        @usableFromInline
        func reconstructPath(
            from source: Vertex,
            to destination: Vertex,
            meetingVertex: Vertex,
            forwardPredecessors: [Vertex: Edge?],
            backwardPredecessors: [Vertex: Edge?]
        ) -> Path<Vertex, Edge> {
            var forwardVertices: [Vertex] = [meetingVertex]
            var forwardEdges: [Edge] = []

            var currentVertex = meetingVertex
            while let optionalEdge = forwardPredecessors[currentVertex], let edge = optionalEdge {
                forwardEdges.insert(edge, at: 0)
                guard let predecessor = graph.source(of: edge) else { break }
                if predecessor == source { break }
                forwardVertices.insert(predecessor, at: 0)
                currentVertex = predecessor
            }

            var backwardVertices: [Vertex] = []
            var backwardEdges: [Edge] = []

            currentVertex = meetingVertex
            while let optionalEdge = backwardPredecessors[currentVertex], let edge = optionalEdge {
                backwardEdges.append(edge)
                guard let successor = graph.destination(of: edge) else { break }
                if successor == destination { break }
                backwardVertices.append(successor)
                currentVertex = successor
            }

            let allVertices = forwardVertices + backwardVertices
            let allEdges = forwardEdges + backwardEdges

            return Path(
                source: source,
                destination: destination,
                vertices: allVertices,
                edges: allEdges
            )
        }
    }

    extension BidirectionalDijkstra: ShortestPathAlgorithm {
        @inlinable
        public func shortestPath(
            from source: Vertex,
            to destination: Vertex,
            in graph: Graph,
            observation: AlgorithmObservation<Event>?
        ) -> Path<Vertex, Edge>? {
            shortestPath(from: source, to: destination, observation: observation).path
        }
    }

    extension BidirectionalDijkstra.PriorityItem: Equatable {
        @inlinable
        public static func == (lhs: Self, rhs: Self) -> Bool {
            lhs.vertex == rhs.vertex && lhs.direction == rhs.direction
        }
    }

    extension BidirectionalDijkstra.PriorityItem: Comparable {
        @inlinable
        public static func < (lhs: Self, rhs: Self) -> Bool {
            lhs.cost < rhs.cost
        }
    }

    extension BidirectionalDijkstra: AlgorithmObserving {}

    extension BidirectionalDijkstra.Event: VertexExaminedEvent, EdgeExaminedEvent, EdgeRelaxedEvent {
        /// Returns the examined directional vertex carried by the event.
        @inlinable
        public static func examinedVertex(from event: Self) -> BidirectionalDijkstra.DirectedVertex? {
            guard case .vertexExamined(let vertex) = event else { return nil }
            return vertex
        }

        /// Returns the examined directional edge carried by the event.
        @inlinable
        public static func examinedEdge(from event: Self) -> BidirectionalDijkstra.DirectedEdge? {
            guard case .edgeExamined(let edge) = event else { return nil }
            return edge
        }

        /// Returns successful directional edge-relaxation details carried by the event.
        @inlinable
        public static func relaxation(from event: Self) -> BidirectionalDijkstra.Relaxation? {
            guard case .edgeRelaxed(let relaxation) = event else { return nil }
            return relaxation
        }
    }
#endif
