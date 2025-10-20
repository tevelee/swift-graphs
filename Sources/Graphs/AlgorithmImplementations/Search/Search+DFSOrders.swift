extension SearchAlgorithm {
    /// Creates a depth-first search algorithm with a specific order.
    ///
    /// - Parameter order: The DFS order to use for traversal.
    /// - Returns: A DFS ordered search algorithm instance.
    @inlinable
    public static func dfs<Graph>(order: DFSOrder<Graph>) -> Self where Self == DFSOrderedSearch<Graph> {
        .init(order: order)
    }
}

/// A depth-first search algorithm with specific ordering for the SearchAlgorithm protocol.
///
/// This struct wraps the core DFS algorithm with a specific order to provide a
/// SearchAlgorithm interface, making it easy to use ordered DFS as a general search algorithm.
///
/// - Complexity: O(V + E) where V is the number of vertices and E is the number of edges
public struct DFSOrderedSearch<Graph: IncidenceGraph>: SearchAlgorithm where Graph.VertexDescriptor: Hashable {
    /// The DFS order to use for traversal.
    public let order: DFSOrder<Graph>
    
    /// Creates a new DFS ordered search algorithm.
    ///
    /// - Parameter order: The DFS order to use for traversal.
    @inlinable
    public init(order: DFSOrder<Graph>) {
        self.order = order
    }
    
    /// Performs a depth-first search with specific ordering from the source vertex.
    ///
    /// - Parameters:
    ///   - source: The vertex to start search from.
    ///   - graph: The graph to search in.
    ///   - visitor: An optional visitor to observe the search progress.
    /// - Returns: A sequence of vertices in the specified order.
    @inlinable
    public func search(
        from source: Graph.VertexDescriptor,
        in graph: Graph,
        visitor: DepthFirstSearch<Graph>.Visitor?
    ) -> AnySequence<Graph.VertexDescriptor> {
        let base = DepthFirstSearch(on: graph, from: source)
        return AnySequence {
            let buffer = SharedBuffer<Graph.VertexDescriptor>()
            var iterator = base.makeIterator(visitor: order.makeVisitor(graph, buffer).combined(with: visitor))
            return AnyIterator {
                if !buffer.elements.isEmpty {
                    return buffer.elements.removeFirst()
                }
                while iterator.next() != nil {
                    if !buffer.elements.isEmpty {
                        return buffer.elements.removeFirst()
                    }
                }
                return nil
            }
        }
    }
}
