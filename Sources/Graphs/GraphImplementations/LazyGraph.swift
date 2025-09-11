protocol LazyEdge<Vertex> {
    associatedtype Vertex

    var source: Vertex { get }
    var destination: Vertex { get }
}

struct SimpleEdge<Vertex>: LazyEdge {
    let source: Vertex
    let destination: Vertex
}

struct LazyIncidenceGraph<Vertex, Edge: LazyEdge<Vertex>, Edges: Collection<Edge>> {
    let edgeProvider: (VertexDescriptor) -> Edges
    
    init(edges: @escaping (VertexDescriptor) -> Edges) {
        self.edgeProvider = edges
    }
}

extension LazyIncidenceGraph: Graph {
    typealias VertexDescriptor = Vertex
    typealias EdgeDescriptor = Edge
}

extension LazyIncidenceGraph: IncidenceGraph {
    func outgoingEdges(of vertex: Vertex) -> Edges {
        edgeProvider(vertex)
    }
    
    func source(of edge: Edge) -> Vertex? {
        edge.source
    }
    
    func destination(of edge: Edge) -> Vertex? {
        edge.destination
    }
    
    func outDegree(of vertex: Vertex) -> Int {
        edgeProvider(vertex).count
    }
}

extension LazyIncidenceGraph {
    init<Neighbors: Collection<Vertex>>(neighbors: @escaping (VertexDescriptor) -> Neighbors) where Edges == LazyMapCollection<Neighbors, SimpleEdge<Vertex>> {
        self.edgeProvider = { source in
            neighbors(source).lazy.map {
                SimpleEdge(source: source, destination: $0)
            }
        }
    }
}
