import Foundation

struct Prim<
    Graph: IncidenceGraph & EdgePropertyGraph & VertexListGraph,
    Weight: AdditiveArithmetic & Comparable
> where
    Graph.VertexDescriptor: Hashable
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
        var priorityQueue: [PriorityItem] = []
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
                priorityQueue.append(PriorityItem(
                    weight: currentEdgeWeight,
                    edge: edge,
                    source: startVertex,
                    destination: destination
                ))
            }
        }
        
        priorityQueue.sort { $0.weight < $1.weight }
        
        while !priorityQueue.isEmpty && inMST.count < graph.vertexCount {
            let currentItem = priorityQueue.removeFirst()
            
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
                    priorityQueue.append(PriorityItem(
                        weight: newEdgeWeight,
                        edge: newEdge,
                        source: currentItem.destination,
                        destination: newDestination
                    ))
                }
            }
            
            priorityQueue.sort { $0.weight < $1.weight }
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
