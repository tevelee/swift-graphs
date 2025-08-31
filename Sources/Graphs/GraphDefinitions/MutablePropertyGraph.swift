protocol VertexMutablePropertyGraph: VertexPropertyGraph where VertexPropertyMap: MutablePropertyMap {
    var vertexPropertyMap: VertexPropertyMap { get set }
}

extension VertexMutablePropertyGraph {
    mutating func setProperty(value: VertexPropertyMap.Property.Value, of vertex: VertexDescriptor) {
        var map = vertexPropertyMap
        map[vertex] = value
        vertexPropertyMap = map
    }
}

protocol EdgeMutablePropertyGraph: EdgePropertyGraph where EdgePropertyMap: MutablePropertyMap {
    var edgePropertyMap: EdgePropertyMap { get set }
}

extension EdgeMutablePropertyGraph {
    mutating func setProperty(value: EdgePropertyMap.Property.Value, of edge: EdgeDescriptor) {
        var map = edgePropertyMap
        map[edge] = value
        edgePropertyMap = map
    }
}

protocol MutablePropertyGraph: VertexMutablePropertyGraph, EdgeMutablePropertyGraph {}
