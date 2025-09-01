protocol VertexPropertyGraph: Graph {
    associatedtype VertexPropertyMap: PropertyMap where VertexPropertyMap.Key == VertexDescriptor, VertexPropertyMap.Value: PropertyValues<VertexMarker>

    var vertexPropertyMap: VertexPropertyMap { get }
}

extension VertexPropertyGraph {
    subscript(vertex: VertexPropertyMap.Key) -> VertexPropertyMap.Value {
        vertexPropertyMap[vertex]
    }
}

protocol EdgePropertyGraph: Graph {
    associatedtype EdgePropertyMap: PropertyMap where EdgePropertyMap.Key == EdgeDescriptor, EdgePropertyMap.Value: PropertyValues<EdgeMarker>

    var edgePropertyMap: EdgePropertyMap { get }
}

extension EdgePropertyGraph {
    subscript(edge: EdgePropertyMap.Key) -> EdgePropertyMap.Value {
        edgePropertyMap[edge]
    }
}

protocol PropertyGraph: VertexPropertyGraph, EdgePropertyGraph {}
