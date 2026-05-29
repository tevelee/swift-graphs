#if !GRAPHS_USES_TRAITS || GRAPHS_SERIALIZATION
import Foundation
#if canImport(FoundationXML)
import FoundationXML
#endif

extension SerializationFormat {
    /// Creates a GraphML format with the specified options.
    ///
    /// - Parameters:
    ///   - directed: Whether the graph is directed (default: true)
    ///   - includeSchema: Whether to include XML schema (default: true)
    /// - Returns: A configured GraphML format serializer
    public static func graphML<G>(
        directed: Bool = true,
        includeSchema: Bool = true
    ) -> Self where Self == GraphMLFormat<G> {
        .init(
            directed: directed,
            includeSchema: includeSchema
        )
    }
}

/// A serialization format for GraphML (XML-based).
///
/// This format allows graphs to be represented in a standardized XML format,
/// supporting complex graph structures and custom data.
public struct GraphMLFormat<G: VertexListGraph & EdgeListGraph & IncidenceGraph>: SerializationFormat where G.VertexDescriptor: SerializableDescriptor {
    private let directed: Bool
    private let includeSchema: Bool
    
    public init(
        directed: Bool = true,
        includeSchema: Bool = true
    ) {
        self.directed = directed
        self.includeSchema = includeSchema
    }
    
    public func serialize(_ graph: G) throws -> Data {
        var xml = "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n"
        
        if includeSchema {
            xml.append("<graphml xmlns=\"http://graphml.graphdrawing.org/xmlns\" xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\" xsi:schemaLocation=\"http://graphml.graphdrawing.org/xmlns http://graphml.graphdrawing.org/xmlns/1.0/graphml.xsd\">\n")
        } else {
            xml.append("<graphml>\n")
        }
        
        let edgeDefaultValue = directed ? "directed" : "undirected"
        xml.append("  <graph edgedefault=\"\(edgeDefaultValue)\">\n")
        
        // Vertices
        for vertex in graph.vertices() {
            let id = vertex.serializedIdentifier
            xml.append("    <node id=\"\(id)\"/>\n")
        }
        
        // Edges
        for edge in graph.edges() {
            guard let source = graph.source(of: edge),
                  let destination = graph.destination(of: edge)
            else {
                throw SerializationError.missingDescriptorIdentifier
            }
            xml.append("    <edge source=\"\(source.serializedIdentifier)\" target=\"\(destination.serializedIdentifier)\"/>\n")
        }

        xml.append("  </graph>\n")
        xml.append("</graphml>")

        guard let data = xml.data(using: .utf8) else {
            throw SerializationError.encodingFailed(NSError(domain: "UTF8", code: -1))
        }
        return data
    }
}

extension DeserializationFormat {
    /// Creates a GraphML format for reading graphs back from GraphML XML.
    ///
    /// - Returns: A GraphML deserialization format targeting graph type `G`.
    public static func graphML<G>() -> Self where Self == GraphMLFormat<G> {
        .init()
    }
}

/// Collects `<node>` and `<edge>` elements from a GraphML document in document order.
private final class GraphMLParserDelegate: NSObject, XMLParserDelegate {
    var nodeIDs: [String] = []
    var edges: [(source: String, target: String)] = []

    func parser(
        _ parser: XMLParser,
        didStartElement elementName: String,
        namespaceURI: String?,
        qualifiedName qName: String?,
        attributes attributeDict: [String: String]
    ) {
        switch elementName {
        case "node":
            if let id = attributeDict["id"] {
                nodeIDs.append(id)
            }
        case "edge":
            if let source = attributeDict["source"], let target = attributeDict["target"] {
                edges.append((source, target))
            }
        default:
            break
        }
    }
}

extension GraphMLFormat: DeserializationFormat where G: MutableGraph {
    /// Reconstructs a graph from GraphML produced by ``serialize(_:)``.
    ///
    /// Reads `<node id="…"/>` and `<edge source="…" target="…"/>` elements. Node ids serve only
    /// as a correspondence map; the reconstructed graph assigns its own descriptors. `<data>`
    /// property values are ignored by structural deserialization.
    public func deserialize(_ data: Data, into graph: inout G) throws {
        let parser = XMLParser(data: data)
        let delegate = GraphMLParserDelegate()
        parser.delegate = delegate
        guard parser.parse() else {
            let reason = parser.parserError.map { "\($0)" } ?? "unknown error"
            throw SerializationError.invalidFormat("malformed GraphML: \(reason)")
        }

        var idMap: [String: G.VertexDescriptor] = [:]
        for id in delegate.nodeIDs {
            idMap[id] = graph.addVertex()
        }
        for edge in delegate.edges {
            guard let source = idMap[edge.source] else {
                throw SerializationError.unknownVertexReference(edge.source)
            }
            guard let target = idMap[edge.target] else {
                throw SerializationError.unknownVertexReference(edge.target)
            }
            _ = graph.addEdge(from: source, to: target)
        }
    }
}

extension GraphMLFormat: PropertySerializationFormat where G: PropertyGraph, G: IncidenceGraph {
    public func serialize(
        _ graph: G,
        vertexProperties: [any GraphProperty.Type],
        edgeProperties: [any GraphProperty.Type]
    ) throws -> Data {
        var xml = "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n"
        
        if includeSchema {
            xml.append("<graphml xmlns=\"http://graphml.graphdrawing.org/xmlns\" xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\" xsi:schemaLocation=\"http://graphml.graphdrawing.org/xmlns http://graphml.graphdrawing.org/xmlns/1.0/graphml.xsd\">\n")
        } else {
            xml.append("<graphml>\n")
        }
        
        let edgeDefaultValue = directed ? "directed" : "undirected"
        xml.append("  <graph edgedefault=\"\(edgeDefaultValue)\">\n")
        
        // Define keys for properties
        let vertexPropertyKeys = generatePropertyKeys(for: vertexProperties)
        let edgePropertyKeys = generatePropertyKeys(for: edgeProperties)
        
        for (keyId, name) in vertexPropertyKeys {
            xml.append("    <key id=\"\(keyId)\" for=\"node\" attr.name=\"\(name)\" attr.type=\"string\"/>\n")
        }
        
        for (keyId, name) in edgePropertyKeys {
            xml.append("    <key id=\"\(keyId)\" for=\"edge\" attr.name=\"\(name)\" attr.type=\"string\"/>\n")
        }
        
        // Vertices
        for vertex in graph.vertices() {
            let id = vertex.serializedIdentifier
            xml.append("    <node id=\"\(id)\">\n")
            let props = extractVertexProperties(
                from: graph,
                vertex: vertex,
                propertyTypes: vertexProperties
            )
            for (keyId, name) in vertexPropertyKeys {
                if let value = props[name] {
                    xml.append("      <data key=\"\(keyId)\">\(escapeXML(value))</data>\n")
                }
            }
            xml.append("    </node>\n")
        }
        
        // Edges
        for edge in graph.edges() {
            guard let source = graph.source(of: edge),
                  let destination = graph.destination(of: edge) else {
                throw SerializationError.missingDescriptorIdentifier
            }

            let sourceId = source.serializedIdentifier
            let targetId = destination.serializedIdentifier
            xml.append("    <edge source=\"\(sourceId)\" target=\"\(targetId)\">\n")
            let props = extractEdgeProperties(
                from: graph,
                edge: edge,
                propertyTypes: edgeProperties
            )
            for (keyId, name) in edgePropertyKeys {
                if let value = props[name] {
                    xml.append("      <data key=\"\(keyId)\">\(escapeXML(value))</data>\n")
                }
            }
            xml.append("    </edge>\n")
        }
        
        xml.append("  </graph>\n")
        xml.append("</graphml>")
        
        guard let data = xml.data(using: .utf8) else {
            throw SerializationError.encodingFailed(NSError(domain: "UTF8", code: -1))
        }
        return data
    }
    
    private func generatePropertyKeys(
        for propertyTypes: [any GraphProperty.Type]
    ) -> [(key: String, value: String)] {
        var keys: [(String, String)] = []
        for (index, propertyType) in propertyTypes.enumerated() {
            let name = "\(propertyType)"
            keys.append(("d\(index)", name))
        }
        return keys
    }
    
    private func escapeXML(_ value: Any) -> String {
        let str = "\(value)"
        return str
            .replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
            .replacingOccurrences(of: "\"", with: "&quot;")
            .replacingOccurrences(of: "'", with: "&apos;")
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
