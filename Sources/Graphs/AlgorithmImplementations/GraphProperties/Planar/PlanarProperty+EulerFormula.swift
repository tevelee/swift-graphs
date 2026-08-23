extension PlanarPropertyAlgorithm {
    /// Creates an Euler formula-based planar property algorithm.
    ///
    /// - Returns: A new Euler formula-based planar property algorithm
    @inlinable
    public static func eulerFormula<Graph>() -> Self where Self == EulerFormulaPlanarPropertyAlgorithm<Graph> {
        .init()
    }
}

extension EulerFormulaPlanarPropertyAlgorithm: PlanarPropertyAlgorithm {}
