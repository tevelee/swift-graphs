extension ShortestPathUntilAlgorithm {
    static func aStar<Graph: IncidenceGraph, Weight: Numeric>(
        weight: CostAlgorithm<Graph, Weight>,
        heuristic: Heuristic<Graph, Weight>
    ) -> Self where Self == AStarShortestPath<Graph, Weight> {
        .init(weight: weight, heuristic: heuristic)
    }
}

struct AStarShortestPath<Graph: IncidenceGraph & EdgePropertyGraph & VertexListGraph, Weight: Numeric & Comparable>: ShortestPathUntilAlgorithm where Graph.VertexDescriptor: Hashable {
    let weight: CostAlgorithm<Graph, Weight>
    let heuristic: Heuristic<Graph, Weight>

    func shortestPath(
        from source: Graph.VertexDescriptor,
        until condition: @escaping (Graph.VertexDescriptor) -> Bool,
        in graph: Graph
    ) -> Path<Graph.VertexDescriptor, Graph.EdgeDescriptor>? {
        let sequence = AStarAlgorithm(
            on: graph,
            from: source,
            edgeWeight: weight,
            heuristic: heuristic
        )
        guard let result = sequence.first(where: { condition($0.currentVertex) }) else { return nil }
        let destination = result.currentVertex
        return Path(
            source: source,
            destination: destination,
            vertices: result.vertices(to: destination, in: graph),
            edges: result.edges(to: destination, in: graph)
        )
    }
}


