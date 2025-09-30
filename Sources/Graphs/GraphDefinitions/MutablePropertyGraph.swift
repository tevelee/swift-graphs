/// A protocol for graphs that support mutable vertex properties.
///
/// Vertex mutable property graphs allow both reading and writing vertex properties,
/// enabling dynamic modification of vertex data during graph operations.
public protocol VertexMutablePropertyGraph: VertexPropertyGraph, VertexMutableGraph where VertexPropertyMap: MutablePropertyMap {
    var vertexPropertyMap: VertexPropertyMap { get set }
}

extension VertexMutablePropertyGraph {
    @discardableResult
    @inlinable
    public mutating func addVertex(configure: (inout VertexPropertyMap.Value) -> Void) -> VertexDescriptor {
        let vertex = addVertex()
        configure(&vertexPropertyMap[vertex])
        return vertex
    }

    @inlinable
    public subscript(vertex: VertexPropertyMap.Key) -> VertexPropertyMap.Value {
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

/// A protocol for graphs that support mutable edge properties.
///
/// Edge mutable property graphs allow both reading and writing edge properties,
/// enabling dynamic modification of edge data during graph operations.
public protocol EdgeMutablePropertyGraph: EdgePropertyGraph, EdgeMutableGraph where EdgePropertyMap: MutablePropertyMap {
    var edgePropertyMap: EdgePropertyMap { get set }
}

extension EdgeMutablePropertyGraph {
    @discardableResult
    @inlinable
    public mutating func addEdge(from source: VertexDescriptor, to destination: VertexDescriptor, configure: (inout EdgePropertyMap.Value) -> Void) -> EdgeDescriptor? {
        guard let edge = addEdge(from: source, to: destination) else { return nil }
        configure(&edgePropertyMap[edge])
        return edge
    }

    @inlinable
    public subscript(edge: EdgePropertyMap.Key) -> EdgePropertyMap.Value {
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

/// A protocol for graphs that support mutable properties for both vertices and edges.
///
/// Mutable property graphs combine vertex and edge mutable property capabilities,
/// providing complete flexibility for modifying graph data during operations.
public protocol MutablePropertyGraph: VertexMutablePropertyGraph, EdgeMutablePropertyGraph {}

