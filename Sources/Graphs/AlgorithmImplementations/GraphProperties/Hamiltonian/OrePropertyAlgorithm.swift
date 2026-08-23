/// Standard implementation of Ore's theorem for Hamiltonian cycles.
public struct StandardOrePropertyAlgorithm<Graph: IncidenceGraph & VertexListGraph & BidirectionalGraph> where Graph.VertexDescriptor: Hashable {
    public typealias Event = OreProperty<Graph>.Event

    /// Creates a new standard Ore property algorithm.
    @inlinable
    public init() {}

    /// Checks if the graph satisfies Ore's theorem for Hamiltonian cycles.
    ///
    /// - Parameters:
    ///   - graph: The graph to check
    ///   - observation: An optional observation of algorithm progress.
    /// - Returns: `true` if the graph satisfies Ore's theorem, `false` otherwise
    @inlinable
    public func satisfiesOre(
        in graph: Graph,
        observation: AlgorithmObservation<Event>?
    ) -> Bool {
        let n = graph.vertexCount

        // Ore's theorem requires at least 3 vertices
        guard n >= 3 else {
            observation?.receive(.insufficientVertexCount(n))
            return false
        }

        let vertices = Array(graph.vertices())
        observation?.receive(.vertexCountChecked(n))

        // Check all pairs of non-adjacent vertices
        for i in 0 ..< vertices.count {
            for j in (i + 1) ..< vertices.count {
                let u = vertices[i]
                let v = vertices[j]

                // Check if u and v are adjacent
                let areAdjacent = graph.outgoingEdges(of: u).contains { edge in
                    graph.destination(of: edge) == v
                }

                observation?.receive(.vertexPairChecked(u, v, adjacent: areAdjacent))

                if !areAdjacent {
                    let degreeSum = graph.degree(of: u) + graph.degree(of: v)
                    observation?.receive(.degreeSumChecked(u, v, sum: degreeSum, required: n))

                    if degreeSum < n {
                        observation?.receive(.degreeSumTooLow(u, v, sum: degreeSum, required: n))
                        return false
                    }
                }
            }
        }

        return true
    }
}
