import Foundation

struct DijkstraAllPaths<
    Graph: IncidenceGraph & EdgePropertyGraph,
    Weight: Numeric & Comparable
> where
    Graph.VertexDescriptor: Hashable,
    Weight.Magnitude == Weight
{
    typealias Vertex = Graph.VertexDescriptor
    typealias Edge = Graph.EdgeDescriptor
    
    struct Visitor {
        var startDijkstraFromSource: ((Vertex) -> Void)?
        var completeDijkstraFromSource: ((Vertex) -> Void)?
    }
    
    private let graph: Graph
    private let edgeWeight: CostDefinition<Graph, Weight>
    
    init(
        on graph: Graph,
        edgeWeight: CostDefinition<Graph, Weight>
    ) {
        self.graph = graph
        self.edgeWeight = edgeWeight
    }
    
    func shortestPathsFromSource(_ source: Vertex, visitor: Visitor? = nil) -> ShortestPathsFromSource<Vertex, Edge, Weight> {
        visitor?.startDijkstraFromSource?(source)
        let dijkstra = Dijkstra(on: graph, from: source, edgeWeight: edgeWeight)
        let result = dijkstra.allShortestPaths()
        visitor?.completeDijkstraFromSource?(source)
        return result
    }
}

extension DijkstraAllPaths: ShortestPathsFromSourceAlgorithm {
    func shortestPathsFromSource(
        _ source: Vertex,
        in graph: Graph
    ) -> ShortestPathsFromSource<Vertex, Edge, Weight> {
        shortestPathsFromSource(source)
    }
}

// Visitor support
extension DijkstraAllPaths: VisitorSupporting {}

