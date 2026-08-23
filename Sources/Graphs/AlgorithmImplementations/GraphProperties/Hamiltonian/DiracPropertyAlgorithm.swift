/// Standard implementation of Dirac's theorem for Hamiltonian cycles.
public struct StandardDiracPropertyAlgorithm<Graph: IncidenceGraph & VertexListGraph & BidirectionalGraph> where Graph.VertexDescriptor: Hashable {
    public typealias Event = DiracProperty<Graph>.Event

    /// Creates a new standard Dirac property algorithm.
    @inlinable
    public init() {}

    /// Checks if the graph satisfies Dirac's theorem for Hamiltonian cycles.
    ///
    /// - Parameters:
    ///   - graph: The graph to check
    ///   - observation: An optional observation of algorithm progress.
    /// - Returns: `true` if the graph satisfies Dirac's theorem, `false` otherwise
    @inlinable
    public func satisfiesDirac(
        in graph: Graph,
        observation: AlgorithmObservation<Event>?
    ) -> Bool {
        let n = graph.vertexCount

        // Dirac's theorem requires at least 3 vertices
        guard n >= 3 else {
            observation?.receive(.insufficientVertexCount(n))
            return false
        }

        let minDegree = n / 2
        observation?.receive(.minimumDegreeComputed(minDegree))

        // Check if every vertex has degree >= n/2
        for vertex in graph.vertices() {
            let degree = graph.degree(of: vertex)
            observation?.receive(.vertexDegreeChecked(vertex: vertex, degree: degree, minimum: minDegree))

            // Use proper comparison: degree must be >= n/2
            // Since we can't have fractional degrees, we need degree >= (n+1)/2
            if degree * 2 < n {
                observation?.receive(.vertexDegreeTooLow(vertex: vertex, degree: degree, minimum: minDegree))
                return false
            }
        }

        return true
    }
}
