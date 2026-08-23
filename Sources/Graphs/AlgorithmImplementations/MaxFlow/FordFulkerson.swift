#if !GRAPHS_USES_TRAITS || GRAPHS_OPTIMIZATION
    /// Ford-Fulkerson algorithm for computing maximum flow.
    ///
    /// This algorithm finds the maximum flow in a flow network by repeatedly finding
    /// augmenting paths and increasing the flow along them until no more augmenting
    /// paths exist.
    ///
    /// - Complexity: O(E * max_flow) where E is the number of edges
    public struct FordFulkerson<
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
            /// The edge's new flow.
            public let flow: Flow

            /// Creates flow-update details.
            @inlinable
            public init(edge: Edge, flow: Flow) {
                self.edge = edge
                self.flow = flow
            }
        }

        /// Details about an augmenting-path search.
        public struct PathSearch {
            /// The search source.
            public let source: Vertex
            /// The search sink.
            public let sink: Vertex

            /// Creates path-search details.
            @inlinable
            public init(source: Vertex, sink: Vertex) {
                self.source = source
                self.sink = sink
            }
        }

        /// An event emitted synchronously while Ford-Fulkerson advances.
        public enum Event {
            /// A residual edge was examined.
            case edgeExamined(EdgeExamination)
            /// Flow augmentation along a path started.
            case pathAugmentationStarted(PathAugmentation)
            /// Flow was updated on an edge.
            case flowUpdated(FlowUpdate)
            /// An augmenting-path search started.
            case pathSearchStarted(PathSearch)
        }

        /// Typed selectors for Ford-Fulkerson events.
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
            /// Selects augmenting-path searches as they start.
            public static var pathSearchStarted: AlgorithmEventCase<Event, PathSearch> {
                .init {
                    guard case .pathSearchStarted(let value) = $0 else { return nil }
                    return value
                }
            }
        }

        /// The capacity cost definition for edge capacities.
        @usableFromInline
        let capacityCost: CostDefinition<Graph, Flow>

        /// Creates a new Ford-Fulkerson algorithm.
        ///
        /// - Parameter capacityCost: The capacity cost definition for edge capacities.
        @inlinable
        public init(capacityCost: CostDefinition<Graph, Flow>) {
            self.capacityCost = capacityCost
        }

        /// Computes the maximum flow using Ford-Fulkerson algorithm.
        ///
        /// - Parameters:
        ///   - source: The source vertex
        ///   - sink: The sink vertex
        ///   - graph: The flow network graph
        ///   - observation: An optional algorithm observation
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

            // Main Ford-Fulkerson loop
            while let augmentingPath = findAugmentingPath(
                from: source,
                to: sink,
                in: graph,
                residualCapacities: residualCapacities,
                observation: observation
            ) {
                let pathFlow = augmentingPath.bottleneck
                totalFlow += pathFlow

                observation?.receive(.pathAugmentationStarted(.init(edges: augmentingPath.edges, flow: pathFlow)))

                // Update flows and residual capacities along the path
                for edge in augmentingPath.edges {
                    let currentFlow = edgeFlows[edge] ?? .zero
                    let newFlow = currentFlow + pathFlow
                    edgeFlows[edge] = newFlow

                    // Update residual capacity (forward edge)
                    let currentResidual = residualCapacities[edge] ?? .zero
                    residualCapacities[edge] = currentResidual - pathFlow

                    // Update residual capacity (backward edge)
                    if let reverseEdge = findReverseEdge(edge, in: graph) {
                        let reverseResidual = residualCapacities[reverseEdge] ?? .zero
                        residualCapacities[reverseEdge] = reverseResidual + pathFlow
                    }

                    observation?.receive(.flowUpdated(.init(edge: edge, flow: newFlow)))
                }
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
        func findAugmentingPath(
            from source: Vertex,
            to sink: Vertex,
            in graph: Graph,
            residualCapacities: [Edge: Flow],
            observation: AlgorithmObservation<Event>?
        ) -> AugmentingPath? {
            observation?.receive(.pathSearchStarted(.init(source: source, sink: sink)))

            var visited: Set<Vertex> = []
            var parent: [Vertex: Vertex] = [:]
            var parentEdge: [Vertex: Edge] = [:]

            var queue: [Vertex] = [source]
            visited.insert(source)

            while !queue.isEmpty {
                let current = queue.removeFirst()

                if current == sink {
                    // Reconstruct path
                    var path: [Edge] = []
                    var bottleneck: Flow?
                    var vertex = sink

                    while let parentVertex = parent[vertex], let edge = parentEdge[vertex] {
                        path.append(edge)
                        let residual = residualCapacities[edge] ?? .zero
                        bottleneck = bottleneck.map { min($0, residual) } ?? residual
                        vertex = parentVertex
                    }

                    path.reverse()
                    guard let b = bottleneck else { return nil }
                    return AugmentingPath(edges: path, bottleneck: b)
                }

                // Check outgoing edges
                for edge in graph.outgoingEdges(of: current) {
                    guard let destination = graph.destination(of: edge) else { continue }
                    let residual = residualCapacities[edge] ?? .zero

                    if !visited.contains(destination) && residual > .zero {
                        visited.insert(destination)
                        parent[destination] = current
                        parentEdge[destination] = edge
                        queue.append(destination)
                        observation?.receive(.edgeExamined(.init(edge: edge, residualCapacity: residual)))
                    }
                }
            }

            return nil
        }

        @usableFromInline
        func findReverseEdge(_ edge: Edge, in graph: Graph) -> Edge? {
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

        @usableFromInline
        struct AugmentingPath {
            @usableFromInline
            let edges: [Edge]
            @usableFromInline
            let bottleneck: Flow
        }
    }

#endif

#if !GRAPHS_USES_TRAITS || GRAPHS_OPTIMIZATION
    extension FordFulkerson.Event: EdgeExaminedEvent {
        @inlinable
        public static func examinedEdge(from event: Self) -> FordFulkerson.EdgeExamination? {
            guard case .edgeExamined(let examination) = event else { return nil }
            return examination
        }
    }
#endif
