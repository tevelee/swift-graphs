extension SearchAlgorithm {
    static func uniformCostSearch<Graph, Weight>(
        edgeWeight: CostDefinition<Graph, Weight>
    ) -> Self where Self == UniformCostSearchAlgorithm<Graph, Weight> {
        .init(edgeWeight: edgeWeight)
    }
}

struct UniformCostSearchAlgorithm<
    Graph: IncidenceGraph & EdgePropertyGraph,
    Weight: Numeric & Comparable
>: SearchAlgorithm where
    Graph.VertexDescriptor: Hashable,
    Weight.Magnitude == Weight
{
    typealias Visitor = UniformCostSearch<Graph, Weight>.Visitor
    
    let edgeWeight: CostDefinition<Graph, Weight>
    
    init(edgeWeight: CostDefinition<Graph, Weight>) {
        self.edgeWeight = edgeWeight
    }
    
    func search(
        from source: Graph.VertexDescriptor,
        in graph: Graph,
        visitor: Visitor?
    ) -> UniformCostSearch<Graph, Weight> {
        UniformCostSearch(on: graph, from: source, edgeWeight: edgeWeight)
    }
}

extension UniformCostSearchAlgorithm: VisitorSupporting {}
