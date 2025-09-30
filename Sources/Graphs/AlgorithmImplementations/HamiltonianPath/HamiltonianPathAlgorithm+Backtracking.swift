extension HamiltonianPathAlgorithm {
    /// Creates a backtracking Hamiltonian path algorithm.
    ///
    /// - Returns: A new backtracking Hamiltonian path algorithm
    @inlinable
    public static func backtracking<Graph>() -> Self where Self == BacktrackingHamiltonian<Graph> {
        .init()
    }
}

extension BacktrackingHamiltonian: HamiltonianPathAlgorithm {
    @inlinable
    public func hamiltonianPath(in graph: Graph) -> Path<Graph.VertexDescriptor, Graph.EdgeDescriptor>? {
        hamiltonianPath(in: graph, visitor: nil)
    }
    
    @inlinable
    public func hamiltonianPath(from source: Graph.VertexDescriptor, in graph: Graph) -> Path<Graph.VertexDescriptor, Graph.EdgeDescriptor>? {
        hamiltonianPath(from: source, in: graph, visitor: nil)
    }
    
    @inlinable
    public func hamiltonianPath(from source: Graph.VertexDescriptor, to destination: Graph.VertexDescriptor, in graph: Graph) -> Path<Graph.VertexDescriptor, Graph.EdgeDescriptor>? {
        hamiltonianPath(from: source, to: destination, in: graph, visitor: nil)
    }
}