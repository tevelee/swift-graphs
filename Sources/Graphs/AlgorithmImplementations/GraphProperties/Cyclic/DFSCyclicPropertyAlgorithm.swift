/// DFS-based algorithm for checking if a graph is cyclic.
public struct DFSCyclicPropertyAlgorithm<Graph: IncidenceGraph & VertexListGraph> where Graph.VertexDescriptor: Hashable {
    public typealias Event = DepthFirstSearch<Graph>.Event

    /// Creates a new DFS-based cyclic property algorithm.
    @inlinable
    public init() {}

    /// Checks if the graph is cyclic using DFS.
    ///
    /// - Parameters:
    ///   - graph: The graph to check
    ///   - observation: An optional observation of the algorithm progress
    /// - Returns: `true` if the graph is cyclic, `false` otherwise
    @inlinable
    public func isCyclic(
        in graph: Graph,
        observation: AlgorithmObservation<Event>?
    ) -> Bool {
        // Handle empty graphs and single vertex graphs
        guard graph.vertexCount > 1 else {
            return false
        }

        var hasCycle = false
        // Run DFS from each unvisited vertex using the existing DFS implementation
        // We need to track visited vertices to handle disconnected graphs
        var visitedVertices = Set<Graph.VertexDescriptor>()

        for vertex in graph.vertices() where !hasCycle && !visitedVertices.contains(vertex) {
            let trackingObservation = AlgorithmObservation<Event> { event in
                switch event {
                    case .vertexDiscovered(let v):
                        visitedVertices.insert(v)
                    case .backEdgeTraversed:
                        hasCycle = true
                    default:
                        break
                }
                observation?.receive(event)
            }

            var iterator = DepthFirstSearch(on: graph, from: vertex)
                .makeIterator(observation: trackingObservation)
            while iterator.next() != nil {}
        }

        return hasCycle
    }
}
