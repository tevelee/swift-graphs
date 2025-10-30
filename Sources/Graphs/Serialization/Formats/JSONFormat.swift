import Foundation

extension SerializationFormat {
    /// Creates a JSON format with the specified options.
    ///
    /// - Parameters:
    ///   - prettyPrint: Whether to format with indentation (default: true)
    ///   - includeMetadata: Whether to include metadata (default: true)
    ///   - directed: Whether to mark as directed (default: nil)
    /// - Returns: A configured JSON format serializer
    public static func json<G>(
        prettyPrint: Bool = true,
        includeMetadata: Bool = true,
        directed: Bool? = nil
    ) -> Self where Self == JSONFormat<G> {
        .init(
            prettyPrint: prettyPrint,
            includeMetadata: includeMetadata,
            directed: directed
        )
    }
}

/// A serialization format for JSON.
///
/// This format represents graphs as JSON objects with vertices and edges arrays.
public struct JSONFormat<G: VertexListGraph & EdgeListGraph>: SerializationFormat where G.VertexDescriptor: SerializableDescriptor {
    private let prettyPrint: Bool
    private let includeMetadata: Bool
    private let directed: Bool?
    
    public init(
        prettyPrint: Bool = true,
        includeMetadata: Bool = true,
        directed: Bool? = nil
    ) {
        self.prettyPrint = prettyPrint
        self.includeMetadata = includeMetadata
        self.directed = directed
    }
    
    public func serialize(_ graph: G) throws -> Data {
        var result: [String: Any] = [:]
        
        if includeMetadata {
            if let directed = directed {
                result["directed"] = directed
            }
            result["vertexCount"] = graph.vertexCount
            result["edgeCount"] = graph.edgeCount
        }
        
        // Vertices
        var vertices: [[String: Any]] = []
        for vertex in graph.vertices() {
            let vertexDict: [String: Any] = ["id": vertex.serializedIdentifier]
            vertices.append(vertexDict)
        }
        result["vertices"] = vertices
        
        // Edges (requires IncidenceGraph)
        var edges: [[String: Any]] = []
        if let incidenceGraph = graph as? any IncidenceGraph {
            for edge in graph.edges() {
                if let (sourceId, targetId) = try? extractEdgeEndpoints(incidenceGraph: incidenceGraph, edge: edge) {
                    let edgeDict: [String: Any] = [
                        "source": sourceId,
                        "target": targetId
                    ]
                    edges.append(edgeDict)
                }
            }
        }
        result["edges"] = edges
        
        let jsonData = try JSONSerialization.data(
            withJSONObject: result,
            options: prettyPrint ? [.prettyPrinted, .sortedKeys] : [.sortedKeys]
        )
        return jsonData
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
        
        return (sourceSerializable.serializedIdentifier, destinationSerializable.serializedIdentifier)
    }
}

extension JSONFormat: PropertySerializationFormat where G: PropertyGraph, G: IncidenceGraph {
    public func serialize(
        _ graph: G,
        vertexProperties: [any GraphProperty.Type],
        edgeProperties: [any GraphProperty.Type]
    ) throws -> Data {
        var result: [String: Any] = [:]
        
        if includeMetadata {
            if let directed = directed {
                result["directed"] = directed
            }
            result["vertexCount"] = graph.vertexCount
            result["edgeCount"] = graph.edgeCount
        }
        
        // Vertices
        var vertices: [[String: Any]] = []
        for vertex in graph.vertices() {
            var vertexDict: [String: Any] = ["id": vertex.serializedIdentifier]
            
            let props = extractVertexProperties(
                from: graph,
                vertex: vertex,
                propertyTypes: vertexProperties
            )
            if !props.isEmpty {
                vertexDict["properties"] = props
            }
            
            vertices.append(vertexDict)
        }
        result["vertices"] = vertices
        
        // Edges
        var edges: [[String: Any]] = []
        for edge in graph.edges() {
            guard let source = graph.source(of: edge),
                  let destination = graph.destination(of: edge) else {
                continue
            }
            
            var edgeDict: [String: Any] = [
                "source": source.serializedIdentifier,
                "target": destination.serializedIdentifier
            ]
            
            let props = extractEdgeProperties(
                from: graph,
                edge: edge,
                propertyTypes: edgeProperties
            )
            if !props.isEmpty {
                edgeDict["properties"] = props
            }
            
            edges.append(edgeDict)
        }
        result["edges"] = edges
        
        let jsonData = try JSONSerialization.data(
            withJSONObject: result,
            options: prettyPrint ? [.prettyPrinted, .sortedKeys] : [.sortedKeys]
        )
        return jsonData
    }
    
    private func extractVertexProperties(
        from graph: G,
        vertex: G.VertexDescriptor,
        propertyTypes: [any GraphProperty.Type]
    ) -> [String: Any] {
        guard !propertyTypes.isEmpty else { return [:] }
        
        var result: [String: Any] = [:]
        let propertyMap = graph.vertexPropertyMap
        let props = propertyMap[vertex]
        
        for propertyType in propertyTypes {
            let typeName = "\(propertyType)"
            if let prop = propertyType as? any VertexProperty.Type {
                result[typeName] = props[prop]
            }
        }
        
        return result
    }
    
    private func extractEdgeProperties(
        from graph: G,
        edge: G.EdgeDescriptor,
        propertyTypes: [any GraphProperty.Type]
    ) -> [String: Any] {
        guard !propertyTypes.isEmpty else { return [:] }
        
        var result: [String: Any] = [:]
        let propertyMap = graph.edgePropertyMap
        let props = propertyMap[edge]
        
        for propertyType in propertyTypes {
            let typeName = "\(propertyType)"
            if let prop = propertyType as? any EdgeProperty.Type {
                result[typeName] = props[prop]
            }
        }
        
        return result
    }
}
