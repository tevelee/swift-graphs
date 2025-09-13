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
    
    struct Visitor {
        var examineVertex: ((Vertex, Direction) -> Void)?
        var examineEdge: ((Edge, Direction) -> Void)?
        var edgeRelaxed: ((Edge, Direction) -> Void)?
        var edgeNotRelaxed: ((Edge, Direction) -> Void)?
        var meetingFound: ((Vertex, Cost<Weight>) -> Void)?
    }
    
    enum Direction {
        case forward
        case backward
    }
    
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
    
    func shortestPath(from source: Vertex, to destination: Vertex, visitor: Visitor? = nil) -> Result {
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
            let currentVertex = item.vertex
            let currentCost = item.cost
            let direction = item.direction
            
            if direction == .forward && forwardVisited.contains(currentVertex) { continue }
            if direction == .backward && backwardVisited.contains(currentVertex) { continue }
            
            let storedCost = direction == .forward ? forwardDistances[currentVertex] : backwardDistances[currentVertex]
            if currentCost != storedCost { continue }
            
            if direction == .forward {
                forwardVisited.insert(currentVertex)
            } else {
                backwardVisited.insert(currentVertex)
            }
            
            visitor?.examineVertex?(currentVertex, direction)
            
            if direction == .forward && backwardVisited.contains(currentVertex) {
                let backwardCost = backwardDistances[currentVertex] ?? .infinite
                if case .finite(let currentWeight) = currentCost,
                   case .finite(let backwardWeight) = backwardCost {
                    let totalCost = currentWeight + backwardWeight
                    if case .finite(let bestWeight) = bestDistance {
                        if totalCost < bestWeight {
                            bestDistance = .finite(totalCost)
                            meetingVertex = currentVertex
                            visitor?.meetingFound?(currentVertex, bestDistance)
                        }
                    } else {
                        bestDistance = .finite(totalCost)
                        meetingVertex = currentVertex
                        visitor?.meetingFound?(currentVertex, bestDistance)
                    }
                }
            } else if direction == .backward && forwardVisited.contains(currentVertex) {
                let forwardCost = forwardDistances[currentVertex] ?? .infinite
                if case .finite(let currentWeight) = currentCost,
                   case .finite(let forwardWeight) = forwardCost {
                    let totalCost = forwardWeight + currentWeight
                    if case .finite(let bestWeight) = bestDistance {
                        if totalCost < bestWeight {
                            bestDistance = .finite(totalCost)
                            meetingVertex = currentVertex
                            visitor?.meetingFound?(currentVertex, bestDistance)
                        }
                    } else {
                        bestDistance = .finite(totalCost)
                        meetingVertex = currentVertex
                        visitor?.meetingFound?(currentVertex, bestDistance)
                    }
                }
            }
            
            if direction == .forward {
                exploreForward(
                    from: currentVertex,
                    currentCost: currentCost,
                    distances: &forwardDistances,
                    predecessors: &forwardPredecessors,
                    queue: &queue,
                    visitor: visitor
                )
            } else {
                exploreBackward(
                    from: currentVertex,
                    currentCost: currentCost,
                    distances: &backwardDistances,
                    predecessors: &backwardPredecessors,
                    queue: &queue,
                    visitor: visitor
                )
            }
        }
        
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
        from currentVertex: Vertex,
        currentCost: Cost<Weight>,
        distances: inout [Vertex: Cost<Weight>],
        predecessors: inout [Vertex: Edge?],
        queue: inout any QueueProtocol<PriorityItem>,
        visitor: Visitor?
    ) {
        for edge in graph.outgoingEdges(of: currentVertex) {
            guard let neighbor = graph.destination(of: edge) else { continue }
            
            visitor?.examineEdge?(edge, .forward)
            
            let weight = edgeWeight.costToExplore(edge, graph)
            let newCost = currentCost + weight
            
            let currentBestCost = distances[neighbor] ?? .infinite
            if currentBestCost == nil || newCost < currentBestCost {
                distances[neighbor] = newCost
                predecessors[neighbor] = edge
                queue.enqueue(PriorityItem(vertex: neighbor, cost: newCost, direction: .forward))
                visitor?.edgeRelaxed?(edge, .forward)
            } else {
                visitor?.edgeNotRelaxed?(edge, .forward)
            }
        }
    }
    
    private func exploreBackward(
        from currentVertex: Vertex,
        currentCost: Cost<Weight>,
        distances: inout [Vertex: Cost<Weight>],
        predecessors: inout [Vertex: Edge?],
        queue: inout any QueueProtocol<PriorityItem>,
        visitor: Visitor?
    ) {
        for edge in graph.incomingEdges(of: currentVertex) {
            guard let neighbor = graph.source(of: edge) else { continue }
            
            visitor?.examineEdge?(edge, .backward)
            
            let weight = edgeWeight.costToExplore(edge, graph)
            let newCost = currentCost + weight
            
            let currentBestCost = distances[neighbor] ?? .infinite
            if currentBestCost == nil || newCost < currentBestCost {
                distances[neighbor] = newCost
                predecessors[neighbor] = edge
                queue.enqueue(PriorityItem(vertex: neighbor, cost: newCost, direction: .backward))
                visitor?.edgeRelaxed?(edge, .backward)
            } else {
                visitor?.edgeNotRelaxed?(edge, .backward)
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
        var forwardVertices: [Vertex] = [meetingVertex]
        var forwardEdges: [Edge] = []
        
        var currentVertex = meetingVertex
        while let optionalEdge = forwardPredecessors[currentVertex], let edge = optionalEdge {
            forwardEdges.insert(edge, at: 0)
            guard let predecessor = graph.source(of: edge) else { break }
            if predecessor == source { break }
            forwardVertices.insert(predecessor, at: 0)
            currentVertex = predecessor
        }
        
        var backwardVertices: [Vertex] = []
        var backwardEdges: [Edge] = []
        
        currentVertex = meetingVertex
        while let optionalEdge = backwardPredecessors[currentVertex], let edge = optionalEdge {
            backwardEdges.append(edge)
            guard let successor = graph.destination(of: edge) else { break }
            if successor == destination { break }
            backwardVertices.append(successor)
            currentVertex = successor
        }
        
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

extension BidirectionalDijkstra: VisitorSupporting {}



