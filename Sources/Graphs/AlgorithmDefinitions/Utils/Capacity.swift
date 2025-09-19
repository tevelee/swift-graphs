import Foundation

/// Edge property for representing capacity in flow networks
enum Capacity: EdgeProperty {
    static let defaultValue: Double = 0.0
}

extension EdgeProperties {
    var capacity: Double {
        get { self[Capacity.self] }
        set { self[Capacity.self] = newValue }
    }
}

extension CostDefinition where Graph: EdgePropertyGraph, Cost: Numeric & Comparable {
    static func capacity() -> Self {
        .init { edge, graph in
            let capacity = graph[edge].capacity
            // Convert Double to Cost type
            if let costValue = Cost(exactly: Int(capacity)) {
                return costValue
            } else {
                return .zero
            }
        }
    }
}
