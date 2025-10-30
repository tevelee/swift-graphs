/// Generic result builder for constructing arrays of any type.
@resultBuilder
public struct ArrayBuilder<Element> {
    @inlinable
    public init() {}
    
    @inlinable
    public static func buildExpression(_ expression: Element) -> [Element] {
        [expression]
    }
    
    @inlinable
    public static func buildBlock(_ components: [Element]...) -> [Element] {
        components.flatMap { $0 }
    }
    
    @inlinable
    public static func buildArray(_ components: [[Element]]) -> [Element] {
        components.flatMap { $0 }
    }
    
    @inlinable
    public static func buildOptional(_ component: [Element]?) -> [Element] {
        component ?? []
    }
    
    @inlinable
    public static func buildEither(first component: [Element]) -> [Element] {
        component
    }
    
    @inlinable
    public static func buildEither(second component: [Element]) -> [Element] {
        component
    }
}
