/// A protocol for random graph generation algorithms.
public protocol RandomGraphAlgorithm<Graph>: AlgorithmObserving {
    /// The graph type that this algorithm operates on.
    associatedtype Graph: MutableGraph where Graph.VertexDescriptor: Hashable
    /// The event type published by the algorithm.
    associatedtype Event

    /// Appends a random graph to an existing graph.
    ///
    /// - Parameters:
    ///   - graph: The graph to append to (modified in place)
    ///   - vertexCount: The number of vertices to add
    ///   - generator: The random number generator to use
    ///   - observation: An optional algorithm observation.
    func appendRandomGraph<RNG: RandomNumberGenerator>(
        into graph: inout Graph,
        vertexCount: Int,
        using generator: inout RNG,
        observation: AlgorithmObservation<Event>?
    )
}

extension ObservedAlgorithm: RandomGraphAlgorithm where Base: RandomGraphAlgorithm {
    @inlinable
    public func appendRandomGraph<RNG: RandomNumberGenerator>(
        into graph: inout Base.Graph,
        vertexCount: Int,
        using generator: inout RNG,
        observation: AlgorithmObservation<Base.Event>?
    ) {
        base.appendRandomGraph(into: &graph, vertexCount: vertexCount, using: &generator, observation: self.observation.followed(by: observation))
    }
}

extension RandomGraphAlgorithm {
    /// Creates a random graph algorithm with a specific generator.
    ///
    /// - Parameter generator: The random number generator to use
    /// - Returns: A random graph algorithm with the specified generator
    @inlinable
    public func withGenerator<RNG: RandomNumberGenerator>(_ generator: RNG) -> RandomGraphAlgorithmWithGenerator<Self, RNG> {
        RandomGraphAlgorithmWithGenerator(self, generator: generator)
    }
}

/// A protocol for graphs that can be constructed randomly.
public protocol RandomGraphConstructible: MutableGraph {
    /// Creates an empty graph.
    init()
}

extension RandomGraphConstructible where VertexDescriptor: Hashable {
    /// Creates a random graph using the specified algorithm.
    ///
    /// - Parameters:
    ///   - vertexCount: The number of vertices in the graph
    ///   - algorithm: The random graph algorithm to use
    /// - Returns: A randomly generated graph
    @inlinable
    public static func randomGraph<Algorithm: RandomGraphAlgorithm<Self>>(
        vertexCount: Int,
        using algorithm: Algorithm
    ) -> Self {
        var graph = Self()
        var rng = SystemRandomNumberGenerator()
        algorithm.appendRandomGraph(into: &graph, vertexCount: vertexCount, using: &rng, observation: nil)
        return graph
    }

    static func randomGraph<Algorithm: RandomGraphAlgorithm<Self>>(
        vertexCount: Int,
        using algorithm: Algorithm,
        observation: AlgorithmObservation<Algorithm.Event>?
    ) -> Self {
        var graph = Self()
        var rng = SystemRandomNumberGenerator()
        algorithm.appendRandomGraph(into: &graph, vertexCount: vertexCount, using: &rng, observation: observation)
        return graph
    }
}

// MARK: - Default Implementations

#if !GRAPHS_USES_TRAITS || GRAPHS_GENERATION
    extension RandomGraphConstructible where VertexDescriptor: Hashable {
        /// Creates a random graph using Erdos-Renyi model as the default.
        /// This is the most commonly used random graph model with uniform edge probability.
        public static func randomGraph(
            vertexCount: Int,
            edgeProbability: Double = 0.5
        ) -> Self {
            randomGraph(vertexCount: vertexCount, using: .erdosRenyi(edgeProbability: edgeProbability))
        }

        /// Creates a random graph using Barabasi-Albert model for scale-free networks.
        /// This generates graphs with power-law degree distribution.
        public static func randomScaleFreeGraph(
            vertexCount: Int,
            averageDegree: Double = 2.0
        ) -> Self where Self: BidirectionalGraph {
            randomGraph(vertexCount: vertexCount, using: .barabasiAlbert(averageDegree: averageDegree))
        }

        /// Creates a random graph using Watts-Strogatz model for small-world networks.
        /// This generates graphs with high clustering and short path lengths.
        public static func randomSmallWorldGraph(
            vertexCount: Int,
            averageDegree: Double = 4.0,
            rewiringProbability: Double = 0.1
        ) -> Self {
            randomGraph(vertexCount: vertexCount, using: .wattsStrogatz(averageDegree: averageDegree, rewiringProbability: rewiringProbability))
        }
    }
#endif

extension MutableGraph where VertexDescriptor: Hashable {
    mutating func appendRandom<Algorithm: RandomGraphAlgorithm<Self>>(vertexCount: Int, using algorithm: Algorithm) {
        var rng = SystemRandomNumberGenerator()
        algorithm.appendRandomGraph(into: &self, vertexCount: vertexCount, using: &rng, observation: nil)
    }

    mutating func appendRandom<Algorithm: RandomGraphAlgorithm<Self>, RNG: RandomNumberGenerator>(
        vertexCount: Int,
        using algorithm: Algorithm,
        generator: inout RNG
    ) {
        algorithm.appendRandomGraph(into: &self, vertexCount: vertexCount, using: &generator, observation: nil)
    }
}

// A wrapper that fixes a particular RNG to an algorithm.
public struct RandomGraphAlgorithmWithGenerator<Algorithm: RandomGraphAlgorithm, RNG: RandomNumberGenerator>: RandomGraphAlgorithm {
    public typealias Graph = Algorithm.Graph
    public typealias Event = Algorithm.Event

    @usableFromInline
    var algorithm: Algorithm
    @usableFromInline
    var fixedGenerator: RNG

    @usableFromInline
    init(_ algorithm: Algorithm, generator: RNG) {
        self.algorithm = algorithm
        self.fixedGenerator = generator
    }

    // Ignores the incoming RNG and uses the fixed one.
    @inlinable
    public func appendRandomGraph<R: RandomNumberGenerator>(
        into graph: inout Algorithm.Graph,
        vertexCount: Int,
        using generator: inout R,
        observation: AlgorithmObservation<Algorithm.Event>? = nil
    ) {
        var g = fixedGenerator
        algorithm.appendRandomGraph(into: &graph, vertexCount: vertexCount, using: &g, observation: observation)
    }
}
