protocol EdgeProperties {
    subscript<P: EdgeProperty>(property: P.Type) -> P.Value { get set }
}
