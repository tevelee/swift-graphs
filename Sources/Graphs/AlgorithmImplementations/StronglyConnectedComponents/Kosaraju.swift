#if !GRAPHS_USES_TRAITS || GRAPHS_CONNECTIVITY
    import OrderedCollections

    /// Kosaraju's algorithm for finding strongly connected components.
    ///
    /// Kosaraju's algorithm finds strongly connected components in a directed graph
    /// by performing two depth-first searches: first on the original graph to get
    /// finish times, then on the transposed graph in reverse finish time order.
    ///
    /// - Complexity: O(V + E) where V is the number of vertices and E is the number of edges
    public struct Kosaraju<Graph: BidirectionalGraph & VertexListGraph> where Graph.VertexDescriptor: Hashable {
        /// The vertex type of the graph.
        public typealias Vertex = Graph.VertexDescriptor
        /// The edge type of the graph.
        public typealias Edge = Graph.EdgeDescriptor

        public enum Event {
            case vertexDiscovered(Vertex)
            case edgeExamined(Edge)
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

        @usableFromInline
        enum ColorProperty: VertexProperty {
            @usableFromInline
            static var defaultValue: Color { .white }
        }

        /// The graph to find strongly connected components in.
        @usableFromInline
        let graph: Graph

        /// Creates a new Kosaraju algorithm instance.
        ///
        /// - Parameter graph: The graph to find strongly connected components in.
        @inlinable
        public init(on graph: Graph) {
            self.graph = graph
        }

        /// Finds strongly connected components in the graph.
        ///
        /// - Parameter observation: An optional observation of the algorithm's progress.
        /// - Returns: The strongly connected components result.
        @inlinable
        public func stronglyConnectedComponents(
            observation: AlgorithmObservation<Event>? = nil
        ) -> StronglyConnectedComponentsResult<Vertex> {
            var propertyMap = graph.makeVertexPropertyMap()
            let colorProperty = ColorProperty.self

            // Step 1: Perform DFS on the original graph to get finish times
            var finishOrder: [Vertex] = []

            /// First DFS pass to get finish times using the existing DFS algorithm.
            ///
            /// - Parameter vertex: The vertex to start DFS from.
            func dfs1(_ vertex: Vertex) {
                // Use the existing DFS algorithm but manage shared state manually
                let dfs = DepthFirstSearch(on: graph, from: vertex)
                let finishTimeObservation = AlgorithmObservation<DepthFirstSearch<Graph>.Event> { event in
                    switch event {
                        case .vertexDiscovered(let v):
                            if propertyMap[v][colorProperty] == .white {
                                propertyMap[v][colorProperty] = .gray
                                observation?.receive(.vertexDiscovered(v))
                            }
                        case .edgeExamined(let edge):
                            observation?.receive(.edgeExamined(edge))
                        case .vertexFinished(let v):
                            propertyMap[v][colorProperty] = .black
                            observation?.receive(.vertexFinished(v))
                            finishOrder.append(v)
                        default:
                            break
                    }
                }

                var iterator = dfs.makeIterator(observation: finishTimeObservation)
                while iterator.next() != nil {}
            }

            // First pass: DFS on original graph
            for vertex in graph.vertices() where propertyMap[vertex][colorProperty] == .white {
                dfs1(vertex)
            }

            // Step 2: Reset colors and perform DFS on the transpose graph
            for vertex in graph.vertices() {
                propertyMap[vertex][colorProperty] = .white
            }

            var components: [[Vertex]] = []

            /// Second DFS pass on the transpose graph using the existing DFS algorithm.
            ///
            /// - Parameters:
            ///   - vertex: The vertex to start DFS from.
            ///   - component: The current component being built.
            func dfs2(_ vertex: Vertex, component: inout [Vertex]) {
                // Use the existing DFS algorithm on the transpose graph
                let transposeGraph = graph.transpose()
                var localComponent: [Vertex] = []

                let dfs = DepthFirstSearch(on: transposeGraph, from: vertex)
                let componentObservation = AlgorithmObservation<DepthFirstSearch<ReversedGraphView<Graph>>.Event> { event in
                    switch event {
                        case .vertexDiscovered(let v):
                            if propertyMap[v][colorProperty] == .white {
                                propertyMap[v][colorProperty] = .gray
                                observation?.receive(.vertexDiscovered(v))
                                localComponent.append(v)
                            }
                        case .edgeExamined(let edge):
                            observation?.receive(.edgeExamined(edge))
                        case .vertexFinished(let v):
                            propertyMap[v][colorProperty] = .black
                            observation?.receive(.vertexFinished(v))
                        default:
                            break
                    }
                }

                var iterator = dfs.makeIterator(observation: componentObservation)
                while iterator.next() != nil {}

                // Append the collected vertices to the component
                component.append(contentsOf: localComponent)
            }

            // Second pass: DFS on transpose graph in reverse finish order
            for vertex in finishOrder.reversed() where propertyMap[vertex][colorProperty] == .white {
                var component: [Vertex] = []
                observation?.receive(.componentStarted(vertex))
                dfs2(vertex, component: &component)
                observation?.receive(.componentFinished(component))
                components.append(component)
            }

            return StronglyConnectedComponentsResult(components: components)
        }
    }
#endif

#if !GRAPHS_USES_TRAITS || GRAPHS_CONNECTIVITY
    extension Kosaraju.Event: VertexDiscoveredEvent, EdgeExaminedEvent {
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
