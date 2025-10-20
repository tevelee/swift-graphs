extension DiracPropertyAlgorithm {
    /// Creates a standard Dirac property algorithm.
    ///
    /// - Returns: A new standard Dirac property algorithm
    @inlinable
    public static func standard<Graph>() -> Self where Self == StandardDiracPropertyAlgorithm<Graph> {
        .init()
    }
}

extension StandardDiracPropertyAlgorithm: DiracPropertyAlgorithm {}
