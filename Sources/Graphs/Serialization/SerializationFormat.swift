#if !GRAPHS_USES_TRAITS || GRAPHS_SERIALIZATION
    import Foundation

    /// A protocol for graph serialization formats.
    ///
    /// Conformers require an ``IncidenceGraph`` so that every edge's endpoints can be resolved
    /// directly; this lets serialization fail loudly (throwing ``SerializationError``) rather than
    /// silently dropping edges whose endpoints cannot be determined.
    public protocol SerializationFormat {
        associatedtype G: VertexListGraph & EdgeListGraph & IncidenceGraph where G.VertexDescriptor: SerializableDescriptor

        func serialize(_ graph: G) throws -> Data
    }

    public protocol PropertySerializationFormat: SerializationFormat where G: PropertyGraph, G: IncidenceGraph {
        func serialize(
            _ graph: G,
            vertexProperties: [any GraphProperty.Type],
            edgeProperties: [any GraphProperty.Type]
        ) throws -> Data
    }

    /// A protocol for graph deserialization formats (data → graph).
    ///
    /// Deserialization is the inverse of ``SerializationFormat``: it reads serialized
    /// `Data` and reconstructs the graph's structure into a mutable graph. Vertices are
    /// created in the order they appear and their serialized identifiers are used purely
    /// as a correspondence map so edges can be reconnected to the right vertices — the
    /// reconstructed graph assigns its own fresh descriptors.
    public protocol DeserializationFormat {
        /// The mutable graph type that vertices and edges are added to.
        associatedtype G: MutableGraph

        /// Reads a graph from `data`, adding its vertices and edges into `graph`.
        ///
        /// - Parameters:
        ///   - data: The serialized representation to read.
        ///   - graph: The mutable graph to populate. Existing contents are preserved;
        ///     deserialized vertices and edges are appended.
        /// - Throws: ``SerializationError`` if the data is malformed or references an unknown vertex.
        func deserialize(_ data: Data, into graph: inout G) throws
    }

    /// Errors that can occur during graph serialization or deserialization.
    public enum SerializationError: Error, CustomStringConvertible {
        case missingDescriptorIdentifier
        case unsupportedPropertyType(String)
        case encodingFailed(Error)
        case invalidFormat(String)
        case unknownVertexReference(String)

        public var description: String {
            switch self {
                case .missingDescriptorIdentifier:
                    return "Descriptor does not conform to SerializableDescriptor"
                case .unsupportedPropertyType(let type):
                    return "Property type '\(type)' is not Codable"
                case .encodingFailed(let error):
                    return "Encoding failed: \(error)"
                case .invalidFormat(let detail):
                    return "Invalid serialized format: \(detail)"
                case .unknownVertexReference(let id):
                    return "Edge references unknown vertex id '\(id)'"
            }
        }
    }
#endif
