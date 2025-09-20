import Foundation

extension PlanarPropertyAlgorithm {
    static func hopcroftTarjan<Graph>() -> Self where Self == HopcroftTarjanPlanarPropertyAlgorithm<Graph> {
        .init()
    }
}

extension HopcroftTarjanPlanarPropertyAlgorithm: PlanarPropertyAlgorithm {
    func isPlanar(in graph: Graph) -> Bool {
        isPlanar(in: graph, visitor: nil)
    }
}
