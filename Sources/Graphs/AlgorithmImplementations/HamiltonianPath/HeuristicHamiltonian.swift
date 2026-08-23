#if !GRAPHS_USES_TRAITS || GRAPHS_ADVANCED
    /// Heuristic algorithm for finding Hamiltonian paths and cycles.
    ///
    /// This algorithm uses various heuristics to guide the search for Hamiltonian
    /// paths and cycles, potentially finding solutions faster than pure backtracking.
    ///
    /// - Complexity: O(V!) in the worst case where V is the number of vertices
    public struct HeuristicHamiltonian<Graph: IncidenceGraph & VertexListGraph>
    where Graph.VertexDescriptor: Hashable {

        /// The heuristic strategy to use.
        public enum Heuristic {
            /// Prioritize vertices with lower degree.
            case degreeBased
            /// Use random selection.
            case random
            /// Use nearest neighbor approach.
            case nearestNeighbor
        }

        /// An event emitted while the heuristic Hamiltonian algorithm runs.
        public enum Event {
            case vertexExamined(Graph.VertexDescriptor)
            case edgeExamined(Graph.EdgeDescriptor)
            case vertexAddedToPath(Graph.VertexDescriptor)
            case vertexRemovedFromPath(Graph.VertexDescriptor)
            case vertexBacktracked(Graph.VertexDescriptor)
        }

        /// Selectors for heuristic Hamiltonian events.
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

        /// The heuristic strategy to use.
        @usableFromInline
        let heuristic: Heuristic

        /// Creates a new heuristic Hamiltonian algorithm.
        ///
        /// - Parameter heuristic: The heuristic strategy to use (default: .degreeBased)
        @inlinable
        public init(heuristic: Heuristic = .degreeBased) {
            self.heuristic = heuristic
        }

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

            // Try starting from each vertex, prioritizing those with lower degree
            let sortedVertices = vertices.sorted {
                graph.outDegree(of: $0) < graph.outDegree(of: $1)
            }

            for startVertex in sortedVertices {
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

            if backtrackPathWithHeuristic(
                current: source,
                path: &path,
                visited: &visited,
                target: nil,
                in: graph,
                observation: observation
            ) {
                let dest = path.last ?? source
                return buildPath(from: path, source: source, destination: dest, in: graph)
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

            if backtrackPathWithHeuristic(
                current: source,
                path: &path,
                visited: &visited,
                target: destination,
                in: graph,
                observation: observation
            ) {
                return buildPath(from: path, source: source, destination: destination, in: graph)
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

            if backtrackCycleWithHeuristic(
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
                return buildPath(from: path, source: source, destination: source, in: graph)
            }

            return nil
        }

        private func backtrackPathWithHeuristic(
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

            // Get unvisited neighbors and apply heuristic
            let unvisitedNeighbors = graph.successors(of: current).filter { !visited.contains($0) }
            let orderedNeighbors = applyHeuristic(to: unvisitedNeighbors, in: graph)

            // Try neighbors in heuristic order
            for neighbor in orderedNeighbors {
                observation?.receive(.vertexExamined(neighbor))

                // Examine edges to neighbors
                for edge in graph.outgoingEdges(of: current) {
                    if graph.destination(of: edge) == neighbor {
                        observation?.receive(.edgeExamined(edge))
                    }
                }

                path.append(neighbor)
                visited.insert(neighbor)
                observation?.receive(.vertexAddedToPath(neighbor))

                if backtrackPathWithHeuristic(
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

            return false
        }

        private func backtrackCycleWithHeuristic(
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

            // Get unvisited neighbors and apply heuristic
            let unvisitedNeighbors = graph.successors(of: current).filter { !visited.contains($0) }
            let orderedNeighbors = applyHeuristic(to: unvisitedNeighbors, in: graph)

            // Try neighbors in heuristic order
            for neighbor in orderedNeighbors {
                observation?.receive(.vertexExamined(neighbor))

                // Examine edges to neighbors
                for edge in graph.outgoingEdges(of: current) {
                    if graph.destination(of: edge) == neighbor {
                        observation?.receive(.edgeExamined(edge))
                    }
                }

                path.append(neighbor)
                visited.insert(neighbor)
                observation?.receive(.vertexAddedToPath(neighbor))

                if backtrackCycleWithHeuristic(
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

            return false
        }

        private func applyHeuristic(
            to neighbors: [Graph.VertexDescriptor],
            in graph: Graph
        ) -> [Graph.VertexDescriptor] {
            switch heuristic {
                case .degreeBased:
                    // Prefer vertices with lower degree (fewer remaining choices)
                    return neighbors.sorted {
                        graph.outDegree(of: $0) < graph.outDegree(of: $1)
                    }

                case .random:
                    // Random order
                    return neighbors.shuffled()

                case .nearestNeighbor:
                    // For now, just use degree-based (could be extended with distance heuristics)
                    return neighbors.sorted {
                        graph.outDegree(of: $0) < graph.outDegree(of: $1)
                    }
            }
        }

        private func buildPath(
            from path: [Graph.VertexDescriptor],
            source: Graph.VertexDescriptor,
            destination: Graph.VertexDescriptor,
            in graph: Graph
        ) -> Path<Graph.VertexDescriptor, Graph.EdgeDescriptor>? {
            guard path.count > 0, let pathFirst = path.first, let pathLast = path.last else { return nil }

            // Handle single vertex case
            if path.count == 1 {
                return Path(
                    source: pathFirst,
                    destination: pathFirst,
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

            return Path(
                source: pathFirst,
                destination: pathLast,
                vertices: path,
                edges: edges
            )
        }
    }

    extension HeuristicHamiltonian: AlgorithmObserving {}
#endif

#if !GRAPHS_USES_TRAITS || GRAPHS_ADVANCED
    extension HeuristicHamiltonian.Event: VertexExaminedEvent, EdgeExaminedEvent {
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
