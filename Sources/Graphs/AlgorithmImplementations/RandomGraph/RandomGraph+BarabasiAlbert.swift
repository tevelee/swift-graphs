extension BarabasiAlbert: RandomGraphAlgorithm {}

extension RandomGraphAlgorithm {
    /// Creates a Barabasi-Albert random graph algorithm.
    ///
    /// - Parameter averageDegree: The target average degree for the generated graph
    /// - Returns: A new Barabasi-Albert random graph algorithm
    @inlinable
    public static func barabasiAlbert<Graph: RandomGraphConstructible>(
        averageDegree: Double
    ) -> Self where Self == BarabasiAlbert<Graph>, Graph.VertexDescriptor: Hashable {
        .init(averageDegree: averageDegree)
    }
}
