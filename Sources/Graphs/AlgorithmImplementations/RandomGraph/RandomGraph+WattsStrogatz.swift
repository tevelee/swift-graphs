#if !GRAPHS_USES_TRAITS || GRAPHS_GENERATION
extension WattsStrogatz: RandomGraphAlgorithm {}

extension RandomGraphAlgorithm {
    /// Creates a Watts-Strogatz random graph algorithm.
    ///
    /// - Parameters:
    ///   - averageDegree: The target average degree for the generated graph
    ///   - rewiringProbability: The probability of rewiring each edge (0.0 to 1.0)
    /// - Returns: A new Watts-Strogatz random graph algorithm
    @inlinable
    public static func wattsStrogatz<Graph: RandomGraphConstructible>(
        averageDegree: Double,
        rewiringProbability: Double
    ) -> Self where Self == WattsStrogatz<Graph>, Graph.VertexDescriptor: Hashable {
        .init(averageDegree: averageDegree, rewiringProbability: rewiringProbability)
    }
}
#endif
