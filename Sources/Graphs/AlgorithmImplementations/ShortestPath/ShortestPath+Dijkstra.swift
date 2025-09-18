extension ShortestPathAlgorithm where Weight: Numeric, Weight.Magnitude == Weight {
    static func dijkstra<Graph: IncidenceGraph & EdgePropertyGraph, Weight>(
        weight: CostDefinition<Graph, Weight>
    ) -> Self where Self == DijkstraShortestPathAlgorithm<Graph, Weight>, Graph.VertexDescriptor: Hashable {
        .init(weight: weight)
    }
}

struct DijkstraShortestPathAlgorithm<
    Graph: IncidenceGraph & EdgePropertyGraph,
    Weight: Numeric & Comparable
>: ShortestPathAlgorithm where
    Graph.VertexDescriptor: Hashable,
    Weight.Magnitude == Weight
{
    typealias Visitor = Dijkstra<Graph, Weight>.Visitor
    
    let weight: CostDefinition<Graph, Weight>
    
    func shortestPath(
        from source: Graph.VertexDescriptor,
        to destination: Graph.VertexDescriptor,
        in graph: Graph,
        visitor: Visitor?
    ) -> Path<Graph.VertexDescriptor, Graph.EdgeDescriptor>? {
        let sequence = Dijkstra(on: graph, from: source, edgeWeight: weight).withVisitor { visitor }
        guard let result = sequence.first(where: { $0.currentVertex == destination }) else { return nil }
        return Path(
            source: source,
            destination: destination,
            vertices: result.vertices(to: destination, in: graph),
            edges: result.edges(to: destination, in: graph)
        )
    }
}

extension DijkstraShortestPathAlgorithm: VisitorSupporting {}
