import Foundation

protocol VisitorSupporting {
    associatedtype Visitor: Composable where Visitor.Other == Visitor
    
    func withVisitor(_ visitor: Visitor) -> VisitorWrapper<Self, Visitor>
}

extension VisitorSupporting {
    func withVisitor(_ visitor: Visitor) -> VisitorWrapper<Self, Visitor> {
        .init(base: self, visitor: visitor)
    }
}

struct VisitorWrapper<Base, Visitor> {
    let base: Base
    let visitor: Visitor
}

extension VisitorWrapper: VisitorSupporting where Base: VisitorSupporting, Visitor: Composable, Visitor.Other == Visitor {}
