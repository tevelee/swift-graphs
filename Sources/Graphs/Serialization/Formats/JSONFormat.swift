#if !GRAPHS_USES_TRAITS || GRAPHS_SERIALIZATION
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
public struct JSONFormat<G: VertexListGraph & EdgeListGraph & IncidenceGraph>: SerializationFormat where G.VertexDescriptor: SerializableDescriptor {
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
        
        // Edges
        var edges: [[String: Any]] = []
        for edge in graph.edges() {
            guard let source = graph.source(of: edge),
                  let destination = graph.destination(of: edge)
            else {
                throw SerializationError.missingDescriptorIdentifier
            }
            edges.append([
                "source": source.serializedIdentifier,
                "target": destination.serializedIdentifier
            ])
        }
        result["edges"] = edges

        let jsonData = try JSONSerialization.data(
            withJSONObject: result,
            options: prettyPrint ? [.prettyPrinted, .sortedKeys] : [.sortedKeys]
        )
        return jsonData
    }
}

extension DeserializationFormat {
    /// Creates a JSON format for reading graphs back from JSON produced by ``SerializationFormat/json(prettyPrint:includeMetadata:directed:)``.
    ///
    /// - Returns: A JSON deserialization format targeting graph type `G`.
    public static func json<G>() -> Self where Self == JSONFormat<G> {
        .init()
    }
}

extension JSONFormat: DeserializationFormat where G: MutableGraph {
    /// Reconstructs a graph from JSON produced by ``serialize(_:)``.
    ///
    /// Reads the `vertices` and `edges` arrays, creating a vertex per `id` and an edge per
    /// `source`/`target` pair. Vertex ids serve only as a correspondence map; the reconstructed
    /// graph assigns its own descriptors. Properties, if present, are ignored by structural
    /// deserialization.
    public func deserialize(_ data: Data, into graph: inout G) throws {
        let object: Any
        do {
            object = try JSONSerialization.jsonObject(with: data)
        } catch {
            throw SerializationError.invalidFormat("not valid JSON: \(error)")
        }
        guard let root = object as? [String: Any] else {
            throw SerializationError.invalidFormat("expected a top-level JSON object")
        }

        var idMap: [String: G.VertexDescriptor] = [:]
        let vertices = root["vertices"] as? [[String: Any]] ?? []
        for vertex in vertices {
            guard let id = vertex["id"] as? String else {
                throw SerializationError.invalidFormat("vertex entry missing string 'id'")
            }
            idMap[id] = graph.addVertex()
        }

        let edges = root["edges"] as? [[String: Any]] ?? []
        for edge in edges {
            guard let sourceId = edge["source"] as? String,
                  let targetId = edge["target"] as? String
            else {
                throw SerializationError.invalidFormat("edge entry missing string 'source'/'target'")
            }
            guard let source = idMap[sourceId] else {
                throw SerializationError.unknownVertexReference(sourceId)
            }
            guard let target = idMap[targetId] else {
                throw SerializationError.unknownVertexReference(targetId)
            }
            _ = graph.addEdge(from: source, to: target)
        }
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
                throw SerializationError.missingDescriptorIdentifier
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
#endif
