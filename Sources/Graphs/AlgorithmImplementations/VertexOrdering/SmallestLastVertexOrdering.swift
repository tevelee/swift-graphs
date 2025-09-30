import Foundation

/// Smallest Last Vertex Ordering algorithm.
/// 
/// This algorithm orders vertices by repeatedly removing the vertex with the smallest degree
/// and placing it last in the sequence. This ordering is particularly effective for graph
/// coloring algorithms as it tends to reduce the number of colors needed.
///
/// - Complexity: O(V²) where V is the number of vertices
public struct SmallestLastVertexOrderingAlgorithm<
    Graph: IncidenceGraph & VertexListGraph & BidirectionalGraph
> where Graph.VertexDescriptor: Hashable {
    
    /// A visitor that can be used to observe the Smallest Last Vertex algorithm progress.
    public struct Visitor {
        /// Called when examining a vertex.
        public var examineVertex: ((Graph.VertexDescriptor) -> Void)?
        /// Called when removing a vertex.
        public var removeVertex: ((Graph.VertexDescriptor, Int) -> Void)?
        /// Called when updating a vertex's degree.
        public var updateDegree: ((Graph.VertexDescriptor, Int, Int) -> Void)?
        
        /// Creates a new visitor.
        @inlinable
        public init(
            examineVertex: ((Graph.VertexDescriptor) -> Void)? = nil,
            removeVertex: ((Graph.VertexDescriptor, Int) -> Void)? = nil,
            updateDegree: ((Graph.VertexDescriptor, Int, Int) -> Void)? = nil
        ) {
            self.examineVertex = examineVertex
            self.removeVertex = removeVertex
            self.updateDegree = updateDegree
        }
    }
    
    /// Creates a new Smallest Last Vertex Ordering algorithm.
    @inlinable
    public init() {}
    
    /// Orders vertices using the Smallest Last Vertex algorithm.
    ///
    /// - Parameters:
    ///   - graph: The graph to order vertices for
    ///   - visitor: An optional visitor to observe the algorithm progress
    /// - Returns: An array of vertex descriptors in the computed order
    @inlinable
    public func orderVertices(in graph: Graph, visitor: Visitor? = nil) -> [Graph.VertexDescriptor] {
        var remainingVertices = Set(graph.vertices())
        var degrees: [Graph.VertexDescriptor: Int] = [:]
        var ordering: [Graph.VertexDescriptor] = []

        // Initialize degrees and create deterministic vertex ordering
        let vertexList = graph.vertices()
        for vertex in vertexList {
            degrees[vertex] = graph.degree(of: vertex)
        }

        // Process vertices in reverse order (smallest degree first)
        while !remainingVertices.isEmpty {
            // Find vertex with minimum degree (use deterministic tie-breaking)
            let minDegree = degrees.values.min() ?? 0
            let minDegreeVertices = vertexList.filter { remainingVertices.contains($0) && degrees[$0] == minDegree }

            // If there are ties, choose the first one in vertex list order (deterministic)
            let vertexToRemove = minDegreeVertices.first!

            visitor?.examineVertex?(vertexToRemove)
            visitor?.removeVertex?(vertexToRemove, minDegree)

            // Remove vertex from remaining set
            remainingVertices.remove(vertexToRemove)
            degrees.removeValue(forKey: vertexToRemove)

            // Add to ordering (we'll reverse at the end)
            ordering.append(vertexToRemove)

            // Update degrees of neighbors
            for neighbor in graph.successors(of: vertexToRemove) {
                if remainingVertices.contains(neighbor) {
                    let oldDegree = degrees[neighbor] ?? 0
                    let newDegree = oldDegree - 1
                    degrees[neighbor] = newDegree
                    visitor?.updateDegree?(neighbor, oldDegree, newDegree)
                }
            }
        }

        // Reverse to get smallest-last ordering
        return ordering.reversed()
    }
}

extension SmallestLastVertexOrderingAlgorithm: VisitorSupporting {}
