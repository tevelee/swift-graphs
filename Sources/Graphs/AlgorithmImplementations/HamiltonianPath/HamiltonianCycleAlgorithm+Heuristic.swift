extension HamiltonianCycleAlgorithm {
    static func heuristic<Graph>(_ heuristic: HeuristicHamiltonian<Graph>.Heuristic = .degreeBased) -> Self where Self == HeuristicHamiltonian<Graph> {
        .init(heuristic: heuristic)
    }
}

extension HeuristicHamiltonian: HamiltonianCycleAlgorithm {
    func hamiltonianCycle(in graph: Graph) -> Path<Graph.VertexDescriptor, Graph.EdgeDescriptor>? {
        hamiltonianCycle(in: graph, visitor: nil)
    }
}
