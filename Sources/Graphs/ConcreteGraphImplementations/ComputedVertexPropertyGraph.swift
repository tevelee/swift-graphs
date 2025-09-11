extension Graph {
    func withVertexProperty<Property: VertexProperty>(
        for property: Property.Type = Property.self,
        _ compute: @escaping (VertexDescriptor, Self) -> Property.Value
    ) -> ComputedVertexPropertyGraph<Self, Property> {
        ComputedVertexPropertyGraph(base: self, compute: compute)
    }
}

struct ComputedVertexPropertyGraph<Base: Graph, Property: VertexProperty> {
    var base: Base
    let compute: (Base.VertexDescriptor, Base) -> Property.Value
}

extension ComputedVertexPropertyGraph: Graph where Base: Graph {
    typealias VertexDescriptor = Base.VertexDescriptor
    typealias EdgeDescriptor = Base.EdgeDescriptor
}

extension ComputedVertexPropertyGraph: VertexListGraph where Base: VertexListGraph {
    typealias Vertices = Base.Vertices
    func vertices() -> Vertices { base.vertices() }
    var vertexCount: Int { base.vertexCount }
}

extension ComputedVertexPropertyGraph: EdgeListGraph where Base: EdgeListGraph {
    typealias Edges = Base.Edges
    func edges() -> Edges { base.edges() }
    var edgeCount: Int { base.edgeCount }
}

extension ComputedVertexPropertyGraph: IncidenceGraph where Base: IncidenceGraph {
    typealias OutgoingEdges = Base.OutgoingEdges
    func outgoingEdges(of vertex: VertexDescriptor) -> OutgoingEdges { base.outgoingEdges(of: vertex) }
    func source(of edge: EdgeDescriptor) -> VertexDescriptor? { base.source(of: edge) }
    func destination(of edge: EdgeDescriptor) -> VertexDescriptor? { base.destination(of: edge) }
    func outDegree(of vertex: VertexDescriptor) -> Int { base.outDegree(of: vertex) }
}

extension ComputedVertexPropertyGraph: BidirectionalGraph where Base: BidirectionalGraph {
    typealias IncomingEdges = Base.IncomingEdges
    func incomingEdges(of vertex: VertexDescriptor) -> IncomingEdges { base.incomingEdges(of: vertex) }
    func inDegree(of vertex: VertexDescriptor) -> Int { base.inDegree(of: vertex) }
}

extension ComputedVertexPropertyGraph: EdgeMutableGraph where Base: EdgeMutableGraph {
    @discardableResult
    mutating func addEdge(from source: VertexDescriptor, to destination: VertexDescriptor) -> EdgeDescriptor? {
        base.addEdge(from: source, to: destination)
    }
    mutating func remove(edge: consuming EdgeDescriptor) {
        base.remove(edge: edge)
    }
}

extension ComputedVertexPropertyGraph: VertexMutableGraph where Base: VertexMutableGraph {
    mutating func addVertex() -> VertexDescriptor {
        base.addVertex()
    }
    mutating func remove(vertex: consuming VertexDescriptor) {
        base.remove(vertex: vertex)
    }
}

extension ComputedVertexPropertyGraph: EdgePropertyGraph where Base: EdgePropertyGraph {
    var edgePropertyMap: Base.EdgePropertyMap { base.edgePropertyMap }
}

extension ComputedVertexPropertyGraph: EdgeMutablePropertyGraph where Base: EdgeMutablePropertyGraph {
    var edgePropertyMap: Base.EdgePropertyMap {
        get { base.edgePropertyMap }
        set { base.edgePropertyMap = newValue }
    }
}

extension ComputedVertexPropertyGraph: VertexPropertyGraph where Base: VertexPropertyGraph {
    var vertexPropertyMap: ComputedVertexPropertyMap<Base.VertexPropertyMap, Property> {
        .init(base: base.vertexPropertyMap) { edge in
            compute(edge, base)
        }
    }
}

struct ComputedVertexPropertyMap<
    Base: PropertyMap,
    Property: VertexProperty
>: PropertyMap where
    Base.Value: VertexProperties
{
    var base: Base
    let compute: (Base.Key) -> Property.Value

    subscript(key: Base.Key) -> ComputedVertexProperties<Base.Value, Property> {
        .init(base: base[key]) {
            compute(key)
        }
    }
}

struct ComputedVertexProperties<Base: VertexProperties, Property: VertexProperty>: VertexProperties {
    var base: Base
    let compute: () -> Property.Value

    subscript<P: VertexProperty>(property: P.Type) -> P.Value {
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
