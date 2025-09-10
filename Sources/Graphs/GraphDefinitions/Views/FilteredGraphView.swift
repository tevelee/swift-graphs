import Collections

struct FilteredGraphView<Base: IncidenceGraph>: Graph {
    typealias VertexDescriptor = Base.VertexDescriptor
    typealias EdgeDescriptor = Base.EdgeDescriptor

    let base: Base
    let includeVertex: (VertexDescriptor) -> Bool
    let includeEdge: (EdgeDescriptor) -> Bool
}

extension FilteredGraphView: VertexListGraph where Base: VertexListGraph {
    struct Vertices: Sequence {
        let baseVertices: Base.Vertices
        let predicate: (Base.VertexDescriptor) -> Bool
        func makeIterator() -> Iterator { Iterator(baseIterator: baseVertices.makeIterator(), predicate: predicate) }
        struct Iterator: IteratorProtocol {
            var baseIterator: Base.Vertices.Iterator
            let predicate: (Base.VertexDescriptor) -> Bool
            mutating func next() -> Base.VertexDescriptor? {
                while let v = baseIterator.next() {
                    if predicate(v) { return v }
                }
                return nil
            }
        }
    }
    func vertices() -> Vertices { .init(baseVertices: base.vertices(), predicate: includeVertex) }
    var vertexCount: Int { vertices().reduce(0) { acc, _ in acc + 1 } }
}

extension FilteredGraphView: EdgeListGraph where Base: EdgeListGraph {
    struct Edges: Sequence {
        let baseEdges: Base.Edges
        let predicate: (Base.EdgeDescriptor) -> Bool
        func makeIterator() -> Iterator { Iterator(baseIterator: baseEdges.makeIterator(), predicate: predicate) }
        struct Iterator: IteratorProtocol {
            var baseIterator: Base.Edges.Iterator
            let predicate: (Base.EdgeDescriptor) -> Bool
            mutating func next() -> Base.EdgeDescriptor? {
                while let e = baseIterator.next() {
                    if predicate(e) { return e }
                }
                return nil
            }
        }
    }
    func edges() -> Edges { .init(baseEdges: base.edges(), predicate: includeEdge) }
    var edgeCount: Int { edges().reduce(0) { acc, _ in acc + 1 } }
}

extension FilteredGraphView: IncidenceGraph {
    struct OutgoingEdges: Sequence {
        let base: Base
        let vertex: Base.VertexDescriptor
        let vertexOk: (Base.VertexDescriptor) -> Bool
        let edgeOk: (Base.EdgeDescriptor) -> Bool
        func makeIterator() -> Iterator { Iterator(baseIterator: base.outgoingEdges(of: vertex).makeIterator(), base: base, edgeOk: edgeOk, vertexOk: vertexOk) }
        struct Iterator: IteratorProtocol {
            var baseIterator: Base.OutgoingEdges.Iterator
            let base: Base
            let edgeOk: (Base.EdgeDescriptor) -> Bool
            let vertexOk: (Base.VertexDescriptor) -> Bool
            mutating func next() -> Base.EdgeDescriptor? {
                while let e = baseIterator.next() {
                    guard edgeOk(e), let d = base.destination(of: e), vertexOk(d) else { continue }
                    return e
                }
                return nil
            }
        }
    }
    func outgoingEdges(of vertex: VertexDescriptor) -> OutgoingEdges {
        guard includeVertex(vertex) else { return .init(base: base, vertex: vertex, vertexOk: { _ in false }, edgeOk: { _ in false }) }
        return .init(base: base, vertex: vertex, vertexOk: includeVertex, edgeOk: includeEdge)
    }
    func source(of edge: EdgeDescriptor) -> VertexDescriptor? {
        guard includeEdge(edge), let s = base.source(of: edge), includeVertex(s) else { return nil }
        return s
    }
    func destination(of edge: EdgeDescriptor) -> VertexDescriptor? {
        guard includeEdge(edge), let d = base.destination(of: edge), includeVertex(d) else { return nil }
        return d
    }
    func outDegree(of vertex: VertexDescriptor) -> Int {
        outgoingEdges(of: vertex).count { _ in true }
    }
}


