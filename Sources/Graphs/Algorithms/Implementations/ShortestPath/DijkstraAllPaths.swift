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
    
    private let graph: Graph
    private let edgeWeight: CostDefinition<Graph, Weight>
    
    init(
        on graph: Graph,
        edgeWeight: CostDefinition<Graph, Weight>
    ) {
        self.graph = graph
        self.edgeWeight = edgeWeight
    }
    
    func shortestPathsFromSource(_ source: Vertex) -> ShortestPathsFromSource<Vertex, Edge, Weight> {
        let dijkstra = Dijkstra(on: graph, from: source, edgeWeight: edgeWeight)
        return dijkstra.allShortestPaths()
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

