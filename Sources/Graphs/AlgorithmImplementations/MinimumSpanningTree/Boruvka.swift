import Foundation

struct Boruvka<
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
        var completeComponentMerge: ((Int) -> Void)?
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
        // Union-Find data structure
        var parent: [Vertex: Vertex] = [:]
        var rank: [Vertex: Int] = [:]
        
        // Initialize all vertices as separate components
        for vertex in graph.vertices() {
            parent[vertex] = vertex
            rank[vertex] = 0
        }
        
        // Find root with path compression
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
        
        // Union by rank
        func union(_ x: Vertex, _ y: Vertex) {
            let rootX = find(x)
            let rootY = find(y)
            
            if rootX == rootY { return }
            
            let rankX = rank[rootX] ?? 0
            let rankY = rank[rootY] ?? 0
            
            if rankX < rankY {
                parent[rootX] = rootY
            } else if rankX > rankY {
                parent[rootY] = rootX
            } else {
                parent[rootY] = rootX
                rank[rootX] = rankX + 1
            }
        }
        
        var mstEdges: [Edge] = []
        var totalWeight = Weight.zero
        var mstVertices: Set<Vertex> = []
        
        // Get all edges
        let allEdges = Array(graph.edges())
        
        // Notify visitor about all edges being examined
        for edge in allEdges {
            visitor?.examineEdge?(edge)
        }
        
        var iteration = 0
        // Repeat until we have one component or no more edges
        while mstEdges.count < graph.vertexCount - 1 && !allEdges.isEmpty {
            // Find minimum weight edge for each component
            var componentMinEdges: [Vertex: (Edge, Weight)] = [:]
            
            for edge in allEdges {
                guard let source = graph.source(of: edge),
                      let destination = graph.destination(of: edge) else { continue }
                
                let sourceRoot = find(source)
                let destRoot = find(destination)
                
                // Skip if both vertices are in the same component
                if sourceRoot == destRoot { continue }
                
                let edgeWeight = edgeWeight.costToExplore(edge, graph)
                
                // Update minimum edge for source component
                if let existing = componentMinEdges[sourceRoot] {
                    if edgeWeight < existing.1 {
                        componentMinEdges[sourceRoot] = (edge, edgeWeight)
                    }
                } else {
                    componentMinEdges[sourceRoot] = (edge, edgeWeight)
                }
                
                // Update minimum edge for destination component
                if let existing = componentMinEdges[destRoot] {
                    if edgeWeight < existing.1 {
                        componentMinEdges[destRoot] = (edge, edgeWeight)
                    }
                } else {
                    componentMinEdges[destRoot] = (edge, edgeWeight)
                }
            }
            
            // Add minimum edges to MST
            var addedAnyEdge = false
            for (_, (edge, edgeWeight)) in componentMinEdges {
                guard let source = graph.source(of: edge),
                      let destination = graph.destination(of: edge) else { continue }
                
                let sourceRoot = find(source)
                let destRoot = find(destination)
                
                // Skip if both vertices are now in the same component
                if sourceRoot == destRoot { 
                    visitor?.skipEdge?(edge, "Vertices already in same component")
                    continue 
                }
                
                // Add edge to MST
                mstEdges.append(edge)
                totalWeight = totalWeight + edgeWeight
                mstVertices.insert(source)
                mstVertices.insert(destination)
                union(source, destination)
                visitor?.addEdge?(edge, edgeWeight)
                visitor?.unionVertices?(source, destination)
                addedAnyEdge = true
            }
            
            visitor?.completeComponentMerge?(iteration)
            iteration += 1
            
            // If no edges were added, break to avoid infinite loop
            if !addedAnyEdge { break }
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

extension Boruvka: VisitorSupporting {}
