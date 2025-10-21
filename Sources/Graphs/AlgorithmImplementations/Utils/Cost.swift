/// Represents a cost that can be either finite or infinite.
public enum Cost<Weight> {
    case infinite
    case finite(Weight)
}

extension Cost: Equatable where Weight: Equatable {}

extension Cost: Comparable where Weight: Comparable {
    @inlinable
    public static func < (lhs: Self, rhs: Self) -> Bool {
        switch (lhs, rhs) {
            case (.infinite, _): false
            case (_, .infinite): true
            case (.finite(let lhsValue), .finite(let rhsValue)): lhsValue < rhsValue
        }
    }
}

extension Cost where Weight: AdditiveArithmetic {
    @inlinable
    public static func + (lhs: Self, rhs: Self) -> Self {
        switch (lhs, rhs) {
            case (.infinite, _), (_, .infinite):
                return .infinite
            case (.finite(let lhsValue), .finite(let rhsValue)):
                return .finite(lhsValue + rhsValue)
        }
    }
    
    @inlinable
    public static func + (lhs: Self, rhs: Weight) -> Self {
        switch lhs {
        case .infinite:
            return .infinite
        case .finite(let lhsValue):
            return .finite(lhsValue + rhs)
        }
    }
}

extension Cost: ExpressibleByIntegerLiteral where Weight == UInt {
    @inlinable
    public init(integerLiteral value: Weight) {
        self = .finite(value)
    }
}

extension Cost: ExpressibleByFloatLiteral where Weight == Double {
    @inlinable
    public init(floatLiteral value: Weight) {
        self = .finite(value)
    }
}

extension Cost: ExpressibleByNilLiteral {
    @inlinable
    public init(nilLiteral: ()) {
        self = .infinite
    }
}
