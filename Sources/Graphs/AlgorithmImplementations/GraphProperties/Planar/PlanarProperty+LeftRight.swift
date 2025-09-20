import Foundation

extension PlanarPropertyAlgorithm {
    static func leftRight<Graph>() -> Self where Self == LeftRightPlanarPropertyAlgorithm<Graph> {
        .init()
    }
}

extension LeftRightPlanarPropertyAlgorithm: PlanarPropertyAlgorithm {
    func isPlanar(in graph: Graph) -> Bool {
        isPlanar(in: graph, visitor: nil)
    }
}
