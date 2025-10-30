@testable import Graphs

enum Weight: VertexProperty, EdgeProperty, SerializableProperty {
    static let defaultValue = 1.0
}
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
