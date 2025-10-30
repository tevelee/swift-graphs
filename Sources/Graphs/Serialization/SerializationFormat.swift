import Foundation

/// A protocol for graph serialization formats.
public protocol SerializationFormat {
    associatedtype G: VertexListGraph & EdgeListGraph where G.VertexDescriptor: SerializableDescriptor

    func serialize(_ graph: G) throws -> Data
}

public protocol PropertySerializationFormat: SerializationFormat where G: PropertyGraph, G: IncidenceGraph {
    func serialize(
        _ graph: G,
        vertexProperties: [any GraphProperty.Type],
        edgeProperties: [any GraphProperty.Type]
    ) throws -> Data
}

/// Errors that can occur during graph serialization.
public enum SerializationError: Error, CustomStringConvertible {
    case missingDescriptorIdentifier
    case unsupportedPropertyType(String)
    case encodingFailed(Error)
    
    public var description: String {
        switch self {
        case .missingDescriptorIdentifier:
            return "Descriptor does not conform to SerializableDescriptor"
        case .unsupportedPropertyType(let type):
            return "Property type '\(type)' is not Codable"
        case .encodingFailed(let error):
            return "Encoding failed: \(error)"
        }
    }
}

