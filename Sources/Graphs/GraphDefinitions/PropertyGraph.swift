protocol VertexPropertyGraph: Graph {
    associatedtype VertexPropertyMap: PropertyMap<VertexDescriptor, VertexPropertyValues>

    var vertexPropertyMap: VertexPropertyMap { get }
}

extension VertexPropertyGraph {
    subscript(vertex: VertexPropertyMap.Key) -> VertexPropertyMap.Value {
        vertexPropertyMap[vertex]
    }
}

extension VertexPropertyGraph where Self: VertexListGraph {
    func vertices(satisfying condition: @escaping (VertexPropertyValues) -> Bool) -> LazyFilterSequence<Vertices> {
        vertices().lazy.filter { condition(vertexPropertyMap[$0]) }
    }
}

protocol EdgePropertyGraph: Graph {
    associatedtype EdgePropertyMap: PropertyMap<EdgeDescriptor, EdgePropertyValues>

    var edgePropertyMap: EdgePropertyMap { get }
}

extension EdgePropertyGraph {
    subscript(edge: EdgePropertyMap.Key) -> EdgePropertyMap.Value {
        edgePropertyMap[edge]
    }
}

extension EdgePropertyGraph where Self: EdgeListGraph {
    func edges(satisfying condition: @escaping (EdgePropertyValues) -> Bool) -> LazyFilterSequence<Edges> {
        edges().lazy.filter { condition(edgePropertyMap[$0]) }
    }
}

protocol PropertyGraph: VertexPropertyGraph, EdgePropertyGraph {}
