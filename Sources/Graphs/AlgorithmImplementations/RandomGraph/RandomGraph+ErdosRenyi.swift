import Foundation

extension ErdosRenyi: RandomGraphAlgorithm {
    func appendRandomGraph<RNG: RandomNumberGenerator>(
        into graph: inout Graph,
        vertexCount: Int,
        using generator: inout RNG
    ) {
        appendRandomGraph(into: &graph, vertexCount: vertexCount, using: &generator, visitor: nil)
    }
}

extension RandomGraphAlgorithm {
    static func erdosRenyi<Graph: RandomGraphConstructible>(
        edgeProbability: Double
    ) -> Self where Self == ErdosRenyi<Graph>, Graph.VertexDescriptor: Hashable {
        .init(edgeProbability: edgeProbability)
    }
}
