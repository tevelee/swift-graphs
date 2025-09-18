import Foundation

extension WattsStrogatz: RandomGraphAlgorithm {}

extension RandomGraphAlgorithm {
    static func wattsStrogatz<Graph: RandomGraphConstructible>(
        averageDegree: Double,
        rewiringProbability: Double
    ) -> Self where Self == WattsStrogatz<Graph>, Graph.VertexDescriptor: Hashable {
        .init(averageDegree: averageDegree, rewiringProbability: rewiringProbability)
    }
}
