protocol GraphProperty<Value> {
    associatedtype Value

    static var defaultValue: Value { get }
}
