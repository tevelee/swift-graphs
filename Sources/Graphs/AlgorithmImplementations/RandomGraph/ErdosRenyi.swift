import Foundation

/// Erdos-Renyi random graph generation algorithm.
///
/// This algorithm generates random graphs where each possible edge is included
/// with a fixed probability p, independently of other edges.
///
/// - Complexity: O(V²) where V is the number of vertices
public struct ErdosRenyi<
    Graph: MutableGraph
> where Graph.VertexDescriptor: Hashable {
    /// The vertex type of the graph.
    public typealias Vertex = Graph.VertexDescriptor
    
    /// A visitor that can be used to observe the Erdos-Renyi algorithm progress.
    public struct Visitor {
        /// Called when adding a vertex.
        public var addVertex: ((Vertex) -> Void)?
        /// Called when adding an edge.
        public var addEdge: ((Vertex, Vertex) -> Void)?
        /// Called when skipping an edge.
        public var skipEdge: ((Vertex, Vertex, String) -> Void)?
        /// Called when examining a vertex pair.
        public var examineVertexPair: ((Vertex, Vertex) -> Void)?
        
        /// Creates a new visitor.
        @inlinable
        public init(
            addVertex: ((Vertex) -> Void)? = nil,
            addEdge: ((Vertex, Vertex) -> Void)? = nil,
            skipEdge: ((Vertex, Vertex, String) -> Void)? = nil,
            examineVertexPair: ((Vertex, Vertex) -> Void)? = nil
        ) {
            self.addVertex = addVertex
            self.addEdge = addEdge
            self.skipEdge = skipEdge
            self.examineVertexPair = examineVertexPair
        }
    }
    
    /// The result of the Erdos-Renyi algorithm.
    @usableFromInline
    struct Result {
        @usableFromInline
        let graph: Graph
        @usableFromInline
        let vertices: [Vertex]
        @usableFromInline
        let edges: [(Vertex, Vertex)]
        @usableFromInline
        let edgeProbability: Double
    }
    
    /// The probability of including each possible edge.
    @usableFromInline
    let edgeProbability: Double
    
    /// Creates a new Erdos-Renyi algorithm.
    ///
    /// - Parameter edgeProbability: The probability of including each possible edge (0.0 to 1.0)
    @inlinable
    public init(edgeProbability: Double) {
        self.edgeProbability = edgeProbability
    }
    
    /// Appends a random Erdos-Renyi graph to an existing graph.
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
        var newVertices: [Vertex] = []
        for _ in 0..<vertexCount {
            let v = graph.addVertex()
            visitor?.addVertex?(v)
            newVertices.append(v)
        }
        
        // Add edges with probability p among the newly added vertices
        for i in 0..<newVertices.count {
            for j in (i + 1)..<newVertices.count {
                visitor?.examineVertexPair?(newVertices[i], newVertices[j])
                if Double.random(in: 0...1, using: &generator) < edgeProbability {
                    graph.addEdge(from: newVertices[i], to: newVertices[j])
                    visitor?.addEdge?(newVertices[i], newVertices[j])
                } else {
                    visitor?.skipEdge?(newVertices[i], newVertices[j], "Probability check failed")
                }
            }
        }
    }
}

extension ErdosRenyi: VisitorSupporting {}
