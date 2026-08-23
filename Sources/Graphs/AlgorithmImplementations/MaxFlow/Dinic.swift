#if !GRAPHS_USES_TRAITS || GRAPHS_OPTIMIZATION
    /// Dinic's algorithm for computing maximum flow.
    ///
    /// This algorithm finds the maximum flow in a flow network by building level graphs
    /// and finding blocking flows, which provides better time complexity than Edmonds-Karp.
    ///
    /// - Complexity: O(V^2 * E) where V is the number of vertices and E is the number of edges
    public struct Dinic<
        Graph: IncidenceGraph & BidirectionalGraph & EdgeListGraph & VertexListGraph,
        Flow: AdditiveArithmetic & Comparable
    >
    where
        Graph.VertexDescriptor: Hashable,
        Graph.EdgeDescriptor: Hashable
    {
        /// The vertex type of the graph.
        public typealias Vertex = Graph.VertexDescriptor
        /// The edge type of the graph.
        public typealias Edge = Graph.EdgeDescriptor

        /// Details about an edge examination in the residual graph.
        public struct EdgeExamination {
            /// The edge being examined.
            public let edge: Edge
            /// The edge's residual capacity at examination time.
            public let residualCapacity: Flow

            /// Creates edge-examination details.
            @inlinable
            public init(edge: Edge, residualCapacity: Flow) {
                self.edge = edge
                self.residualCapacity = residualCapacity
            }
        }

        /// Details about an augmenting path before flow is pushed through it.
        public struct PathAugmentation {
            /// The edges in the augmenting path.
            public let edges: [Edge]
            /// The flow to push through the path.
            public let flow: Flow

            /// Creates path-augmentation details.
            @inlinable
            public init(edges: [Edge], flow: Flow) {
                self.edges = edges
                self.flow = flow
            }
        }

        /// Details about an edge flow update.
        public struct FlowUpdate {
            /// The updated edge.
            public let edge: Edge
            /// The flow pushed through the edge.
            public let flow: Flow

            /// Creates flow-update details.
            @inlinable
            public init(edge: Edge, flow: Flow) {
                self.edge = edge
                self.flow = flow
            }
        }

        /// Details about assigning a vertex to a level graph layer.
        public struct LevelAssignment {
            /// The assigned vertex.
            public let vertex: Vertex
            /// The assigned level.
            public let level: Int

            /// Creates level-assignment details.
            @inlinable
            public init(vertex: Vertex, level: Int) {
                self.vertex = vertex
                self.level = level
            }
        }

        /// An event emitted synchronously while Dinic's algorithm advances.
        public enum Event {
            /// A residual edge was examined.
            case edgeExamined(EdgeExamination)
            /// Flow augmentation along a path started.
            case pathAugmentationStarted(PathAugmentation)
            /// Flow was updated on an edge.
            case flowUpdated(FlowUpdate)
            /// Construction of a level graph started.
            case levelGraphBuildStarted
            /// A blocking-flow search started.
            case blockingFlowSearchStarted
            /// A vertex was assigned to a level graph layer.
            case levelAssigned(LevelAssignment)
            /// An edge became blocked.
            case edgeBlocked(Edge)
        }

        /// Typed selectors for Dinic events.
        public enum EventCases {
            /// Selects examined edges and their residual capacities.
            public static var edgeExamined: AlgorithmEventCase<Event, EdgeExamination> {
                .init {
                    guard case .edgeExamined(let value) = $0 else { return nil }
                    return value
                }
            }
            /// Selects path augmentations as they start.
            public static var pathAugmentationStarted: AlgorithmEventCase<Event, PathAugmentation> {
                .init {
                    guard case .pathAugmentationStarted(let value) = $0 else { return nil }
                    return value
                }
            }
            /// Selects edge flow updates.
            public static var flowUpdated: AlgorithmEventCase<Event, FlowUpdate> {
                .init {
                    guard case .flowUpdated(let value) = $0 else { return nil }
                    return value
                }
            }
            /// Selects level graph builds as they start.
            public static var levelGraphBuildStarted: AlgorithmEventCase<Event, Void> { .init { if case .levelGraphBuildStarted = $0 { () } else { nil } } }
            /// Selects blocking-flow searches as they start.
            public static var blockingFlowSearchStarted: AlgorithmEventCase<Event, Void> {
                .init { if case .blockingFlowSearchStarted = $0 { () } else { nil } }
            }
            /// Selects vertex level assignments.
            public static var levelAssigned: AlgorithmEventCase<Event, LevelAssignment> {
                .init {
                    guard case .levelAssigned(let value) = $0 else { return nil }
                    return value
                }
            }
            /// Selects blocked edges.
            public static var edgeBlocked: AlgorithmEventCase<Event, Edge> {
                .init {
                    guard case .edgeBlocked(let value) = $0 else { return nil }
                    return value
                }
            }
        }

        /// The capacity cost definition for edge capacities.
        @usableFromInline
        let capacityCost: CostDefinition<Graph, Flow>

        /// Creates a new Dinic's algorithm.
        ///
        /// - Parameter capacityCost: The capacity cost definition for edge capacities.
        @inlinable
        public init(capacityCost: CostDefinition<Graph, Flow>) {
            self.capacityCost = capacityCost
        }

        /// Computes the maximum flow using Dinic's algorithm.
        ///
        /// - Parameters:
        ///   - source: The source vertex
        ///   - sink: The sink vertex
        ///   - graph: The flow network graph
        ///   - observation: An optional observation to observe the algorithm progress
        /// - Returns: The maximum flow result
        @inlinable
        public func maximumFlow(
            from source: Vertex,
            to sink: Vertex,
            in graph: Graph,
            observation: AlgorithmObservation<Event>? = nil
        ) -> MaxFlowResult<Vertex, Edge, Flow> {
            // Initialize flow and residual capacity maps
            var edgeFlows: [Edge: Flow] = [:]
            var residualCapacities: [Edge: Flow] = [:]

            // Initialize all flows to zero and residual capacities to edge capacities
            for edge in graph.edges() {
                let capacity = capacityCost.costToExplore(edge, graph)
                edgeFlows[edge] = .zero
                residualCapacities[edge] = capacity
            }

            var totalFlow: Flow = .zero

            // Main Dinic's algorithm loop
            while true {
                // Build level graph using BFS
                guard
                    let levelGraph = buildLevelGraph(
                        from: source,
                        to: sink,
                        in: graph,
                        residualCapacities: residualCapacities,
                        observation: observation
                    )
                else {
                    break  // No more augmenting paths
                }

                // Find blocking flow in level graph
                let blockingFlow = findBlockingFlow(
                    from: source,
                    to: sink,
                    in: graph,
                    levelGraph: levelGraph,
                    residualCapacities: &residualCapacities,
                    observation: observation
                )

                if blockingFlow == .zero {
                    break  // No more flow can be pushed
                }

                totalFlow += blockingFlow

                // Update flows along the paths found in blocking flow
                updateFlows(
                    in: graph,
                    edgeFlows: &edgeFlows,
                    residualCapacities: residualCapacities,
                    observation: observation
                )
            }

            // Find minimum cut
            let (minCutEdges, sourceSide, sinkSide) = findMinimumCut(
                from: source,
                to: sink,
                in: graph,
                residualCapacities: residualCapacities
            )

            return MaxFlowResult(
                flowValue: totalFlow,
                edgeFlows: edgeFlows,
                residualCapacities: residualCapacities,
                minCutEdges: minCutEdges,
                sourceSideVertices: sourceSide,
                sinkSideVertices: sinkSide
            )
        }

        @usableFromInline
        func buildLevelGraph(
            from source: Vertex,
            to sink: Vertex,
            in graph: Graph,
            residualCapacities: [Edge: Flow],
            observation: AlgorithmObservation<Event>?
        ) -> [Vertex: Int]? {
            observation?.receive(.levelGraphBuildStarted)

            var level: [Vertex: Int] = [:]
            var queue: [Vertex] = [source]
            level[source] = 0

            while !queue.isEmpty {
                let current = queue.removeFirst()
                let currentLevel = level[current] ?? 0

                if current == sink {
                    return level
                }

                for edge in graph.outgoingEdges(of: current) {
                    guard let destination = graph.destination(of: edge) else { continue }
                    let residual = residualCapacities[edge] ?? .zero

                    if level[destination] == nil && residual > .zero {
                        level[destination] = currentLevel + 1
                        queue.append(destination)
                        observation?.receive(.levelAssigned(.init(vertex: destination, level: currentLevel + 1)))
                    }
                }
            }

            return nil  // No path to sink
        }

        @usableFromInline
        func findBlockingFlow(
            from source: Vertex,
            to sink: Vertex,
            in graph: Graph,
            levelGraph: [Vertex: Int],
            residualCapacities: inout [Edge: Flow],
            observation: AlgorithmObservation<Event>?
        ) -> Flow {
            observation?.receive(.blockingFlowSearchStarted)

            var totalFlow: Flow = .zero
            var current: [Vertex: Int] = [:]

            // Initialize current edge pointer for each vertex
            for vertex in graph.vertices() {
                current[vertex] = 0
            }

            // DFS to find blocking flow. `limit` is the minimum residual seen so far
            // on the path from source; nil means no upper bound yet (first edge sets it).
            func dfs(_ vertex: Vertex, _ limit: Flow?) -> Flow {
                if vertex == sink {
                    return limit ?? .zero
                }

                let vertexLevel = levelGraph[vertex] ?? Int.max
                let outgoingEdges = Array(graph.outgoingEdges(of: vertex))

                for i in (current[vertex] ?? 0) ..< outgoingEdges.count {
                    let edge = outgoingEdges[i]
                    guard let destination = graph.destination(of: edge) else { continue }

                    let destinationLevel = levelGraph[destination] ?? Int.max
                    let residual = residualCapacities[edge] ?? .zero

                    if destinationLevel == vertexLevel + 1 && residual > .zero {
                        let newLimit: Flow = limit.map { min($0, residual) } ?? residual
                        let pushedFlow = dfs(destination, newLimit)

                        if pushedFlow > .zero {
                            residualCapacities[edge] = residual - pushedFlow

                            if let reverseEdge = findReverseEdge(edge, in: graph) {
                                let reverseResidual = residualCapacities[reverseEdge] ?? .zero
                                residualCapacities[reverseEdge] = reverseResidual + pushedFlow
                            }

                            observation?.receive(.flowUpdated(.init(edge: edge, flow: pushedFlow)))
                            return pushedFlow
                        }
                    }
                }

                return .zero
            }

            while true {
                let flow = dfs(source, nil)
                if flow == .zero {
                    break
                }
                totalFlow += flow
            }

            return totalFlow
        }

        @usableFromInline
        func updateFlows(
            in graph: Graph,
            edgeFlows: inout [Edge: Flow],
            residualCapacities: [Edge: Flow],
            observation: AlgorithmObservation<Event>?
        ) {
            // Update flows based on residual capacity changes
            for edge in graph.edges() {
                let originalCapacity = capacityCost.costToExplore(edge, graph)
                let currentResidual = residualCapacities[edge] ?? .zero
                let flow = originalCapacity - currentResidual
                edgeFlows[edge] = flow
            }
        }

        private func findReverseEdge(_ edge: Edge, in graph: Graph) -> Edge? {
            guard let source = graph.source(of: edge),
                let destination = graph.destination(of: edge)
            else { return nil }

            // Look for the reverse edge
            for reverseEdge in graph.outgoingEdges(of: destination) where graph.destination(of: reverseEdge) == source {
                return reverseEdge
            }

            return nil
        }

        @usableFromInline
        func findMinimumCut(
            from source: Vertex,
            to sink: Vertex,
            in graph: Graph,
            residualCapacities: [Edge: Flow]
        ) -> ([Edge], Set<Vertex>, Set<Vertex>) {
            var visited: Set<Vertex> = []
            var queue: [Vertex] = [source]
            visited.insert(source)

            // BFS to find reachable vertices from source
            while !queue.isEmpty {
                let current = queue.removeFirst()

                for edge in graph.outgoingEdges(of: current) {
                    guard let destination = graph.destination(of: edge) else { continue }
                    let residual = residualCapacities[edge] ?? .zero

                    if !visited.contains(destination) && residual > .zero {
                        visited.insert(destination)
                        queue.append(destination)
                    }
                }
            }

            // Find edges that cross the cut
            var minCutEdges: [Edge] = []
            for edge in graph.edges() {
                guard let sourceVertex = graph.source(of: edge),
                    let destinationVertex = graph.destination(of: edge)
                else { continue }

                if visited.contains(sourceVertex) && !visited.contains(destinationVertex) {
                    minCutEdges.append(edge)
                }
            }

            let sourceSide = visited
            let sinkSide = Set(graph.vertices().filter { !visited.contains($0) })

            return (minCutEdges, sourceSide, sinkSide)
        }
    }
#endif

#if !GRAPHS_USES_TRAITS || GRAPHS_OPTIMIZATION
    extension Dinic.Event: EdgeExaminedEvent {
        @inlinable
        public static func examinedEdge(from event: Self) -> Dinic.EdgeExamination? {
            guard case .edgeExamined(let examination) = event else { return nil }
            return examination
        }
    }
#endif
