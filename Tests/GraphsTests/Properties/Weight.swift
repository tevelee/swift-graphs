@testable import Graphs

#if !GRAPHS_USES_TRAITS || GRAPHS_SERIALIZATION
enum Weight: VertexProperty, EdgeProperty, SerializableProperty {
    static let defaultValue = 1.0
}
#else
enum Weight: VertexProperty, EdgeProperty {
    static let defaultValue = 1.0
}
#endif
extension VertexProperties {
    var weight: Double {
        get { self[Weight.self] }
        set { self[Weight.self] = newValue }
    }
}

extension EdgeProperties {
    var weight: Double {
        get { self[Weight.self] }
        set { self[Weight.self] = newValue }
    }
}
