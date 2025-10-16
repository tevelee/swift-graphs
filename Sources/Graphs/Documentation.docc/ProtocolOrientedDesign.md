# Protocol-Oriented Design

Understanding the protocol hierarchy and how it enables flexible, type-safe graph operations.

## Overview

The Graphs library leverages Swift's protocol-oriented programming to create a flexible, extensible architecture. This design allows algorithms to work uniformly across different graph representations while maintaining type safety and performance.

## The Core Protocol: GraphComponent

``GraphComponent`` is the foundational protocol that defines what it means to be a graph:

```swift
public protocol GraphComponent<Node, Edge> {
    associatedtype Node
    associatedtype Edge = Empty
    
    func edges(from node: Node) -> [GraphEdge<Node, Edge>]
}
```

### Minimal but Powerful

This deceptively simple protocol requires only one method: retrieving edges from a node. Yet this single requirement enables:

- **Graph traversals**: BFS, DFS, and custom strategies
- **Shortest path algorithms**: Dijkstra, A*, Bellman-Ford
- **Connectivity analysis**: Finding components, cycles, and paths
- **Network flow**: Maximum flow and minimum cut algorithms

### Why This Design?

The minimal protocol design follows several principles:

1. **Locality of Information**: Many graph algorithms only need to know a node's immediate neighbors
2. **Flexibility**: No assumptions about how data is stored or computed
3. **Lazy Evaluation**: Edges can be computed on-demand without materializing the entire graph
4. **Efficiency**: No overhead from unnecessary requirements

## The Graph Protocol

``Graph`` extends ``GraphComponent`` to provide access to all graph elements:

```swift
public protocol Graph<Node, Edge>: GraphComponent {
    var allNodes: [Node] { get }
    var allEdges: [GraphEdge<Node, Edge>] { get }
}
```

### When to Use Graph vs GraphComponent

- **Use GraphComponent when**: You only need local information (traversals, pathfinding)
- **Use Graph when**: You need global information (all nodes, full enumeration)

### Default Implementations

The library provides sensible defaults:

```swift
extension Graph {
    public var allEdges: [GraphEdge<Node, Edge>] {
        allNodes.flatMap(edges)
    }
}
```

This allows graph types to implement just `allNodes`, with `allEdges` computed automatically.

## Specialized Protocols

### BinaryGraphComponent

For binary trees and binary graphs:

```swift
public protocol BinaryGraphComponent<Node, Edge>: GraphComponent {
    func leftEdge(from node: Node) -> GraphEdge<Node, Edge>?
    func rightEdge(from node: Node) -> GraphEdge<Node, Edge>?
}
```

This enables specialized operations like inorder traversal:

```swift
binaryGraph.traverse(from: root, strategy: .dfs(order: .inorder()))
```

### BipartiteGraph

For graphs with two distinct node partitions:

```swift
public protocol BipartiteGraph<LeftNode, RightNode, Edge>: GraphComponent {
    associatedtype LeftNode
    associatedtype RightNode
    
    func edges(from node: LeftNode) -> [GraphEdge<Node, Edge>]
    // ...
}
```

Enables bipartite-specific algorithms:

```swift
bipartiteGraph.maximumMatching(using: .hopcroftKarp())
```

### MutableGraph

For graphs that support dynamic modifications:

```swift
public protocol MutableGraph<Node, Edge>: Graph {
    mutating func addNode(_ node: Node)
    mutating func removeNode(where: (Node) -> Bool)
    mutating func addEdge(_ edge: GraphEdge<Node, Edge>)
    mutating func removeEdge(where: (GraphEdge<Node, Edge>) -> Bool)
}
```

## Protocol Extensions and Conditional Conformance

The library uses protocol extensions to add functionality based on constraints:

### Weighted Graphs

```swift
extension GraphComponent where Edge: Weighted {
    public func shortestPath(from: Node, to: Node, 
                            using: some ShortestPathAlgorithm<Node, Edge>) -> Path<Node, Edge>?
}
```

This method is only available when edges have weights.

### Equatable Nodes

```swift
extension GraphComponent where Node: Equatable {
    public func contains(node: Node) -> Bool
    public func neighbors(of node: Node) -> [Node]
}
```

Convenience methods available when nodes can be compared.

### Hashable Nodes

```swift
extension GraphComponent where Node: Hashable {
    public func shortestPath(from: Node, to: Node) -> Path<Node, Edge>?
    // Uses default Dijkstra algorithm
}
```

Default algorithm selection when efficient lookups are possible.

## Protocol Composition

Protocols can be combined to express complex requirements:

```swift
extension GraphComponent where 
    Node: Hashable,
    Edge: Weighted,
    Edge.Weight: Numeric {
    
    public func minimumSpanningTree(using: some MinimumSpanningTreeAlgorithm<Node, Edge>)
        -> Set<GraphEdge<Node, Edge>>
}
```

This ensures the algorithm is only available when all requirements are met.

## Algorithm Protocols

Each algorithm category defines its own protocol:

### ShortestPathAlgorithm

```swift
public protocol ShortestPathAlgorithm<Node, Edge> {
    func shortestPath(from: Node, to: Node, 
                     in graph: some GraphComponent<Node, Edge>) -> Path<Node, Edge>?
}
```

### GraphTraversalStrategy

```swift
public protocol GraphTraversalStrategy<Node, Edge, Visit> {
    associatedtype Storage
    
    func initializeStorage(startNode: Node) -> Storage
    func next(from storage: inout Storage, 
             graph: some GraphComponent<Node, Edge>) -> Visit?
}
```

### MinimumSpanningTreeAlgorithm

```swift
public protocol MinimumSpanningTreeAlgorithm<Node, Edge> {
    func minimumSpanningTree(in graph: some Graph<Node, Edge>) 
        -> Set<GraphEdge<Node, Edge>>
}
```

## Benefits of Protocol-Oriented Design

### 1. Flexibility

New graph types automatically gain all compatible algorithms:

```swift
struct MyGraph: GraphComponent {
    func edges(from node: String) -> [GraphEdge<String, Int>] {
        // Implementation
    }
}

let graph = MyGraph()
// Immediately available:
graph.traverse(from: "A", strategy: .bfs())
graph.shortestPath(from: "A", to: "B", using: .dijkstra())
```

### 2. Type Safety

Impossible operations are compile-time errors:

```swift
let unweightedGraph: ConnectedGraph<String, Empty> = ...
// Error: method not available for unweighted graphs
unweightedGraph.shortestPath(from: "A", to: "B")
```

### 3. Performance

Generic specialization eliminates runtime overhead:

```swift
// Specialized at compile time for String nodes and Int edges
func analyze(graph: some Graph<String, Int>) {
    graph.traverse(from: "start", strategy: .bfs())
}
```

### 4. Discoverability

Xcode autocomplete shows only applicable methods based on type constraints.

## Real-World Example

Here's how protocols work together in practice:

```swift
// Start with any graph type
let graph = ConnectedGraph(edges: [
    "A": ["B": 4, "C": 2],
    "B": ["D": 5],
    "C": ["D": 1],
    "D": []
])

// GraphComponent enables traversal
let visited = graph.traverse(from: "A", strategy: .bfs())

// Weighted enables shortest path
if let path = graph.shortestPath(from: "A", to: "D") {
    print("Path cost: \(path.cost)")
}

// Graph enables global operations
let allNodes = graph.allNodes
let isConnected = graph.isConnected()
```

## See Also

- <doc:Architecture>
- <doc:StorageAndAlgorithms>
- <doc:GenericConstraints>
