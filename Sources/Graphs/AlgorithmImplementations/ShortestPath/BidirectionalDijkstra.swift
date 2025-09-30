import Foundation

/// Bidirectional Dijkstra's algorithm for finding shortest paths between two vertices.
///
/// Bidirectional Dijkstra's algorithm searches from both the source and destination
/// simultaneously, meeting in the middle. This can be more efficient than standard
/// Dijkstra's algorithm for point-to-point shortest path queries.
///
/// - Complexity: O(E log V) where E is the number of edges and V is the number of vertices
public struct BidirectionalDijkstra<
    Graph: IncidenceGraph & BidirectionalGraph & EdgePropertyGraph,
    Weight: Numeric & Comparable
> where
    Graph.VertexDescriptor: Hashable,
    Weight.Magnitude == Weight
{
    /// The vertex type of the graph.
    public typealias Vertex = Graph.VertexDescriptor
    /// The edge type of the graph.
    public typealias Edge = Graph.EdgeDescriptor
    
    /// A visitor that can be used to observe the bidirectional Dijkstra algorithm's progress.
    public struct Visitor {
        /// Called when examining a vertex.
        public var examineVertex: ((Vertex, Direction) -> Void)?
        /// Called when examining an edge.
        public var examineEdge: ((Edge, Direction) -> Void)?
        /// Called when an edge is relaxed.
        public var edgeRelaxed: ((Edge, Direction) -> Void)?
        /// Called when an edge is not relaxed.
        public var edgeNotRelaxed: ((Edge, Direction) -> Void)?
        /// Called when a meeting point is found.
        public var meetingFound: ((Vertex, Cost<Weight>) -> Void)?
        
        /// Creates a new visitor.
        @inlinable
        public init(
            examineVertex: ((Vertex, Direction) -> Void)? = nil,
            examineEdge: ((Edge, Direction) -> Void)? = nil,
            edgeRelaxed: ((Edge, Direction) -> Void)? = nil,
            edgeNotRelaxed: ((Edge, Direction) -> Void)? = nil,
            meetingFound: ((Vertex, Cost<Weight>) -> Void)? = nil
        ) {
            self.examineVertex = examineVertex
            self.examineEdge = examineEdge
            self.edgeRelaxed = edgeRelaxed
            self.edgeNotRelaxed = edgeNotRelaxed
            self.meetingFound = meetingFound
        }
    }
    
    /// The direction of search in bidirectional Dijkstra.
    public enum Direction {
        /// Forward search from source to destination.
        case forward
        /// Backward search from destination to source.
        case backward
    }
    
    /// The result of a bidirectional Dijkstra search.
    public struct Result {
        /// The shortest path, if one exists.
        public let path: Path<Vertex, Edge>?
        /// The total distance of the shortest path.
        public let totalDistance: Cost<Weight>
        /// The vertex where the forward and backward searches met.
        public let meetingVertex: Vertex?
        
        /// Creates a new result.
        @inlinable
        public init(path: Path<Vertex, Edge>?, totalDistance: Cost<Weight>, meetingVertex: Vertex?) {
            self.path = path
            self.totalDistance = totalDistance
            self.meetingVertex = meetingVertex
        }
    }
    
    @usableFromInline
    let graph: Graph
    @usableFromInline
    let edgeWeight: CostDefinition<Graph, Weight>
    @usableFromInline
    let makePriorityQueue: () -> any QueueProtocol<PriorityItem>
    
    /// A priority queue item for bidirectional Dijkstra.
    public struct PriorityItem {
        /// The vertex.
        public let vertex: Vertex
        /// The cost to reach this vertex.
        public let cost: Cost<Weight>
        /// The search direction.
        public let direction: Direction
        
        /// Creates a new priority item.
        @inlinable
        public init(vertex: Vertex, cost: Cost<Weight>, direction: Direction) {
            self.vertex = vertex
            self.cost = cost
            self.direction = direction
        }
    }
    
    /// Creates a new bidirectional Dijkstra algorithm instance.
    ///
    /// - Parameters:
    ///   - graph: The graph to search in.
    ///   - edgeWeight: The cost definition for edge weights.
    ///   - makePriorityQueue: A factory for creating priority queues.
    @inlinable
    public init(
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
    
    /// Finds the shortest path between two vertices.
    ///
    /// - Parameters:
    ///   - source: The source vertex.
    ///   - destination: The destination vertex.
    ///   - visitor: An optional visitor to observe the algorithm's progress.
    /// - Returns: The shortest path result.
    @inlinable
    public func shortestPath(from source: Vertex, to destination: Vertex, visitor: Visitor? = nil) -> Result {
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
    
    /// Explores forward from a vertex.
    ///
    /// - Parameters:
    ///   - currentVertex: The current vertex.
    ///   - currentCost: The current cost to reach the vertex.
    ///   - distances: The distances dictionary to update.
    ///   - predecessors: The predecessors dictionary to update.
    ///   - queue: The priority queue to add new items to.
    ///   - visitor: An optional visitor.
    @usableFromInline
    func exploreForward(
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
    
    /// Explores backward from a vertex.
    ///
    /// - Parameters:
    ///   - currentVertex: The current vertex.
    ///   - currentCost: The current cost to reach the vertex.
    ///   - distances: The distances dictionary to update.
    ///   - predecessors: The predecessors dictionary to update.
    ///   - queue: The priority queue to add new items to.
    ///   - visitor: An optional visitor.
    @usableFromInline
    func exploreBackward(
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
    
    /// Reconstructs the shortest path from the meeting point.
    ///
    /// - Parameters:
    ///   - source: The source vertex.
    ///   - destination: The destination vertex.
    ///   - meetingVertex: The vertex where the searches met.
    ///   - forwardPredecessors: The forward predecessors.
    ///   - backwardPredecessors: The backward predecessors.
    /// - Returns: The reconstructed path.
    @usableFromInline
    func reconstructPath(
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
    @inlinable
    public func shortestPath(
        from source: Vertex,
        to destination: Vertex,
        in graph: Graph,
        visitor: Visitor?
    ) -> Path<Vertex, Edge>? {
        shortestPath(from: source, to: destination).path
    }
}


extension BidirectionalDijkstra.PriorityItem: Equatable {
    @inlinable
    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.vertex == rhs.vertex && lhs.direction == rhs.direction
    }
}

extension BidirectionalDijkstra.PriorityItem: Comparable {
    @inlinable
    public static func < (lhs: Self, rhs: Self) -> Bool {
        lhs.cost < rhs.cost
    }
}

extension BidirectionalDijkstra: VisitorSupporting {}
