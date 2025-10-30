extension Graph {
    /// Creates a computed vertex property graph that dynamically calculates vertex properties.
    ///
    /// - Parameters:
    ///   - property: The type of property to compute
    ///   - compute: A closure that computes the property value for each vertex
    /// - Returns: A computed vertex property graph
    @inlinable
    public func withVertexProperty<Property: VertexProperty>(
        for property: Property.Type = Property.self,
        _ compute: @escaping (VertexDescriptor, Self) -> Property.Value
    ) -> ComputedVertexPropertyGraph<Self, Property> {
        ComputedVertexPropertyGraph(base: self, compute: compute)
    }
}

/// A graph that dynamically computes vertex properties on demand.
///
/// ComputedVertexPropertyGraph wraps a base graph and provides computed vertex properties
/// that are calculated dynamically when accessed. This is useful for properties that
/// are expensive to store but can be computed efficiently on demand.
public struct ComputedVertexPropertyGraph<Base: Graph, Property: VertexProperty> where Base.VertexDescriptor: Hashable {
    public var base: Base
    public let compute: (Base.VertexDescriptor, Base) -> Property.Value
    
    public typealias UnderlyingPropertyMap = DictionaryPropertyMap<Base.VertexDescriptor, VertexPropertyValues>
    @usableFromInline
    var _vertexPropertyMap = UnderlyingPropertyMap(defaultValue: VertexPropertyValues())
    
    @inlinable
    public init(base: Base, compute: @escaping (Base.VertexDescriptor, Base) -> Property.Value) {
        self.base = base
        self.compute = compute
    }
}

extension ComputedVertexPropertyGraph: Graph where Base: Graph {
    public typealias VertexDescriptor = Base.VertexDescriptor
    public typealias EdgeDescriptor = Base.EdgeDescriptor
}

extension ComputedVertexPropertyGraph: VertexListGraph where Base: VertexListGraph {
    public typealias Vertices = Base.Vertices
    
    @inlinable
    public func vertices() -> Vertices { base.vertices() }
    
    @inlinable
    public var vertexCount: Int { base.vertexCount }
}

extension ComputedVertexPropertyGraph: EdgeListGraph where Base: EdgeListGraph {
    public typealias Edges = Base.Edges
    
    @inlinable
    public func edges() -> Edges { base.edges() }
    
    @inlinable
    public var edgeCount: Int { base.edgeCount }
}

extension ComputedVertexPropertyGraph: IncidenceGraph where Base: IncidenceGraph {
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

extension ComputedVertexPropertyGraph: BidirectionalGraph where Base: BidirectionalGraph {
    public typealias IncomingEdges = Base.IncomingEdges
    
    @inlinable
    public func incomingEdges(of vertex: VertexDescriptor) -> IncomingEdges { base.incomingEdges(of: vertex) }
    
    @inlinable
    public func inDegree(of vertex: VertexDescriptor) -> Int { base.inDegree(of: vertex) }
}

extension ComputedVertexPropertyGraph: EdgeMutableGraph where Base: EdgeMutableGraph {
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

extension ComputedVertexPropertyGraph: VertexMutableGraph where Base: VertexMutableGraph {
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

extension ComputedVertexPropertyGraph: EdgePropertyGraph where Base: EdgePropertyGraph {
    public typealias EdgeProperties = Base.EdgeProperties
    public typealias EdgePropertyMap = Base.EdgePropertyMap
    @inlinable
    public var edgePropertyMap: Base.EdgePropertyMap { base.edgePropertyMap }
}

extension ComputedVertexPropertyGraph: EdgeMutablePropertyGraph where Base: EdgeMutablePropertyGraph {
    @inlinable
    public var edgePropertyMap: Base.EdgePropertyMap {
        get { base.edgePropertyMap }
        set { base.edgePropertyMap = newValue }
    }
}

extension ComputedVertexPropertyGraph: VertexPropertyGraph {
    public typealias VertexProperties = ComputedVertexProperties<VertexPropertyValues, Property>
    public typealias VertexPropertyMap = ComputedVertexPropertyMap<UnderlyingPropertyMap, Property>
    @inlinable
    public var vertexPropertyMap: ComputedVertexPropertyMap<UnderlyingPropertyMap, Property> {
        .init(base: _vertexPropertyMap) { vertex in
            compute(vertex, base)
        }
    }
}

/// A property map that dynamically computes vertex properties.
///
/// ComputedVertexPropertyMap wraps a base property map and provides computed properties
/// that are calculated dynamically when accessed.
public struct ComputedVertexPropertyMap<
    Base: PropertyMap,
    Property: VertexProperty
>: PropertyMap where
    Base.Value: VertexProperties
{
    public var base: Base
    public let compute: (Base.Key) -> Property.Value

    @inlinable
    public init(base: Base, compute: @escaping (Base.Key) -> Property.Value) {
        self.base = base
        self.compute = compute
    }

    @inlinable
    public subscript(key: Base.Key) -> ComputedVertexProperties<Base.Value, Property> {
        .init(base: base[key]) {
            compute(key)
        }
    }
}

/// Vertex properties that include computed values.
///
/// ComputedVertexProperties combines base vertex properties with computed properties,
/// providing a unified interface for accessing both stored and computed vertex data.
public struct ComputedVertexProperties<Base: VertexProperties, Property: VertexProperty>: VertexProperties {
    public var base: Base
    public let compute: () -> Property.Value

    @inlinable
    public init(base: Base, compute: @escaping () -> Property.Value) {
        self.base = base
        self.compute = compute
    }

    @inlinable
    public subscript<P: VertexProperty>(property: P.Type) -> P.Value {
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
