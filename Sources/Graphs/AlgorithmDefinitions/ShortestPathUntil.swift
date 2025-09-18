extension IncidenceGraph {
    func shortestPath(
        from source: VertexDescriptor,
        until condition: @escaping (VertexDescriptor) -> Bool,
        using algorithm: some ShortestPathUntilAlgorithm<Self>
    ) -> Path<VertexDescriptor, EdgeDescriptor>? {
        algorithm.shortestPath(from: source, until: condition, in: self, visitor: nil)
    }
}

protocol ShortestPathUntilAlgorithm<Graph> {
    associatedtype Graph: IncidenceGraph
    associatedtype Visitor

    func shortestPath(
        from source: Graph.VertexDescriptor,
        until condition: @escaping (Graph.VertexDescriptor) -> Bool,
        in graph: Graph,
        visitor: Visitor?
    ) -> Path<Graph.VertexDescriptor, Graph.EdgeDescriptor>?
}

extension VisitorWrapper: ShortestPathUntilAlgorithm where Base: ShortestPathUntilAlgorithm, Base.Visitor == Visitor, Visitor: Composable, Visitor.Other == Visitor {
    typealias Graph = Base.Graph
    
    func shortestPath(
        from source: Base.Graph.VertexDescriptor,
        until condition: @escaping (Base.Graph.VertexDescriptor) -> Bool,
        in graph: Base.Graph,
        visitor: Base.Visitor?
    ) -> Path<Base.Graph.VertexDescriptor, Base.Graph.EdgeDescriptor>? {
        base.shortestPath(from: source, until: condition, in: graph, visitor: self.visitor.combined(with: visitor))
    }
}
