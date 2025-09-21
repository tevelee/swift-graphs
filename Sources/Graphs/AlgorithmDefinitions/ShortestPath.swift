extension IncidenceGraph where VertexDescriptor: Equatable {
    func shortestPath<Weight: AdditiveArithmetic & Comparable>(
        from source: VertexDescriptor,
        to destination: VertexDescriptor,
        using algorithm: some ShortestPathAlgorithm<Self, Weight>
    ) -> Path<VertexDescriptor, EdgeDescriptor>? {
        algorithm.shortestPath(from: source, to: destination, in: self, visitor: nil)
    }
}

// MARK: - Default Implementations

extension IncidenceGraph where Self: EdgePropertyGraph, VertexDescriptor: Hashable {
    /// Finds the shortest path between two vertices using Dijkstra's algorithm as the default.
    /// This is the most commonly used and efficient algorithm for non-negative edge weights.
    func shortestPath<Weight: Numeric & Comparable>(
        from source: VertexDescriptor,
        to destination: VertexDescriptor,
        weight: CostDefinition<Self, Weight>
    ) -> Path<VertexDescriptor, EdgeDescriptor>? where Weight.Magnitude == Weight {
        shortestPath(from: source, to: destination, using: .dijkstra(weight: weight))
    }
}

protocol ShortestPathAlgorithm<Graph, Weight> {
    associatedtype Graph: IncidenceGraph
    associatedtype Weight: AdditiveArithmetic & Comparable
    associatedtype Visitor

    func shortestPath(
        from source: Graph.VertexDescriptor,
        to destination: Graph.VertexDescriptor,
        in graph: Graph,
        visitor: Visitor?
    ) -> Path<Graph.VertexDescriptor, Graph.EdgeDescriptor>?
}

extension ShortestPathAlgorithm where Self: ShortestPathUntilAlgorithm, Graph.VertexDescriptor: Equatable {
    func shortestPath(
        from source: Graph.VertexDescriptor,
        to destination: Graph.VertexDescriptor,
        in graph: Graph,
        visitor: Visitor?
    ) -> Path<Graph.VertexDescriptor, Graph.EdgeDescriptor>? {
        shortestPath(from: source, until: { $0 == destination }, in: graph, visitor: visitor)
    }
}

extension VisitorWrapper: ShortestPathAlgorithm where Base: ShortestPathAlgorithm, Base.Visitor == Visitor, Visitor: Composable, Visitor.Other == Visitor {
    typealias Graph = Base.Graph
    typealias Weight = Base.Weight

    func shortestPath(
        from source: Base.Graph.VertexDescriptor,
        to destination: Base.Graph.VertexDescriptor,
        in graph: Base.Graph,
        visitor: Base.Visitor?
    ) -> Path<Base.Graph.VertexDescriptor, Base.Graph.EdgeDescriptor>? {
        base.shortestPath(from: source, to: destination, in: graph, visitor: self.visitor.combined(with: visitor))
    }
}
