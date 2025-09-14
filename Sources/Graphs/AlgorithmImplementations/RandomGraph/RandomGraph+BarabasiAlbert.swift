import Foundation

extension BarabasiAlbert: RandomGraphAlgorithm {
    func appendRandomGraph<RNG: RandomNumberGenerator>(
        into graph: inout Graph,
        vertexCount: Int,
        using generator: inout RNG
    ) {
        appendRandomGraph(into: &graph, vertexCount: vertexCount, using: &generator, visitor: nil)
    }
}

extension RandomGraphAlgorithm {
    static func barabasiAlbert<Graph: RandomGraphConstructible>(
        averageDegree: Double
    ) -> Self where Self == BarabasiAlbert<Graph>, Graph.VertexDescriptor: Hashable {
        .init(averageDegree: averageDegree)
    }
}
