extension ShortestPathAlgorithm where Weight: Numeric, Weight.Magnitude == Weight {
    static func dijkstra<Graph: IncidenceGraph & EdgePropertyGraph, Weight>(
        weight: CostDefinition<Graph, Weight>
    ) -> Self where Self == DijkstraShortestPath<Graph, Weight>, Graph.VertexDescriptor: Hashable {
        .init(weight: weight)
    }
}

struct DijkstraShortestPath<
    Graph: IncidenceGraph & EdgePropertyGraph,
    Weight: Numeric & Comparable
>: ShortestPathAlgorithm where
    Graph.VertexDescriptor: Hashable,
    Weight.Magnitude == Weight
{
    let weight: CostDefinition<Graph, Weight>
    
    func shortestPath(
        from source: Graph.VertexDescriptor,
        to destination: Graph.VertexDescriptor,
        in graph: Graph
    ) -> Path<Graph.VertexDescriptor, Graph.EdgeDescriptor>? {
        let dijkstra = Dijkstra(on: graph, from: source, edgeWeight: weight)
        guard let result = dijkstra.first(where: { $0.currentVertex == destination }) else { return nil }
        return Path(
            source: source,
            destination: destination,
            vertices: result.vertices(to: destination, in: graph),
            edges: result.edges(to: destination, in: graph)
        )
    }
}
