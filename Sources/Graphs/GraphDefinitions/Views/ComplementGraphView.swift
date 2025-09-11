import Collections

struct ComplementGraphView<
    Base: EdgeLookupGraph & VertexListGraph
>: Graph where
    Base.VertexDescriptor: Hashable
{
    typealias VertexDescriptor = Base.VertexDescriptor
    struct EdgeDescriptor: Hashable {
        let source: VertexDescriptor
        let destination: VertexDescriptor
    }
    let base: Base
}

extension ComplementGraphView: VertexListGraph {
    typealias Vertices = Base.Vertices
    func vertices() -> Vertices { base.vertices() }
    var vertexCount: Int { base.vertexCount }
}

extension ComplementGraphView: EdgeListGraph {
    struct Edges: Sequence {
        let base: Base
        func makeIterator() -> Iterator { Iterator(base: base, outer: base.vertices().makeIterator(), inner: nil) }
        struct Iterator: IteratorProtocol {
            let base: Base
            var outer: Base.Vertices.Iterator
            var inner: Base.Vertices.Iterator?
            var currentSource: Base.VertexDescriptor?
            mutating func next() -> EdgeDescriptor? {
                while true {
                    if var innerIt = inner, let s = currentSource {
                        while let d = innerIt.next() {
                            if s == d { continue }
                            if base.edge(from: s, to: d) == nil { inner = innerIt; return EdgeDescriptor(source: s, destination: d) }
                        }
                        inner = nil
                    }
                    guard let s = outer.next() else { return nil }
                    currentSource = s
                    inner = base.vertices().makeIterator()
                }
            }
        }
    }
    func edges() -> Edges { .init(base: base) }
    var edgeCount: Int {
        // Count complement edges by iteration to avoid existential casts
        edges().reduce(0) { acc, _ in acc + 1 }
    }
}

extension ComplementGraphView: IncidenceGraph {
    struct OutgoingEdges: Sequence {
        let base: Base
        let source: Base.VertexDescriptor
        func makeIterator() -> Iterator { Iterator(base: base, source: source, it: base.vertices().makeIterator()) }
        struct Iterator: IteratorProtocol {
            let base: Base
            let source: Base.VertexDescriptor
            var it: Base.Vertices.Iterator
            mutating func next() -> EdgeDescriptor? {
                while let d = it.next() {
                    if d == source { continue }
                    if base.edge(from: source, to: d) == nil { return EdgeDescriptor(source: source, destination: d) }
                }
                return nil
            }
        }
    }
    func outgoingEdges(of vertex: VertexDescriptor) -> OutgoingEdges { .init(base: base, source: vertex) }
    func source(of edge: EdgeDescriptor) -> VertexDescriptor? { edge.source }
    func destination(of edge: EdgeDescriptor) -> VertexDescriptor? { edge.destination }
    func outDegree(of vertex: VertexDescriptor) -> Int {
        var count = 0
        for d in base.vertices() {
            if d == vertex { continue }
            if base.edge(from: vertex, to: d) == nil { count &+= 1 }
        }
        return count
    }
}


