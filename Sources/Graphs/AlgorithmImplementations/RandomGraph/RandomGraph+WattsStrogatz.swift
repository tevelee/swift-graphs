import Foundation

extension WattsStrogatz: RandomGraphAlgorithm {
    func appendRandomGraph<RNG: RandomNumberGenerator>(
        into graph: inout Graph,
        vertexCount: Int,
        using generator: inout RNG
    ) {
        appendRandomGraph(into: &graph, vertexCount: vertexCount, using: &generator, visitor: nil)
    }
}

extension RandomGraphAlgorithm {
    static func wattsStrogatz<Graph: RandomGraphConstructible>(
        averageDegree: Double,
        rewiringProbability: Double
    ) -> Self where Self == WattsStrogatz<Graph>, Graph.VertexDescriptor: Hashable {
        .init(averageDegree: averageDegree, rewiringProbability: rewiringProbability)
    }
}
