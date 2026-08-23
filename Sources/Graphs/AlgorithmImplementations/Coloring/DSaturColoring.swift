#if !GRAPHS_USES_TRAITS || GRAPHS_ANALYSIS
    /// A DSatur (Degree of Saturation) graph coloring algorithm.
    ///
    /// This algorithm colors vertices based on their saturation degree (number of different colors
    /// used by adjacent vertices) and degree. It tends to produce better colorings than greedy algorithms.
    ///
    /// - Complexity: O(V^2) where V is the number of vertices
    public struct DSaturColoringAlgorithm<
        Graph: IncidenceGraph & VertexListGraph,
        Color: IntegerBasedColor
    > where Graph.VertexDescriptor: Hashable {

        /// An event emitted while DSatur coloring advances.
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

        /// Typed selectors for DSatur-coloring events.
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

        /// Creates a new DSatur coloring algorithm.
        @inlinable
        public init() {}

        /// Colors the graph using the DSatur algorithm.
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
            var usedColors: Set<Color> = []

            // Get all vertices
            let vertices = Array(graph.vertices())

            // If no vertices, return empty coloring
            guard !vertices.isEmpty else {
                return GraphColoring<Graph.VertexDescriptor, Color>(vertexColors: [:], isProper: true)
            }

            // Calculate degrees for all vertices
            let degrees = Dictionary(
                uniqueKeysWithValues: vertices.map { vertex in
                    observation?.receive(.vertexExamined(vertex))
                    return (vertex, graph.outDegree(of: vertex))
                }
            )

            // Find vertex with maximum degree to start (break ties by vertex index for determinism)
            let startVertex = vertices.enumerated().max {
                guard let deg0 = degrees[$0.element], let deg1 = degrees[$1.element] else { return false }
                if deg0 != deg1 {
                    return deg0 < deg1
                }
                // Break ties by vertex index for determinism
                return $0.offset > $1.offset
            }!.element

            // Color the first vertex with color 0
            let firstColor = Color(integerValue: 0)
            vertexColors[startVertex] = firstColor
            usedColors.insert(firstColor)
            observation?.receive(.colorAssigned(vertex: startVertex, color: firstColor))

            // Create priority queue for uncolored vertices
            var uncoloredVertices = Set(vertices)
            uncoloredVertices.remove(startVertex)

            // Color remaining vertices using DSatur heuristic
            while !uncoloredVertices.isEmpty {
                // Find vertex with maximum saturation degree
                let nextVertex = findMaxSaturationVertex(
                    in: uncoloredVertices,
                    graph: graph,
                    vertexColors: vertexColors,
                    vertices: vertices
                )

                observation?.receive(.vertexExamined(nextVertex))

                // Find the smallest available color for this vertex
                let neighbors = Set(graph.successors(of: nextVertex))

                // Examine edges to neighbors
                for edge in graph.outgoingEdges(of: nextVertex) {
                    observation?.receive(.edgeExamined(edge))
                }

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

                vertexColors[nextVertex] = assignedColor!
                usedColors.insert(assignedColor!)
                observation?.receive(.colorAssigned(vertex: nextVertex, color: assignedColor!))
                uncoloredVertices.remove(nextVertex)
            }

            // Check if the coloring is proper
            let isProper = checkProperColoring(in: graph, vertexColors: vertexColors)

            return GraphColoring(vertexColors: vertexColors, isProper: isProper)
        }

        @usableFromInline
        func findMaxSaturationVertex(
            in uncoloredVertices: Set<Graph.VertexDescriptor>,
            graph: Graph,
            vertexColors: [Graph.VertexDescriptor: Color],
            vertices: [Graph.VertexDescriptor]
        ) -> Graph.VertexDescriptor {
            var maxSaturation = -1
            var maxDegree = -1
            guard var selectedVertex = uncoloredVertices.first else {
                preconditionFailure(
                    "findMaxSaturationVertex called with empty uncoloredVertices set"
                        + " - this should never happen as the function is only called"
                        + " when !uncoloredVertices.isEmpty"
                )
            }

            for vertex in uncoloredVertices {
                let neighbors = Set(graph.successors(of: vertex))
                let saturationDegree = Set(
                    neighbors.compactMap { neighbor in
                        vertexColors[neighbor]
                    }
                ).count

                let degree = graph.outDegree(of: vertex)

                // Select vertex with maximum saturation degree, breaking ties by degree, then by vertex index
                let shouldSelect: Bool
                if saturationDegree > maxSaturation {
                    shouldSelect = true
                } else if saturationDegree == maxSaturation && degree > maxDegree {
                    shouldSelect = true
                } else if saturationDegree == maxSaturation && degree == maxDegree {
                    // Both saturation and degree are equal, use vertex index for determinism
                    guard let currentIndex = vertices.firstIndex(of: vertex),
                        let selectedIndex = vertices.firstIndex(of: selectedVertex)
                    else {
                        shouldSelect = false
                        break
                    }
                    shouldSelect = currentIndex < selectedIndex
                } else {
                    shouldSelect = false
                }

                if shouldSelect {
                    maxSaturation = saturationDegree
                    maxDegree = degree
                    selectedVertex = vertex
                }
            }

            return selectedVertex
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
    extension DSaturColoringAlgorithm.Event: VertexExaminedEvent, EdgeExaminedEvent {
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
