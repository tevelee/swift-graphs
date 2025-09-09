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
        set { vertexPropertyMap[vertex] = newValue }
        _read {
            yield vertexPropertyMap[vertex]
        }
        _modify {
            var value = vertexPropertyMap[vertex]
            defer { vertexPropertyMap[vertex] = value }
            yield &value
        }
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
        set { edgePropertyMap[edge] = newValue }
        _read {
            yield edgePropertyMap[edge]
        }
        _modify {
            var value = edgePropertyMap[edge]
            defer { edgePropertyMap[edge] = value }
            yield &value
        }
    }
}

protocol MutablePropertyGraph: VertexMutablePropertyGraph, EdgeMutablePropertyGraph {}

