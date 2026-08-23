/// A protocol for graphs that support mutable vertex properties.
///
/// Vertex mutable property graphs allow both reading and writing vertex properties,
/// enabling dynamic modification of vertex data during graph operations.
public protocol MutableVertexPropertyGraph: VertexPropertyGraph, VertexMutableGraph {
    subscript(vertex: VertexDescriptor) -> VertexProperties { get set }
}

extension MutableVertexPropertyGraph {
    @discardableResult
    @inlinable
    public mutating func addVertex(configure: (inout VertexProperties) -> Void) -> VertexDescriptor {
        let vertex = addVertex()
        var properties = self[vertex]
        configure(&properties)
        self[vertex] = properties
        return vertex
    }
}

/// A protocol for graphs that support mutable edge properties.
///
/// Edge mutable property graphs allow both reading and writing edge properties,
/// enabling dynamic modification of edge data during graph operations.
public protocol MutableEdgePropertyGraph: EdgePropertyGraph, EdgeMutableGraph {
    subscript(edge: EdgeDescriptor) -> EdgeProperties { get set }
}

extension MutableEdgePropertyGraph {
    @discardableResult
    @inlinable
    public mutating func addEdge(
        from source: VertexDescriptor,
        to destination: VertexDescriptor,
        configure: (inout EdgeProperties) -> Void
    ) -> EdgeDescriptor? {
        guard let edge = addEdge(from: source, to: destination) else { return nil }
        var properties = self[edge]
        configure(&properties)
        self[edge] = properties
        return edge
    }
}

/// A protocol for graphs that support mutable properties for both vertices and edges.
///
/// Mutable property graphs combine vertex and edge mutable property capabilities,
/// providing complete flexibility for modifying graph data during operations.
public protocol MutablePropertyGraph: MutableVertexPropertyGraph, MutableEdgePropertyGraph {}

extension MutablePropertyGraph where Self: VertexPropertyGraph {
    /// Adds multiple edges to the graph by creating vertices from labels.
    ///
    /// Vertices with the same label are automatically deduplicated.
    ///
    /// - Parameters:
    ///   - property: A key path to the vertex property used for labeling
    ///   - edges: An array of tuples specifying source and destination labels for each edge
    @inlinable
    public mutating func addEdges<V: Hashable>(
        providing property: WritableKeyPath<VertexProperties, V>,
        edges: [(source: V, destination: V)]
    ) {
        let labelToVertex: [V: VertexDescriptor] = Dictionary(
            grouping: edges.flatMap { [$0.source, $0.destination] },
            by: { $0 }
        )
        .compactMapValues(\.first)
        .mapValues { label in
            addVertex { $0[keyPath: property] = label }
        }

        for (sourceLabel, destinationLabel) in edges {
            let source = labelToVertex[sourceLabel]!
            let destination = labelToVertex[destinationLabel]!
            addEdge(from: source, to: destination)
        }
    }

    /// Adds multiple edges to the graph by creating vertices from labels using a result builder.
    ///
    /// Vertices with the same label are automatically deduplicated.
    ///
    /// - Parameters:
    ///   - property: A key path to the vertex property used for labeling
    ///   - edges: A closure building edges using the `-->` operator
    @inlinable
    public mutating func addEdges<V: Hashable>(
        providing property: WritableKeyPath<VertexProperties, V>,
        @ArrayBuilder<(source: V, destination: V)> edges: () -> [(source: V, destination: V)]
    ) {
        let builtEdges = edges().map { ($0.source, $0.destination) }
        addEdges(providing: property, edges: builtEdges)
    }
}

extension MutablePropertyGraph where Self: VertexPropertyGraph & EdgePropertyGraph {
    /// Adds multiple edges to the graph by creating vertices from labels, with edge property configuration.
    ///
    /// Vertices with the same label are automatically deduplicated.
    ///
    /// - Parameters:
    ///   - property: A key path to the vertex property used for labeling
    ///   - edges: An array of tuples specifying source label, destination label, and a configuration closure for each edge
    @inlinable
    public mutating func addEdges<V: Hashable>(
        providing property: WritableKeyPath<VertexProperties, V>,
        edges: [(source: V, destination: V, configure: (inout EdgeProperties) -> Void)]
    ) {
        let labelToVertex: [V: VertexDescriptor] = Dictionary(
            grouping: edges.flatMap { [$0.source, $0.destination] },
            by: { $0 }
        )
        .compactMapValues(\.first)
        .mapValues { label in
            addVertex { $0[keyPath: property] = label }
        }

        for (sourceLabel, destinationLabel, configure) in edges {
            let source = labelToVertex[sourceLabel]!
            let destination = labelToVertex[destinationLabel]!
            addEdge(from: source, to: destination, configure: configure)
        }
    }

    /// Adds multiple edges to the graph by creating vertices from labels, with edge property configuration using a result builder.
    ///
    /// Vertices with the same label are automatically deduplicated.
    ///
    /// - Parameters:
    ///   - property: A key path to the vertex property used for labeling
    ///   - edges: A closure building edges using the `-->` and `|` operators
    @inlinable
    public mutating func addEdges<V: Hashable>(
        providing property: WritableKeyPath<VertexProperties, V>,
        @ArrayBuilder<(source: V, destination: V, configure: (inout EdgeProperties) -> Void)> edges: () -> [(
            source: V, destination: V, configure: (inout EdgeProperties) -> Void
        )]
    ) {
        let builtEdges = edges().map { ($0.source, $0.destination, $0.configure) }
        addEdges(providing: property, edges: builtEdges)
    }
}
