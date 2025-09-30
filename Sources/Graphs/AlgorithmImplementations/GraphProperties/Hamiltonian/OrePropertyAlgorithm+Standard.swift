extension OrePropertyAlgorithm {
    /// Creates a standard Ore property algorithm.
    ///
    /// - Returns: A new standard Ore property algorithm
    @inlinable
    public static func standard<Graph>() -> Self where Self == StandardOrePropertyAlgorithm<Graph> {
        .init()
    }
}

extension StandardOrePropertyAlgorithm: OrePropertyAlgorithm {}
