import Foundation

extension PlanarPropertyAlgorithm {
    static func eulerFormula<Graph>() -> Self where Self == EulerFormulaPlanarPropertyAlgorithm<Graph> {
        .init()
    }
}

extension EulerFormulaPlanarPropertyAlgorithm: PlanarPropertyAlgorithm {
    func isPlanar(in graph: Graph) -> Bool {
        isPlanar(in: graph, visitor: nil)
    }
}
