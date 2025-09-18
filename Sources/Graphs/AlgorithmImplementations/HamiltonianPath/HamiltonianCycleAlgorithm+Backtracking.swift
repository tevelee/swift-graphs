extension HamiltonianCycleAlgorithm {
    static func backtracking<Graph>() -> Self where Self == BacktrackingHamiltonian<Graph> {
        .init()
    }
}

extension BacktrackingHamiltonian: HamiltonianCycleAlgorithm {}
