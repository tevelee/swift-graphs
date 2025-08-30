protocol EdgeStorage {
    associatedtype Vertex: Hashable
    associatedtype Edge: Hashable
    associatedtype Edges: Sequence<Edge>

    mutating func addEdge(from source: Vertex, to destination: Vertex) -> Edge
    mutating func remove(edge: Edge)
    func endpoints(of edge: Edge) -> (source: Vertex, destination: Vertex)?
    func edges() -> Edges
    var numberOfEdges: Int { get }

    // Incidence operations
    func outEdges(of vertex: Vertex) -> Edges
    func outDegree(of vertex: Vertex) -> Int
    func inEdges(of vertex: Vertex) -> Edges
    func inDegree(of vertex: Vertex) -> Int
}
