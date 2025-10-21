extension ErdosRenyi: RandomGraphAlgorithm {}

extension RandomGraphAlgorithm {
    /// Creates an Erdos-Renyi random graph algorithm.
    ///
    /// - Parameter edgeProbability: The probability of including each possible edge (0.0 to 1.0)
    /// - Returns: A new Erdos-Renyi random graph algorithm
    @inlinable
    public static func erdosRenyi<Graph: RandomGraphConstructible>(
        edgeProbability: Double
    ) -> Self where Self == ErdosRenyi<Graph>, Graph.VertexDescriptor: Hashable {
        .init(edgeProbability: edgeProbability)
    }
}
