extension PlanarPropertyAlgorithm {
    /// Creates a Boyer-Myrvold planar property algorithm.
    ///
    /// - Returns: A new Boyer-Myrvold planar property algorithm
    @inlinable
    public static func boyerMyrvold<Graph>() -> Self where Self == BoyerMyrvoldPlanarPropertyAlgorithm<Graph> {
        .init()
    }
}

extension BoyerMyrvoldPlanarPropertyAlgorithm: PlanarPropertyAlgorithm {}
