protocol VertexPropertyGraph: Graph {
    associatedtype VertexProperties: Graphs.VertexProperties
    associatedtype VertexPropertyMap: PropertyMap<VertexDescriptor, VertexProperties>

    var vertexPropertyMap: VertexPropertyMap { get }
}

extension VertexPropertyGraph {
    subscript(vertex: VertexPropertyMap.Key) -> VertexPropertyMap.Value {
        vertexPropertyMap[vertex]
    }
}

extension VertexPropertyGraph where Self: VertexListGraph {
    func vertices(satisfying condition: @escaping (VertexProperties) -> Bool) -> LazyFilterSequence<Vertices> {
        vertices().lazy.filter { condition(vertexPropertyMap[$0]) }
    }
}

protocol EdgePropertyGraph: Graph {
    associatedtype EdgeProperties: Graphs.EdgeProperties
    associatedtype EdgePropertyMap: PropertyMap<EdgeDescriptor, EdgeProperties>

    var edgePropertyMap: EdgePropertyMap { get }
}

extension EdgePropertyGraph {
    subscript(edge: EdgePropertyMap.Key) -> EdgePropertyMap.Value {
        edgePropertyMap[edge]
    }
}

extension EdgePropertyGraph where Self: EdgeListGraph {
    func edges(satisfying condition: @escaping (EdgeProperties) -> Bool) -> LazyFilterSequence<Edges> {
        edges().lazy.filter { condition(edgePropertyMap[$0]) }
    }
}

protocol PropertyGraph: VertexPropertyGraph, EdgePropertyGraph {}
