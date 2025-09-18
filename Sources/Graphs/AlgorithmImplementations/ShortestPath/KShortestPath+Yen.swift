import Foundation

extension KShortestPathsAlgorithm where Weight: AdditiveArithmetic {
    static func yen<Graph: IncidenceGraph & EdgePropertyGraph, Weight>(
        weight: CostDefinition<Graph, Weight>
    ) -> Self where Self == YenKShortestPath<Graph, Weight>, Graph.VertexDescriptor: Hashable {
        .init(weight: weight)
    }
}

struct YenKShortestPath<
    Graph: IncidenceGraph & EdgePropertyGraph,
    Weight: AdditiveArithmetic & Comparable
>: KShortestPathsAlgorithm where
    Graph.VertexDescriptor: Hashable
{
    typealias Visitor = Yen<Graph, Weight>.Visitor
    
    let weight: CostDefinition<Graph, Weight>
    
    func kShortestPaths(
        from source: Graph.VertexDescriptor,
        to destination: Graph.VertexDescriptor,
        k: Int,
        in graph: Graph,
        visitor: Visitor?
    ) -> [Path<Graph.VertexDescriptor, Graph.EdgeDescriptor>] {
        let yen = Yen(edgeWeight: weight)
        return yen.kShortestPaths(from: source, to: destination, k: k, in: graph, visitor: visitor)
    }
}

extension YenKShortestPath: VisitorSupporting {}
