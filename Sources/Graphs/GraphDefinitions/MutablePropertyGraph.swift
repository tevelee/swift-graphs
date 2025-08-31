protocol VertexMutablePropertyGraph: VertexPropertyGraph, VertexMutableGraph where VertexPropertyMap: MutablePropertyMap {
    var vertexPropertyMap: VertexPropertyMap { get set }
}

extension VertexMutablePropertyGraph {
    @discardableResult
    mutating func addVertex(with property: VertexPropertyMap.Property.Value) -> VertexDescriptor {
        let vertex = addVertex()
        vertexPropertyMap[vertex] = property
        return vertex
    }
}

protocol EdgeMutablePropertyGraph: EdgePropertyGraph, EdgeMutableGraph where EdgePropertyMap: MutablePropertyMap {
    var edgePropertyMap: EdgePropertyMap { get set }
}

extension EdgeMutablePropertyGraph {
    @discardableResult
    mutating func addEdge(from source: VertexDescriptor, to destination: VertexDescriptor, with property: EdgePropertyMap.Property.Value) -> EdgeDescriptor? {
        guard let edge = addEdge(from: source, to: destination) else { return nil }
        edgePropertyMap[edge] = property
        return edge
    }
}

protocol MutablePropertyGraph: VertexMutablePropertyGraph, EdgeMutablePropertyGraph {}

