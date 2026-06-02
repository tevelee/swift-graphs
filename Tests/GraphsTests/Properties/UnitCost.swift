@testable import Graphs

#if !GRAPHS_USES_TRAITS || GRAPHS_SERIALIZATION
    enum UnitCost: EdgeProperty, SerializableProperty {
        static let defaultValue = 0.0
    }
#else
    enum UnitCost: EdgeProperty {
        static let defaultValue = 0.0
    }
#endif

extension EdgeProperties {
    var unitCost: Double {
        get { self[UnitCost.self] }
        set { self[UnitCost.self] = newValue }
    }
}
