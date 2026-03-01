#if !GRAPHS_USES_TRAITS || GRAPHS_ADVANCED
extension HamiltonianCycleAlgorithm {
    /// Creates a heuristic Hamiltonian cycle algorithm.
    ///
    /// - Parameter heuristic: The heuristic strategy to use (default: .degreeBased)
    /// - Returns: A new heuristic Hamiltonian cycle algorithm
    @inlinable
    public static func heuristic<Graph>(_ heuristic: HeuristicHamiltonian<Graph>.Heuristic = .degreeBased) -> Self where Self == HeuristicHamiltonian<Graph> {
        .init(heuristic: heuristic)
    }
}

extension HeuristicHamiltonian: HamiltonianCycleAlgorithm {
    @inlinable
    public func hamiltonianCycle(in graph: Graph) -> Path<Graph.VertexDescriptor, Graph.EdgeDescriptor>? {
        hamiltonianCycle(in: graph, visitor: nil)
    }
}
#endif
