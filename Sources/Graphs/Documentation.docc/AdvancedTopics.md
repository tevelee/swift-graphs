# Advanced Topics

Extending the library with custom graph types, algorithms, and optimizations.

## Overview

The library is designed for extensibility. You can create custom graph implementations, add new algorithms, and extend existing functionality while maintaining type safety and composability.

## Creating Custom Graph Types

### Implementing GraphComponent

The minimal requirement is implementing `edges(from:)`:

```swift
struct DatabaseBackedGraph: GraphComponent {
    typealias Node = UUID
    typealias Edge = Empty
    
    let database: Database
    
    func edges(from node: UUID) -> [GraphEdge<UUID, Empty>] {
        // Query database for edges
        let rows = database.query("""
            SELECT target_id FROM edges 
            WHERE source_id = ?
        """, node)
        
        return rows.map { row in
            GraphEdge(source: node, destination: row["target_id"] as! UUID)
        }
    }
}

// All algorithms now work automatically!
let graph = DatabaseBackedGraph(database: myDB)
let path = graph.shortestPath(from: userA, to: userB, using: .dijkstra())
```

### Implementing Full Graph Protocol

Add global access for more functionality:

```swift
struct DatabaseGraph: Graph {
    typealias Node = UUID
    typealias Edge = Empty
    
    let database: Database
    
    var allNodes: [UUID] {
        database.query("SELECT DISTINCT id FROM nodes")
            .map { $0["id"] as! UUID }
    }
    
    var allEdges: [GraphEdge<UUID, Empty>] {
        database.query("SELECT source_id, target_id FROM edges")
            .map { row in
                GraphEdge(
                    source: row["source_id"] as! UUID,
                    destination: row["target_id"] as! UUID
                )
            }
    }
    
    func edges(from node: UUID) -> [GraphEdge<UUID, Empty>] {
        database.query("SELECT target_id FROM edges WHERE source_id = ?", node)
            .map { GraphEdge(source: node, destination: $0["target_id"] as! UUID) }
    }
}
```

### Optimized Custom Graph

Add caching and efficient lookups:

```swift
struct CachedGraph<Node: Hashable, Edge>: Graph {
    private let baseGraph: any Graph<Node, Edge>
    private var edgeCache: [Node: [GraphEdge<Node, Edge>]] = [:]
    private let queue = DispatchQueue(label: "graph.cache")
    
    init(wrapping graph: any Graph<Node, Edge>) {
        self.baseGraph = graph
    }
    
    var allNodes: [Node] { baseGraph.allNodes }
    var allEdges: [GraphEdge<Node, Edge>] { baseGraph.allEdges }
    
    func edges(from node: Node) -> [GraphEdge<Node, Edge>] {
        // Thread-safe cache access
        queue.sync {
            if let cached = edgeCache[node] {
                return cached
            }
            
            let edges = baseGraph.edges(from: node)
            edgeCache[node] = edges
            return edges
        }
    }
}

// Usage
let expensive = LazyGraph<Int, Empty> { node in
    expensiveComputation(for: node)
}
let cached = CachedGraph(wrapping: expensive)
```

## Custom Algorithms

### Implementing Algorithm Protocols

Create custom shortest path algorithm:

```swift
struct MyCustomShortestPath<Node: Hashable, Edge: Weighted>: ShortestPathAlgorithm 
where Edge.Weight: Numeric {
    let heuristic: (Node, Node) -> Edge.Weight
    
    func shortestPath(
        from source: Node,
        to destination: Node,
        in graph: some GraphComponent<Node, Edge>
    ) -> Path<Node, Edge>? {
        // Your custom implementation
        var openSet: Set<Node> = [source]
        var cameFrom: [Node: GraphEdge<Node, Edge>] = [:]
        var gScore: [Node: Edge.Weight] = [source: .zero]
        
        while !openSet.isEmpty {
            // Custom logic here
            let current = findBestNode(in: openSet, scores: gScore, goal: destination)
            
            if current == destination {
                return Path(connectingEdges: cameFrom, source: source, destination: destination)
            }
            
            openSet.remove(current)
            
            for edge in graph.edges(from: current) {
                let tentative = gScore[current]! + edge.value.weight
                
                if tentative < gScore[edge.destination, default: .max] {
                    cameFrom[edge.destination] = edge
                    gScore[edge.destination] = tentative
                    openSet.insert(edge.destination)
                }
            }
        }
        
        return nil
    }
    
    private func findBestNode(
        in set: Set<Node>,
        scores: [Node: Edge.Weight],
        goal: Node
    ) -> Node {
        set.min { a, b in
            let aScore = scores[a]! + heuristic(a, goal)
            let bScore = scores[b]! + heuristic(b, goal)
            return aScore < bScore
        }!
    }
}

// Use it
let custom = MyCustomShortestPath<String, Int> { from, to in
    // Custom heuristic
    estimateDistance(from: from, to: to)
}

let path = graph.shortestPath(from: "A", to: "Z", using: custom)
```

### Custom Traversal Strategy

Implement priority-based traversal with custom logic:

```swift
struct CustomPriorityTraversal<Node, Edge>: GraphTraversalStrategy {
    typealias Visit = (node: Node, priority: Double)
    
    struct Storage {
        var queue: Heap<Visit>
        var visited: Set<Node>
    }
    
    let priorityFunction: (Node) -> Double
    
    func initializeStorage(startNode: Node) -> Storage {
        var heap = Heap<Visit> { $0.priority < $1.priority }
        heap.insert((startNode, priorityFunction(startNode)))
        
        return Storage(
            queue: heap,
            visited: []
        )
    }
    
    func next(
        from storage: inout Storage,
        graph: some GraphComponent<Node, Edge>
    ) -> Visit? where Node: Hashable {
        guard let current = storage.queue.popMin() else {
            return nil
        }
        
        guard storage.visited.insert(current.node).inserted else {
            return next(from: &storage, graph: graph)
        }
        
        for edge in graph.edges(from: current.node) {
            if !storage.visited.contains(edge.destination) {
                let priority = priorityFunction(edge.destination)
                storage.queue.insert((edge.destination, priority))
            }
        }
        
        return current
    }
}

// Usage
let strategy = CustomPriorityTraversal<String, Empty> { node in
    Double(node.count)  // Priority based on string length
}

for visit in graph.traversal(from: "start", strategy: strategy) {
    print("\(visit.node) with priority \(visit.priority)")
}
```

## Advanced Graph Transformations

### Filtered Subgraph

Create views of graphs with filtered edges:

```swift
struct FilteredGraph<Base: GraphComponent>: GraphComponent {
    typealias Node = Base.Node
    typealias Edge = Base.Edge
    
    let base: Base
    let predicate: (GraphEdge<Node, Edge>) -> Bool
    
    func edges(from node: Node) -> [GraphEdge<Node, Edge>] {
        base.edges(from: node).filter(predicate)
    }
}

extension GraphComponent {
    func filtered(_ predicate: @escaping (GraphEdge<Node, Edge>) -> Bool) -> FilteredGraph<Self> {
        FilteredGraph(base: self, predicate: predicate)
    }
}

// Usage
let heavyEdges = graph.filtered { $0.value.weight > 10 }
let mst = heavyEdges.minimumSpanningTree(using: .kruskal())
```

### Mapped Edges

Transform edge values without copying:

```swift
struct MappedEdgeGraph<Base: GraphComponent, NewEdge>: GraphComponent {
    typealias Node = Base.Node
    typealias Edge = NewEdge
    
    let base: Base
    let transform: (Base.Edge) -> NewEdge
    
    func edges(from node: Node) -> [GraphEdge<Node, NewEdge>] {
        base.edges(from: node).map { edge in
            GraphEdge(
                source: edge.source,
                destination: edge.destination,
                value: transform(edge.value)
            )
        }
    }
}

extension GraphComponent {
    func mapEdges<T>(_ transform: @escaping (Edge) -> T) -> MappedEdgeGraph<Self, T> {
        MappedEdgeGraph(base: self, transform: transform)
    }
}

// Usage
let distances = routes.mapEdges { $0.distance }
let times = routes.mapEdges { $0.travelTime }
```

### Union Graph

Combine multiple graphs:

```swift
struct UnionGraph<G1: Graph, G2: Graph>: Graph 
where G1.Node == G2.Node, G1.Edge == G2.Edge {
    typealias Node = G1.Node
    typealias Edge = G1.Edge
    
    let graph1: G1
    let graph2: G2
    
    var allNodes: [Node] {
        Set(graph1.allNodes + graph2.allNodes).array
    }
    
    var allEdges: [GraphEdge<Node, Edge>] {
        graph1.allEdges + graph2.allEdges
    }
    
    func edges(from node: Node) -> [GraphEdge<Node, Edge>] {
        graph1.edges(from: node) + graph2.edges(from: node)
    }
}

// Usage
let roads = ConnectedGraph<City, Distance>(edges: roadEdges)
let flights = ConnectedGraph<City, Distance>(edges: flightEdges)
let multiModal = UnionGraph(graph1: roads, graph2: flights)
```

## Performance Optimization

### Using @inlinable

Mark performance-critical code as inlinable for cross-module optimization:

```swift
public struct FastGraph<Node: Hashable, Edge>: GraphComponent {
    private let adjacencyList: [Node: [GraphEdge<Node, Edge>]]
    
    @inlinable
    public func edges(from node: Node) -> [GraphEdge<Node, Edge>] {
        adjacencyList[node] ?? []
    }
}
```

### Specialization Hints

Use concrete types for better performance:

```swift
// Generic version - may be slower
func analyze<G: Graph>(_ graph: G) {
    // ...
}

// Specialized version - faster
func analyze(_ graph: ConnectedHashGraph<String, Int>) {
    // Compiler can optimize specifically for this type
}
```

### Parallel Algorithms

Implement parallel versions of algorithms:

```swift
import Dispatch

struct ParallelBFS<Node: Hashable>: GraphTraversalStrategy {
    typealias Visit = Node
    
    struct Storage {
        var currentLevel: [Node]
        var nextLevel: [Node]
        var visited: Set<Node>
        let queue: DispatchQueue
    }
    
    func initializeStorage(startNode: Node) -> Storage {
        Storage(
            currentLevel: [startNode],
            nextLevel: [],
            visited: [startNode],
            queue: DispatchQueue(label: "parallel.bfs", attributes: .concurrent)
        )
    }
    
    func next(
        from storage: inout Storage,
        graph: some GraphComponent<Node, Empty>
    ) -> Node? {
        if storage.currentLevel.isEmpty {
            if storage.nextLevel.isEmpty {
                return nil
            }
            storage.currentLevel = storage.nextLevel
            storage.nextLevel = []
        }
        
        guard let current = storage.currentLevel.popLast() else {
            return nil
        }
        
        // Process neighbors in parallel
        DispatchQueue.concurrentPerform(iterations: graph.edges(from: current).count) { i in
            let edge = graph.edges(from: current)[i]
            storage.queue.async(flags: .barrier) {
                if storage.visited.insert(edge.destination).inserted {
                    storage.nextLevel.append(edge.destination)
                }
            }
        }
        
        return current
    }
}
```

## Type-Safe Graph Properties

### Custom Associated Types

Create graphs with rich type information:

```swift
protocol TypedGraphComponent {
    associatedtype NodeType: Hashable
    associatedtype EdgeType
    associatedtype NodeLabel
    associatedtype EdgeLabel
    
    func edges(from node: NodeType) -> [TypedEdge<NodeType, EdgeType, NodeLabel, EdgeLabel>]
    func label(for node: NodeType) -> NodeLabel
}

struct TypedEdge<Node, Edge, NodeLabel, EdgeLabel> {
    let source: Node
    let destination: Node
    let value: Edge
    let label: EdgeLabel
}

// Usage: Protein interaction network
struct Protein: Hashable {
    let id: String
}

struct Interaction {
    let strength: Double
}

struct ProteinNetwork: TypedGraphComponent {
    typealias NodeType = Protein
    typealias EdgeType = Interaction
    typealias NodeLabel = String  // Protein name
    typealias EdgeLabel = String  // Interaction type
    
    // Implementation
}
```

### Phantom Types

Use phantom types for compile-time guarantees:

```swift
enum Directed {}
enum Undirected {}

struct TypedGraph<Node, Edge, Direction>: GraphComponent {
    private let edges: [GraphEdge<Node, Edge>]
    
    func edges(from node: Node) -> [GraphEdge<Node, Edge>] {
        // Implementation
    }
}

extension TypedGraph where Direction == Directed {
    func reversed() -> TypedGraph<Node, Edge, Directed> {
        // Only available for directed graphs
    }
}

extension TypedGraph where Direction == Undirected {
    func asDirected() -> TypedGraph<Node, Edge, Directed> {
        // Convert undirected to directed
    }
}

// Usage - compile-time safety
let directed: TypedGraph<String, Int, Directed> = ...
let reversed = directed.reversed()  // ✓ OK

let undirected: TypedGraph<String, Int, Undirected> = ...
// undirected.reversed()  // ✗ Compile error!
```

## Async/Await Graph Operations

### Async Graph Protocol

```swift
protocol AsyncGraphComponent<Node, Edge> {
    associatedtype Node
    associatedtype Edge
    
    func edges(from node: Node) async throws -> [GraphEdge<Node, Edge>]
}

// Example: API-based graph
struct APIGraph: AsyncGraphComponent {
    typealias Node = String
    typealias Edge = Empty
    
    let apiClient: APIClient
    
    func edges(from node: String) async throws -> [GraphEdge<String, Empty>] {
        let response = try await apiClient.fetch("/nodes/\(node)/edges")
        return response.map { edge in
            GraphEdge(source: node, destination: edge.destination)
        }
    }
}

// Async traversal
extension AsyncGraphComponent {
    func traverse(from start: Node) async throws -> [Node] {
        var visited: Set<Node> = []
        var queue: [Node] = [start]
        var result: [Node] = []
        
        while let current = queue.popFirst() {
            guard visited.insert(current).inserted else { continue }
            result.append(current)
            
            let edges = try await edges(from: current)
            queue.append(contentsOf: edges.map(\.destination))
        }
        
        return result
    }
}
```

## Memory-Efficient Graphs

### Compressed Sparse Row (CSR) Format

```swift
struct CSRGraph<Node: Hashable, Edge>: Graph {
    let nodes: [Node]
    let edges: [GraphEdge<Node, Edge>]
    let rowPointers: [Int]
    private let nodeToIndex: [Node: Int]
    
    init(edges: [GraphEdge<Node, Edge>]) {
        // Build CSR representation
        let uniqueNodes = Set(edges.flatMap { [$0.source, $0.destination] })
        self.nodes = Array(uniqueNodes)
        self.nodeToIndex = Dictionary(uniqueKeysWithValues: nodes.enumerated().map { ($1, $0) })
        
        var sortedEdges = edges.sorted { 
            nodeToIndex[$0.source]! < nodeToIndex[$1.source]!
        }
        
        self.edges = sortedEdges
        
        var pointers: [Int] = []
        var currentNode = 0
        
        for (i, edge) in sortedEdges.enumerated() {
            let sourceIndex = nodeToIndex[edge.source]!
            while currentNode < sourceIndex {
                pointers.append(i)
                currentNode += 1
            }
        }
        
        while currentNode < nodes.count {
            pointers.append(sortedEdges.count)
            currentNode += 1
        }
        
        self.rowPointers = pointers
    }
    
    var allNodes: [Node] { nodes }
    var allEdges: [GraphEdge<Node, Edge>] { edges }
    
    func edges(from node: Node) -> [GraphEdge<Node, Edge>] {
        guard let index = nodeToIndex[node] else { return [] }
        let start = rowPointers[index]
        let end = index + 1 < rowPointers.count ? rowPointers[index + 1] : edges.count
        return Array(edges[start..<end])
    }
}
```

## Testing Custom Implementations

### Property-Based Testing

```swift
import XCTest

class CustomGraphTests: XCTestCase {
    func testGraphInvariants<G: Graph>(_ graph: G) where G.Node: Hashable {
        // All edges must have valid endpoints
        for edge in graph.allEdges {
            XCTAssertTrue(graph.allNodes.contains(edge.source))
            XCTAssertTrue(graph.allNodes.contains(edge.destination))
        }
        
        // edges(from:) must return subset of allEdges
        for node in graph.allNodes {
            let nodeEdges = graph.edges(from: node)
            for edge in nodeEdges {
                XCTAssertTrue(graph.allEdges.contains(where: { $0 == edge }))
            }
        }
    }
    
    func testCustomGraph() {
        let graph = MyCustomGraph(...)
        testGraphInvariants(graph)
    }
}
```

## See Also

- <doc:Architecture>
- <doc:ProtocolOrientedDesign>
- <doc:StorageAndAlgorithms>
- <doc:CodeExamples>
