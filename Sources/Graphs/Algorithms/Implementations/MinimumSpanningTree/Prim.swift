import Foundation

struct Prim<
    Graph: IncidenceGraph & EdgePropertyGraph & VertexListGraph,
    Weight: Numeric & Comparable
> where
    Graph.VertexDescriptor: Hashable,
    Weight.Magnitude == Weight
{
    typealias Vertex = Graph.VertexDescriptor
    typealias Edge = Graph.EdgeDescriptor
    
    struct Visitor {
        var examineVertex: ((Vertex) -> Void)?
        var examineEdge: ((Edge) -> Void)?
        var addEdge: ((Edge, Weight) -> Void)?
        var skipEdge: ((Edge, String) -> Void)?
    }
    
    struct Result {
        let edges: [Edge]
        let totalWeight: Weight
        let vertices: Set<Vertex>
    }
    
    struct PriorityItem {
        let weight: Weight
        let edge: Edge
        let source: Vertex
        let destination: Vertex
    }
    
    private let graph: Graph
    private let edgeWeight: CostDefinition<Graph, Weight>
    private let startVertex: Vertex?
    
    init(
        on graph: Graph,
        edgeWeight: CostDefinition<Graph, Weight>,
        startVertex: Vertex? = nil
    ) {
        self.graph = graph
        self.edgeWeight = edgeWeight
        self.startVertex = startVertex
    }
    
    func minimumSpanningTree(visitor: Visitor? = nil) -> Result {
        // Priority queue for edges (weight, edge, source, destination)
        var priorityQueue: [PriorityItem] = []
        
        // Track which vertices are in the MST
        var inMST: Set<Vertex> = []
        
        // Track MST edges and total weight
        var mstEdges: [Edge] = []
        var totalWeight = Weight.zero
        
        // Choose starting vertex
        let start = startVertex ?? Array(graph.vertices()).first!
        inMST.insert(start)
        visitor?.examineVertex?(start)
        
        // Add all edges from the starting vertex to the priority queue
        for edge in graph.outgoingEdges(of: start) {
            if let destination = graph.destination(of: edge) {
                visitor?.examineEdge?(edge)
                let edgeWeight = edgeWeight.costToExplore(edge, graph)
                priorityQueue.append(PriorityItem(
                    weight: edgeWeight,
                    edge: edge,
                    source: start,
                    destination: destination
                ))
            }
        }
        
        // Sort priority queue by weight (min-heap simulation)
        priorityQueue.sort { $0.weight < $1.weight }
        
        while !priorityQueue.isEmpty && inMST.count < graph.vertexCount {
            // Get the edge with minimum weight
            let item = priorityQueue.removeFirst()
            
            visitor?.examineEdge?(item.edge)
            
            // Skip if destination is already in MST
            if inMST.contains(item.destination) {
                visitor?.skipEdge?(item.edge, "Destination already in MST")
                continue
            }
            
            // Add edge to MST
            mstEdges.append(item.edge)
            totalWeight = totalWeight + item.weight
            inMST.insert(item.destination)
            visitor?.addEdge?(item.edge, item.weight)
            visitor?.examineVertex?(item.destination)
            
            // Add all edges from the new vertex to the priority queue
            for newEdge in graph.outgoingEdges(of: item.destination) {
                if let newDestination = graph.destination(of: newEdge),
                   !inMST.contains(newDestination) {
                    visitor?.examineEdge?(newEdge)
                    let newEdgeWeight = edgeWeight.costToExplore(newEdge, graph)
                    priorityQueue.append(PriorityItem(
                        weight: newEdgeWeight,
                        edge: newEdge,
                        source: item.destination,
                        destination: newDestination
                    ))
                }
            }
            
            // Re-sort priority queue (in a real implementation, you'd use a proper heap)
            priorityQueue.sort { $0.weight < $1.weight }
        }
        
        // Include all vertices, even those not connected by edges
        for vertex in graph.vertices() {
            inMST.insert(vertex)
        }
        
        let result = Result(
            edges: mstEdges,
            totalWeight: totalWeight,
            vertices: inMST
        )
        
        
        return result
    }
}

// Visitor support
extension Prim {
    func withVisitor(_ makeVisitor: @escaping () -> Visitor) -> PrimWithVisitor<Graph, Weight> {
        .init(base: self, makeVisitor: makeVisitor)
    }
}

struct PrimWithVisitor<Graph: IncidenceGraph & EdgePropertyGraph & VertexListGraph, Weight: Numeric & Comparable>
where Graph.VertexDescriptor: Hashable, Weight.Magnitude == Weight {
    typealias Base = Prim<Graph, Weight>
    let base: Base
    let makeVisitor: () -> Base.Visitor
}

extension PrimWithVisitor {
    func minimumSpanningTree() -> Base.Result {
        base.minimumSpanningTree(visitor: makeVisitor())
    }
}
