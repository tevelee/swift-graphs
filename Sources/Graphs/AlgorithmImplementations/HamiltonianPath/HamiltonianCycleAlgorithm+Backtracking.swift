extension HamiltonianCycleAlgorithm {
    /// Creates a backtracking Hamiltonian cycle algorithm.
    ///
    /// - Returns: A new backtracking Hamiltonian cycle algorithm
    @inlinable
    public static func backtracking<Graph>() -> Self where Self == BacktrackingHamiltonian<Graph> {
        .init()
    }
}

extension BacktrackingHamiltonian: HamiltonianCycleAlgorithm {}
