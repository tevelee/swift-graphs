/// A protocol for algorithms that find all paths between two vertices.
public protocol AllPathsAlgorithm<Graph> {
    /// The type of graph this algorithm operates on.
    associatedtype Graph: IncidenceGraph
    
    /// The type of sequence returned by the algorithm.
    associatedtype PathSequence: Sequence<Path<Graph.VertexDescriptor, Graph.EdgeDescriptor>>
    
    /// Finds all paths between two vertices.
    ///
    /// - Parameters:
    ///   - source: The starting vertex
    ///   - destination: The target vertex
    ///   - graph: The graph to search
    /// - Returns: A sequence of all paths from source to destination
    func allPaths(
        from source: Graph.VertexDescriptor,
        to destination: Graph.VertexDescriptor,
        in graph: Graph
    ) -> PathSequence
}

extension IncidenceGraph where VertexDescriptor: Equatable {
    /// Finds all paths between two vertices using the specified algorithm.
    ///
    /// - Parameters:
    ///   - source: The starting vertex
    ///   - destination: The target vertex
    ///   - algorithm: The all paths algorithm to use
    /// - Returns: A sequence of all paths from source to destination
    @inlinable
    public func allPaths<Algorithm: AllPathsAlgorithm>(
        from source: VertexDescriptor,
        to destination: VertexDescriptor,
        using algorithm: Algorithm
    ) -> Algorithm.PathSequence where Algorithm.Graph == Self {
        algorithm.allPaths(from: source, to: destination, in: self)
    }
}

extension IncidenceGraph where VertexDescriptor: Hashable {
    /// Finds all paths between two vertices using Depth-First Search as the default.
    ///
    /// - Parameters:
    ///   - source: The starting vertex
    ///   - destination: The target vertex
    /// - Returns: A sequence of all paths from source to destination
    @inlinable
    public func allPaths(
        from source: VertexDescriptor,
        to destination: VertexDescriptor
    ) -> DFSAllPaths<Self> {
        allPaths(from: source, to: destination, using: .dfs())
    }
}
