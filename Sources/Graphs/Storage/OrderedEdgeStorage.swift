import Collections
import Foundation

extension EdgeStorage {
    static func ordered<Vertex>() -> OrderedEdgeStorage<Vertex> where Self == OrderedEdgeStorage<Vertex> {
        OrderedEdgeStorage()
    }
}

struct OrderedEdgeStorage<Vertex: Hashable>: EdgeStorage {
    struct Edge: Identifiable, Hashable {
        private let _id: UUID

        var id: some Hashable { _id }

        fileprivate init() {
            _id = UUID()
        }
    }

    private var _edges: OrderedDictionary<Edge, (source: Vertex, destination: Vertex)> = [:]

    var numberOfEdges: Int {
        _edges.count
    }

    func edges() -> OrderedSet<Edge> {
        _edges.keys
    }

    func endpoints(of edge: Edge) -> (source: Vertex, destination: Vertex)? {
        _edges[edge]
    }

    func outEdges(of vertex: Vertex) -> OrderedSet<Edge> {
        _edges.filter { $0.value.source == vertex }.keys
    }

    func outDegree(of vertex: Vertex) -> Int {
        outEdges(of: vertex).count
    }

    func inEdges(of vertex: Vertex) -> OrderedSet<Edge> {
        _edges.filter { $0.value.destination == vertex }.keys
    }

    func inDegree(of vertex: Vertex) -> Int {
        inEdges(of: vertex).count
    }

    mutating func addEdge(from source: Vertex, to destination: Vertex) -> Edge {
        let edge = Edge()
        _edges[edge] = (source, destination)
        return edge
    }
    
    mutating func remove(edge: Edge) {
        _edges[edge] = nil
    }
}
