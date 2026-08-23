extension TraversalAlgorithm {
    @inlinable
    public static func dfs<Graph>(order: DFSOrder<Graph> = .preorder) -> Self where Self == DFSTraversal<Graph> {
        .init(order: order)
    }
}

public struct DFSTraversal<Graph: IncidenceGraph>: TraversalAlgorithm where Graph.VertexDescriptor: Hashable {
    public typealias Event = DepthFirstSearch<Graph>.Event

    public let order: DFSOrder<Graph>
    @usableFromInline
    let shouldTraverse: ((DepthFirstSearch<Graph>.TraversalCandidate) -> Bool)?

    @inlinable
    public init(order: DFSOrder<Graph>) {
        self.order = order
        self.shouldTraverse = nil
    }

    @inlinable
    init(order: DFSOrder<Graph>, shouldTraverse: ((DepthFirstSearch<Graph>.TraversalCandidate) -> Bool)?) {
        self.order = order
        self.shouldTraverse = shouldTraverse
    }

    /// Adds a policy that decides whether candidate tree edges may be traversed.
    @inlinable
    public func allowingTraversal(_ predicate: @escaping (DepthFirstSearch<Graph>.TraversalCandidate) -> Bool) -> Self {
        let earlier = shouldTraverse
        return .init(order: order) { candidate in
            (earlier?(candidate) ?? true) && predicate(candidate)
        }
    }

    @inlinable
    public func traverse(
        from source: Graph.VertexDescriptor,
        in graph: Graph,
        observation: AlgorithmObservation<Event>?
    ) -> TraversalResult<Graph.VertexDescriptor, Graph.EdgeDescriptor> {
        var edges: [Graph.EdgeDescriptor] = []
        let vertices = SharedBuffer<Graph.VertexDescriptor>()

        let collector = AlgorithmObservation<Event> { event in
            if case .edgeExamined(let edge) = event { edges.append(edge) }
        }
        var iterator = DepthFirstSearch(on: graph, from: source, shouldTraverse: shouldTraverse)
            .makeIterator(observation: order.makeObservation(graph, vertices).followed(by: collector).followed(by: observation))
        while iterator.next() != nil {}

        return TraversalResult(
            vertices: vertices.elements,
            edges: edges
        )
    }
}

extension DFSTraversal: AlgorithmObserving {}
