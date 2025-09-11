protocol GraphProperty<Value> {
    associatedtype Value

    static var defaultValue: Value { get }
}

protocol VertexProperty<Value>: GraphProperty {}
protocol EdgeProperty<Value>: GraphProperty {}

extension Optional: GraphProperty where Wrapped: GraphProperty {
    static var defaultValue: Self { nil }
}
extension Optional: VertexProperty where Wrapped: VertexProperty {}
extension Optional: EdgeProperty where Wrapped: EdgeProperty {}
