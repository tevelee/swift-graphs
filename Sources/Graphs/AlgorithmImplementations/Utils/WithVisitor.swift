import Foundation

struct VisitorFactoryWrapper<Base, Visitor> {
    let base: Base
    let makeVisitor: () -> Visitor
    
    init(base: Base, makeVisitor: @escaping () -> Visitor) {
        self.base = base
        self.makeVisitor = makeVisitor
    }
}

extension VisitorFactoryWrapper: Sequence where Base: VisitorIteratorSupporting, Base.Visitor == Visitor {
    func makeIterator() -> Base.Iterator {
        base.makeIterator(visitor: makeVisitor())
    }
}

struct VisitorWrapper<Base, Visitor> {
    let base: Base
    let visitor: Visitor
    
    init(base: Base, visitor: Visitor) {
        self.base = base
        self.visitor = visitor
    }
}

protocol SequenceVisitorFactorySupporting {
    associatedtype Visitor
    
    func withVisitor(_ makeVisitor: @escaping () -> Visitor) -> VisitorFactoryWrapper<Self, Visitor>
}

protocol VisitorIteratorSupporting {
    associatedtype Visitor
    associatedtype Iterator: IteratorProtocol
    
    func makeIterator(visitor: Visitor) -> Iterator
}

extension SequenceVisitorFactorySupporting {
    func withVisitor(_ makeVisitor: @escaping () -> Visitor) -> VisitorFactoryWrapper<Self, Visitor> {
        VisitorFactoryWrapper(base: self, makeVisitor: makeVisitor)
    }
}

protocol VisitorSupporting {
    associatedtype Visitor
    
    func withVisitor(_ visitor: Visitor) -> VisitorWrapper<Self, Visitor>
}

extension VisitorSupporting {
    func withVisitor(_ visitor: Visitor) -> VisitorWrapper<Self, Visitor> {
        VisitorWrapper(base: self, visitor: visitor)
    }
}
