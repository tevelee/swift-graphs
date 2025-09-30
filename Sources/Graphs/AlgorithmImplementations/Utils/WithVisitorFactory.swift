public protocol VisitorSupportingSequence {
    associatedtype Visitor: Composable where Visitor.Other == Visitor
    associatedtype Iterator: IteratorProtocol
    
    func makeIterator(visitor: Visitor?) -> Iterator
}

extension VisitorSupportingSequence {
    @inlinable
    public func withVisitor(_ makeVisitor: @escaping () -> Visitor?) -> VisitorFactoryWrapper<Self, Visitor> {
        VisitorFactoryWrapper(base: self, makeVisitor: makeVisitor)
    }
}

public struct VisitorFactoryWrapper<Base, Visitor> {
    @usableFromInline
    let base: Base
    @usableFromInline
    let makeVisitor: () -> Visitor?
    
    @inlinable
    public init(base: Base, makeVisitor: @escaping () -> Visitor?) {
        self.base = base
        self.makeVisitor = makeVisitor
    }
}

extension VisitorFactoryWrapper: Sequence where Base: VisitorSupportingSequence, Base.Visitor == Visitor {
    @inlinable
    public func makeIterator() -> Base.Iterator {
        base.makeIterator(visitor: makeVisitor())
    }
}

extension VisitorFactoryWrapper: VisitorSupportingSequence where Base: VisitorSupportingSequence, Visitor == Base.Visitor {
    @inlinable
    public func makeIterator(visitor: Base.Visitor?) -> Base.Iterator {
        base.makeIterator(visitor: makeVisitor()?.combined(with: visitor) ?? visitor)
    }
}
