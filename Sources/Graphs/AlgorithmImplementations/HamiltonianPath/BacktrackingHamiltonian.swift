#if !GRAPHS_USES_TRAITS || GRAPHS_ADVANCED
    /// Backtracking algorithm for finding Hamiltonian paths and cycles.
    ///
    /// This algorithm uses backtracking to systematically explore all possible
    /// paths and cycles in the graph to find Hamiltonian ones.
    ///
    /// - Complexity: O(V!) in the worst case where V is the number of vertices
    public struct BacktrackingHamiltonian<Graph: IncidenceGraph & VertexListGraph>
    where Graph.VertexDescriptor: Hashable {

        /// An event emitted while the backtracking Hamiltonian algorithm runs.
        public enum Event {
            case vertexExamined(Graph.VertexDescriptor)
            case edgeExamined(Graph.EdgeDescriptor)
            case vertexAddedToPath(Graph.VertexDescriptor)
            case vertexRemovedFromPath(Graph.VertexDescriptor)
            case vertexBacktracked(Graph.VertexDescriptor)
        }

        /// Selectors for backtracking Hamiltonian events.
        public enum EventCases {
            public static var vertexExamined: AlgorithmEventCase<Event, Graph.VertexDescriptor> {
                .init {
                    guard case .vertexExamined(let value) = $0 else { return nil }
                    return value
                }
            }
            public static var edgeExamined: AlgorithmEventCase<Event, Graph.EdgeDescriptor> {
                .init {
                    guard case .edgeExamined(let value) = $0 else { return nil }
                    return value
                }
            }
            public static var vertexAddedToPath: AlgorithmEventCase<Event, Graph.VertexDescriptor> {
                .init {
                    guard case .vertexAddedToPath(let value) = $0 else { return nil }
                    return value
                }
            }
            public static var vertexRemovedFromPath: AlgorithmEventCase<Event, Graph.VertexDescriptor> {
                .init {
                    guard case .vertexRemovedFromPath(let value) = $0 else { return nil }
                    return value
                }
            }
            public static var vertexBacktracked: AlgorithmEventCase<Event, Graph.VertexDescriptor> {
                .init {
                    guard case .vertexBacktracked(let value) = $0 else { return nil }
                    return value
                }
            }
        }

        /// Creates a new backtracking Hamiltonian algorithm.
        @inlinable
        public init() {}

        /// Finds a Hamiltonian path in the graph.
        ///
        /// - Parameters:
        ///   - graph: The graph to search in
        ///   - observation: An optional observation to observe the algorithm progress
        /// - Returns: A Hamiltonian path if one exists, nil otherwise
        @inlinable
        public func hamiltonianPath(in graph: Graph, observation: AlgorithmObservation<Event>? = nil) -> Path<Graph.VertexDescriptor, Graph.EdgeDescriptor>? {
            let vertices = Array(graph.vertices())
            guard !vertices.isEmpty else { return nil }

            // Try starting from each vertex
            for startVertex in vertices {
                observation?.receive(.vertexExamined(startVertex))
                if let path = findHamiltonianPath(from: startVertex, in: graph, observation: observation) {
                    return path
                }
            }

            return nil
        }

        /// Finds a Hamiltonian path starting from a specific vertex.
        ///
        /// - Parameters:
        ///   - source: The starting vertex
        ///   - graph: The graph to search in
        ///   - observation: An optional observation to observe the algorithm progress
        /// - Returns: A Hamiltonian path if one exists, nil otherwise
        @inlinable
        public func hamiltonianPath(
            from source: Graph.VertexDescriptor,
            in graph: Graph,
            observation: AlgorithmObservation<Event>? = nil
        ) -> Path<Graph.VertexDescriptor, Graph.EdgeDescriptor>? {
            return findHamiltonianPath(from: source, in: graph, observation: observation)
        }

        /// Finds a Hamiltonian path between two specific vertices.
        ///
        /// - Parameters:
        ///   - source: The starting vertex
        ///   - destination: The ending vertex
        ///   - graph: The graph to search in
        ///   - observation: An optional observation to observe the algorithm progress
        /// - Returns: A Hamiltonian path if one exists, nil otherwise
        @inlinable
        public func hamiltonianPath(
            from source: Graph.VertexDescriptor,
            to destination: Graph.VertexDescriptor,
            in graph: Graph,
            observation: AlgorithmObservation<Event>? = nil
        ) -> Path<Graph.VertexDescriptor, Graph.EdgeDescriptor>? {
            return findHamiltonianPath(from: source, to: destination, in: graph, observation: observation)
        }

        /// Finds a Hamiltonian cycle in the graph.
        ///
        /// - Parameters:
        ///   - graph: The graph to search in
        ///   - observation: An optional observation to observe the algorithm progress
        /// - Returns: A Hamiltonian cycle if one exists, nil otherwise
        @inlinable
        public func hamiltonianCycle(in graph: Graph, observation: AlgorithmObservation<Event>? = nil) -> Path<Graph.VertexDescriptor, Graph.EdgeDescriptor>? {
            let vertices = Array(graph.vertices())
            guard !vertices.isEmpty else { return nil }

            // Try starting from each vertex
            for startVertex in vertices {
                observation?.receive(.vertexExamined(startVertex))
                if let cycle = findHamiltonianCycle(from: startVertex, in: graph, observation: observation) {
                    return cycle
                }
            }

            return nil
        }

        @usableFromInline
        func findHamiltonianPath(
            from source: Graph.VertexDescriptor,
            in graph: Graph,
            observation: AlgorithmObservation<Event>?
        ) -> Path<Graph.VertexDescriptor, Graph.EdgeDescriptor>? {
            var path: [Graph.VertexDescriptor] = [source]
            var visited: Set<Graph.VertexDescriptor> = [source]
            observation?.receive(.vertexAddedToPath(source))

            if backtrackPath(
                current: source,
                path: &path,
                visited: &visited,
                target: nil,
                in: graph,
                observation: observation
            ) {
                return buildPath(from: path, in: graph)
            }

            return nil
        }

        @usableFromInline
        func findHamiltonianPath(
            from source: Graph.VertexDescriptor,
            to destination: Graph.VertexDescriptor,
            in graph: Graph,
            observation: AlgorithmObservation<Event>?
        ) -> Path<Graph.VertexDescriptor, Graph.EdgeDescriptor>? {
            var path: [Graph.VertexDescriptor] = [source]
            var visited: Set<Graph.VertexDescriptor> = [source]
            observation?.receive(.vertexAddedToPath(source))

            if backtrackPath(
                current: source,
                path: &path,
                visited: &visited,
                target: destination,
                in: graph,
                observation: observation
            ) {
                return buildPath(from: path, in: graph)
            }

            return nil
        }

        @usableFromInline
        func findHamiltonianCycle(
            from source: Graph.VertexDescriptor,
            in graph: Graph,
            observation: AlgorithmObservation<Event>?
        ) -> Path<Graph.VertexDescriptor, Graph.EdgeDescriptor>? {
            var path: [Graph.VertexDescriptor] = [source]
            var visited: Set<Graph.VertexDescriptor> = [source]
            observation?.receive(.vertexAddedToPath(source))

            if backtrackCycle(
                current: source,
                path: &path,
                visited: &visited,
                start: source,
                in: graph,
                observation: observation
            ) {
                // Add the starting vertex at the end to complete the cycle
                path.append(source)
                observation?.receive(.vertexAddedToPath(source))
                return buildPath(from: path, in: graph)
            }

            return nil
        }

        private func backtrackPath(
            current: Graph.VertexDescriptor,
            path: inout [Graph.VertexDescriptor],
            visited: inout Set<Graph.VertexDescriptor>,
            target: Graph.VertexDescriptor?,
            in graph: Graph,
            observation: AlgorithmObservation<Event>?
        ) -> Bool {
            let vertices = Array(graph.vertices())

            // If we have a target and reached it, check if all vertices are visited
            if let target = target, current == target {
                return visited.count == vertices.count
            }

            // If no target, check if all vertices are visited
            if target == nil && visited.count == vertices.count {
                return true
            }

            // Try all unvisited neighbors
            for neighbor in graph.successors(of: current) {
                observation?.receive(.vertexExamined(neighbor))

                // Examine edges to neighbors
                for edge in graph.outgoingEdges(of: current) {
                    if graph.destination(of: edge) == neighbor {
                        observation?.receive(.edgeExamined(edge))
                    }
                }

                if !visited.contains(neighbor) {
                    path.append(neighbor)
                    visited.insert(neighbor)
                    observation?.receive(.vertexAddedToPath(neighbor))

                    if backtrackPath(
                        current: neighbor,
                        path: &path,
                        visited: &visited,
                        target: target,
                        in: graph,
                        observation: observation
                    ) {
                        return true
                    }

                    // Backtrack
                    path.removeLast()
                    visited.remove(neighbor)
                    observation?.receive(.vertexRemovedFromPath(neighbor))
                    observation?.receive(.vertexBacktracked(neighbor))
                }
            }

            return false
        }

        private func backtrackCycle(
            current: Graph.VertexDescriptor,
            path: inout [Graph.VertexDescriptor],
            visited: inout Set<Graph.VertexDescriptor>,
            start: Graph.VertexDescriptor,
            in graph: Graph,
            observation: AlgorithmObservation<Event>?
        ) -> Bool {
            let vertices = Array(graph.vertices())

            // If all vertices visited, check if we can return to start
            if visited.count == vertices.count {
                return graph.successors(of: current).contains(start)
            }

            // Try all unvisited neighbors
            for neighbor in graph.successors(of: current) {
                observation?.receive(.vertexExamined(neighbor))

                // Examine edges to neighbors
                for edge in graph.outgoingEdges(of: current) {
                    if graph.destination(of: edge) == neighbor {
                        observation?.receive(.edgeExamined(edge))
                    }
                }

                if !visited.contains(neighbor) {
                    path.append(neighbor)
                    visited.insert(neighbor)
                    observation?.receive(.vertexAddedToPath(neighbor))

                    if backtrackCycle(
                        current: neighbor,
                        path: &path,
                        visited: &visited,
                        start: start,
                        in: graph,
                        observation: observation
                    ) {
                        return true
                    }

                    // Backtrack
                    path.removeLast()
                    visited.remove(neighbor)
                    observation?.receive(.vertexRemovedFromPath(neighbor))
                    observation?.receive(.vertexBacktracked(neighbor))
                }
            }

            return false
        }

        private func buildPath(
            from path: [Graph.VertexDescriptor],
            in graph: Graph
        ) -> Path<Graph.VertexDescriptor, Graph.EdgeDescriptor>? {
            guard path.count > 0 else { return nil }

            // Handle single vertex case
            if path.count == 1 {
                return Path(
                    source: path[0],
                    destination: path[0],
                    vertices: path,
                    edges: []
                )
            }

            var edges: [Graph.EdgeDescriptor] = []

            for i in 0 ..< (path.count - 1) {
                let from = path[i]
                let to = path[i + 1]

                // Find edge between from and to
                guard
                    let edge = graph.outgoingEdges(of: from).first(where: {
                        graph.destination(of: $0) == to
                    })
                else {
                    return nil  // Invalid path
                }
                edges.append(edge)
            }

            guard let first = path.first, let last = path.last else {
                return nil
            }
            return Path(
                source: first,
                destination: last,
                vertices: path,
                edges: edges
            )
        }
    }

    extension BacktrackingHamiltonian: AlgorithmObserving {}
#endif

#if !GRAPHS_USES_TRAITS || GRAPHS_ADVANCED
    extension BacktrackingHamiltonian.Event: VertexExaminedEvent, EdgeExaminedEvent {
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
