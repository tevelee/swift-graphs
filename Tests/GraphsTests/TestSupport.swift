@testable import Graphs

// Shared test-only properties
enum Weight: VertexProperty, EdgeProperty {
    static let defaultValue = 1.0
}

extension VertexPropertyValues {
    var weight: Double {
        get { self[Weight.self] }
        set { self[Weight.self] = newValue }
    }
}

extension EdgePropertyValues {
    var weight: Double {
        get { self[Weight.self] }
        set { self[Weight.self] = newValue }
    }
}


