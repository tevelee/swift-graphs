#if !GRAPHS_USES_TRAITS || GRAPHS_SERIALIZATION
/// A protocol for vertex or edge descriptors that can be serialized.
///
/// Conforming types provide a string identifier that uniquely represents
/// the descriptor in serialized output formats.
public protocol SerializableDescriptor {
    /// A string identifier for this descriptor used in serialization.
    ///
    /// This identifier should uniquely identify the descriptor within
    /// the context of a graph and remain consistent across serializations.
    var serializedIdentifier: String { get }
}
#endif
