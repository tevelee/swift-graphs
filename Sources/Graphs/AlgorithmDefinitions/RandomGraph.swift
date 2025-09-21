import Foundation

protocol RandomGraphAlgorithm<Graph> {
    associatedtype Graph: MutableGraph where Graph.VertexDescriptor: Hashable
    associatedtype Visitor

    func appendRandomGraph<RNG: RandomNumberGenerator>(
        into graph: inout Graph,
        vertexCount: Int,
        using generator: inout RNG,
        visitor: Visitor?
    )
}

extension VisitorWrapper: RandomGraphAlgorithm where Base: RandomGraphAlgorithm, Base.Visitor == Visitor, Visitor: Composable, Visitor.Other == Visitor {
    typealias Visitor = Base.Visitor
    
    func appendRandomGraph<RNG: RandomNumberGenerator>(
        into graph: inout Base.Graph,
        vertexCount: Int,
        using generator: inout RNG,
        visitor: Base.Visitor?
    ) {
        base.appendRandomGraph(into: &graph, vertexCount: vertexCount, using: &generator, visitor: self.visitor.combined(with: visitor))
    }
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
        algorithm.appendRandomGraph(into: &graph, vertexCount: vertexCount, using: &rng, visitor: nil)
        return graph
    }
    
    static func randomGraph<Algorithm: RandomGraphAlgorithm<Self>>(
        vertexCount: Int,
        using algorithm: Algorithm,
        visitor: Algorithm.Visitor?
    ) -> Self {
        var graph = Self.init()
        var rng = SystemRandomNumberGenerator()
        algorithm.appendRandomGraph(into: &graph, vertexCount: vertexCount, using: &rng, visitor: visitor)
        return graph
    }
}

// MARK: - Default Implementations

extension RandomGraphConstructible where VertexDescriptor: Hashable {
    /// Creates a random graph using Erdos-Renyi model as the default.
    /// This is the most commonly used random graph model with uniform edge probability.
    static func randomGraph(
        vertexCount: Int,
        edgeProbability: Double = 0.5
    ) -> Self {
        randomGraph(vertexCount: vertexCount, using: .erdosRenyi(edgeProbability: edgeProbability))
    }
    
    /// Creates a random graph using Barabasi-Albert model for scale-free networks.
    /// This generates graphs with power-law degree distribution.
    static func randomScaleFreeGraph(
        vertexCount: Int,
        averageDegree: Double = 2.0
    ) -> Self where Self: BidirectionalGraph {
        randomGraph(vertexCount: vertexCount, using: .barabasiAlbert(averageDegree: averageDegree))
    }
    
    /// Creates a random graph using Watts-Strogatz model for small-world networks.
    /// This generates graphs with high clustering and short path lengths.
    static func randomSmallWorldGraph(
        vertexCount: Int,
        averageDegree: Double = 4.0,
        rewiringProbability: Double = 0.1
    ) -> Self {
        randomGraph(vertexCount: vertexCount, using: .wattsStrogatz(averageDegree: averageDegree, rewiringProbability: rewiringProbability))
    }
}

extension MutableGraph where VertexDescriptor: Hashable {
    mutating func appendRandom<Algorithm: RandomGraphAlgorithm<Self>>(vertexCount: Int, using algorithm: Algorithm) {
        var rng = SystemRandomNumberGenerator()
        algorithm.appendRandomGraph(into: &self, vertexCount: vertexCount, using: &rng, visitor: nil)
    }

    mutating func appendRandom<Algorithm: RandomGraphAlgorithm<Self>, RNG: RandomNumberGenerator>(
        vertexCount: Int,
        using algorithm: Algorithm,
        generator: inout RNG
    ) {
        algorithm.appendRandomGraph(into: &self, vertexCount: vertexCount, using: &generator, visitor: nil)
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
        using generator: inout R,
        visitor: Algorithm.Visitor?
    ) {
        var g = fixedGenerator
        algorithm.appendRandomGraph(into: &graph, vertexCount: vertexCount, using: &g, visitor: visitor)
    }
}
