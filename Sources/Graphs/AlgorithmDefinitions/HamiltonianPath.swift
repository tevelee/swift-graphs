extension IncidenceGraph where Self: VertexListGraph, VertexDescriptor: Hashable {
    /// Finds a Hamiltonian path using the specified algorithm.
    ///
    /// - Parameter algorithm: The Hamiltonian path algorithm to use
    /// - Returns: A Hamiltonian path if one exists, nil otherwise
    @inlinable
    public func hamiltonianPath(
        using algorithm: some HamiltonianPathAlgorithm<Self>
    ) -> Path<VertexDescriptor, EdgeDescriptor>? {
        algorithm.hamiltonianPath(in: self, visitor: nil)
    }
    
    /// Finds a Hamiltonian cycle using the specified algorithm.
    ///
    /// - Parameter algorithm: The Hamiltonian cycle algorithm to use
    /// - Returns: A Hamiltonian cycle if one exists, nil otherwise
    @inlinable
    public func hamiltonianCycle(
        using algorithm: some HamiltonianCycleAlgorithm<Self>
    ) -> Path<VertexDescriptor, EdgeDescriptor>? {
        algorithm.hamiltonianCycle(in: self, visitor: nil)
    }
    
    /// Finds a Hamiltonian path from a specific source using the specified algorithm.
    ///
    /// - Parameters:
    ///   - source: The starting vertex
    ///   - algorithm: The Hamiltonian path algorithm to use
    /// - Returns: A Hamiltonian path if one exists, nil otherwise
    @inlinable
    public func hamiltonianPath(
        from source: VertexDescriptor,
        using algorithm: some HamiltonianPathAlgorithm<Self>
    ) -> Path<VertexDescriptor, EdgeDescriptor>? {
        algorithm.hamiltonianPath(from: source, in: self, visitor: nil)
    }
    
    /// Finds a Hamiltonian path between two specific vertices using the specified algorithm.
    ///
    /// - Parameters:
    ///   - source: The starting vertex
    ///   - destination: The ending vertex
    ///   - algorithm: The Hamiltonian path algorithm to use
    /// - Returns: A Hamiltonian path if one exists, nil otherwise
    @inlinable
    public func hamiltonianPath(
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
    ///
    /// - Returns: A Hamiltonian path if one exists, nil otherwise
    @inlinable
    public func hamiltonianPath() -> Path<VertexDescriptor, EdgeDescriptor>? {
        hamiltonianPath(using: .backtracking())
    }
    
    /// Finds a Hamiltonian cycle using backtracking algorithm as the default.
    /// This is a general-purpose algorithm that works for most graphs.
    ///
    /// - Returns: A Hamiltonian cycle if one exists, nil otherwise
    @inlinable
    public func hamiltonianCycle() -> Path<VertexDescriptor, EdgeDescriptor>? {
        hamiltonianCycle(using: .backtracking())
    }
    
    /// Finds a Hamiltonian path from a specific source using backtracking algorithm as the default.
    ///
    /// - Parameter source: The starting vertex
    /// - Returns: A Hamiltonian path if one exists, nil otherwise
    @inlinable
    public func hamiltonianPath(from source: VertexDescriptor) -> Path<VertexDescriptor, EdgeDescriptor>? {
        hamiltonianPath(from: source, using: .backtracking())
    }
    
    /// Finds a Hamiltonian path between two specific vertices using backtracking algorithm as the default.
    func hamiltonianPath(from source: VertexDescriptor, to destination: VertexDescriptor) -> Path<VertexDescriptor, EdgeDescriptor>? {
        hamiltonianPath(from: source, to: destination, using: .backtracking())
    }
}

/// A protocol for Hamiltonian path algorithms.
public protocol HamiltonianPathAlgorithm<Graph> {
    /// The graph type that this algorithm operates on.
    associatedtype Graph: IncidenceGraph & VertexListGraph where Graph.VertexDescriptor: Hashable
    /// The visitor type for observing algorithm progress.
    associatedtype Visitor
    
    /// Finds a Hamiltonian path in the graph.
    ///
    /// - Parameters:
    ///   - graph: The graph to search in
    ///   - visitor: An optional visitor to observe the algorithm progress
    /// - Returns: A Hamiltonian path if one exists, nil otherwise
    @inlinable
    func hamiltonianPath(in graph: Graph, visitor: Visitor?) -> Path<Graph.VertexDescriptor, Graph.EdgeDescriptor>?
    
    /// Finds a Hamiltonian path starting from a specific vertex.
    ///
    /// - Parameters:
    ///   - source: The starting vertex
    ///   - graph: The graph to search in
    ///   - visitor: An optional visitor to observe the algorithm progress
    /// - Returns: A Hamiltonian path if one exists, nil otherwise
    @inlinable
    func hamiltonianPath(from source: Graph.VertexDescriptor, in graph: Graph, visitor: Visitor?) -> Path<Graph.VertexDescriptor, Graph.EdgeDescriptor>?
    
    /// Finds a Hamiltonian path between two specific vertices.
    ///
    /// - Parameters:
    ///   - source: The starting vertex
    ///   - destination: The ending vertex
    ///   - graph: The graph to search in
    ///   - visitor: An optional visitor to observe the algorithm progress
    /// - Returns: A Hamiltonian path if one exists, nil otherwise
    @inlinable
    func hamiltonianPath(from source: Graph.VertexDescriptor, to destination: Graph.VertexDescriptor, in graph: Graph, visitor: Visitor?) -> Path<Graph.VertexDescriptor, Graph.EdgeDescriptor>?
}

/// A protocol for Hamiltonian cycle algorithms.
public protocol HamiltonianCycleAlgorithm<Graph> {
    /// The graph type that this algorithm operates on.
    associatedtype Graph: IncidenceGraph & VertexListGraph where Graph.VertexDescriptor: Hashable
    /// The visitor type for observing algorithm progress.
    associatedtype Visitor
    
    /// Finds a Hamiltonian cycle in the graph.
    ///
    /// - Parameters:
    ///   - graph: The graph to search in
    ///   - visitor: An optional visitor to observe the algorithm progress
    /// - Returns: A Hamiltonian cycle if one exists, nil otherwise
    @inlinable
    func hamiltonianCycle(in graph: Graph, visitor: Visitor?) -> Path<Graph.VertexDescriptor, Graph.EdgeDescriptor>?
}

extension VisitorWrapper: HamiltonianPathAlgorithm where Base: HamiltonianPathAlgorithm, Base.Visitor == Visitor, Visitor: Composable, Visitor.Other == Visitor {
    public typealias Graph = Base.Graph
    
    @inlinable
    public func hamiltonianPath(in graph: Base.Graph, visitor: Base.Visitor?) -> Path<Base.Graph.VertexDescriptor, Base.Graph.EdgeDescriptor>? {
        base.hamiltonianPath(in: graph, visitor: self.visitor.combined(with: visitor))
    }
    
    @inlinable
    public func hamiltonianPath(from source: Base.Graph.VertexDescriptor, in graph: Base.Graph, visitor: Base.Visitor?) -> Path<Base.Graph.VertexDescriptor, Base.Graph.EdgeDescriptor>? {
        base.hamiltonianPath(from: source, in: graph, visitor: self.visitor.combined(with: visitor))
    }
    
    @inlinable
    public func hamiltonianPath(from source: Base.Graph.VertexDescriptor, to destination: Base.Graph.VertexDescriptor, in graph: Base.Graph, visitor: Base.Visitor?) -> Path<Base.Graph.VertexDescriptor, Base.Graph.EdgeDescriptor>? {
        base.hamiltonianPath(from: source, to: destination, in: graph, visitor: self.visitor.combined(with: visitor))
    }
}

extension VisitorWrapper: HamiltonianCycleAlgorithm where Base: HamiltonianCycleAlgorithm, Base.Visitor == Visitor, Visitor: Composable, Visitor.Other == Visitor {
    public typealias Graph = Base.Graph
    
    @inlinable
    public func hamiltonianCycle(in graph: Base.Graph, visitor: Base.Visitor?) -> Path<Base.Graph.VertexDescriptor, Base.Graph.EdgeDescriptor>? {
        base.hamiltonianCycle(in: graph, visitor: self.visitor.combined(with: visitor))
    }
}
