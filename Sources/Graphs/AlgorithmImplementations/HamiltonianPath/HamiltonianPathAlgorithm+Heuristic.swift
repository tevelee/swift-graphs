extension HamiltonianPathAlgorithm {
    static func heuristic<Graph>(_ heuristic: HeuristicHamiltonian<Graph>.Heuristic = .degreeBased) -> Self where Self == HeuristicHamiltonian<Graph> {
        .init(heuristic: heuristic)
    }
}

extension HeuristicHamiltonian: HamiltonianPathAlgorithm {
    func hamiltonianPath(in graph: Graph) -> Path<Graph.VertexDescriptor, Graph.EdgeDescriptor>? {
        hamiltonianPath(in: graph, visitor: nil)
    }
    
    func hamiltonianPath(from source: Graph.VertexDescriptor, in graph: Graph) -> Path<Graph.VertexDescriptor, Graph.EdgeDescriptor>? {
        hamiltonianPath(from: source, in: graph, visitor: nil)
    }
    
    func hamiltonianPath(from source: Graph.VertexDescriptor, to destination: Graph.VertexDescriptor, in graph: Graph) -> Path<Graph.VertexDescriptor, Graph.EdgeDescriptor>? {
        hamiltonianPath(from: source, to: destination, in: graph, visitor: nil)
    }
}