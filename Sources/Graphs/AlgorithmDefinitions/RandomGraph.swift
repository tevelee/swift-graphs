import Foundation

protocol RandomGraphAlgorithm<Graph> {
    associatedtype Graph: MutableGraph where Graph.VertexDescriptor: Hashable

    func appendRandomGraph<RNG: RandomNumberGenerator>(
        into graph: inout Graph,
        vertexCount: Int,
        using generator: inout RNG
    )
}

extension RandomGraphAlgorithm {
    func withGenerator<RNG: RandomNumberGenerator>(_ generator: RNG) -> RandomGraphAlgorithmWithGenerator<Self, RNG> {
        RandomGraphAlgorithmWithGenerator(self, generator: generator)
    }
}

protocol RandomGraphConstructible: MutableGraph {
    init()
}

extension RandomGraphConstructible where VertexDescriptor: Hashable {
    static func randomGraph<Algorithm: RandomGraphAlgorithm<Self>>(
        vertexCount: Int,
        using algorithm: Algorithm
    ) -> Self {
        var graph = Self.init()
        var rng = SystemRandomNumberGenerator()
        algorithm.appendRandomGraph(into: &graph, vertexCount: vertexCount, using: &rng)
        return graph
    }
}

extension MutableGraph where VertexDescriptor: Hashable {
    mutating func appendRandom<Algorithm: RandomGraphAlgorithm<Self>>(vertexCount: Int, using algorithm: Algorithm) {
        var rng = SystemRandomNumberGenerator()
        algorithm.appendRandomGraph(into: &self, vertexCount: vertexCount, using: &rng)
    }

    mutating func appendRandom<Algorithm: RandomGraphAlgorithm<Self>, RNG: RandomNumberGenerator>(
        vertexCount: Int,
        using algorithm: Algorithm,
        generator: inout RNG
    ) {
        algorithm.appendRandomGraph(into: &self, vertexCount: vertexCount, using: &generator)
    }
}

// A wrapper that fixes a particular RNG to an algorithm.
struct RandomGraphAlgorithmWithGenerator<Algorithm: RandomGraphAlgorithm, RNG: RandomNumberGenerator>: RandomGraphAlgorithm {
    typealias Graph = Algorithm.Graph

    var algorithm: Algorithm
    var fixedGenerator: RNG

    init(_ algorithm: Algorithm, generator: RNG) {
        self.algorithm = algorithm
        self.fixedGenerator = generator
    }

    // Ignores the incoming RNG and uses the fixed one.
    func appendRandomGraph<R: RandomNumberGenerator>(
        into graph: inout Algorithm.Graph,
        vertexCount: Int,
        using generator: inout R
    ) {
        var g = fixedGenerator
        algorithm.appendRandomGraph(into: &graph, vertexCount: vertexCount, using: &g)
    }
}
