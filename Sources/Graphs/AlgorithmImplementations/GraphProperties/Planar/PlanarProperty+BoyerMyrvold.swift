import Foundation

extension PlanarPropertyAlgorithm {
    static func boyerMyrvold<Graph>() -> Self where Self == BoyerMyrvoldPlanarPropertyAlgorithm<Graph> {
        .init()
    }
}

extension BoyerMyrvoldPlanarPropertyAlgorithm: PlanarPropertyAlgorithm {
    func isPlanar(in graph: Graph) -> Bool {
        isPlanar(in: graph, visitor: nil)
    }
}
