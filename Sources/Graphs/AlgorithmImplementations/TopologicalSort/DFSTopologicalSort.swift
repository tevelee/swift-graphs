#if !GRAPHS_USES_TRAITS || GRAPHS_CONNECTIVITY
    import OrderedCollections

    /// DFS-based algorithm for topological sorting.
    ///
    /// This algorithm uses depth-first search and processes vertices in reverse finish time order.
    /// If a back edge is detected during DFS, the graph contains a cycle.
    ///
    /// - Complexity: O(V + E) where V is the number of vertices and E is the number of edges
    public struct DFSTopologicalSort<Graph: IncidenceGraph & VertexListGraph>: TopologicalSortAlgorithm where Graph.VertexDescriptor: Hashable {
        /// The vertex type of the graph.
        public typealias Vertex = Graph.VertexDescriptor
        /// The edge type of the graph.
        public typealias Edge = Graph.EdgeDescriptor

        public enum Event {
            case vertexDiscovered(Vertex)
            case edgeExamined(Edge)
            case treeEdgeTraversed(Edge)
            case backEdgeDetected(Edge)
            case forwardEdgeTraversed(Edge)
            case crossEdgeTraversed(Edge)
            case vertexFinished(Vertex)
            case cycleDetected([Vertex])
        }

        public enum EventCases {
            public static var vertexDiscovered: AlgorithmEventCase<Event, Vertex> {
                .init {
                    guard case .vertexDiscovered(let value) = $0 else { return nil }
                    return value
                }
            }
            public static var edgeExamined: AlgorithmEventCase<Event, Edge> {
                .init {
                    guard case .edgeExamined(let value) = $0 else { return nil }
                    return value
                }
            }
            public static var treeEdgeTraversed: AlgorithmEventCase<Event, Edge> {
                .init {
                    guard case .treeEdgeTraversed(let value) = $0 else { return nil }
                    return value
                }
            }
            public static var backEdgeDetected: AlgorithmEventCase<Event, Edge> {
                .init {
                    guard case .backEdgeDetected(let value) = $0 else { return nil }
                    return value
                }
            }
            public static var forwardEdgeTraversed: AlgorithmEventCase<Event, Edge> {
                .init {
                    guard case .forwardEdgeTraversed(let value) = $0 else { return nil }
                    return value
                }
            }
            public static var crossEdgeTraversed: AlgorithmEventCase<Event, Edge> {
                .init {
                    guard case .crossEdgeTraversed(let value) = $0 else { return nil }
                    return value
                }
            }
            public static var vertexFinished: AlgorithmEventCase<Event, Vertex> {
                .init {
                    guard case .vertexFinished(let value) = $0 else { return nil }
                    return value
                }
            }
            public static var cycleDetected: AlgorithmEventCase<Event, [Vertex]> {
                .init {
                    guard case .cycleDetected(let value) = $0 else { return nil }
                    return value
                }
            }
        }

        /// The color of a vertex in the algorithm.
        @usableFromInline
        enum Color: Sendable {
            /// Undiscovered vertex.
            case white
            /// Discovered but not fully processed vertex.
            case gray
            /// Fully processed vertex.
            case black
        }

        @usableFromInline
        enum ColorProperty: VertexProperty {
            @usableFromInline
            static var defaultValue: Color { .white }
        }

        /// Creates a new DFS topological sort algorithm.
        @inlinable
        public init() {}

        /// Performs topological sort using DFS.
        ///
        /// - Parameters:
        ///   - graph: The graph to sort topologically.
        ///   - observation: An optional observation of the algorithm progress.
        /// - Returns: The topological sort result.
        @inlinable
        public func topologicalSort(
            in graph: Graph,
            observation: AlgorithmObservation<Event>?
        ) -> TopologicalSortResult<Graph.VertexDescriptor> {
            var sortedVertices: [Vertex] = []
            var hasCycle = false
            var cycleVertices: [Vertex] = []
            var propertyMap: DictionaryPropertyMap<Vertex, VertexPropertyValues> = graph.makeVertexPropertyMap()
            let colorProperty: any VertexProperty<Color>.Type = ColorProperty.self

            // Process all vertices to handle disconnected components
            for vertex in graph.vertices() {
                let color = propertyMap[vertex][colorProperty]
                if color == .white {
                    let (cycle, cycleNodes) = dfsVisit(
                        from: vertex,
                        in: graph,
                        propertyMap: &propertyMap,
                        colorProperty: colorProperty,
                        sortedVertices: &sortedVertices,
                        observation: observation
                    )
                    if cycle {
                        hasCycle = true
                        cycleVertices.append(contentsOf: cycleNodes)
                    }
                }
            }

            if hasCycle {
                observation?.receive(.cycleDetected(cycleVertices))
            }

            // Vertices were appended in finish order; reverse to get topological order
            sortedVertices.reverse()

            return TopologicalSortResult(
                sortedVertices: sortedVertices,
                hasCycle: hasCycle,
                cycleVertices: cycleVertices
            )
        }

        @usableFromInline
        func dfsVisit(
            from vertex: Vertex,
            in graph: Graph,
            propertyMap: inout DictionaryPropertyMap<Vertex, VertexPropertyValues>,
            colorProperty: any VertexProperty<Color>.Type,
            sortedVertices: inout [Vertex],
            observation: AlgorithmObservation<Event>?
        ) -> (hasCycle: Bool, cycleVertices: [Vertex]) {
            var hasCycle = false
            var cycleVertices: [Vertex] = []
            var stack: [Vertex] = []

            stack.push(vertex)

            while !stack.isEmpty {
                guard let current = stack.pop() else { break }
                let color = propertyMap[current][colorProperty]

                switch color {
                    case .white:
                        // Mark as discovered
                        propertyMap[current][colorProperty] = .gray
                        observation?.receive(.vertexDiscovered(current))

                        // Push back for processing after neighbors
                        stack.push(current)

                        // Process all outgoing edges
                        for edge in graph.outgoingEdges(of: current) {
                            observation?.receive(.edgeExamined(edge))
                            guard let destination = graph.destination(of: edge) else { continue }

                            let destColor = propertyMap[destination][colorProperty]
                            switch destColor {
                                case .white:
                                    observation?.receive(.treeEdgeTraversed(edge))
                                    stack.push(destination)
                                case .gray:
                                    // Back edge detected - cycle found
                                    observation?.receive(.backEdgeDetected(edge))
                                    hasCycle = true
                                    cycleVertices.append(destination)
                                case .black:
                                    observation?.receive(.crossEdgeTraversed(edge))
                            }
                        }

                    case .gray:
                        // Mark as finished and add to sorted list
                        propertyMap[current][colorProperty] = .black
                        observation?.receive(.vertexFinished(current))
                        sortedVertices.append(current)  // Appended in finish order; reversed after all DFS visits

                    case .black:
                        // Already processed
                        break
                }
            }

            return (hasCycle, cycleVertices)
        }
    }

#endif

#if !GRAPHS_USES_TRAITS || GRAPHS_CONNECTIVITY
    extension DFSTopologicalSort.Event: VertexDiscoveredEvent, EdgeExaminedEvent {
        @inlinable
        public static func discoveredVertex(from event: Self) -> Graph.VertexDescriptor? {
            guard case .vertexDiscovered(let vertex) = event else { return nil }
            return vertex
        }

        @inlinable
        public static func examinedEdge(from event: Self) -> Graph.EdgeDescriptor? {
            guard case .edgeExamined(let edge) = event else { return nil }
            return edge
        }
    }
#endif
