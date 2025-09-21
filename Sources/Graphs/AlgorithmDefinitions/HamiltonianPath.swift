extension IncidenceGraph where Self: VertexListGraph, VertexDescriptor: Hashable {
    func hamiltonianPath(
        using algorithm: some HamiltonianPathAlgorithm<Self>
    ) -> Path<VertexDescriptor, EdgeDescriptor>? {
        algorithm.hamiltonianPath(in: self, visitor: nil)
    }
    
    func hamiltonianCycle(
        using algorithm: some HamiltonianCycleAlgorithm<Self>
    ) -> Path<VertexDescriptor, EdgeDescriptor>? {
        algorithm.hamiltonianCycle(in: self, visitor: nil)
    }
    
    func hamiltonianPath(
        from source: VertexDescriptor,
        using algorithm: some HamiltonianPathAlgorithm<Self>
    ) -> Path<VertexDescriptor, EdgeDescriptor>? {
        algorithm.hamiltonianPath(from: source, in: self, visitor: nil)
    }
    
    func hamiltonianPath(
        from source: VertexDescriptor,
        to destination: VertexDescriptor,
        using algorithm: some HamiltonianPathAlgorithm<Self>
    ) -> Path<VertexDescriptor, EdgeDescriptor>? {
        algorithm.hamiltonianPath(from: source, to: destination, in: self, visitor: nil)
    }
}

// MARK: - Default Implementations

extension IncidenceGraph where Self: VertexListGraph, VertexDescriptor: Hashable {
    /// Finds a Hamiltonian path using backtracking algorithm as the default.
    /// This is a general-purpose algorithm that works for most graphs.
    func hamiltonianPath() -> Path<VertexDescriptor, EdgeDescriptor>? {
        hamiltonianPath(using: .backtracking())
    }
    
    /// Finds a Hamiltonian cycle using backtracking algorithm as the default.
    /// This is a general-purpose algorithm that works for most graphs.
    func hamiltonianCycle() -> Path<VertexDescriptor, EdgeDescriptor>? {
        hamiltonianCycle(using: .backtracking())
    }
    
    /// Finds a Hamiltonian path from a specific source using backtracking algorithm as the default.
    func hamiltonianPath(from source: VertexDescriptor) -> Path<VertexDescriptor, EdgeDescriptor>? {
        hamiltonianPath(from: source, using: .backtracking())
    }
    
    /// Finds a Hamiltonian path between two specific vertices using backtracking algorithm as the default.
    func hamiltonianPath(from source: VertexDescriptor, to destination: VertexDescriptor) -> Path<VertexDescriptor, EdgeDescriptor>? {
        hamiltonianPath(from: source, to: destination, using: .backtracking())
    }
}

protocol HamiltonianPathAlgorithm<Graph> {
    associatedtype Graph: IncidenceGraph & VertexListGraph where Graph.VertexDescriptor: Hashable
    associatedtype Visitor
    
    func hamiltonianPath(in graph: Graph, visitor: Visitor?) -> Path<Graph.VertexDescriptor, Graph.EdgeDescriptor>?
    func hamiltonianPath(from source: Graph.VertexDescriptor, in graph: Graph, visitor: Visitor?) -> Path<Graph.VertexDescriptor, Graph.EdgeDescriptor>?
    func hamiltonianPath(from source: Graph.VertexDescriptor, to destination: Graph.VertexDescriptor, in graph: Graph, visitor: Visitor?) -> Path<Graph.VertexDescriptor, Graph.EdgeDescriptor>?
}

protocol HamiltonianCycleAlgorithm<Graph> {
    associatedtype Graph: IncidenceGraph & VertexListGraph where Graph.VertexDescriptor: Hashable
    associatedtype Visitor
    
    func hamiltonianCycle(in graph: Graph, visitor: Visitor?) -> Path<Graph.VertexDescriptor, Graph.EdgeDescriptor>?
}

extension VisitorWrapper: HamiltonianPathAlgorithm where Base: HamiltonianPathAlgorithm, Base.Visitor == Visitor, Visitor: Composable, Visitor.Other == Visitor {
    typealias Graph = Base.Graph
    
    func hamiltonianPath(in graph: Base.Graph, visitor: Base.Visitor?) -> Path<Base.Graph.VertexDescriptor, Base.Graph.EdgeDescriptor>? {
        base.hamiltonianPath(in: graph, visitor: self.visitor.combined(with: visitor))
    }
    
    func hamiltonianPath(from source: Base.Graph.VertexDescriptor, in graph: Base.Graph, visitor: Base.Visitor?) -> Path<Base.Graph.VertexDescriptor, Base.Graph.EdgeDescriptor>? {
        base.hamiltonianPath(from: source, in: graph, visitor: self.visitor.combined(with: visitor))
    }
    
    func hamiltonianPath(from source: Base.Graph.VertexDescriptor, to destination: Base.Graph.VertexDescriptor, in graph: Base.Graph, visitor: Base.Visitor?) -> Path<Base.Graph.VertexDescriptor, Base.Graph.EdgeDescriptor>? {
        base.hamiltonianPath(from: source, to: destination, in: graph, visitor: self.visitor.combined(with: visitor))
    }
}

extension VisitorWrapper: HamiltonianCycleAlgorithm where Base: HamiltonianCycleAlgorithm, Base.Visitor == Visitor, Visitor: Composable, Visitor.Other == Visitor {
    typealias Graph = Base.Graph
    
    func hamiltonianCycle(in graph: Base.Graph, visitor: Base.Visitor?) -> Path<Base.Graph.VertexDescriptor, Base.Graph.EdgeDescriptor>? {
        base.hamiltonianCycle(in: graph, visitor: self.visitor.combined(with: visitor))
    }
}
