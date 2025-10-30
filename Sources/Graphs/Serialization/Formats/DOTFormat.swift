import Foundation

extension SerializationFormat {
    /// Creates a DOT (Graphviz) format with the specified options.
    ///
    /// - Parameters:
    ///   - directed: Whether the graph is directed (default: true)
    ///   - graphName: The name of the graph (default: "G")
    ///   - strict: Whether to use strict mode (default: false)
    ///   - graphAttributes: Custom graph-level attributes (default: empty)
    ///   - defaultNodeAttributes: Default node attributes (default: empty)
    ///   - defaultEdgeAttributes: Default edge attributes (default: empty)
    /// - Returns: A configured DOT format serializer
    public static func dot<G>(
        directed: Bool = true,
        graphName: String = "G",
        strict: Bool = false,
        graphAttributes: [String: String] = [:],
        defaultNodeAttributes: [String: String] = [:],
        defaultEdgeAttributes: [String: String] = [:]
    ) -> Self where Self == DOTFormat<G> {
        .init(
            directed: directed,
            graphName: graphName,
            strict: strict,
            graphAttributes: graphAttributes,
            defaultNodeAttributes: defaultNodeAttributes,
            defaultEdgeAttributes: defaultEdgeAttributes
        )
    }
}

/// A serialization format for Graphviz DOT files.
///
/// The DOT format is a plain text graph description language used by Graphviz.
/// It supports both directed and undirected graphs with various attributes.
///
/// Example usage:
/// ```swift
/// let formatter = GraphFormatter()
/// let dotString = try formatter.string(
///     from: graph,
///     using: .dot(directed: true, graphName: "MyGraph"),
///     vertexProperties: [Label.self],
///     edgeProperties: [Weight.self]
/// )
/// ```
public struct DOTFormat<G: VertexListGraph & EdgeListGraph>: SerializationFormat where G.VertexDescriptor: SerializableDescriptor {
    private let directed: Bool
    private let graphName: String
    private let strict: Bool
    private let graphAttributes: [String: String]
    private let defaultNodeAttributes: [String: String]
    private let defaultEdgeAttributes: [String: String]
    
    public init(
        directed: Bool = true,
        graphName: String = "G",
        strict: Bool = false,
        graphAttributes: [String: String] = [:],
        defaultNodeAttributes: [String: String] = [:],
        defaultEdgeAttributes: [String: String] = [:]
    ) {
        self.directed = directed
        self.graphName = graphName
        self.strict = strict
        self.graphAttributes = graphAttributes
        self.defaultNodeAttributes = defaultNodeAttributes
        self.defaultEdgeAttributes = defaultEdgeAttributes
    }
    
    public func serialize(_ graph: G) throws -> Data {
        var lines: [String] = []
        
        // Graph declaration
        let strictKeyword = strict ? "strict " : ""
        let graphType = directed ? "digraph" : "graph"
        let edgeOp = directed ? "->" : "--"
        lines.append("\(strictKeyword)\(graphType) \(graphName) {")
        
        // Graph attributes
        if !graphAttributes.isEmpty {
            let attrs = formatAttributes(graphAttributes)
            lines.append("  graph [\(attrs)];")
        }
        
        // Default node attributes
        if !defaultNodeAttributes.isEmpty {
            let attrs = formatAttributes(defaultNodeAttributes)
            lines.append("  node [\(attrs)];")
        }
        
        // Default edge attributes
        if !defaultEdgeAttributes.isEmpty {
            let attrs = formatAttributes(defaultEdgeAttributes)
            lines.append("  edge [\(attrs)];")
        }
        
        // Vertices
        for vertex in graph.vertices() {
            let id = vertexIdentifier(vertex)
            lines.append("  \(id);")
        }
        
        // Edges (requires IncidenceGraph)
        if let incidenceGraph = graph as? any IncidenceGraph {
            for edge in graph.edges() {
                if let (sourceId, targetId) = try? extractEdgeEndpoints(incidenceGraph: incidenceGraph, edge: edge) {
                    lines.append("  \(sourceId) \(edgeOp) \(targetId);")
                }
            }
        }
        
        lines.append("}")
        
        let result = lines.joined(separator: "\n")
        guard let data = result.data(using: .utf8) else {
            throw SerializationError.encodingFailed(NSError(domain: "UTF8", code: -1))
        }
        return data
    }
    
    // MARK: - Private Helpers
    
    private func vertexIdentifier(_ vertex: G.VertexDescriptor) -> String {
        let id = vertex.serializedIdentifier
        // Escape if necessary
        if id.contains(" ") || id.contains("\"") || id.contains("\\") {
            let escaped = id
                .replacingOccurrences(of: "\\", with: "\\\\")
                .replacingOccurrences(of: "\"", with: "\\\"")
            return "\"\(escaped)\""
        }
        return id
    }
    
    private func formatAttributes(_ attrs: [String: String]) -> String {
        attrs.keys.sorted().map { key in
            let value = attrs[key]!
            let escapedValue = value
                .replacingOccurrences(of: "\\", with: "\\\\")
                .replacingOccurrences(of: "\"", with: "\\\"")
            return "\(key)=\"\(escapedValue)\""
        }.joined(separator: ", ")
    }
    
    private func extractEdgeEndpoints(
        incidenceGraph: any IncidenceGraph,
        edge: Any
    ) throws -> (String, String)? {
        return try extractEndpointsHelper(incidenceGraph: incidenceGraph, edge: edge)
    }
    
    private func extractEndpointsHelper<IG: IncidenceGraph>(
        incidenceGraph: IG,
        edge: Any
    ) throws -> (String, String)? {
        guard let typedEdge = edge as? IG.EdgeDescriptor else {
            return nil
        }
        
        guard let source = incidenceGraph.source(of: typedEdge),
              let destination = incidenceGraph.destination(of: typedEdge),
              let sourceSerializable = source as? SerializableDescriptor,
              let destinationSerializable = destination as? SerializableDescriptor else {
            return nil
        }
        
        let sourceId = vertexIdentifier(sourceSerializable)
        let destinationId = vertexIdentifier(destinationSerializable)
        
        return (sourceId, destinationId)
    }
    
    private func vertexIdentifier(_ serializable: SerializableDescriptor) -> String {
        let id = serializable.serializedIdentifier
        // Escape if necessary
        if id.contains(" ") || id.contains("\"") || id.contains("\\") {
            let escaped = id
                .replacingOccurrences(of: "\\", with: "\\\\")
                .replacingOccurrences(of: "\"", with: "\\\"")
            return "\"\(escaped)\""
        }
        return id
    }
}

extension DOTFormat: PropertySerializationFormat where G: PropertyGraph, G: IncidenceGraph {
    public func serialize(
        _ graph: G,
        vertexProperties: [any GraphProperty.Type],
        edgeProperties: [any GraphProperty.Type]
    ) throws -> Data {
        var lines: [String] = []
        
        // Graph declaration
        let strictKeyword = strict ? "strict " : ""
        let graphType = directed ? "digraph" : "graph"
        let edgeOp = directed ? "->" : "--"
        lines.append("\(strictKeyword)\(graphType) \(graphName) {")
        
        // Graph attributes
        if !graphAttributes.isEmpty {
            let attrs = formatAttributes(graphAttributes)
            lines.append("  graph [\(attrs)];")
        }
        
        // Default node attributes
        if !defaultNodeAttributes.isEmpty {
            let attrs = formatAttributes(defaultNodeAttributes)
            lines.append("  node [\(attrs)];")
        }
        
        // Default edge attributes
        if !defaultEdgeAttributes.isEmpty {
            let attrs = formatAttributes(defaultEdgeAttributes)
            lines.append("  edge [\(attrs)];")
        }
        
        // Vertices
        for vertex in graph.vertices() {
            let id = vertexIdentifier(vertex)
            let attributes = extractVertexProperties(
                from: graph,
                vertex: vertex,
                propertyTypes: vertexProperties
            )
            
            if attributes.isEmpty {
                lines.append("  \(id);")
            } else {
                let attrs = formatAttributes(attributes)
                lines.append("  \(id) [\(attrs)];")
            }
        }
        
        // Edges
        for edge in graph.edges() {
            guard let source = graph.source(of: edge),
                  let destination = graph.destination(of: edge) else {
                continue
            }
            
            let sourceId = vertexIdentifier(source)
            let destinationId = vertexIdentifier(destination)
            let attributes = extractEdgeProperties(
                from: graph,
                edge: edge,
                propertyTypes: edgeProperties
            )
            
            if attributes.isEmpty {
                lines.append("  \(sourceId) \(edgeOp) \(destinationId);")
            } else {
                let attrs = formatAttributes(attributes)
                lines.append("  \(sourceId) \(edgeOp) \(destinationId) [\(attrs)];")
            }
        }
        
        lines.append("}")
        
        let result = lines.joined(separator: "\n")
        guard let data = result.data(using: .utf8) else {
            throw SerializationError.encodingFailed(NSError(domain: "UTF8", code: -1))
        }
        return data
    }
    
    private func extractVertexProperties(
        from graph: G,
        vertex: G.VertexDescriptor,
        propertyTypes: [any GraphProperty.Type]
    ) -> [String: String] {
        guard !propertyTypes.isEmpty else { return [:] }
        
        var result: [String: String] = [:]
        let propertyMap = graph.vertexPropertyMap
        let props = propertyMap[vertex]
        
        for propertyType in propertyTypes {
            let typeName = "\(propertyType)"
            if let prop = propertyType as? any VertexProperty.Type {
                result[typeName] = "\(props[prop])"
            }
        }
        
        return result
    }
    
    private func extractEdgeProperties(
        from graph: G,
        edge: G.EdgeDescriptor,
        propertyTypes: [any GraphProperty.Type]
    ) -> [String: String] {
        guard !propertyTypes.isEmpty else { return [:] }
        
        var result: [String: String] = [:]
        let propertyMap = graph.edgePropertyMap
        let props = propertyMap[edge]
        
        for propertyType in propertyTypes {
            let typeName = "\(propertyType)"
            if let prop = propertyType as? any EdgeProperty.Type {
                result[typeName] = "\(props[prop])"
            }
        }
        
        return result
    }
}
