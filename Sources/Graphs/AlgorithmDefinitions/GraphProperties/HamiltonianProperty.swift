import Foundation

extension IncidenceGraph where Self: VertexListGraph & BidirectionalGraph, VertexDescriptor: Hashable {
    /// Checks if the graph has a Hamiltonian cycle using a hybrid approach:
    /// 1. First tries quick theorem checks (Dirac/Ore)
    /// 2. Falls back to more expensive algorithms if theorems don't apply
    func hasHamiltonianCycle(
        using diracAlgorithm: some DiracPropertyAlgorithm<Self>,
        oreAlgorithm: some OrePropertyAlgorithm<Self>,
        cycleAlgorithm: some HamiltonianCycleAlgorithm<Self>
    ) -> Bool {
        // First try quick theorem checks
        if satisfiesDirac(using: diracAlgorithm) || satisfiesOre(using: oreAlgorithm) {
            return true
        }
        
        // Fall back to more expensive algorithms
        return cycleAlgorithm.hamiltonianCycle(in: self, visitor: nil) != nil
    }
    
    /// Convenience method using standard algorithms
    func hasHamiltonianCycle() -> Bool {
        hasHamiltonianCycle(
            using: StandardDiracPropertyAlgorithm<Self>(),
            oreAlgorithm: StandardOrePropertyAlgorithm<Self>(),
            cycleAlgorithm: .backtracking()
        )
    }
}

extension IncidenceGraph where Self: VertexListGraph & BidirectionalGraph, VertexDescriptor: Hashable {
    /// Checks if the graph has a Hamiltonian path using a hybrid approach:
    /// 1. First tries quick theorem checks (Dirac/Ore) - if satisfied, cycle exists, so path exists
    /// 2. Falls back to more expensive algorithms if theorems don't apply
    func hasHamiltonianPath(
        using diracAlgorithm: some DiracPropertyAlgorithm<Self>,
        oreAlgorithm: some OrePropertyAlgorithm<Self>,
        pathAlgorithm: some HamiltonianPathAlgorithm<Self>
    ) -> Bool {
        // First try quick theorem checks - if theorems are satisfied, we have a cycle, so we have a path
        if satisfiesDirac(using: diracAlgorithm) || satisfiesOre(using: oreAlgorithm) {
            return true
        }
        
        // Fall back to more expensive algorithms
        return pathAlgorithm.hamiltonianPath(in: self, visitor: nil) != nil
    }
    
    /// Convenience method using standard algorithms
    func hasHamiltonianPath() -> Bool {
        hasHamiltonianPath(
            using: StandardDiracPropertyAlgorithm<Self>(),
            oreAlgorithm: StandardOrePropertyAlgorithm<Self>(),
            pathAlgorithm: .backtracking()
        )
    }
}

extension IncidenceGraph where Self: VertexListGraph & BidirectionalGraph, VertexDescriptor: Hashable {
    func satisfiesDirac(
        using algorithm: some DiracPropertyAlgorithm<Self>
    ) -> Bool {
        algorithm.satisfiesDirac(in: self, visitor: nil)
    }
    
    func satisfiesOre(
        using algorithm: some OrePropertyAlgorithm<Self>
    ) -> Bool {
        algorithm.satisfiesOre(in: self, visitor: nil)
    }
}

// MARK: - Default Implementations

extension IncidenceGraph where Self: VertexListGraph & BidirectionalGraph, VertexDescriptor: Hashable {
    /// Checks if the graph satisfies Dirac's theorem using standard algorithm as the default.
    /// This is the most commonly used algorithm for checking Dirac's condition.
    func satisfiesDirac() -> Bool {
        satisfiesDirac(using: .standard())
    }
    
    /// Checks if the graph satisfies Ore's theorem using standard algorithm as the default.
    /// This is the most commonly used algorithm for checking Ore's condition.
    func satisfiesOre() -> Bool {
        satisfiesOre(using: .standard())
    }
}

protocol DiracPropertyAlgorithm<Graph> {
    associatedtype Graph: IncidenceGraph & BidirectionalGraph where Graph.VertexDescriptor: Hashable
    associatedtype Visitor
    
    func satisfiesDirac(
        in graph: Graph,
        visitor: Visitor?
    ) -> Bool
}

protocol OrePropertyAlgorithm<Graph> {
    associatedtype Graph: IncidenceGraph & BidirectionalGraph where Graph.VertexDescriptor: Hashable
    associatedtype Visitor
    
    func satisfiesOre(
        in graph: Graph,
        visitor: Visitor?
    ) -> Bool
}

extension VisitorWrapper: DiracPropertyAlgorithm where Base: DiracPropertyAlgorithm, Base.Visitor == Visitor, Visitor: Composable, Visitor.Other == Visitor {
    func satisfiesDirac(in graph: Base.Graph, visitor: Base.Visitor?) -> Bool {
        base.satisfiesDirac(in: graph, visitor: self.visitor.combined(with: visitor))
    }
}

extension VisitorWrapper: OrePropertyAlgorithm where Base: OrePropertyAlgorithm, Base.Visitor == Visitor, Visitor: Composable, Visitor.Other == Visitor {
    func satisfiesOre(in graph: Base.Graph, visitor: Base.Visitor?) -> Bool {
        base.satisfiesOre(in: graph, visitor: self.visitor.combined(with: visitor))
    }
}
