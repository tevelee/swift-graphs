import Collections

protocol AdjacencyGraph: Graph {
    associatedtype AdjacentVertices: Sequence<VertexDescriptor>

    func adjacentVertices(of vertex: VertexDescriptor) -> AdjacentVertices
}

extension AdjacencyGraph where Self: BidirectionalGraph, VertexDescriptor: Hashable {
    func adjacentVertices(of vertex: VertexDescriptor) -> OrderedSet<VertexDescriptor> {
        var result: OrderedSet<VertexDescriptor> = []
        result.append(contentsOf: outgoingEdges(of: vertex).compactMap(destination))
        result.append(contentsOf: incomingEdges(of: vertex).compactMap(source))
        return result
    }
}
