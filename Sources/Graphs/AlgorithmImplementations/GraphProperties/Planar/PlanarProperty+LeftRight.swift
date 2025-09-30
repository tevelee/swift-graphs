import Foundation

extension PlanarPropertyAlgorithm {
    /// Creates a Left-Right planar property algorithm.
    ///
    /// - Returns: A new Left-Right planar property algorithm
    @inlinable
    public static func leftRight<Graph>() -> Self where Self == LeftRightPlanarPropertyAlgorithm<Graph> {
        .init()
    }
}

extension LeftRightPlanarPropertyAlgorithm: PlanarPropertyAlgorithm {
    @inlinable
    public func isPlanar(in graph: Graph) -> Bool {
        isPlanar(in: graph, visitor: nil)
    }
}
