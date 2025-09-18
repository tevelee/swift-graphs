protocol VisitorSupportingSequence {
    associatedtype Visitor: Composable where Visitor.Other == Visitor
    associatedtype Iterator: IteratorProtocol
    
    func makeIterator(visitor: Visitor?) -> Iterator
}

extension VisitorSupportingSequence {
    func withVisitor(_ makeVisitor: @escaping () -> Visitor?) -> VisitorFactoryWrapper<Self, Visitor> {
        VisitorFactoryWrapper(base: self, makeVisitor: makeVisitor)
    }
}

struct VisitorFactoryWrapper<Base, Visitor> {
    let base: Base
    let makeVisitor: () -> Visitor?
}

extension VisitorFactoryWrapper: Sequence where Base: VisitorSupportingSequence, Base.Visitor == Visitor {
    func makeIterator() -> Base.Iterator {
        base.makeIterator(visitor: makeVisitor())
    }
}

extension VisitorFactoryWrapper: VisitorSupportingSequence where Base: VisitorSupportingSequence, Visitor == Base.Visitor {
    func makeIterator(visitor: Base.Visitor?) -> Base.Iterator {
        base.makeIterator(visitor: makeVisitor()?.combined(with: visitor) ?? visitor)
    }
}
