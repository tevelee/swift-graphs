protocol GraphProperty<Value> {
    associatedtype Value

    static var defaultValue: Value { get }
}

protocol VertexProperty<Value>: GraphProperty {}
protocol EdgeProperty<Value>: GraphProperty {}
