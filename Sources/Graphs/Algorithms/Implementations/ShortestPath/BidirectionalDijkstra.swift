import Foundation

struct BidirectionalDijkstra<
    Graph: IncidenceGraph & BidirectionalGraph & EdgePropertyGraph,
    Weight: Numeric & Comparable
> where
    Graph.VertexDescriptor: Hashable,
    Weight.Magnitude == Weight
{
    typealias Vertex = Graph.VertexDescriptor
    typealias Edge = Graph.EdgeDescriptor
    
    
    struct Result {
        let path: Path<Vertex, Edge>?
        let totalDistance: Cost<Weight>
        let meetingVertex: Vertex?
    }
    
    private let graph: Graph
    private let edgeWeight: CostDefinition<Graph, Weight>
    private let makePriorityQueue: () -> any QueueProtocol<PriorityItem>
    
    struct PriorityItem {
        let vertex: Vertex
        let cost: Cost<Weight>
        let direction: Direction
    }
    
    enum Direction {
        case forward
        case backward
    }
    
    init(
        on graph: Graph,
        edgeWeight: CostDefinition<Graph, Weight>,
        makePriorityQueue: @escaping () -> any QueueProtocol<PriorityItem> = {
            PriorityQueue()
        }
    ) {
        self.graph = graph
        self.edgeWeight = edgeWeight
        self.makePriorityQueue = makePriorityQueue
    }
    
    func shortestPath(from source: Vertex, to destination: Vertex) -> Result {
        var forwardDistances: [Vertex: Cost<Weight>] = [:]
        var backwardDistances: [Vertex: Cost<Weight>] = [:]
        var forwardPredecessors: [Vertex: Edge?] = [:]
        var backwardPredecessors: [Vertex: Edge?] = [:]
        var forwardVisited: Set<Vertex> = []
        var backwardVisited: Set<Vertex> = []
        
        var queue = makePriorityQueue()
        
        // Initialize
        forwardDistances[source] = .finite(.zero)
        backwardDistances[destination] = .finite(.zero)
        forwardPredecessors[source] = nil
        backwardPredecessors[destination] = nil
        
        queue.enqueue(PriorityItem(vertex: source, cost: .finite(.zero), direction: .forward))
        queue.enqueue(PriorityItem(vertex: destination, cost: .finite(.zero), direction: .backward))
        
        var bestDistance: Cost<Weight> = .infinite
        var meetingVertex: Vertex?
        
        while let item = queue.dequeue() {
            let current = item.vertex
            let currentCost = item.cost
            let direction = item.direction
            
            // Check if we've already processed this vertex in this direction
            if direction == .forward && forwardVisited.contains(current) { continue }
            if direction == .backward && backwardVisited.contains(current) { continue }
            
            // Verify this is still the best cost for this vertex
            let storedCost = direction == .forward ? forwardDistances[current] : backwardDistances[current]
            if currentCost != storedCost { continue }
            
            // Mark as visited
            if direction == .forward {
                forwardVisited.insert(current)
            } else {
                backwardVisited.insert(current)
            }
            
            // Check if we've found a meeting point
            if direction == .forward && backwardVisited.contains(current) {
                let backwardCost = backwardDistances[current] ?? .infinite
                if case .finite(let currentWeight) = currentCost,
                   case .finite(let backwardWeight) = backwardCost {
                    let totalCost = currentWeight + backwardWeight
                    if case .finite(let bestWeight) = bestDistance {
                        if totalCost < bestWeight {
                            bestDistance = .finite(totalCost)
                            meetingVertex = current
                        }
                    } else {
                        bestDistance = .finite(totalCost)
                        meetingVertex = current
                    }
                }
            } else if direction == .backward && forwardVisited.contains(current) {
                let forwardCost = forwardDistances[current] ?? .infinite
                if case .finite(let currentWeight) = currentCost,
                   case .finite(let forwardWeight) = forwardCost {
                    let totalCost = forwardWeight + currentWeight
                    if case .finite(let bestWeight) = bestDistance {
                        if totalCost < bestWeight {
                            bestDistance = .finite(totalCost)
                            meetingVertex = current
                        }
                    } else {
                        bestDistance = .finite(totalCost)
                        meetingVertex = current
                    }
                }
            }
            
            // Early termination if we've found a path and processed enough vertices
            if case .finite = bestDistance {
                // Continue for a few more iterations to ensure optimality
                // This is a simplified implementation
            }
            
            // Explore neighbors
            if direction == .forward {
                exploreForward(
                    from: current,
                    currentCost: currentCost,
                    distances: &forwardDistances,
                    predecessors: &forwardPredecessors,
                    queue: &queue
                )
            } else {
                exploreBackward(
                    from: current,
                    currentCost: currentCost,
                    distances: &backwardDistances,
                    predecessors: &backwardPredecessors,
                    queue: &queue
                )
            }
        }
        
        // Reconstruct path if we found one
        let path = meetingVertex.map { reconstructPath(
            from: source,
            to: destination,
            meetingVertex: $0,
            forwardPredecessors: forwardPredecessors,
            backwardPredecessors: backwardPredecessors
        )}
        
        return Result(
            path: path,
            totalDistance: bestDistance,
            meetingVertex: meetingVertex
        )
    }
    
    private func exploreForward(
        from current: Vertex,
        currentCost: Cost<Weight>,
        distances: inout [Vertex: Cost<Weight>],
        predecessors: inout [Vertex: Edge?],
        queue: inout any QueueProtocol<PriorityItem>
    ) {
        for edge in graph.outgoingEdges(of: current) {
            guard let neighbor = graph.destination(of: edge) else { continue }
            
            let weight = edgeWeight.costToExplore(edge, graph)
            let newCost = currentCost + weight
            
            let currentBestCost = distances[neighbor]
            if currentBestCost == nil || newCost < currentBestCost! {
                distances[neighbor] = newCost
                predecessors[neighbor] = edge
                queue.enqueue(PriorityItem(vertex: neighbor, cost: newCost, direction: .forward))
            }
        }
    }
    
    private func exploreBackward(
        from current: Vertex,
        currentCost: Cost<Weight>,
        distances: inout [Vertex: Cost<Weight>],
        predecessors: inout [Vertex: Edge?],
        queue: inout any QueueProtocol<PriorityItem>
    ) {
        for edge in graph.incomingEdges(of: current) {
            guard let neighbor = graph.source(of: edge) else { continue }
            
            let weight = edgeWeight.costToExplore(edge, graph)
            let newCost = currentCost + weight
            
            let currentBestCost = distances[neighbor]
            if currentBestCost == nil || newCost < currentBestCost! {
                distances[neighbor] = newCost
                predecessors[neighbor] = edge
                queue.enqueue(PriorityItem(vertex: neighbor, cost: newCost, direction: .backward))
            }
        }
    }
    
    private func reconstructPath(
        from source: Vertex,
        to destination: Vertex,
        meetingVertex: Vertex,
        forwardPredecessors: [Vertex: Edge?],
        backwardPredecessors: [Vertex: Edge?]
    ) -> Path<Vertex, Edge> {
        // Reconstruct forward path from source to meeting vertex
        var forwardVertices: [Vertex] = [meetingVertex]
        var forwardEdges: [Edge] = []
        
        var current = meetingVertex
        while let edge = forwardPredecessors[current] {
            forwardEdges.insert(edge!, at: 0)
            guard let predecessor = graph.source(of: edge!) else { break }
            if predecessor == source { break }
            forwardVertices.insert(predecessor, at: 0)
            current = predecessor
        }
        
        // Reconstruct backward path from meeting vertex to destination
        var backwardVertices: [Vertex] = []
        var backwardEdges: [Edge] = []
        
        current = meetingVertex
        while let edge = backwardPredecessors[current] {
            backwardEdges.append(edge!)
            guard let successor = graph.destination(of: edge!) else { break }
            if successor == destination { break }
            backwardVertices.append(successor)
            current = successor
        }
        
        // Combine paths
        let allVertices = forwardVertices + backwardVertices
        let allEdges = forwardEdges + backwardEdges
        
        return Path(
            source: source,
            destination: destination,
            vertices: allVertices,
            edges: allEdges
        )
    }
}

extension BidirectionalDijkstra: ShortestPathAlgorithm {
    func shortestPath(
        from source: Vertex,
        to destination: Vertex,
        in graph: Graph
    ) -> Path<Vertex, Edge>? {
        shortestPath(from: source, to: destination).path
    }
}


extension BidirectionalDijkstra.PriorityItem: Equatable {
    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.vertex == rhs.vertex && lhs.direction == rhs.direction
    }
}

extension BidirectionalDijkstra.PriorityItem: Comparable {
    static func < (lhs: Self, rhs: Self) -> Bool {
        lhs.cost < rhs.cost
    }
}

extension ShortestPathAlgorithm {
    static func bidirectionalDijkstra<Graph: IncidenceGraph & BidirectionalGraph & EdgePropertyGraph, Weight: Numeric & Comparable>(
        on graph: Graph,
        edgeWeight: CostDefinition<Graph, Weight>
    ) -> BidirectionalDijkstra<Graph, Weight> where Self == BidirectionalDijkstra<Graph, Weight>, Graph.VertexDescriptor: Hashable, Weight.Magnitude == Weight {
        BidirectionalDijkstra(on: graph, edgeWeight: edgeWeight)
    }
}
