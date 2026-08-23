#if !GRAPHS_USES_TRAITS || GRAPHS_GENERATION
    /// Barabasi-Albert random graph generation algorithm.
    ///
    /// This algorithm generates scale-free networks using preferential attachment.
    /// New vertices are more likely to connect to vertices with higher degrees.
    ///
    /// - Complexity: O(V * k) where V is the number of vertices and k is the average degree
    public struct BarabasiAlbert<
        Graph: MutableGraph & BidirectionalGraph
    > where Graph.VertexDescriptor: Hashable {
        /// The vertex type of the graph.
        public typealias Vertex = Graph.VertexDescriptor

        /// An event emitted while generating a Barabasi-Albert graph.
        public enum Event {
            /// A vertex was added.
            case vertexAdded(Vertex)
            /// An edge was added between two vertices.
            case edgeAdded(source: Vertex, destination: Vertex)
            /// A preferential-attachment target was selected.
            case targetSelected(Vertex, candidates: [Vertex])
            /// A vertex degree was updated.
            case degreeUpdated(Vertex, degree: Int)
        }

        /// Typed selectors for Barabasi-Albert events.
        public enum EventCases {
            /// Selects added vertices.
            public static var vertexAdded: AlgorithmEventCase<Event, Vertex> {
                .init {
                    guard case .vertexAdded(let vertex) = $0 else { return nil }
                    return vertex
                }
            }

            /// Selects added edges.
            public static var edgeAdded: AlgorithmEventCase<Event, (source: Vertex, destination: Vertex)> {
                .init {
                    guard case .edgeAdded(let source, let destination) = $0 else { return nil }
                    return (source, destination)
                }
            }

            /// Selects preferential-attachment targets.
            public static var targetSelected: AlgorithmEventCase<Event, (target: Vertex, candidates: [Vertex])> {
                .init {
                    guard case .targetSelected(let target, let candidates) = $0 else { return nil }
                    return (target, candidates)
                }
            }

            /// Selects degree updates.
            public static var degreeUpdated: AlgorithmEventCase<Event, (vertex: Vertex, degree: Int)> {
                .init {
                    guard case .degreeUpdated(let vertex, let degree) = $0 else { return nil }
                    return (vertex, degree)
                }
            }
        }

        /// The result of the Barabasi-Albert algorithm.
        @usableFromInline
        struct Result {
            @usableFromInline
            let graph: Graph
            @usableFromInline
            let vertices: [Vertex]
            @usableFromInline
            let edges: [(Vertex, Vertex)]
            @usableFromInline
            let degreeDistribution: [Vertex: Int]
        }

        /// The target average degree for the generated graph.
        @usableFromInline
        let averageDegree: Double

        /// Creates a new Barabasi-Albert algorithm.
        ///
        /// - Parameter averageDegree: The target average degree for the generated graph
        @inlinable
        public init(averageDegree: Double) {
            self.averageDegree = averageDegree
        }

        /// Appends a random Barabasi-Albert graph to an existing graph.
        ///
        /// - Parameters:
        ///   - graph: The graph to append to (modified in place)
        ///   - vertexCount: The number of vertices to add
        ///   - generator: The random number generator to use
        ///   - observation: An optional observation of algorithm progress.
        @inlinable
        public func appendRandomGraph<RNG: RandomNumberGenerator>(
            into graph: inout Graph,
            vertexCount: Int,
            using generator: inout RNG,
            observation: AlgorithmObservation<Event>? = nil
        ) {
            guard vertexCount > 0 else { return }

            // If the graph is empty, start by adding one vertex to seed preferential attachment
            var vertices: [Vertex] = []
            for _ in 0 ..< vertexCount {
                let newVertex = graph.addVertex()
                observation?.receive(.vertexAdded(newVertex))
                vertices.append(newVertex)

                // Calculate number of edges to add for this vertex
                let targetEdges = max(1, min(vertices.count - 1, Int(averageDegree)))

                // Preferential attachment among existing vertices (excluding the new one)
                if vertices.count > 1 {
                    for _ in 0 ..< targetEdges {
                        if let target = selectVertexByPreferentialAttachment(
                            from: vertices.dropLast(),
                            using: &generator,
                            observation: observation,
                            graph: graph
                        ) {
                            graph.addEdge(from: newVertex, to: target)
                            observation?.receive(.edgeAdded(source: newVertex, destination: target))
                            observation?.receive(.degreeUpdated(target, degree: graph.degree(of: target)))
                        }
                    }
                }
            }
        }

        @usableFromInline
        func selectVertexByPreferentialAttachment<RNG: RandomNumberGenerator>(
            from vertices: ArraySlice<Vertex>,
            using generator: inout RNG,
            observation: AlgorithmObservation<Event>?,
            graph: Graph
        ) -> Vertex? {
            guard !vertices.isEmpty else { return nil }

            // Compute degrees on the fly
            let degrees = vertices.map { graph.degree(of: $0) }
            let totalDegree = degrees.reduce(0, +)

            let selected: Vertex?
            if totalDegree == 0 {
                selected = vertices.randomElement(using: &generator)
            } else {
                let threshold = Int.random(in: 0 ..< max(1, totalDegree), using: &generator)
                var cumulative = 0
                var found: Vertex?
                for (index, v) in vertices.enumerated() {
                    cumulative += degrees[index]
                    if threshold < cumulative {
                        found = v
                        break
                    }
                }
                selected = found ?? vertices.last
            }

            if let target = selected {
                observation?.receive(.targetSelected(target, candidates: Array(vertices)))
            }
            return selected
        }
    }

#endif
