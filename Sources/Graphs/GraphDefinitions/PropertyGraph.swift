protocol VertexPropertyGraph: Graph {
    associatedtype VertexPropertyMap: PropertyMap where VertexPropertyMap.Key == VertexDescriptor

    var vertexPropertyMap: VertexPropertyMap { get }
}

extension VertexPropertyGraph {
    func propertyValue(of vertex: VertexDescriptor) -> VertexPropertyMap.Property.Value {
        vertexPropertyMap[vertex]
    }
}

protocol EdgePropertyGraph: Graph {
    associatedtype EdgePropertyMap: PropertyMap where EdgePropertyMap.Key == EdgeDescriptor

    var edgePropertyMap: EdgePropertyMap { get }
}

extension EdgePropertyGraph {
    func propertyValue(of edge: EdgeDescriptor) -> EdgePropertyMap.Property.Value {
        edgePropertyMap[edge]
    }
}

protocol PropertyGraph: VertexPropertyGraph, EdgePropertyGraph {}
