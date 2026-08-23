#if !GRAPHS_USES_TRAITS || GRAPHS_PATHFINDING
    extension ShortestPathUntilAlgorithm {
        /// Creates a Dijkstra shortest path algorithm.
        ///
        /// - Parameter weight: The cost definition for edge weights.
        /// - Returns: A Dijkstra shortest path algorithm instance.
        @inlinable
        public static func dijkstra<Graph: IncidenceGraph, Weight: Numeric>(
            weight: CostDefinition<Graph, Weight>
        ) -> Self where Self == DijkstraShortestPathAlgorithm<Graph, Weight>, Weight.Magnitude == Weight, Graph.VertexDescriptor: Hashable {
            .init(weight: weight)
        }
    }

    extension ShortestPathAlgorithm {
        /// Creates a Dijkstra shortest path algorithm.
        ///
        /// - Parameter weight: The cost definition for edge weights.
        /// - Returns: A Dijkstra shortest path algorithm instance.
        @inlinable
        public static func dijkstra<Graph: IncidenceGraph, Weight: Numeric>(
            weight: CostDefinition<Graph, Weight>
        ) -> Self where Self == DijkstraShortestPathAlgorithm<Graph, Weight>, Weight.Magnitude == Weight, Graph.VertexDescriptor: Hashable {
            .init(weight: weight)
        }
    }

    /// A Dijkstra shortest path algorithm implementation.
    ///
    /// This struct wraps the core Dijkstra algorithm to provide both ``ShortestPathAlgorithm``
    /// and ``ShortestPathUntilAlgorithm`` interfaces, supporting point-to-point and condition-based search.
    ///
    /// - Complexity: O((V + E) log V) where V is the number of vertices and E is the number of edges
    public struct DijkstraShortestPathAlgorithm<
        Graph: IncidenceGraph,
        Weight: Numeric & Comparable
    >: ShortestPathUntilAlgorithm
    where
        Weight.Magnitude == Weight,
        Graph.VertexDescriptor: Hashable
    {
        /// The event type emitted by the core algorithm.
        public typealias Event = Dijkstra<Graph, Weight>.Event

        /// The cost definition for edge weights.
        public let weight: CostDefinition<Graph, Weight>

        /// Creates a new Dijkstra shortest path algorithm.
        ///
        /// - Parameter weight: The cost definition for edge weights.
        @inlinable
        public init(weight: CostDefinition<Graph, Weight>) {
            self.weight = weight
        }

        /// Finds the shortest path from source until a condition is met using Dijkstra's algorithm.
        ///
        /// - Parameters:
        ///   - source: The source vertex
        ///   - condition: The condition that determines when to stop
        ///   - graph: The graph to search in
        ///   - observation: An optional observation of the algorithm progress
        /// - Returns: The shortest path to the first vertex that satisfies the condition, if one exists
        @inlinable
        public func shortestPath(
            from source: Graph.VertexDescriptor,
            until condition: @escaping (Graph.VertexDescriptor) -> Bool,
            in graph: Graph,
            observation: AlgorithmObservation<Event>?
        ) -> Path<Graph.VertexDescriptor, Graph.EdgeDescriptor>? {
            var iterator = Dijkstra(on: graph, from: source, edgeWeight: weight).makeIterator(observation: observation)
            while let result = iterator.next() {
                guard condition(result.currentVertex) else { continue }
                let destination = result.currentVertex
                return Path(
                    source: source,
                    destination: destination,
                    vertices: result.vertices(to: destination, in: graph),
                    edges: result.edges(to: destination, in: graph)
                )
            }
            return nil
        }
    }

    extension DijkstraShortestPathAlgorithm: AlgorithmObserving {}
#endif
