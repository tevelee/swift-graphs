import Foundation

// MARK: - Convenience Extensions for Hamiltonian Properties

// MARK: - Algorithm Factory Extensions

extension IncidenceGraph where Self: VertexListGraph & BidirectionalGraph, VertexDescriptor: Hashable {
    /// Creates a standard Dirac property algorithm
    func diracAlgorithm() -> StandardDiracPropertyAlgorithm<Self> {
        StandardDiracPropertyAlgorithm<Self>()
    }
    
    /// Creates a standard Ore property algorithm
    func oreAlgorithm() -> StandardOrePropertyAlgorithm<Self> {
        StandardOrePropertyAlgorithm<Self>()
    }
}
