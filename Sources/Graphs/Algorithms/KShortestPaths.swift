import Foundation

protocol KShortestPathsAlgorithm<Graph, Weight> {
    associatedtype Graph: IncidenceGraph
    associatedtype Weight: Numeric & Comparable
    
    func kShortestPaths(
        from source: Graph.VertexDescriptor,
        to destination: Graph.VertexDescriptor,
        k: Int,
        in graph: Graph
    ) -> [Path<Graph.VertexDescriptor, Graph.EdgeDescriptor>]
}

extension IncidenceGraph where VertexDescriptor: Equatable {
    func kShortestPaths<Weight: Numeric & Comparable>(
        from source: VertexDescriptor,
        to destination: VertexDescriptor,
        k: Int,
        using algorithm: some KShortestPathsAlgorithm<Self, Weight>
    ) -> [Path<VertexDescriptor, EdgeDescriptor>] {
        algorithm.kShortestPaths(from: source, to: destination, k: k, in: self)
    }
}
