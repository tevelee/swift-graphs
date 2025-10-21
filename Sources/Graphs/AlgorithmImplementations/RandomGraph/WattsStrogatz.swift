/// Watts-Strogatz random graph generation algorithm.
///
/// This algorithm generates small-world networks by starting with a regular
/// ring lattice and randomly rewiring edges with a given probability.
///
/// - Complexity: O(V * k) where V is the number of vertices and k is the average degree
public struct WattsStrogatz<
    Graph: MutableGraph
> where Graph.VertexDescriptor: Hashable {
    /// The vertex type of the graph.
    public typealias Vertex = Graph.VertexDescriptor
    
    /// A visitor that can be used to observe the Watts-Strogatz algorithm progress.
    public struct Visitor {
        /// Called when adding a vertex.
        public var addVertex: ((Vertex) -> Void)?
        /// Called when adding an edge.
        public var addEdge: ((Vertex, Vertex) -> Void)?
        /// Called when rewiring an edge.
        public var rewireEdge: ((Vertex, Vertex, Vertex) -> Void)?
        /// Called when skipping rewiring.
        public var skipRewiring: ((Vertex, Vertex, String) -> Void)?
        /// Called when creating ring lattice edges.
        public var createRingLattice: ((Vertex, Vertex) -> Void)?
        
        /// Creates a new visitor.
        @inlinable
        public init(
            addVertex: ((Vertex) -> Void)? = nil,
            addEdge: ((Vertex, Vertex) -> Void)? = nil,
            rewireEdge: ((Vertex, Vertex, Vertex) -> Void)? = nil,
            skipRewiring: ((Vertex, Vertex, String) -> Void)? = nil,
            createRingLattice: ((Vertex, Vertex) -> Void)? = nil
        ) {
            self.addVertex = addVertex
            self.addEdge = addEdge
            self.rewireEdge = rewireEdge
            self.skipRewiring = skipRewiring
            self.createRingLattice = createRingLattice
        }
    }
    
    /// The result of the Watts-Strogatz algorithm.
    @usableFromInline
    struct Result {
        @usableFromInline
        let graph: Graph
        @usableFromInline
        let vertices: [Vertex]
        @usableFromInline
        let initialEdges: [(Vertex, Vertex)]
        @usableFromInline
        let rewiredEdges: [(Vertex, Vertex)]
        @usableFromInline
        let rewiringProbability: Double
    }
    
    /// The target average degree for the generated graph.
    @usableFromInline
    let averageDegree: Double
    /// The probability of rewiring each edge.
    @usableFromInline
    let rewiringProbability: Double
    
    /// Creates a new Watts-Strogatz algorithm.
    ///
    /// - Parameters:
    ///   - averageDegree: The target average degree for the generated graph
    ///   - rewiringProbability: The probability of rewiring each edge (0.0 to 1.0)
    @inlinable
    public init(averageDegree: Double, rewiringProbability: Double) {
        self.averageDegree = averageDegree
        self.rewiringProbability = rewiringProbability
    }
    
    /// Appends a random Watts-Strogatz graph to an existing graph.
    ///
    /// - Parameters:
    ///   - graph: The graph to append to (modified in place)
    ///   - vertexCount: The number of vertices to add
    ///   - generator: The random number generator to use
    ///   - visitor: An optional visitor to observe the algorithm progress
    @inlinable
    public func appendRandomGraph<RNG: RandomNumberGenerator>(
        into graph: inout Graph,
        vertexCount: Int,
        using generator: inout RNG,
        visitor: Visitor? = nil
    ) {
        guard vertexCount > 0 else { return }
        
        // Add vertices
        var vertices: [Vertex] = []
        for _ in 0..<vertexCount {
            let vertex = graph.addVertex()
            visitor?.addVertex?(vertex)
            vertices.append(vertex)
        }
        
        // Create initial regular ring lattice
        let k = Int(averageDegree) / 2
        var initialEdges: [(Vertex, Vertex)] = []
        for i in 0..<vertexCount {
            for j in 1...max(0, k) {
                let targetIndex = (i + j) % vertexCount
                let source = vertices[i]
                let target = vertices[targetIndex]
                graph.addEdge(from: source, to: target)
                visitor?.createRingLattice?(source, target)
                initialEdges.append((source, target))
            }
        }
        
        // Rewire edges with probability p
        for edge in initialEdges {
            if Double.random(in: 0...1, using: &generator) < rewiringProbability {
                let source = edge.0
                if let randomTarget = vertices.randomElement(using: &generator), randomTarget != source {
                    graph.addEdge(from: source, to: randomTarget)
                    visitor?.rewireEdge?(source, edge.1, randomTarget)
                } else {
                    visitor?.skipRewiring?(source, edge.1, "Self-loop avoided or no target")
                }
            } else {
                visitor?.skipRewiring?(edge.0, edge.1, "Probability check failed")
            }
        }
    }
}

extension WattsStrogatz: VisitorSupporting {}
