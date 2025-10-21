extension Graph {
    /// Creates a computed edge property graph that dynamically calculates edge properties.
    ///
    /// - Parameters:
    ///   - property: The type of property to compute
    ///   - compute: A closure that computes the property value for each edge
    /// - Returns: A computed edge property graph
    @inlinable
    public func withEdgeProperty<Property: EdgeProperty>(
        for property: Property.Type = Property.self,
        _ compute: @escaping (EdgeDescriptor, Self) -> Property.Value
    ) -> ComputedEdgePropertyGraph<Self, Property> {
        ComputedEdgePropertyGraph(base: self, compute: compute)
    }
}

/// A graph that dynamically computes edge properties on demand.
///
/// ComputedEdgePropertyGraph wraps a base graph and provides computed edge properties
/// that are calculated dynamically when accessed. This is useful for properties that
/// are expensive to store but can be computed efficiently on demand.
public struct ComputedEdgePropertyGraph<Base: Graph, Property: EdgeProperty> {
    public var base: Base
    public let compute: (Base.EdgeDescriptor, Base) -> Property.Value
    
    @inlinable
    public init(base: Base, compute: @escaping (Base.EdgeDescriptor, Base) -> Property.Value) {
        self.base = base
        self.compute = compute
    }
}

extension ComputedEdgePropertyGraph: Graph where Base: Graph {
    public typealias VertexDescriptor = Base.VertexDescriptor
    public typealias EdgeDescriptor = Base.EdgeDescriptor
}

extension ComputedEdgePropertyGraph: VertexListGraph where Base: VertexListGraph {
    public typealias Vertices = Base.Vertices
    
    @inlinable
    public func vertices() -> Vertices { base.vertices() }
    
    @inlinable
    public var vertexCount: Int { base.vertexCount }
}

extension ComputedEdgePropertyGraph: EdgeListGraph where Base: EdgeListGraph {
    public typealias Edges = Base.Edges
    
    @inlinable
    public func edges() -> Edges { base.edges() }
    
    @inlinable
    public var edgeCount: Int { base.edgeCount }
}

extension ComputedEdgePropertyGraph: IncidenceGraph where Base: IncidenceGraph {
    public typealias OutgoingEdges = Base.OutgoingEdges
    
    @inlinable
    public func outgoingEdges(of vertex: VertexDescriptor) -> OutgoingEdges { base.outgoingEdges(of: vertex) }
    
    @inlinable
    public func source(of edge: EdgeDescriptor) -> VertexDescriptor? { base.source(of: edge) }
    
    @inlinable
    public func destination(of edge: EdgeDescriptor) -> VertexDescriptor? { base.destination(of: edge) }
    
    @inlinable
    public func outDegree(of vertex: VertexDescriptor) -> Int { base.outDegree(of: vertex) }
}

extension ComputedEdgePropertyGraph: BidirectionalGraph where Base: BidirectionalGraph {
    public typealias IncomingEdges = Base.IncomingEdges
    
    @inlinable
    public func incomingEdges(of vertex: VertexDescriptor) -> IncomingEdges { base.incomingEdges(of: vertex) }
    
    @inlinable
    public func inDegree(of vertex: VertexDescriptor) -> Int { base.inDegree(of: vertex) }
}

extension ComputedEdgePropertyGraph: EdgeMutableGraph where Base: EdgeMutableGraph {
    @discardableResult
    @inlinable
    public mutating func addEdge(from source: VertexDescriptor, to destination: VertexDescriptor) -> EdgeDescriptor? {
        base.addEdge(from: source, to: destination)
    }
    
    #if swift(>=6.2)
    @inlinable
    public mutating func remove(edge: consuming EdgeDescriptor) {
        base.remove(edge: edge)
    }
    #else
    @inlinable
    public mutating func remove(edge: EdgeDescriptor) {
        base.remove(edge: edge)
    }
    #endif
}

extension ComputedEdgePropertyGraph: VertexMutableGraph where Base: VertexMutableGraph {
    @inlinable
    public mutating func addVertex() -> VertexDescriptor {
        base.addVertex()
    }
    
    #if swift(>=6.2)
    @inlinable
    public mutating func remove(vertex: consuming VertexDescriptor) {
        base.remove(vertex: vertex)
    }
    #else
    @inlinable
    public mutating func remove(vertex: VertexDescriptor) {
        base.remove(vertex: vertex)
    }
    #endif
}

extension ComputedEdgePropertyGraph: VertexPropertyGraph where Base: VertexPropertyGraph {
    @inlinable
    public var vertexPropertyMap: Base.VertexPropertyMap { base.vertexPropertyMap }
}

extension ComputedEdgePropertyGraph: VertexMutablePropertyGraph where Base: VertexMutablePropertyGraph {
    @inlinable
    public var vertexPropertyMap: Base.VertexPropertyMap {
        get { base.vertexPropertyMap }
        set { base.vertexPropertyMap = newValue }
    }
}

extension ComputedEdgePropertyGraph: EdgePropertyGraph where Base: EdgePropertyGraph {
    @inlinable
    public var edgePropertyMap: ComputedEdgePropertyMap<Base.EdgePropertyMap, Property> {
        .init(base: base.edgePropertyMap) { edge in
            compute(edge, base)
        }
    }
}

/// A property map that dynamically computes edge properties.
///
/// ComputedEdgePropertyMap wraps a base property map and provides computed properties
/// that are calculated dynamically when accessed.
public struct ComputedEdgePropertyMap<
    Base: PropertyMap,
    Property: EdgeProperty
>: PropertyMap where
    Base.Value: EdgeProperties
{
    public var base: Base
    public let compute: (Base.Key) -> Property.Value

    @inlinable
    public init(base: Base, compute: @escaping (Base.Key) -> Property.Value) {
        self.base = base
        self.compute = compute
    }

    @inlinable
    public subscript(key: Base.Key) -> ComputedEdgeProperties<Base.Value, Property> {
        .init(base: base[key]) {
            compute(key)
        }
    }
}

/// Edge properties that include computed values.
///
/// ComputedEdgeProperties combines base edge properties with computed properties,
/// providing a unified interface for accessing both stored and computed edge data.
public struct ComputedEdgeProperties<Base: EdgeProperties, Property: EdgeProperty>: EdgeProperties {
    public var base: Base
    public let compute: () -> Property.Value

    @inlinable
    public init(base: Base, compute: @escaping () -> Property.Value) {
        self.base = base
        self.compute = compute
    }

    @inlinable
    public subscript<P: EdgeProperty>(property: P.Type) -> P.Value {
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
