extension ShortestPathUntilAlgorithm {
    @inlinable
    public static func dijkstra<Graph: IncidenceGraph, Weight: Numeric>(
        weight: CostDefinition<Graph, Weight>
    ) -> Self where Self == DijkstraShortestPath<Graph, Weight>, Weight.Magnitude == Weight {
        .init(weight: weight)
    }
}

public struct DijkstraShortestPath<
    Graph: IncidenceGraph,
    Weight: Numeric
>: ShortestPathUntilAlgorithm where
    Weight.Magnitude == Weight,
    Graph.VertexDescriptor: Hashable
{
    public typealias Visitor = Dijkstra<Graph, Weight>.Visitor
    
    public let weight: CostDefinition<Graph, Weight>
    
    @inlinable
    public init(weight: CostDefinition<Graph, Weight>) {
        self.weight = weight
    }

    @inlinable
    public func shortestPath(
        from source: Graph.VertexDescriptor,
        until condition: @escaping (Graph.VertexDescriptor) -> Bool,
        in graph: Graph,
        visitor: Visitor?
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

extension DijkstraShortestPath: VisitorSupporting {}
