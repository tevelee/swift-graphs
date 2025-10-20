extension BidirectionalGraph where Self: VertexListGraph, VertexDescriptor: Hashable {
    /// Finds an Eulerian path using the specified algorithm.
    ///
    /// - Parameter algorithm: The algorithm to use for finding the path.
    /// - Returns: An Eulerian path, if one exists.
    @inlinable
    public func eulerianPath(
        using algorithm: some EulerianPathAlgorithm<Self>
    ) -> Path<VertexDescriptor, EdgeDescriptor>? {
        algorithm.eulerianPath(in: self, visitor: nil)
    }
    
    /// Finds an Eulerian cycle using the specified algorithm.
    ///
    /// - Parameter algorithm: The algorithm to use for finding the cycle.
    /// - Returns: An Eulerian cycle, if one exists.
    @inlinable
    public func eulerianCycle(
        using algorithm: some EulerianCycleAlgorithm<Self>
    ) -> Path<VertexDescriptor, EdgeDescriptor>? {
        algorithm.eulerianCycle(in: self, visitor: nil)
    }
    
    /// Checks if the graph has an Eulerian path.
    ///
    /// - Returns: `true` if the graph has an Eulerian path, `false` otherwise.
    @inlinable
    public func hasEulerianPath() -> Bool {
        // A graph has an Eulerian path if and only if:
        // 1. It's connected
        // 2. It has exactly 0 or 2 vertices of odd degree
        let vertices = Array(vertices())
        
        // Empty graph has no Eulerian path
        if vertices.isEmpty {
            return false
        }
        
        var oddDegreeCount = 0
        
        for vertex in vertices {
            let degree = degree(of: vertex)
            if degree % 2 == 1 {
                oddDegreeCount += 1
            }
        }
        
        return oddDegreeCount == 0 || oddDegreeCount == 2
    }
    
    /// Checks if the graph has an Eulerian cycle.
    ///
    /// - Returns: `true` if the graph has an Eulerian cycle, `false` otherwise.
    @inlinable
    public func hasEulerianCycle() -> Bool {
        // A graph has an Eulerian cycle if and only if:
        // 1. It's connected
        // 2. All vertices have even degree
        let vertices = Array(vertices())
        
        // Empty graph has no Eulerian cycle
        if vertices.isEmpty {
            return false
        }
        
        for vertex in vertices {
            if degree(of: vertex) % 2 == 1 {
                return false
            }
        }
        
        return true
    }
}

// MARK: - Default Implementations

extension BidirectionalGraph where Self: VertexListGraph, VertexDescriptor: Hashable {
    /// Finds an Eulerian path using Hierholzer's algorithm as the default.
    /// This is the most efficient algorithm for finding Eulerian paths.
    ///
    /// - Returns: An Eulerian path, if one exists.
    @inlinable
    public func eulerianPath() -> Path<VertexDescriptor, EdgeDescriptor>? {
        eulerianPath(using: .hierholzer())
    }
    
    /// Finds an Eulerian cycle using Hierholzer's algorithm as the default.
    /// This is the most efficient algorithm for finding Eulerian cycles.
    ///
    /// - Returns: An Eulerian cycle, if one exists.
    @inlinable
    public func eulerianCycle() -> Path<VertexDescriptor, EdgeDescriptor>? {
        eulerianCycle(using: .hierholzer())
    }
}

/// A protocol for algorithms that find Eulerian paths.
public protocol EulerianPathAlgorithm<Graph> {
    /// The graph type that this algorithm operates on.
    associatedtype Graph: BidirectionalGraph & VertexListGraph where Graph.VertexDescriptor: Hashable
    /// The visitor type for observing algorithm progress.
    associatedtype Visitor
    
    /// Finds an Eulerian path in the graph.
    ///
    /// - Parameters:
    ///   - graph: The graph to find the path in.
    ///   - visitor: An optional visitor to observe the algorithm's progress.
    /// - Returns: An Eulerian path, if one exists.
    func eulerianPath(in graph: Graph, visitor: Visitor?) -> Path<Graph.VertexDescriptor, Graph.EdgeDescriptor>?
}

/// A protocol for algorithms that find Eulerian cycles.
public protocol EulerianCycleAlgorithm<Graph> {
    /// The graph type that this algorithm operates on.
    associatedtype Graph: BidirectionalGraph & VertexListGraph where Graph.VertexDescriptor: Hashable
    /// The visitor type for observing algorithm progress.
    associatedtype Visitor
    
    /// Finds an Eulerian cycle in the graph.
    ///
    /// - Parameters:
    ///   - graph: The graph to find the cycle in.
    ///   - visitor: An optional visitor to observe the algorithm's progress.
    /// - Returns: An Eulerian cycle, if one exists.
    func eulerianCycle(in graph: Graph, visitor: Visitor?) -> Path<Graph.VertexDescriptor, Graph.EdgeDescriptor>?
}

extension VisitorWrapper: EulerianPathAlgorithm where Base: EulerianPathAlgorithm, Base.Visitor == Visitor, Visitor: Composable, Visitor.Other == Visitor {
    public typealias Graph = Base.Graph
    
    @inlinable
    public func eulerianPath(in graph: Base.Graph, visitor: Base.Visitor?) -> Path<Base.Graph.VertexDescriptor, Base.Graph.EdgeDescriptor>? {
        base.eulerianPath(in: graph, visitor: self.visitor.combined(with: visitor))
    }
}

extension VisitorWrapper: EulerianCycleAlgorithm where Base: EulerianCycleAlgorithm, Base.Visitor == Visitor, Visitor: Composable, Visitor.Other == Visitor {
    public typealias Graph = Base.Graph
    
    @inlinable
    public func eulerianCycle(in graph: Base.Graph, visitor: Base.Visitor?) -> Path<Base.Graph.VertexDescriptor, Base.Graph.EdgeDescriptor>? {
        base.eulerianCycle(in: graph, visitor: self.visitor.combined(with: visitor))
    }
}
