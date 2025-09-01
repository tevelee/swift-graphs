protocol VertexMutablePropertyGraph: VertexPropertyGraph, VertexMutableGraph where VertexPropertyMap: MutablePropertyMap {
    var vertexPropertyMap: VertexPropertyMap { get set }
}

extension VertexMutablePropertyGraph {
    @discardableResult
    mutating func addVertex(configure: (inout VertexPropertyMap.Value) -> Void) -> VertexDescriptor {
        let vertex = addVertex()
        configure(&vertexPropertyMap[vertex])
        return vertex
    }

    subscript(vertex: VertexPropertyMap.Key) -> VertexPropertyMap.Value {
        get { vertexPropertyMap[vertex] }
        set { vertexPropertyMap[vertex] = newValue }
        // TODO: modify accessor
    }
}

protocol EdgeMutablePropertyGraph: EdgePropertyGraph, EdgeMutableGraph where EdgePropertyMap: MutablePropertyMap {
    var edgePropertyMap: EdgePropertyMap { get set }
}

extension EdgeMutablePropertyGraph {
    @discardableResult
    mutating func addEdge(from source: VertexDescriptor, to destination: VertexDescriptor, configure: (inout EdgePropertyMap.Value) -> Void) -> EdgeDescriptor? {
        guard let edge = addEdge(from: source, to: destination) else { return nil }
        configure(&edgePropertyMap[edge])
        return edge
    }

    subscript(edge: EdgePropertyMap.Key) -> EdgePropertyMap.Value {
        get { edgePropertyMap[edge] }
        set { edgePropertyMap[edge] = newValue }
        // TODO: modify accessor
    }
}

protocol MutablePropertyGraph: VertexMutablePropertyGraph, EdgeMutablePropertyGraph {}

