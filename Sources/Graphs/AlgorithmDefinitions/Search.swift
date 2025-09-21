extension Graph where Self: IncidenceGraph, VertexDescriptor: Hashable {
    func search<Algorithm: SearchAlgorithm>(
        from source: VertexDescriptor,
        using algorithm: Algorithm
    ) -> Algorithm.SearchSequence where Algorithm.Graph == Self {
        algorithm.search(from: source, in: self, visitor: nil)
    }
}

// MARK: - Default Implementations

extension Graph where Self: IncidenceGraph, VertexDescriptor: Hashable {
    func search(from source: VertexDescriptor) -> DepthFirstSearch<Self> {
        search(from: source, using: .dfs())
    }
}

protocol SearchAlgorithm<Graph> {
    associatedtype Graph: IncidenceGraph where Graph.VertexDescriptor: Hashable
    associatedtype SearchSequence: Sequence
    associatedtype Visitor

    func search(
        from source: Graph.VertexDescriptor,
        in graph: Graph,
        visitor: Visitor?
    ) -> SearchSequence
}

extension VisitorWrapper: SearchAlgorithm where Base: SearchAlgorithm, Base.Visitor == Visitor, Visitor: Composable, Visitor.Other == Visitor {
    typealias Graph = Base.Graph
    typealias SearchSequence = Base.SearchSequence
    
    func search(
        from source: Base.Graph.VertexDescriptor,
        in graph: Base.Graph,
        visitor: Base.Visitor?
    ) -> Base.SearchSequence {
        base.search(from: source, in: graph, visitor: self.visitor.combined(with: visitor))
    }
}
