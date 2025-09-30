import Foundation

/// A protocol for types that support visitors.
public protocol VisitorSupporting {
    associatedtype Visitor: Composable where Visitor.Other == Visitor
    
    func withVisitor(_ visitor: Visitor) -> VisitorWrapper<Self, Visitor>
}

extension VisitorSupporting {
    @inlinable
    public func withVisitor(_ visitor: Visitor) -> VisitorWrapper<Self, Visitor> {
        .init(base: self, visitor: visitor)
    }
}

/// A wrapper that combines a base type with a visitor.
public struct VisitorWrapper<Base, Visitor> {
    @usableFromInline
    let base: Base
    @usableFromInline
    let visitor: Visitor
    
    @inlinable
    public init(base: Base, visitor: Visitor) {
        self.base = base
        self.visitor = visitor
    }
}

extension VisitorWrapper: VisitorSupporting where Base: VisitorSupporting, Visitor: Composable, Visitor.Other == Visitor {}
