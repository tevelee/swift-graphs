import Foundation

extension BarabasiAlbert: RandomGraphAlgorithm {}

extension RandomGraphAlgorithm {
    static func barabasiAlbert<Graph: RandomGraphConstructible>(
        averageDegree: Double
    ) -> Self where Self == BarabasiAlbert<Graph>, Graph.VertexDescriptor: Hashable {
        .init(averageDegree: averageDegree)
    }
}
