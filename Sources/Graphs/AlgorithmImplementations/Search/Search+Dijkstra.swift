extension SearchAlgorithm {
    static func dijkstra<Graph, Weight>(
        edgeWeight: CostDefinition<Graph, Weight>
    ) -> Self where Self == DijkstraSearch<Graph, Weight> {
        .init(edgeWeight: edgeWeight)
    }
}

struct DijkstraSearch<
    Graph: IncidenceGraph & EdgePropertyGraph,
    Weight: Numeric & Comparable
>: SearchAlgorithm where
    Graph.VertexDescriptor: Hashable,
    Weight.Magnitude == Weight
{
    typealias Visitor = Dijkstra<Graph, Weight>.Visitor
    
    let edgeWeight: CostDefinition<Graph, Weight>
    
    init(edgeWeight: CostDefinition<Graph, Weight>) {
        self.edgeWeight = edgeWeight
    }
    
    func search(
        from source: Graph.VertexDescriptor,
        in graph: Graph,
        visitor: Visitor?
    ) -> Dijkstra<Graph, Weight> {
        Dijkstra(on: graph, from: source, edgeWeight: edgeWeight)
    }
}

extension DijkstraSearch: VisitorSupporting {}
