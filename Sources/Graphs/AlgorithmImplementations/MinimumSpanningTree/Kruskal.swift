import Foundation

struct Kruskal<
    Graph: EdgeListGraph & IncidenceGraph & EdgePropertyGraph & VertexListGraph,
    Weight: AdditiveArithmetic & Comparable
> where
    Graph.VertexDescriptor: Hashable
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
    
    private let edgeWeight: CostDefinition<Graph, Weight>
    
    init(
        edgeWeight: CostDefinition<Graph, Weight>
    ) {
        self.edgeWeight = edgeWeight
    }
    
    func minimumSpanningTree(on graph: Graph, visitor: Visitor? = nil) -> Result {
        var parent: [Vertex: Vertex] = [:]
        var rank: [Vertex: Int] = [:]
        
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
        
        func find(_ vertex: Vertex) -> Vertex {
            guard let currentParent = parent[vertex] else {
                // Initialize if not found
                parent[vertex] = vertex
                return vertex
            }
            
            if currentParent != vertex {
                parent[vertex] = find(currentParent)
            }
            return parent[vertex] ?? vertex
        }
        
        func union(_ firstVertex: Vertex, _ secondVertex: Vertex) {
            let firstRoot = find(firstVertex)
            let secondRoot = find(secondVertex)
            
            if firstRoot == secondRoot { return }
            
            let firstRank = rank[firstRoot] ?? 0
            let secondRank = rank[secondRoot] ?? 0
            
            if firstRank < secondRank {
                parent[firstRoot] = secondRoot
            } else if firstRank > secondRank {
                parent[secondRoot] = firstRoot
            } else {
                parent[secondRoot] = firstRoot
                rank[firstRoot] = firstRank + 1
            }
        }
        
        let sortedEdges = graph.edges().sorted { firstEdge, secondEdge in
            let firstWeight = edgeWeight.costToExplore(firstEdge, graph)
            let secondWeight = edgeWeight.costToExplore(secondEdge, graph)
            return firstWeight < secondWeight
        }
        
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
            let destinationRoot = find(destination)
            
            if sourceRoot != destinationRoot {
                mstEdges.append(edge)
                let currentEdgeWeight = edgeWeight.costToExplore(edge, graph)
                totalWeight = totalWeight + currentEdgeWeight
                mstVertices.insert(source)
                mstVertices.insert(destination)
                union(source, destination)
                visitor?.addEdge?(edge, currentEdgeWeight)
                visitor?.unionVertices?(source, destination)
            } else {
                visitor?.skipEdge?(edge, "Would create cycle")
            }
        }
        
        for vertex in graph.vertices() {
            mstVertices.insert(vertex)
        }
        
        return Result(
            edges: mstEdges,
            totalWeight: totalWeight,
            vertices: mstVertices
        )
    }
}

extension Kruskal: VisitorSupporting {}
