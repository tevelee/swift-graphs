#if !GRAPHS_USES_TRAITS || GRAPHS_ADVANCED
    import OrderedCollections

    /// Bron-Kerbosch algorithm for finding all maximal cliques.
    ///
    /// This algorithm finds all maximal cliques using the Bron-Kerbosch algorithm
    /// with pivoting for improved performance.
    ///
    /// - Complexity: O(3^(n/3)) in worst case, but typically much faster in practice
    public struct BronKerboschCliqueDetection<Graph: IncidenceGraph & VertexListGraph>
    where Graph.VertexDescriptor: Hashable {
        /// The vertex type of the graph.
        public typealias Vertex = Graph.VertexDescriptor
        /// The edge type of the graph.
        public typealias Edge = Graph.EdgeDescriptor

        /// An event emitted while Bron-Kerbosch clique detection advances.
        public enum Event {
            /// Exploration of a clique candidate started.
            case cliqueExplorationStarted([Vertex])
            /// A maximal clique was found.
            case cliqueFound([Vertex])
            /// A pivot vertex was chosen.
            case pivotChosen(Vertex)
            /// The search backtracked to a clique candidate.
            case cliqueBacktracked([Vertex])
        }

        /// Typed selectors for Bron-Kerbosch events.
        public enum EventCases {
            /// Selects clique-exploration starts.
            public static var cliqueExplorationStarted: AlgorithmEventCase<Event, [Vertex]> {
                .init {
                    guard case .cliqueExplorationStarted(let value) = $0 else { return nil }
                    return value
                }
            }

            /// Selects discovered maximal cliques.
            public static var cliqueFound: AlgorithmEventCase<Event, [Vertex]> {
                .init {
                    guard case .cliqueFound(let value) = $0 else { return nil }
                    return value
                }
            }

            /// Selects chosen pivots.
            public static var pivotChosen: AlgorithmEventCase<Event, Vertex> {
                .init {
                    guard case .pivotChosen(let value) = $0 else { return nil }
                    return value
                }
            }

            /// Selects backtracked clique candidates.
            public static var cliqueBacktracked: AlgorithmEventCase<Event, [Vertex]> {
                .init {
                    guard case .cliqueBacktracked(let value) = $0 else { return nil }
                    return value
                }
            }
        }

        /// The graph to find cliques in.
        @usableFromInline
        let graph: Graph

        /// Creates a new Bron-Kerbosch clique detection algorithm.
        ///
        /// - Parameter graph: The graph to find cliques in
        @inlinable
        public init(on graph: Graph) {
            self.graph = graph
        }

        /// Finds all maximal cliques using Bron-Kerbosch with pivoting.
        ///
        /// - Parameter observation: An optional algorithm observation.
        /// - Returns: The clique detection result
        @inlinable
        public func findCliques(
            observation: AlgorithmObservation<Event>? = nil
        ) -> CliqueDetectionResult<Vertex> {
            var cliques: [[Vertex]] = []

            // Build adjacency map for quick neighbor lookup
            var neighbors: [Vertex: Set<Vertex>] = [:]
            for vertex in graph.vertices() {
                neighbors[vertex] = Set(graph.successors(of: vertex))
            }

            let allVertices = Set(graph.vertices())

            bronKerboschWithPivot(
                r: [],
                p: allVertices,
                x: [],
                neighbors: neighbors,
                cliques: &cliques,
                observation: observation
            )

            return CliqueDetectionResult(cliques: cliques)
        }

        @usableFromInline
        func bronKerboschWithPivot(
            r: Set<Vertex>,
            p: Set<Vertex>,
            x: Set<Vertex>,
            neighbors: [Vertex: Set<Vertex>],
            cliques: inout [[Vertex]],
            observation: AlgorithmObservation<Event>?
        ) {
            if p.isEmpty && x.isEmpty {
                // Found a maximal clique (but only if it's not empty)
                if !r.isEmpty {
                    let clique = Array(r)
                    observation?.receive(.cliqueFound(clique))
                    cliques.append(clique)
                }
                return
            }

            observation?.receive(.cliqueExplorationStarted(Array(r)))

            // Choose pivot from P ∪ X with maximum neighbors in P
            let pivot = choosePivot(from: p.union(x), in: p, neighbors: neighbors)
            observation?.receive(.pivotChosen(pivot))

            let pivotNeighbors = neighbors[pivot] ?? []
            let candidates = p.subtracting(pivotNeighbors)

            var currentP = p
            var currentX = x

            for vertex in candidates {
                let vertexNeighbors = neighbors[vertex] ?? []

                bronKerboschWithPivot(
                    r: r.union([vertex]),
                    p: currentP.intersection(vertexNeighbors),
                    x: currentX.intersection(vertexNeighbors),
                    neighbors: neighbors,
                    cliques: &cliques,
                    observation: observation
                )

                currentP.remove(vertex)
                currentX.insert(vertex)
                observation?.receive(.cliqueBacktracked(Array(r)))
            }
        }

        @usableFromInline
        func choosePivot(
            from candidates: Set<Vertex>,
            in p: Set<Vertex>,
            neighbors: [Vertex: Set<Vertex>]
        ) -> Vertex {
            // Choose vertex with maximum degree in P
            if let maxVertex = candidates.max(by: { v1, v2 in
                let count1 = (neighbors[v1] ?? []).intersection(p).count
                let count2 = (neighbors[v2] ?? []).intersection(p).count
                return count1 < count2
            }) {
                return maxVertex
            }
            // Fallback: if candidates is empty, return first vertex from P
            guard let fallback = p.first else {
                preconditionFailure("choosePivot called with empty candidates and empty P - this should not happen")
            }
            return fallback
        }
    }

    extension BronKerboschCliqueDetection: CliqueDetectionAlgorithm {
        @inlinable
        public func findCliques(
            in graph: Graph,
            observation: AlgorithmObservation<Event>?
        ) -> CliqueDetectionResult<Graph.VertexDescriptor> {
            findCliques(observation: observation)
        }
    }
#endif
