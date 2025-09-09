extension ShortestPathUntilAlgorithm {
    static func dijkstra<Graph: IncidenceGraph, Weight: Numeric>(
        weight: CostDefinition<Graph, Weight>
    ) -> Self where Self == DijkstraShortestPath<Graph, Weight>, Weight.Magnitude == Weight {
        .init(weight: weight)
    }
}

struct DijkstraShortestPath<Graph: IncidenceGraph & EdgePropertyGraph & VertexListGraph, Weight: Numeric>: ShortestPathUntilAlgorithm where Weight.Magnitude == Weight, Graph.VertexDescriptor: Hashable {
    let weight: CostDefinition<Graph, Weight>

    func shortestPath(
        from source: Graph.VertexDescriptor,
        until condition: @escaping (Graph.VertexDescriptor) -> Bool,
        in graph: Graph
    ) -> Path<Graph.VertexDescriptor, Graph.EdgeDescriptor>? {
        let sequence = Dijkstra(on: graph, from: source, edgeWeight: weight)
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
