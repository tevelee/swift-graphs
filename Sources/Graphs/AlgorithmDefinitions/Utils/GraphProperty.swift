public protocol GraphProperty<Value> {
    associatedtype Value

    static var defaultValue: Value { get }
}

public protocol VertexProperty<Value>: GraphProperty {}
public protocol EdgeProperty<Value>: GraphProperty {}

extension Optional: GraphProperty where Wrapped: GraphProperty {
    @inlinable
    public static var defaultValue: Self { nil }
}
extension Optional: VertexProperty where Wrapped: VertexProperty {}
extension Optional: EdgeProperty where Wrapped: EdgeProperty {}
