extension Graph {
    func withEdgeProperty<Property: EdgeProperty>(
        for property: Property.Type = Property.self,
        _ compute: @escaping (EdgeDescriptor, Self) -> Property.Value
    ) -> ComputedEdgePropertyGraph<Self, Property> {
        ComputedEdgePropertyGraph(base: self, compute: compute)
    }
}

struct ComputedEdgePropertyGraph<Base: Graph, Property: EdgeProperty> {
    var base: Base
    let compute: (Base.EdgeDescriptor, Base) -> Property.Value
}

extension ComputedEdgePropertyGraph: Graph where Base: Graph {
    typealias VertexDescriptor = Base.VertexDescriptor
    typealias EdgeDescriptor = Base.EdgeDescriptor
}

extension ComputedEdgePropertyGraph: VertexListGraph where Base: VertexListGraph {
    typealias Vertices = Base.Vertices
    func vertices() -> Vertices { base.vertices() }
    var vertexCount: Int { base.vertexCount }
}

extension ComputedEdgePropertyGraph: EdgeListGraph where Base: EdgeListGraph {
    typealias Edges = Base.Edges
    func edges() -> Edges { base.edges() }
    var edgeCount: Int { base.edgeCount }
}

extension ComputedEdgePropertyGraph: IncidenceGraph where Base: IncidenceGraph {
    typealias OutgoingEdges = Base.OutgoingEdges
    func outgoingEdges(of vertex: VertexDescriptor) -> OutgoingEdges { base.outgoingEdges(of: vertex) }
    func source(of edge: EdgeDescriptor) -> VertexDescriptor? { base.source(of: edge) }
    func destination(of edge: EdgeDescriptor) -> VertexDescriptor? { base.destination(of: edge) }
    func outDegree(of vertex: VertexDescriptor) -> Int { base.outDegree(of: vertex) }
}

extension ComputedEdgePropertyGraph: BidirectionalGraph where Base: BidirectionalGraph {
    typealias IncomingEdges = Base.IncomingEdges
    func incomingEdges(of vertex: VertexDescriptor) -> IncomingEdges { base.incomingEdges(of: vertex) }
    func inDegree(of vertex: VertexDescriptor) -> Int { base.inDegree(of: vertex) }
}

extension ComputedEdgePropertyGraph: EdgeMutableGraph where Base: EdgeMutableGraph {
    @discardableResult
    mutating func addEdge(from source: VertexDescriptor, to destination: VertexDescriptor) -> EdgeDescriptor? {
        base.addEdge(from: source, to: destination)
    }
    mutating func remove(edge: consuming EdgeDescriptor) {
        base.remove(edge: edge)
    }
}

extension ComputedEdgePropertyGraph: VertexMutableGraph where Base: VertexMutableGraph {
    mutating func addVertex() -> VertexDescriptor {
        base.addVertex()
    }
    mutating func remove(vertex: consuming VertexDescriptor) {
        base.remove(vertex: vertex)
    }
}

extension ComputedEdgePropertyGraph: VertexPropertyGraph where Base: VertexPropertyGraph {
    var vertexPropertyMap: Base.VertexPropertyMap { base.vertexPropertyMap }
}

extension ComputedEdgePropertyGraph: VertexMutablePropertyGraph where Base: VertexMutablePropertyGraph {
    var vertexPropertyMap: Base.VertexPropertyMap {
        get { base.vertexPropertyMap }
        set { base.vertexPropertyMap = newValue }
    }
}

extension ComputedEdgePropertyGraph: EdgePropertyGraph where Base: EdgePropertyGraph {
    var edgePropertyMap: ComputedEdgePropertyMap<Base.EdgePropertyMap, Property> {
        .init(base: base.edgePropertyMap) { edge in
            compute(edge, base)
        }
    }
}

struct ComputedEdgePropertyMap<
    Base: PropertyMap,
    Property: EdgeProperty
>: PropertyMap where
    Base.Value: EdgeProperties
{
    var base: Base
    let compute: (Base.Key) -> Property.Value

    subscript(key: Base.Key) -> ComputedEdgeProperties<Base.Value, Property> {
        .init(base: base[key]) {
            compute(key)
        }
    }
}

struct ComputedEdgeProperties<Base: EdgeProperties, Property: EdgeProperty>: EdgeProperties {
    var base: Base
    let compute: () -> Property.Value

    subscript<P: EdgeProperty>(property: P.Type) -> P.Value {
        get {
            if property == Property.self, let value = compute() as? P.Value {
                return value
            }
            return base[property]
        }
        set {
            base[property] = newValue
        }
    }
}
