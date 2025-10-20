import Foundation

extension PlanarPropertyAlgorithm {
    /// Creates a Hopcroft-Tarjan planar property algorithm.
    ///
    /// - Returns: A new Hopcroft-Tarjan planar property algorithm
    @inlinable
    public static func hopcroftTarjan<Graph>() -> Self where Self == HopcroftTarjanPlanarPropertyAlgorithm<Graph> {
        .init()
    }
}

extension HopcroftTarjanPlanarPropertyAlgorithm: PlanarPropertyAlgorithm {
    @inlinable
    public func isPlanar(in graph: Graph) -> Bool {
        isPlanar(in: graph, visitor: nil)
    }
}
