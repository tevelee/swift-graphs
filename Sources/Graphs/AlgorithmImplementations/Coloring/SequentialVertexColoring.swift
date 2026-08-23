#if !GRAPHS_USES_TRAITS || GRAPHS_ANALYSIS
    /// Sequential Vertex Coloring algorithm that uses vertex ordering.
    ///
    /// This algorithm assigns colors to vertices in a specific order, ensuring that no two
    /// adjacent vertices share the same color. The efficiency and effectiveness of this method
    /// is heavily influenced by the chosen vertex ordering.
    ///
    /// - Complexity: O(V^2) where V is the number of vertices
    public struct SequentialVertexColoringAlgorithm<
        Graph: IncidenceGraph & VertexListGraph & BidirectionalGraph,
        Color: IntegerBasedColor
    > where Graph.VertexDescriptor: Hashable {

        /// An event emitted while sequential vertex coloring advances.
        public enum Event {
            /// A vertex was examined.
            case vertexExamined(Graph.VertexDescriptor)
            /// An edge was examined.
            case edgeExamined(Graph.EdgeDescriptor)
            /// A color was assigned to a vertex.
            case colorAssigned(vertex: Graph.VertexDescriptor, color: Color)
            /// A vertex was skipped for the given reason.
            case vertexSkipped(vertex: Graph.VertexDescriptor, reason: String)
            /// The configured vertex-ordering algorithm was selected.
            case orderingSelected
        }

        /// Typed selectors for sequential-coloring events.
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

            /// Selects the chosen vertex-ordering algorithm.
            public static var orderingSelected: AlgorithmEventCase<Event, Void> {
                .init {
                    guard case .orderingSelected = $0 else { return nil }
                    return ()
                }
            }
        }

        /// The vertex ordering algorithm to use.
        @usableFromInline
        let orderingAlgorithm: any VertexOrderingAlgorithm<Graph>

        /// Creates a new Sequential Vertex Coloring algorithm.
        ///
        /// - Parameter orderingAlgorithm: The vertex ordering algorithm to use
        @inlinable
        public init(using orderingAlgorithm: some VertexOrderingAlgorithm<Graph>) {
            self.orderingAlgorithm = orderingAlgorithm
        }

        /// Colors the graph using the sequential vertex coloring algorithm.
        ///
        /// - Parameters:
        ///   - graph: The graph to color
        ///   - observation: An optional algorithm observation.
        /// - Returns: The graph coloring result
        @inlinable
        public func color(
            graph: Graph,
            observation: AlgorithmObservation<Event>? = nil
        ) -> GraphColoring<Graph.VertexDescriptor, Color> {
            var vertexColors: [Graph.VertexDescriptor: Color] = [:]
            var usedColors: Set<Color> = []

            // Get vertex ordering - we need to work around the existential type limitation
            observation?.receive(.orderingSelected)
            let orderedVertices: [Graph.VertexDescriptor]

            // Use type erasure to call the method
            if let smallestLast = orderingAlgorithm as? SmallestLastVertexOrderingAlgorithm<Graph> {
                orderedVertices = smallestLast.orderVertices(in: graph, observation: nil)
            } else if let reverseCuthillMcKee = orderingAlgorithm as? ReverseCuthillMcKeeOrderingAlgorithm<Graph> {
                orderedVertices = reverseCuthillMcKee.orderVertices(in: graph, observation: nil)
            } else {
                // Fallback to default ordering (just use vertices as-is)
                orderedVertices = Array(graph.vertices())
            }

            // If no vertices, return empty coloring
            guard !orderedVertices.isEmpty else {
                return GraphColoring<Graph.VertexDescriptor, Color>(vertexColors: [:], isProper: true)
            }

            // Color vertices in the specified order
            for vertex in orderedVertices {
                observation?.receive(.vertexExamined(vertex))

                let neighbors = Set(graph.successors(of: vertex))

                // Examine edges to neighbors
                for edge in graph.outgoingEdges(of: vertex) {
                    observation?.receive(.edgeExamined(edge))
                }

                // Find the smallest available color
                var colorIndex = 0
                var assignedColor: Color?

                while assignedColor == nil {
                    let candidateColor = Color(integerValue: colorIndex)

                    // Check if this color is used by any neighbor
                    let isColorUsedByNeighbor = neighbors.contains { neighbor in
                        if let neighborColor = vertexColors[neighbor] {
                            return neighborColor == candidateColor
                        }
                        return false
                    }

                    if !isColorUsedByNeighbor {
                        assignedColor = candidateColor
                    } else {
                        colorIndex += 1
                    }
                }

                vertexColors[vertex] = assignedColor!
                usedColors.insert(assignedColor!)
                observation?.receive(.colorAssigned(vertex: vertex, color: assignedColor!))
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
    extension SequentialVertexColoringAlgorithm.Event: VertexExaminedEvent, EdgeExaminedEvent {
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
