import Foundation

/// A utility for serializing graphs into various formats.
///
/// `GraphFormatter` provides a unified interface for converting graph structures
/// and their associated properties into standard serialization formats like
/// DOT, JSON, and GraphML.
///
/// Example usage:
/// ```swift
/// var graph = AdjacencyList<String, Double>()
/// graph.addVertex("A")
/// graph.addVertex("B")
/// graph.addEdge(from: "A", to: "B", weight: 1.0)
///
/// let formatter = GraphFormatter()
///
/// // Serialize to DOT format
/// let dotString = try formatter.string(
///     from: graph,
///     using: .dot(directed: true, graphName: "MyGraph"),
///     vertexProperties: [],
///     edgeProperties: [Weight.self]
/// )
///
/// // Serialize to JSON format
/// let jsonString = try formatter.string(
///     from: graph,
///     using: .json(prettyPrint: true)
/// )
/// ```
public struct GraphFormatter {
    /// Creates a new graph formatter.
    public init() {}
    
    /// Formats the given graph into the specified serialization format.
    ///
    /// - Parameters:
    ///   - graph: The graph to serialize.
    ///   - format: The serialization format to use.
    /// - Returns: `Data` representing the serialized graph.
    /// - Throws: `SerializationError` if serialization fails.
    public func format<F: SerializationFormat>(
        _ graph: F.G,
        using format: F
    ) throws -> Data {
        try format.serialize(graph)
    }
    
    /// Formats the given graph with properties into the specified serialization format.
    ///
    /// - Parameters:
    ///   - graph: The graph to serialize.
    ///   - format: The property serialization format to use.
    ///   - vertexProperties: Array of vertex property types to include.
    ///   - edgeProperties: Array of edge property types to include.
    /// - Returns: `Data` representing the serialized graph.
    /// - Throws: `SerializationError` if serialization fails.
    public func format<F: PropertySerializationFormat>(
        _ graph: F.G,
        using format: F,
        vertexProperties: [any GraphProperty.Type] = [],
        edgeProperties: [any GraphProperty.Type] = []
    ) throws -> Data {
        try format.serialize(graph, vertexProperties: vertexProperties, edgeProperties: edgeProperties)
    }
    
    /// Formats the given graph into a string using the specified serialization format.
    ///
    /// - Parameters:
    ///   - graph: The graph to serialize.
    ///   - format: The serialization format to use.
    /// - Returns: A `String` representing the serialized graph.
    /// - Throws: `SerializationError` if serialization fails or encoding to UTF-8 fails.
    public func string<F: SerializationFormat>(
        from graph: F.G,
        using format: F
    ) throws -> String {
        let data = try format.serialize(graph)
        guard let string = String(data: data, encoding: .utf8) else {
            throw SerializationError.encodingFailed(NSError(domain: "UTF8", code: -1))
        }
        return string
    }
    
    /// Formats the given graph with properties into a string using the specified serialization format.
    ///
    /// - Parameters:
    ///   - graph: The graph to serialize.
    ///   - format: The property serialization format to use.
    ///   - vertexProperties: Array of vertex property types to include.
    ///   - edgeProperties: Array of edge property types to include.
    /// - Returns: A `String` representing the serialized graph.
    /// - Throws: `SerializationError` if serialization fails or encoding to UTF-8 fails.
    public func string<F: PropertySerializationFormat>(
        from graph: F.G,
        using format: F,
        vertexProperties: [any GraphProperty.Type] = [],
        edgeProperties: [any GraphProperty.Type] = []
    ) throws -> String {
        let data = try format.serialize(graph, vertexProperties: vertexProperties, edgeProperties: edgeProperties)
        guard let string = String(data: data, encoding: .utf8) else {
            throw SerializationError.encodingFailed(NSError(domain: "UTF8", code: -1))
        }
        return string
    }
}
