#if !GRAPHS_USES_TRAITS || GRAPHS_ANALYSIS
    /// A Welsh-Powell graph coloring algorithm.
    ///
    /// This algorithm sorts vertices by degree in descending order and then colors them,
    /// trying to assign the same color to as many non-adjacent vertices as possible.
    ///
    /// - Complexity: O(V^2) where V is the number of vertices
    public struct WelshPowellColoringAlgorithm<
        Graph: IncidenceGraph & VertexListGraph,
        Color: IntegerBasedColor
    > where Graph.VertexDescriptor: Hashable {

        /// An event emitted while Welsh-Powell coloring advances.
        public enum Event {
            /// A vertex was examined.
            case vertexExamined(Graph.VertexDescriptor)
            /// An edge was examined.
            case edgeExamined(Graph.EdgeDescriptor)
            /// A color was assigned to a vertex.
            case colorAssigned(vertex: Graph.VertexDescriptor, color: Color)
            /// A vertex was skipped for the given reason.
            case vertexSkipped(vertex: Graph.VertexDescriptor, reason: String)
        }

        /// Typed selectors for Welsh-Powell-coloring events.
        public enum EventCases {
            /// Selects examined vertices.
            public static var vertexExamined: AlgorithmEventCase<Event, Graph.VertexDescriptor> {
                .init {
                    guard case .vertexExamined(let value) = $0 else { return nil }
                    return value
                }
            }

            /// Selects examined edges.
            public static var edgeExamined: AlgorithmEventCase<Event, Graph.EdgeDescriptor> {
                .init {
                    guard case .edgeExamined(let value) = $0 else { return nil }
                    return value
                }
            }

            /// Selects assigned colors.
            public static var colorAssigned: AlgorithmEventCase<Event, (vertex: Graph.VertexDescriptor, color: Color)> {
                .init {
                    guard case .colorAssigned(let vertex, let color) = $0 else { return nil }
                    return (vertex, color)
                }
            }

            /// Selects skipped vertices and their reasons.
            public static var vertexSkipped: AlgorithmEventCase<Event, (vertex: Graph.VertexDescriptor, reason: String)> {
                .init {
                    guard case .vertexSkipped(let vertex, let reason) = $0 else { return nil }
                    return (vertex, reason)
                }
            }
        }

        /// Creates a new Welsh-Powell coloring algorithm.
        @inlinable
        public init() {}

        /// Colors the graph using the Welsh-Powell algorithm.
        ///
        /// - Parameters:
        ///   - graph: The graph to color.
        ///   - observation: An optional algorithm observation.
        /// - Returns: The graph coloring result.
        @inlinable
        public func color(
            graph: Graph,
            observation: AlgorithmObservation<Event>? = nil
        ) -> GraphColoring<Graph.VertexDescriptor, Color> {
            var vertexColors: [Graph.VertexDescriptor: Color] = [:]

            // Get all vertices
            let vertices = Array(graph.vertices())

            // If no vertices, return empty coloring
            guard !vertices.isEmpty else {
                return GraphColoring<Graph.VertexDescriptor, Color>(vertexColors: [:], isProper: true)
            }

            // Sort vertices by degree in descending order
            let sortedVertices = vertices.sorted { v1, v2 in
                observation?.receive(.vertexExamined(v1))
                observation?.receive(.vertexExamined(v2))
                return graph.outDegree(of: v1) > graph.outDegree(of: v2)
            }

            var currentColor = Color(integerValue: 0)

            // Color vertices in order of decreasing degree
            for vertex in sortedVertices {
                // Skip if already colored
                if vertexColors[vertex] != nil {
                    observation?.receive(.vertexSkipped(vertex: vertex, reason: "Already colored"))
                    continue
                }

                observation?.receive(.vertexExamined(vertex))

                // Color this vertex with current color
                vertexColors[vertex] = currentColor
                observation?.receive(.colorAssigned(vertex: vertex, color: currentColor))

                // Try to color as many uncolored vertices as possible with the same color
                for otherVertex in sortedVertices {
                    // Skip if already colored or if it's the same vertex
                    if vertexColors[otherVertex] != nil || otherVertex == vertex {
                        continue
                    }

                    observation?.receive(.vertexExamined(otherVertex))

                    // Check if this vertex can be colored with the current color
                    let neighbors = Set(graph.successors(of: otherVertex))

                    // Examine edges to neighbors
                    for edge in graph.outgoingEdges(of: otherVertex) {
                        observation?.receive(.edgeExamined(edge))
                    }

                    let canUseCurrentColor = !neighbors.contains { neighbor in
                        if let neighborColor = vertexColors[neighbor] {
                            return neighborColor == currentColor
                        }
                        return false
                    }

                    if canUseCurrentColor {
                        vertexColors[otherVertex] = currentColor
                        observation?.receive(.colorAssigned(vertex: otherVertex, color: currentColor))
                    }
                }

                // Move to next color
                currentColor = Color(integerValue: currentColor.integerValue + 1)
            }

            // Check if the coloring is proper
            let isProper = checkProperColoring(in: graph, vertexColors: vertexColors)

            return GraphColoring(vertexColors: vertexColors, isProper: isProper)
        }

        @usableFromInline
        func checkProperColoring(
            in graph: Graph,
            vertexColors: [Graph.VertexDescriptor: Color]
        ) -> Bool {
            for vertex in graph.vertices() {
                guard let vertexColor = vertexColors[vertex] else { continue }

                for neighbor in graph.successors(of: vertex) {
                    if let neighborColor = vertexColors[neighbor],
                        vertexColor == neighborColor
                    {
                        return false
                    }
                }
            }
            return true
        }
    }

#endif

#if !GRAPHS_USES_TRAITS || GRAPHS_ANALYSIS
    extension WelshPowellColoringAlgorithm.Event: VertexExaminedEvent, EdgeExaminedEvent {
        @inlinable
        public static func examinedVertex(from event: Self) -> Graph.VertexDescriptor? {
            guard case .vertexExamined(let vertex) = event else { return nil }
            return vertex
        }

        @inlinable
        public static func examinedEdge(from event: Self) -> Graph.EdgeDescriptor? {
            guard case .edgeExamined(let edge) = event else { return nil }
            return edge
        }
    }
#endif
