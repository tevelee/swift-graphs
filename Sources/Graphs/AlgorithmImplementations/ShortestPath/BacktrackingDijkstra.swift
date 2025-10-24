/// Backtracking Dijkstra's algorithm for finding all shortest paths with the same minimum cost.
///
/// This algorithm extends Dijkstra's algorithm to track all predecessors that lead to the
/// optimal cost for each vertex, then backtracks to enumerate all paths with the minimum cost.
///
/// - Complexity: O((V + E) log V) for the Dijkstra phase, plus O(P * L) for path enumeration
///   where P is the number of paths and L is the average path length.
public struct BacktrackingDijkstra<
    Graph: IncidenceGraph,
    Weight: Numeric & Comparable
> where
    Graph.VertexDescriptor: Hashable,
    Weight.Magnitude == Weight
{
    /// The vertex type of the graph.
    public typealias Vertex = Graph.VertexDescriptor
    /// The edge type of the graph.
    public typealias Edge = Graph.EdgeDescriptor
    
    /// A visitor that can be used to observe the algorithm's progress.
    public struct Visitor {
        /// Called when examining a vertex.
        public var examineVertex: ((Vertex) -> Void)?
        /// Called when examining an edge.
        public var examineEdge: ((Edge) -> Void)?
        /// Called when an edge is identified as part of a shortest path.
        public var edgeOnShortestPath: ((Edge) -> Void)?
        /// Called when a vertex is finished (all outgoing edges processed).
        public var finishVertex: ((Vertex) -> Void)?
        /// Called when a complete path is found.
        public var pathFound: (([Vertex], [Edge]) -> Void)?
        
        /// Creates a new visitor.
        @inlinable
        public init(
            examineVertex: ((Vertex) -> Void)? = nil,
            examineEdge: ((Edge) -> Void)? = nil,
            edgeOnShortestPath: ((Edge) -> Void)? = nil,
            finishVertex: ((Vertex) -> Void)? = nil,
            pathFound: (([Vertex], [Edge]) -> Void)? = nil
        ) {
            self.examineVertex = examineVertex
            self.examineEdge = examineEdge
            self.edgeOnShortestPath = edgeOnShortestPath
            self.finishVertex = finishVertex
            self.pathFound = pathFound
        }
    }
    
    /// The result of finding all shortest paths.
    public struct Result {
        /// The source vertex.
        public let source: Vertex
        /// The destination vertex.
        public let destination: Vertex
        /// All paths with the minimum cost.
        public let paths: [Path<Vertex, Edge>]
        /// The optimal cost (or nil if no path exists).
        public let optimalCost: Weight?
        
        /// Creates a new result.
        @inlinable
        public init(source: Vertex, destination: Vertex, paths: [Path<Vertex, Edge>], optimalCost: Weight?) {
            self.source = source
            self.destination = destination
            self.paths = paths
            self.optimalCost = optimalCost
        }
    }
    
    @usableFromInline
    let graph: Graph
    @usableFromInline
    let edgeWeight: CostDefinition<Graph, Weight>
    @usableFromInline
    let makePriorityQueue: () -> any QueueProtocol<PriorityItem>
    
    /// Creates a backtracking Dijkstra algorithm instance.
    ///
    /// - Parameters:
    ///   - graph: The graph to search
    ///   - edgeWeight: The cost definition for edge weights
    ///   - makePriorityQueue: A closure that creates a priority queue (defaults to min-heap)
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
    
    /// Finds all shortest paths from source until a condition is met.
    ///
    /// - Parameters:
    ///   - source: The starting vertex
    ///   - condition: A closure that determines when to stop searching
    ///   - visitor: Optional visitor for algorithm events
    /// - Returns: A result containing all paths with the minimum cost
    @inlinable
    public func findAllShortestPaths(
        from source: Vertex,
        until condition: @escaping (Vertex) -> Bool,
        visitor: Visitor? = nil
    ) -> Result {
        // First, run a standard Dijkstra to find if any vertex satisfying the condition exists and get optimal cost
        let dijkstra = Dijkstra(
            on: graph,
            from: source,
            edgeWeight: edgeWeight
        )
        
        guard let dijkstraResult = dijkstra.first(where: { condition($0.currentVertex) }) else {
            return Result(source: source, destination: source, paths: [], optimalCost: nil)
        }
        
        let optimalCost = dijkstraResult.currentDistance()
        let destination = dijkstraResult.currentVertex
        
        // Now run modified Dijkstra to collect all shortest predecessors
        let (costs, predecessors) = computeAllShortestPredecessors(
            from: source,
            until: condition,
            visitor: visitor
        )
        
        // Verify we found at least one vertex satisfying the condition
        guard let destinationCost = costs[destination], destinationCost == optimalCost else {
            // Shouldn't happen, but handle gracefully
            let path = Path<Vertex, Edge>(
                source: source,
                destination: destination,
                vertices: dijkstraResult.vertices(to: destination, in: graph),
                edges: dijkstraResult.edges(to: destination, in: graph)
            )
            return Result(source: source, destination: destination, paths: [path], optimalCost: optimalCost)
        }
        
        // Backtrack to enumerate all paths
        let paths = enumerateAllPaths(
            from: source,
            to: destination,
            costs: costs,
            predecessors: predecessors,
            visitor: visitor
        )
        
        return Result(source: source, destination: destination, paths: paths, optimalCost: optimalCost)
    }
    
    /// Finds all shortest paths from source to destination.
    ///
    /// - Parameters:
    ///   - source: The starting vertex
    ///   - destination: The target vertex
    ///   - visitor: Optional visitor for algorithm events
    /// - Returns: A result containing all paths with the minimum cost
    @inlinable
    public func findAllShortestPaths(
        from source: Vertex,
        to destination: Vertex,
        visitor: Visitor? = nil
    ) -> Result {
        // First, run a standard Dijkstra to find if a path exists and get optimal cost
        let dijkstra = Dijkstra(
            on: graph,
            from: source,
            edgeWeight: edgeWeight
        )
        
        guard let dijkstraResult = dijkstra.first(where: { $0.currentVertex == destination }) else {
            return Result(source: source, destination: destination, paths: [], optimalCost: nil)
        }
        
        let optimalCost = dijkstraResult.currentDistance()
        
        // Now run modified Dijkstra to collect all shortest predecessors
        let (costs, predecessors) = computeAllShortestPredecessors(
            from: source,
            destination: destination,
            visitor: visitor
        )
        
        // Verify we found the destination
        guard let destinationCost = costs[destination], destinationCost == optimalCost else {
            // Shouldn't happen, but handle gracefully
            let path = Path<Vertex, Edge>(
                source: source,
                destination: destination,
                vertices: dijkstraResult.vertices(to: destination, in: graph),
                edges: dijkstraResult.edges(to: destination, in: graph)
            )
            return Result(source: source, destination: destination, paths: [path], optimalCost: optimalCost)
        }
        
        // Backtrack to enumerate all paths
        let paths = enumerateAllPaths(
            from: source,
            to: destination,
            costs: costs,
            predecessors: predecessors,
            visitor: visitor
        )
        
        return Result(source: source, destination: destination, paths: paths, optimalCost: optimalCost)
    }
    
    /// Priority queue item for Dijkstra's algorithm.
    public struct PriorityItem {
        public let vertex: Vertex
        public let cost: Cost<Weight>
        
        @inlinable
        public init(vertex: Vertex, cost: Cost<Weight>) {
            self.vertex = vertex
            self.cost = cost
        }
    }
    
    /// Runs modified Dijkstra to compute all shortest predecessors for each vertex until a condition is met.
    @usableFromInline
    func computeAllShortestPredecessors(
        from source: Vertex,
        until condition: @escaping (Vertex) -> Bool,
        visitor: Visitor?
    ) -> (costs: [Vertex: Weight], predecessors: [Vertex: [Edge]]) {
        var queue = makePriorityQueue()
        queue.enqueue(PriorityItem(vertex: source, cost: .finite(.zero)))
        
        var costs: [Vertex: Weight] = [source: .zero]
        var predecessors: [Vertex: [Edge]] = [:]
        var visited: Set<Vertex> = []
        
        while let currentItem = queue.dequeue() {
            let currentVertex = currentItem.vertex
            
            // Skip if already visited
            if visited.contains(currentVertex) {
                continue
            }
            
            visited.insert(currentVertex)
            visitor?.examineVertex?(currentVertex)
            
            // Early termination if we've reached a vertex satisfying the condition
            if condition(currentVertex) {
                break
            }
            
            guard let currentCost = costs[currentVertex] else { continue }
            
            // Explore neighbors
            for edge in graph.outgoingEdges(of: currentVertex) {
                guard let neighbor = graph.destination(of: edge) else { continue }
                
                visitor?.examineEdge?(edge)
                
                let edgeCost = edgeWeight.costToExplore(edge, graph)
                let newCost = currentCost + edgeCost
                
                if let existingCost = costs[neighbor] {
                    if newCost < existingCost {
                        // Found a strictly better path - replace predecessors
                        costs[neighbor] = newCost
                        predecessors[neighbor] = [edge]
                        queue.enqueue(PriorityItem(vertex: neighbor, cost: .finite(newCost)))
                        visitor?.edgeOnShortestPath?(edge)
                    } else if newCost == existingCost {
                        // Found another equally optimal path - add to predecessors
                        predecessors[neighbor, default: []].append(edge)
                        visitor?.edgeOnShortestPath?(edge)
                    }
                    // If newCost > existingCost, ignore (not on a shortest path)
                } else {
                    // First time reaching this vertex
                    costs[neighbor] = newCost
                    predecessors[neighbor] = [edge]
                    queue.enqueue(PriorityItem(vertex: neighbor, cost: .finite(newCost)))
                    visitor?.edgeOnShortestPath?(edge)
                }
            }
            
            visitor?.finishVertex?(currentVertex)
        }
        
        return (costs, predecessors)
    }
    
    /// Runs modified Dijkstra to compute all shortest predecessors for each vertex.
    @usableFromInline
    func computeAllShortestPredecessors(
        from source: Vertex,
        destination: Vertex,
        visitor: Visitor?
    ) -> (costs: [Vertex: Weight], predecessors: [Vertex: [Edge]]) {
        var queue = makePriorityQueue()
        queue.enqueue(PriorityItem(vertex: source, cost: .finite(.zero)))
        
        var costs: [Vertex: Weight] = [source: .zero]
        var predecessors: [Vertex: [Edge]] = [:]
        var visited: Set<Vertex> = []
        
        while let currentItem = queue.dequeue() {
            let currentVertex = currentItem.vertex
            
            // Skip if already visited
            if visited.contains(currentVertex) {
                continue
            }
            
            visited.insert(currentVertex)
            visitor?.examineVertex?(currentVertex)
            
            // Early termination if we've reached the destination
            if currentVertex == destination {
                break
            }
            
            guard let currentCost = costs[currentVertex] else { continue }
            
            // Explore neighbors
            for edge in graph.outgoingEdges(of: currentVertex) {
                guard let neighbor = graph.destination(of: edge) else { continue }
                
                visitor?.examineEdge?(edge)
                
                let edgeCost = edgeWeight.costToExplore(edge, graph)
                let newCost = currentCost + edgeCost
                
                if let existingCost = costs[neighbor] {
                    if newCost < existingCost {
                        // Found a strictly better path - replace predecessors
                        costs[neighbor] = newCost
                        predecessors[neighbor] = [edge]
                        queue.enqueue(PriorityItem(vertex: neighbor, cost: .finite(newCost)))
                        visitor?.edgeOnShortestPath?(edge)
                    } else if newCost == existingCost {
                        // Found another equally optimal path - add to predecessors
                        predecessors[neighbor, default: []].append(edge)
                        visitor?.edgeOnShortestPath?(edge)
                    }
                    // If newCost > existingCost, ignore (not on a shortest path)
                } else {
                    // First time reaching this vertex
                    costs[neighbor] = newCost
                    predecessors[neighbor] = [edge]
                    queue.enqueue(PriorityItem(vertex: neighbor, cost: .finite(newCost)))
                    visitor?.edgeOnShortestPath?(edge)
                }
            }
            
            visitor?.finishVertex?(currentVertex)
        }
        
        return (costs, predecessors)
    }
    
    /// Enumerates all paths from source to destination using backtracking.
    @usableFromInline
    func enumerateAllPaths(
        from source: Vertex,
        to destination: Vertex,
        costs: [Vertex: Weight],
        predecessors: [Vertex: [Edge]],
        visitor: Visitor?
    ) -> [Path<Vertex, Edge>] {
        var result: [Path<Vertex, Edge>] = []
        var stack: [([Vertex], [Edge])] = [([destination], [])]
        
        while let (currentPath, currentEdges) = stack.popLast() {
            guard let currentVertex = currentPath.first else { continue }
            
            if currentVertex == source {
                // Found a complete path - reverse it since we built it backwards
                let vertices = currentPath.reversed()
                let edges = currentEdges.reversed()
                let path = Path(
                    source: source,
                    destination: destination,
                    vertices: Array(vertices),
                    edges: Array(edges)
                )
                result.append(path)
                visitor?.pathFound?(Array(vertices), Array(edges))
            } else {
                // Continue backtracking
                guard let incomingEdges = predecessors[currentVertex],
                      let currentCost = costs[currentVertex] else {
                    continue
                }
                
                for edge in incomingEdges {
                    guard let predecessor = graph.source(of: edge),
                          let predecessorCost = costs[predecessor] else {
                        continue
                    }
                    
                    // Verify this edge is on a shortest path
                    let edgeCost = edgeWeight.costToExplore(edge, graph)
                    if predecessorCost + edgeCost == currentCost {
                        var newPath = currentPath
                        newPath.insert(predecessor, at: 0)
                        var newEdges = currentEdges
                        newEdges.insert(edge, at: 0)
                        stack.append((newPath, newEdges))
                    }
                }
            }
        }
        
        return result
    }
}

extension BacktrackingDijkstra.PriorityItem: Equatable {
    @inlinable
    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.vertex == rhs.vertex
    }
}

extension BacktrackingDijkstra.PriorityItem: Comparable {
    @inlinable
    public static func < (lhs: Self, rhs: Self) -> Bool {
        lhs.cost < rhs.cost
    }
}

