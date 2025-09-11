protocol VertexProperties {
    subscript<P: VertexProperty>(property: P.Type) -> P.Value { get set }
}
