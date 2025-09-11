import Foundation

struct Kruskal<
    Graph: EdgeListGraph & IncidenceGraph & EdgePropertyGraph & VertexListGraph,
    Weight: Numeric & Comparable
> where
    Graph.VertexDescriptor: Hashable,
    Weight.Magnitude == Weight
{
    typealias Vertex = Graph.VertexDescriptor
    typealias Edge = Graph.EdgeDescriptor
    
    struct Visitor {
        var examineEdge: ((Edge) -> Void)?
        var addEdge: ((Edge, Weight) -> Void)?
        var skipEdge: ((Edge, String) -> Void)?
        var unionVertices: ((Vertex, Vertex) -> Void)?
    }
    
    struct Result {
        let edges: [Edge]
        let totalWeight: Weight
        let vertices: Set<Vertex>
    }
    
    private let graph: Graph
    private let edgeWeight: CostDefinition<Graph, Weight>
    
    init(
        on graph: Graph,
        edgeWeight: CostDefinition<Graph, Weight>
    ) {
        self.graph = graph
        self.edgeWeight = edgeWeight
    }
    
    func minimumSpanningTree(visitor: Visitor? = nil) -> Result {
        // Union-Find data structure for cycle detection
        var parent: [Vertex: Vertex] = [:]
        var rank: [Vertex: Int] = [:]
        
        // Initialize all vertices as separate sets
        for vertex in graph.vertices() {
            parent[vertex] = vertex
            rank[vertex] = 0
        }
        
        for edge in graph.edges() {
            if let source = graph.source(of: edge), let destination = graph.destination(of: edge) {
                parent[source] = source
                parent[destination] = destination
                rank[source] = 0
                rank[destination] = 0
            }
        }
        
        // Find root with path compression
        func find(_ vertex: Vertex) -> Vertex {
            if parent[vertex] != vertex {
                parent[vertex] = find(parent[vertex]!)
            }
            return parent[vertex]!
        }
        
        // Union by rank
        func union(_ x: Vertex, _ y: Vertex) {
            let rootX = find(x)
            let rootY = find(y)
            
            if rootX == rootY { return }
            
            if rank[rootX]! < rank[rootY]! {
                parent[rootX] = rootY
            } else if rank[rootX]! > rank[rootY]! {
                parent[rootY] = rootX
            } else {
                parent[rootY] = rootX
                rank[rootX]! += 1
            }
        }
        
        // Sort edges by weight
        let sortedEdges = graph.edges().sorted { edge1, edge2 in
            let weight1 = edgeWeight.costToExplore(edge1, graph)
            let weight2 = edgeWeight.costToExplore(edge2, graph)
            return weight1 < weight2
        }
        
        // Notify visitor about all edges being examined
        for edge in sortedEdges {
            visitor?.examineEdge?(edge)
        }
        
        var mstEdges: [Edge] = []
        var totalWeight = Weight.zero
        var mstVertices: Set<Vertex> = []
        
        for edge in sortedEdges {
            guard let source = graph.source(of: edge),
                  let destination = graph.destination(of: edge) else { continue }
            
            let sourceRoot = find(source)
            let destRoot = find(destination)
            
            // If including this edge doesn't create a cycle
            if sourceRoot != destRoot {
                mstEdges.append(edge)
                let edgeWeight = edgeWeight.costToExplore(edge, graph)
                totalWeight = totalWeight + edgeWeight
                mstVertices.insert(source)
                mstVertices.insert(destination)
                union(source, destination)
                visitor?.addEdge?(edge, edgeWeight)
                visitor?.unionVertices?(source, destination)
            } else {
                visitor?.skipEdge?(edge, "Would create cycle")
            }
        }
        
        // Include all vertices, even those not connected by edges
        for vertex in graph.vertices() {
            mstVertices.insert(vertex)
        }
        
        let result = Result(
            edges: mstEdges,
            totalWeight: totalWeight,
            vertices: mstVertices
        )
        
        
        return result
    }
}

// Visitor support
extension Kruskal {
    func withVisitor(_ makeVisitor: @escaping () -> Visitor) -> KruskalWithVisitor<Graph, Weight> {
        .init(base: self, makeVisitor: makeVisitor)
    }
}

struct KruskalWithVisitor<Graph: EdgeListGraph & IncidenceGraph & EdgePropertyGraph & VertexListGraph, Weight: Numeric & Comparable>
where Graph.VertexDescriptor: Hashable, Weight.Magnitude == Weight {
    typealias Base = Kruskal<Graph, Weight>
    let base: Base
    let makeVisitor: () -> Base.Visitor
}

extension KruskalWithVisitor {
    func minimumSpanningTree() -> Base.Result {
        base.minimumSpanningTree(visitor: makeVisitor())
    }
}
