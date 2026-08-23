#if !GRAPHS_USES_TRAITS || GRAPHS_ADVANCED
    /// Hierholzer's algorithm for finding Eulerian paths and cycles.
    ///
    /// Hierholzer's algorithm finds an Eulerian path or cycle in a graph by building
    /// the path incrementally and backtracking when necessary. It works by starting
    /// from a vertex and following edges until no more edges are available, then
    /// backtracking to find unused edges.
    ///
    /// - Complexity: O(E) where E is the number of edges
    public struct Hierholzer<Graph: BidirectionalGraph & VertexListGraph>
    where Graph.VertexDescriptor: Hashable {

        /// Creates a new Hierholzer algorithm instance.
        @inlinable
        public init() {}

        /// An event emitted while finding an Eulerian path.
        public enum Event {
            /// A vertex is about to be examined.
            case vertexExamined(Graph.VertexDescriptor)
            /// An edge is about to be examined.
            case edgeExamined(Graph.EdgeDescriptor)
            /// A vertex was added to the final path.
            case vertexAddedToPath(Graph.VertexDescriptor)
            /// An edge was added to the final path.
            case edgeAddedToPath(Graph.EdgeDescriptor)
            /// The algorithm backtracked from a vertex.
            case vertexBacktracked(Graph.VertexDescriptor)
        }

        /// Typed selectors for Hierholzer events.
        public enum EventCases {
            /// Selects examined vertices.
            public static var vertexExamined: AlgorithmEventCase<Event, Graph.VertexDescriptor> {
                .init {
                    guard case .vertexExamined(let vertex) = $0 else { return nil }
                    return vertex
                }
            }

            /// Selects examined edges.
            public static var edgeExamined: AlgorithmEventCase<Event, Graph.EdgeDescriptor> {
                .init {
                    guard case .edgeExamined(let edge) = $0 else { return nil }
                    return edge
                }
            }

            /// Selects vertices added to the path.
            public static var vertexAddedToPath: AlgorithmEventCase<Event, Graph.VertexDescriptor> {
                .init {
                    guard case .vertexAddedToPath(let vertex) = $0 else { return nil }
                    return vertex
                }
            }

            /// Selects edges added to the path.
            public static var edgeAddedToPath: AlgorithmEventCase<Event, Graph.EdgeDescriptor> {
                .init {
                    guard case .edgeAddedToPath(let edge) = $0 else { return nil }
                    return edge
                }
            }

            /// Selects backtracked vertices.
            public static var vertexBacktracked: AlgorithmEventCase<Event, Graph.VertexDescriptor> {
                .init {
                    guard case .vertexBacktracked(let vertex) = $0 else { return nil }
                    return vertex
                }
            }
        }

        /// Finds an Eulerian path in the graph.
        ///
        /// - Parameters:
        ///   - graph: The graph to find the Eulerian path in.
        ///   - observation: An optional observation of algorithm progress.
        /// - Returns: An Eulerian path, if one exists.
        @inlinable
        public func eulerianPath(
            in graph: Graph,
            observation: AlgorithmObservation<Event>? = nil
        ) -> Path<Graph.VertexDescriptor, Graph.EdgeDescriptor>? {
            guard graph.hasEulerianPath() else { return nil }

            let vertices = Array(graph.vertices())

            // Handle empty graph
            if vertices.isEmpty {
                return nil
            }

            // Handle single vertex with no edges
            if vertices.count == 1 {
                let vertex = vertices[0]
                if graph.degree(of: vertex) == 0 {
                    return Path(source: vertex, destination: vertex, vertices: [vertex], edges: [])
                }
            }

            // Find starting vertex (odd degree vertex if exists, otherwise any vertex)
            var startVertex: Graph.VertexDescriptor?

            for vertex in vertices where graph.degree(of: vertex) % 2 == 1 {
                startVertex = vertex
                break
            }

            // If no odd degree vertex, start from any vertex
            startVertex = startVertex ?? vertices.first

            guard let start = startVertex else { return nil }

            return findEulerianPath(from: start, in: graph, observation: observation)
        }

        /// Finds an Eulerian cycle in the graph.
        ///
        /// - Parameters:
        ///   - graph: The graph to find the Eulerian cycle in.
        ///   - observation: An optional observation of algorithm progress.
        /// - Returns: An Eulerian cycle, if one exists.
        @inlinable
        public func eulerianCycle(
            in graph: Graph,
            observation: AlgorithmObservation<Event>? = nil
        ) -> Path<Graph.VertexDescriptor, Graph.EdgeDescriptor>? {
            guard graph.hasEulerianCycle() else { return nil }

            let vertices = Array(graph.vertices())

            // Handle empty graph
            if vertices.isEmpty {
                return nil
            }

            // Handle single vertex with no edges
            if vertices.count == 1 {
                let vertex = vertices[0]
                if graph.degree(of: vertex) == 0 {
                    let result = Path<Graph.VertexDescriptor, Graph.EdgeDescriptor>(source: vertex, destination: vertex, vertices: [vertex], edges: [])
                    return result
                }
            }

            guard let startVertex = vertices.first else { return nil }

            return findEulerianPath(from: startVertex, in: graph, observation: observation)
        }

        /// Finds an Eulerian path starting from a specific vertex.
        ///
        /// - Parameters:
        ///   - start: The starting vertex.
        ///   - graph: The graph to find the path in.
        ///   - observation: An optional observation of algorithm progress.
        /// - Returns: An Eulerian path, if one exists.
        @usableFromInline
        func findEulerianPath(
            from start: Graph.VertexDescriptor,
            in graph: Graph,
            observation: AlgorithmObservation<Event>?
        ) -> Path<Graph.VertexDescriptor, Graph.EdgeDescriptor>? {
            // Each stack entry records the vertex and the edge used to arrive there.
            // Tracking the incoming edge avoids the post-hoc graph search that breaks
            // for multigraphs (multiple edges between the same pair of vertices).
            var pathPairs: [(vertex: Graph.VertexDescriptor, incomingEdge: Graph.EdgeDescriptor?)] = []

            var adjacency: [Graph.VertexDescriptor: [Graph.EdgeDescriptor]] = [:]
            for vertex in graph.vertices() {
                observation?.receive(.vertexExamined(vertex))
                adjacency[vertex] = Array(graph.outgoingEdges(of: vertex))
            }

            var stack: [(vertex: Graph.VertexDescriptor, incomingEdge: Graph.EdgeDescriptor?)] = [(start, nil)]
            observation?.receive(.vertexExamined(start))

            while !stack.isEmpty {
                let current = stack.last!.vertex

                if let nextEdge = adjacency[current]?.first {
                    observation?.receive(.edgeExamined(nextEdge))
                    adjacency[current]?.removeFirst()

                    guard let nextVertex = graph.destination(of: nextEdge) else { continue }

                    stack.append((nextVertex, nextEdge))
                    observation?.receive(.vertexExamined(nextVertex))
                } else {
                    let popped = stack.removeLast()
                    pathPairs.append(popped)
                    observation?.receive(.vertexAddedToPath(popped.vertex))
                    observation?.receive(.vertexBacktracked(popped.vertex))
                }
            }

            pathPairs.reverse()

            let path = pathPairs.map(\.vertex)
            // The start vertex has no incoming edge; all subsequent entries do.
            let edges: [Graph.EdgeDescriptor] = pathPairs.dropFirst().compactMap(\.incomingEdge)
            for edge in edges {
                observation?.receive(.edgeAddedToPath(edge))
            }

            guard let first = path.first, let last = path.last else { return nil }
            return Path(source: first, destination: last, vertices: path, edges: edges)
        }
    }

#endif

#if !GRAPHS_USES_TRAITS || GRAPHS_ADVANCED
    extension Hierholzer.Event: VertexExaminedEvent, EdgeExaminedEvent {
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
