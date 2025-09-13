extension HamiltonianPathAlgorithm {
    static func heuristic<Graph>(_ heuristic: HeuristicHamiltonian<Graph>.Heuristic = .degreeBased) -> Self where Self == HeuristicHamiltonian<Graph> {
        .init(heuristic: heuristic)
    }
}