import Foundation

struct Prim<
    Graph: IncidenceGraph & EdgePropertyGraph & VertexListGraph,
    Weight: AdditiveArithmetic & Comparable
> where
    Graph.VertexDescriptor: Hashable,
    Graph.EdgeDescriptor: Equatable
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
    
    private let edgeWeight: CostDefinition<Graph, Weight>
    private let startVertex: Vertex?
    
    init(
        edgeWeight: CostDefinition<Graph, Weight>,
        startVertex: Vertex? = nil
    ) {
        self.edgeWeight = edgeWeight
        self.startVertex = startVertex
    }
    
    func minimumSpanningTree(on graph: Graph, visitor: Visitor? = nil) -> Result {
        var priorityQueue = PriorityQueue<PriorityItem>()
        var inMST: Set<Vertex> = []
        var mstEdges: [Edge] = []
        var totalWeight = Weight.zero
        
        guard let startVertex = startVertex ?? Array(graph.vertices()).first else {
            // Return empty result for empty graph
            return Result(edges: [], totalWeight: Weight.zero, vertices: [])
        }
        inMST.insert(startVertex)
        visitor?.examineVertex?(startVertex)
        
        for edge in graph.outgoingEdges(of: startVertex) {
            if let destination = graph.destination(of: edge) {
                visitor?.examineEdge?(edge)
                let currentEdgeWeight = edgeWeight.costToExplore(edge, graph)
                priorityQueue.enqueue(PriorityItem(
                    weight: currentEdgeWeight,
                    edge: edge,
                    source: startVertex,
                    destination: destination
                ))
            }
        }
        
        while !priorityQueue.isEmpty && inMST.count < graph.vertexCount {
            guard let currentItem = priorityQueue.dequeue() else { break }
            
            visitor?.examineEdge?(currentItem.edge)
            
            if inMST.contains(currentItem.destination) {
                visitor?.skipEdge?(currentItem.edge, "Destination already in MST")
                continue
            }
            
            // Early termination: if we have n-1 edges, we can stop
            if mstEdges.count == graph.vertexCount - 1 {
                break
            }
            
            mstEdges.append(currentItem.edge)
            totalWeight = totalWeight + currentItem.weight
            inMST.insert(currentItem.destination)
            visitor?.addEdge?(currentItem.edge, currentItem.weight)
            visitor?.examineVertex?(currentItem.destination)
            
            for newEdge in graph.outgoingEdges(of: currentItem.destination) {
                if let newDestination = graph.destination(of: newEdge),
                   !inMST.contains(newDestination) {
                    visitor?.examineEdge?(newEdge)
                    let newEdgeWeight = edgeWeight.costToExplore(newEdge, graph)
                    priorityQueue.enqueue(PriorityItem(
                        weight: newEdgeWeight,
                        edge: newEdge,
                        source: currentItem.destination,
                        destination: newDestination
                    ))
                }
            }
        }
        
        for vertex in graph.vertices() {
            inMST.insert(vertex)
        }
        
        return Result(
            edges: mstEdges,
            totalWeight: totalWeight,
            vertices: inMST
        )
    }
}

extension Prim: VisitorSupporting {}

extension Prim.PriorityItem: Comparable {
    static func < (lhs: Self, rhs: Self) -> Bool {
        lhs.weight < rhs.weight
    }
    
    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.weight == rhs.weight && lhs.edge == rhs.edge
    }
}

