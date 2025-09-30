extension HamiltonianPathAlgorithm {
    /// Creates a heuristic Hamiltonian path algorithm.
    ///
    /// - Parameter heuristic: The heuristic strategy to use (default: .degreeBased)
    /// - Returns: A new heuristic Hamiltonian path algorithm
    @inlinable
    public static func heuristic<Graph>(_ heuristic: HeuristicHamiltonian<Graph>.Heuristic = .degreeBased) -> Self where Self == HeuristicHamiltonian<Graph> {
        .init(heuristic: heuristic)
    }
}

extension HeuristicHamiltonian: HamiltonianPathAlgorithm {
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