import Foundation

extension ShortestPathAlgorithm where Weight: AdditiveArithmetic {
    static func yen<Graph: IncidenceGraph & EdgePropertyGraph, Weight>(
        weight: CostDefinition<Graph, Weight>
    ) -> Self where Self == YenShortestPath<Graph, Weight>, Graph.VertexDescriptor: Hashable {
        .init(weight: weight)
    }
}

struct YenShortestPath<
    Graph: IncidenceGraph & EdgePropertyGraph,
    Weight: AdditiveArithmetic & Comparable
>: ShortestPathAlgorithm where
    Graph.VertexDescriptor: Hashable
{
    typealias Visitor = Yen<Graph, Weight>.Visitor
    
    let weight: CostDefinition<Graph, Weight>
    
    func shortestPath(
        from source: Graph.VertexDescriptor,
        to destination: Graph.VertexDescriptor,
        in graph: Graph,
        visitor: Visitor?
    ) -> Path<Graph.VertexDescriptor, Graph.EdgeDescriptor>? {
        let yen = Yen(edgeWeight: weight)
        let paths = yen.kShortestPaths(from: source, to: destination, k: 1, in: graph, visitor: visitor)
        return paths.first
    }
}

extension YenShortestPath: VisitorSupporting {}
