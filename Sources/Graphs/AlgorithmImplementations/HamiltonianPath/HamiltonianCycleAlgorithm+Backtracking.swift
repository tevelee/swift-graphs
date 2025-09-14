extension HamiltonianCycleAlgorithm {
    static func backtracking<Graph>() -> Self where Self == BacktrackingHamiltonian<Graph> {
        .init()
    }
}

extension BacktrackingHamiltonian: HamiltonianCycleAlgorithm {
    func hamiltonianCycle(in graph: Graph) -> Path<Graph.VertexDescriptor, Graph.EdgeDescriptor>? {
        hamiltonianCycle(in: graph, visitor: nil)
    }
}
