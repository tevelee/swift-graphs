#if !GRAPHS_USES_TRAITS || GRAPHS_CONNECTIVITY
    import OrderedCollections

    /// DFS-based connected components algorithm.
    ///
    /// This algorithm finds connected components using depth-first search.
    /// It visits all vertices reachable from each unvisited vertex to form components.
    ///
    /// - Complexity: O(V + E) where V is the number of vertices and E is the number of edges
    public struct DFSConnectedComponents<Graph: IncidenceGraph & VertexListGraph> where Graph.VertexDescriptor: Hashable {
        /// The vertex type of the graph.
        public typealias Vertex = Graph.VertexDescriptor
        /// The edge type of the graph.
        public typealias Edge = Graph.EdgeDescriptor

        public enum Event {
            case vertexDiscovered(Vertex)
            case edgeExamined(Edge)
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

        /// The graph to find connected components in.
        @usableFromInline
        let graph: Graph

        /// Creates a new DFS connected components algorithm.
        ///
        /// - Parameter graph: The graph to find connected components in
        @inlinable
        public init(on graph: Graph) {
            self.graph = graph
        }

        /// Finds connected components using DFS.
        ///
        /// - Parameter observation: An optional observation of the algorithm progress
        /// - Returns: The connected components result
        @inlinable
        public func connectedComponents(
            observation: AlgorithmObservation<Event>? = nil
        ) -> ConnectedComponentsResult<Vertex> {
            var propertyMap = graph.makeVertexPropertyMap()
            let colorProperty = ColorProperty.self
            var components: [[Vertex]] = []
            var stack: [Vertex] = []

            for vertex in graph.vertices() where propertyMap[vertex][colorProperty] == .white {
                var component: [Vertex] = []
                stack.append(vertex)
                propertyMap[vertex][colorProperty] = .gray
                while let current = stack.popLast() {
                    observation?.receive(.vertexDiscovered(current))
                    component.append(current)
                    for edge in graph.outgoingEdges(of: current) {
                        observation?.receive(.edgeExamined(edge))
                        guard let destination = graph.destination(of: edge) else { continue }
                        if propertyMap[destination][colorProperty] == .white {
                            propertyMap[destination][colorProperty] = .gray
                            stack.append(destination)
                        }
                    }
                    propertyMap[current][colorProperty] = .black
                }
                observation?.receive(.componentFinished(component))
                components.append(component)
            }

            return ConnectedComponentsResult(components: components)
        }
    }

    extension DFSConnectedComponents: ConnectedComponentsAlgorithm {
        @inlinable
        public func connectedComponents(
            in graph: Graph,
            observation: AlgorithmObservation<Event>?
        ) -> ConnectedComponentsResult<Graph.VertexDescriptor> {
            connectedComponents(observation: observation)
        }
    }
#endif

#if !GRAPHS_USES_TRAITS || GRAPHS_CONNECTIVITY
    extension DFSConnectedComponents.Event: VertexDiscoveredEvent, EdgeExaminedEvent {
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
