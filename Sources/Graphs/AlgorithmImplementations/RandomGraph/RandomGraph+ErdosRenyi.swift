import Foundation

extension ErdosRenyi: RandomGraphAlgorithm {}

extension RandomGraphAlgorithm {
    static func erdosRenyi<Graph: RandomGraphConstructible>(
        edgeProbability: Double
    ) -> Self where Self == ErdosRenyi<Graph>, Graph.VertexDescriptor: Hashable {
        .init(edgeProbability: edgeProbability)
    }
}
