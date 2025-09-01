protocol GraphProperty<Component> {
    associatedtype Component: GraphComponent
    associatedtype Value

    static var defaultValue: Value { get }
}

protocol VertexProperty: GraphProperty where Component == VertexMarker {}
protocol EdgeProperty: GraphProperty where Component == EdgeMarker {}
