extension IncidenceGraph where Self: VertexListGraph, VertexDescriptor: Hashable {
    func topologicalSort(
        using algorithm: some TopologicalSortAlgorithm<Self>
    ) -> TopologicalSortResult<VertexDescriptor> {
        algorithm.topologicalSort(in: self, visitor: nil)
    }
}

// MARK: - Default Implementations

extension IncidenceGraph where Self: VertexListGraph, VertexDescriptor: Hashable {
    /// Performs topological sort using DFS-based algorithm as the default.
    /// This is the most commonly used and efficient algorithm for topological sorting.
    func topologicalSort() -> TopologicalSortResult<VertexDescriptor> {
        topologicalSort(using: .dfs())
    }
}

protocol TopologicalSortAlgorithm<Graph> {
    associatedtype Graph: IncidenceGraph where Graph.VertexDescriptor: Hashable
    associatedtype Visitor

    func topologicalSort(
        in graph: Graph,
        visitor: Visitor?
    ) -> TopologicalSortResult<Graph.VertexDescriptor>
}

extension VisitorWrapper: TopologicalSortAlgorithm where Base: TopologicalSortAlgorithm, Base.Visitor == Visitor, Visitor: Composable, Visitor.Other == Visitor {
    typealias Graph = Base.Graph
    
    func topologicalSort(
        in graph: Base.Graph,
        visitor: Base.Visitor?
    ) -> TopologicalSortResult<Base.Graph.VertexDescriptor> {
        base.topologicalSort(in: graph, visitor: self.visitor.combined(with: visitor))
    }
}

// MARK: - Result Type

/// Represents the result of a topological sort algorithm.
public struct TopologicalSortResult<Vertex: Hashable> {
    /// The topologically sorted vertices.
    public let sortedVertices: [Vertex]
    
    /// Whether the graph contains a cycle (making topological sort impossible).
    public let hasCycle: Bool
    
    /// The vertices that are part of a cycle (if any).
    public let cycleVertices: [Vertex]
    
    /// Creates a new result with the given sorted vertices.
    public init(sortedVertices: [Vertex], hasCycle: Bool = false, cycleVertices: [Vertex] = []) {
        self.sortedVertices = sortedVertices
        self.hasCycle = hasCycle
        self.cycleVertices = cycleVertices
    }
    
    /// Returns whether the topological sort was successful (no cycles).
    public var isValid: Bool {
        !hasCycle
    }
}

extension TopologicalSortResult: Equatable where Vertex: Equatable {
    public static func == (lhs: TopologicalSortResult<Vertex>, rhs: TopologicalSortResult<Vertex>) -> Bool {
        lhs.sortedVertices == rhs.sortedVertices && lhs.hasCycle == rhs.hasCycle && lhs.cycleVertices == rhs.cycleVertices
    }
}

extension TopologicalSortResult: Hashable where Vertex: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(sortedVertices)
        hasher.combine(hasCycle)
        hasher.combine(cycleVertices)
    }
}
