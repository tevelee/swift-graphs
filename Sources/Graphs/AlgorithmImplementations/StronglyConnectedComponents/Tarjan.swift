#if !GRAPHS_USES_TRAITS || GRAPHS_CONNECTIVITY
    import OrderedCollections

    /// Tarjan's algorithm for finding strongly connected components.
    ///
    /// Tarjan's algorithm finds strongly connected components in a directed graph
    /// using a single depth-first search with a stack to track the current path.
    ///
    /// - Complexity: O(V + E) where V is the number of vertices and E is the number of edges
    public struct Tarjan<Graph: IncidenceGraph & VertexListGraph> where Graph.VertexDescriptor: Hashable {
        /// The vertex type of the graph.
        public typealias Vertex = Graph.VertexDescriptor
        /// The edge type of the graph.
        public typealias Edge = Graph.EdgeDescriptor

        public enum Event {
            case vertexDiscovered(Vertex)
            case edgeExamined(Edge)
            case backEdgeEncountered(Edge)
            case crossEdgeEncountered(Edge)
            case vertexFinished(Vertex)
            case componentStarted(Vertex)
            case componentFinished([Vertex])
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
            public static var backEdgeEncountered: AlgorithmEventCase<Event, Edge> {
                .init {
                    guard case .backEdgeEncountered(let value) = $0 else { return nil }
                    return value
                }
            }
            public static var crossEdgeEncountered: AlgorithmEventCase<Event, Edge> {
                .init {
                    guard case .crossEdgeEncountered(let value) = $0 else { return nil }
                    return value
                }
            }
            public static var vertexFinished: AlgorithmEventCase<Event, Vertex> {
                .init {
                    guard case .vertexFinished(let value) = $0 else { return nil }
                    return value
                }
            }
            public static var componentStarted: AlgorithmEventCase<Event, Vertex> {
                .init {
                    guard case .componentStarted(let value) = $0 else { return nil }
                    return value
                }
            }
            public static var componentFinished: AlgorithmEventCase<Event, [Vertex]> {
                .init {
                    guard case .componentFinished(let value) = $0 else { return nil }
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

        /// Property for tracking vertex colors.
        @usableFromInline
        enum ColorProperty: VertexProperty {
            @usableFromInline
            static var defaultValue: Color { .white }
        }

        /// Property for tracking vertex indices.
        @usableFromInline
        enum IndexProperty: VertexProperty {
            @usableFromInline
            static var defaultValue: UInt? { nil }
        }

        /// Property for tracking vertex low links.
        @usableFromInline
        enum LowLinkProperty: VertexProperty {
            @usableFromInline
            static var defaultValue: UInt? { nil }
        }

        /// Property for tracking if vertex is on stack.
        @usableFromInline
        enum OnStackProperty: VertexProperty {
            @usableFromInline
            static var defaultValue: Bool { false }
        }

        /// DFS stack frame for iterative depth-first search.
        @usableFromInline
        struct Frame {
            /// The vertex being processed.
            @usableFromInline var vertex: Vertex
            /// Outgoing edges from this vertex.
            @usableFromInline var edges: [Edge]
            /// Current index into the edges array.
            @usableFromInline var edgeIndex: Int

            @usableFromInline
            init(vertex: Vertex, edges: [Edge]) {
                self.vertex = vertex
                self.edges = edges
                self.edgeIndex = 0
            }
        }

        /// The graph to find SCCs in.
        @usableFromInline
        let graph: Graph

        /// Creates a new Tarjan's algorithm.
        ///
        /// - Parameter graph: The graph to find SCCs in
        @inlinable
        public init(on graph: Graph) {
            self.graph = graph
        }

        /// Finds strongly connected components using Tarjan's algorithm.
        ///
        /// - Parameter observation: An optional observation of the algorithm progress
        /// - Returns: The strongly connected components result
        @inlinable
        public func stronglyConnectedComponents(
            observation: AlgorithmObservation<Event>? = nil
        ) -> StronglyConnectedComponentsResult<Vertex> {
            var propertyMap = graph.makeVertexPropertyMap()
            let colorProperty = ColorProperty.self
            let indexProperty = IndexProperty.self
            let lowLinkProperty = LowLinkProperty.self
            let onStackProperty = OnStackProperty.self

            var index: UInt = 0
            var sccStack: [Vertex] = []
            var frameStack: [Frame] = []
            var components: [[Vertex]] = []

            for startVertex in graph.vertices() where propertyMap[startVertex][colorProperty] == .white {

                // Initialize root frame
                index += 1
                propertyMap[startVertex][indexProperty] = index
                propertyMap[startVertex][lowLinkProperty] = index
                propertyMap[startVertex][colorProperty] = .gray
                propertyMap[startVertex][onStackProperty] = true
                sccStack.append(startVertex)
                observation?.receive(.vertexDiscovered(startVertex))
                frameStack.append(Frame(vertex: startVertex, edges: Array(graph.outgoingEdges(of: startVertex))))

                while !frameStack.isEmpty {
                    let frameIndex = frameStack.count - 1

                    if frameStack[frameIndex].edgeIndex < frameStack[frameIndex].edges.count {
                        let edge = frameStack[frameIndex].edges[frameStack[frameIndex].edgeIndex]
                        frameStack[frameIndex].edgeIndex += 1

                        observation?.receive(.edgeExamined(edge))

                        guard let destination = graph.destination(of: edge) else { continue }

                        let currentVertex = frameStack[frameIndex].vertex
                        let destinationColor = propertyMap[destination][colorProperty]

                        switch destinationColor {
                            case .white:
                                // Tree edge — push child frame
                                index += 1
                                propertyMap[destination][indexProperty] = index
                                propertyMap[destination][lowLinkProperty] = index
                                propertyMap[destination][colorProperty] = .gray
                                propertyMap[destination][onStackProperty] = true
                                sccStack.append(destination)
                                observation?.receive(.vertexDiscovered(destination))
                                frameStack.append(Frame(vertex: destination, edges: Array(graph.outgoingEdges(of: destination))))

                            case .gray:
                                // Back edge
                                observation?.receive(.backEdgeEncountered(edge))
                                if propertyMap[destination][onStackProperty] == true {
                                    let vertexLowLink = propertyMap[currentVertex][lowLinkProperty] ?? 0
                                    let destinationIndex = propertyMap[destination][indexProperty] ?? 0
                                    propertyMap[currentVertex][lowLinkProperty] = min(vertexLowLink, destinationIndex)
                                }

                            case .black:
                                // Cross edge
                                observation?.receive(.crossEdgeEncountered(edge))
                        }
                    } else {
                        // Frame done — finalize and pop
                        let frame = frameStack.removeLast()
                        let vertex = frame.vertex

                        propertyMap[vertex][colorProperty] = .black
                        observation?.receive(.vertexFinished(vertex))

                        // If vertex is a root node, pop the SCC stack and create a component
                        let vertexIndex = propertyMap[vertex][indexProperty] ?? 0
                        let vertexLowLink = propertyMap[vertex][lowLinkProperty] ?? 0

                        if vertexIndex == vertexLowLink {
                            var component: [Vertex] = []
                            var w: Vertex
                            repeat {
                                w = sccStack.removeLast()
                                propertyMap[w][onStackProperty] = false
                                component.append(w)
                            } while w != vertex

                            observation?.receive(.componentStarted(vertex))
                            observation?.receive(.componentFinished(component))
                            components.append(component)
                        }

                        // Update parent's low-link
                        if !frameStack.isEmpty {
                            let parentFrameIndex = frameStack.count - 1
                            let parentVertex = frameStack[parentFrameIndex].vertex
                            let parentLowLink = propertyMap[parentVertex][lowLinkProperty] ?? 0
                            let childLowLink = propertyMap[vertex][lowLinkProperty] ?? 0
                            propertyMap[parentVertex][lowLinkProperty] = min(parentLowLink, childLowLink)
                        }
                    }
                }
            }

            return StronglyConnectedComponentsResult(components: components)
        }
    }
#endif

#if !GRAPHS_USES_TRAITS || GRAPHS_CONNECTIVITY
    extension Tarjan.Event: VertexDiscoveredEvent, EdgeExaminedEvent {
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
