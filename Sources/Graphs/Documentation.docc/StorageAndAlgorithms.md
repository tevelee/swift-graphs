# Storage and Algorithm Separation

How the library separates graph storage strategies from algorithm implementations, inspired by the Boost Graph Library.

## Overview

One of the most powerful aspects of the Graphs library is the complete separation between how graphs store data and how algorithms process that data. This design, inspired by the Boost Graph Library (BGL), enables unprecedented flexibility and reusability.

## The Separation Principle

### Traditional Approach (Coupled)

In traditional graph libraries, storage and algorithms are tightly coupled:

```swift
// Traditional approach
class Graph {
    private var adjacencyList: [Node: [Edge]]
    
    func dijkstra(from: Node, to: Node) -> Path {
        // Algorithm directly accesses adjacencyList
        for neighbor in adjacencyList[current]! { ... }
    }
}
```

**Problems:**
- Algorithm tied to specific storage format
- Can't use algorithm on different graph types
- Hard to add new storage strategies
- Difficult to optimize for different use cases

### This Library's Approach (Separated)

```swift
// Storage: Just provide edges from a node
struct ConnectedGraph<Node, Edge>: GraphComponent {
    func edges(from node: Node) -> [GraphEdge<Node, Edge>] {
        // Storage implementation
    }
}

// Algorithm: Works with any GraphComponent
struct DijkstraAlgorithm<Node, Edge>: ShortestPathAlgorithm {
    func shortestPath(from: Node, to: Node, 
                     in graph: some GraphComponent<Node, Edge>) -> Path? {
        // Algorithm only uses graph.edges(from:)
        for edge in graph.edges(from: current) { ... }
    }
}
```

**Benefits:**
- Algorithm works with ANY graph type
- Easy to add new storage strategies
- Storage can be optimized independently
- Algorithms remain clean and focused

## Storage Strategies

The library provides multiple storage strategies, each optimized for different scenarios:

### 1. Eager Array-Based Storage

``ConnectedGraph`` and ``DisjointGraph`` store edges in arrays:

```swift
public struct ConnectedGraph<Node, Edge>: Graph {
    let _edges: [GraphEdge<Node, Edge>]
    
    public func edges(from node: Node) -> [GraphEdge<Node, Edge>] {
        _edges.filter { isEqual($0.source, node) }
    }
}
```

**Best for:**
- Small to medium graphs
- When you need to iterate all edges frequently
- Immutable graphs

**Trade-offs:**
- O(E) to find edges from a node
- O(E) space complexity
- Simple, predictable performance

### 2. Hash-Based Storage

``ConnectedHashGraph`` and ``DisjointHashGraph`` use hash tables:

```swift
public struct ConnectedHashGraph<Node, Edge, HashValue: Hashable>: Graph {
    private var _edges: [HashValue: [GraphEdge<Node, Edge>]]
    
    public func edges(from node: Node) -> [GraphEdge<Node, Edge>] {
        _edges[hashValue(node)] ?? []
    }
}
```

**Best for:**
- Large graphs
- Frequent edge lookups
- When nodes have good hash functions

**Trade-offs:**
- O(1) average case for edge lookup
- O(V + E) space complexity
- Requires hashable or custom hash function

### 3. Lazy Evaluation

``LazyGraph`` computes edges on-demand:

```swift
public struct LazyGraph<Node, Edge>: GraphComponent {
    let _edges: (Node) -> [GraphEdge<Node, Edge>]
    
    public func edges(from node: Node) -> [GraphEdge<Node, Edge>] {
        _edges(node)  // Computed fresh each time
    }
}

// Example: Infinite graph
let infiniteGrid = LazyGraph<(Int, Int), Empty> { (x, y) in
    [
        GraphEdge(source: (x, y), destination: (x+1, y)),
        GraphEdge(source: (x, y), destination: (x, y+1)),
        GraphEdge(source: (x, y), destination: (x-1, y)),
        GraphEdge(source: (x, y), destination: (x, y-1))
    ]
}
```

**Best for:**
- Infinite or very large graphs
- Dynamically generated graphs
- When storing all edges is impractical

**Trade-offs:**
- No storage overhead for edges
- Computation cost each time edges are accessed
- Cannot enumerate all nodes without bounds

### 4. Grid-Based Storage

``GridGraph`` uses 2D array storage:

```swift
public struct GridGraph<Value>: Graph {
    let grid: [[Value]]
    let availableDirections: GridDirection
    
    public func edges(from node: GridPosition) -> [GraphEdge<GridPosition, Empty>] {
        // Efficiently compute neighbors in grid
        availableDirections.neighbors(of: node, in: grid)
            .map { GraphEdge(source: node, destination: $0) }
    }
}
```

**Best for:**
- Grid-based problems (pathfinding on maps, cellular automata)
- Spatial algorithms
- Regular structure graphs

**Trade-offs:**
- O(1) edge lookup
- O(V) space for grid structure
- Limited to 2D regular topology

### 5. Binary Tree Storage

``ConnectedBinaryGraph`` optimizes for binary trees:

```swift
public struct ConnectedBinaryGraph<Node, Edge>: BinaryGraphComponent {
    let _edges: [Node: (left: GraphEdge?, right: GraphEdge?)]
    
    func leftEdge(from node: Node) -> GraphEdge<Node, Edge>? {
        _edges[node]?.left
    }
    
    func rightEdge(from node: Node) -> GraphEdge<Node, Edge>? {
        _edges[node]?.right
    }
}
```

**Best for:**
- Binary trees
- Algorithms requiring left/right distinction
- Inorder/preorder/postorder traversals

## Algorithm Independence

Algorithms work uniformly across all storage strategies:

```swift
let arrayGraph = ConnectedGraph(edges: [...])
let hashGraph = ConnectedHashGraph(edges: [...])
let lazyGraph = LazyGraph { node in [...] }
let gridGraph = GridGraph(grid: [[...]])

// Same algorithm works on all types
for graph in [arrayGraph, hashGraph, lazyGraph, gridGraph] {
    let path = graph.shortestPath(from: start, to: goal, using: .dijkstra())
    let mst = graph.minimumSpanningTree(using: .kruskal())
    let nodes = graph.traverse(from: start, strategy: .bfs())
}
```

### How It Works

Algorithms are written against the ``GraphComponent`` protocol:

```swift
extension GraphComponent {
    func breadthFirstSearch(from start: Node) -> [Node] {
        var queue: [Node] = [start]
        var visited: Set<Node> = []
        var result: [Node] = []
        
        while let current = queue.removeFirst() {
            if visited.insert(current).inserted {
                result.append(current)
                // Only protocol requirement used:
                for edge in edges(from: current) {
                    queue.append(edge.destination)
                }
            }
        }
        
        return result
    }
}
```

The algorithm never knows or cares about the underlying storage!

## Choosing the Right Storage

### Decision Matrix

| Scenario | Recommended Storage | Rationale |
|----------|-------------------|-----------|
| Small graph (<1000 nodes) | `ConnectedGraph` | Simple, sufficient performance |
| Large graph, frequent lookups | `ConnectedHashGraph` | O(1) edge access |
| Infinite/procedural graph | `LazyGraph` | No storage overhead |
| Grid/map pathfinding | `GridGraph` | Optimized for spatial structure |
| Binary tree operations | `ConnectedBinaryGraph` | Specialized binary operations |
| Database-backed graph | Custom `GraphComponent` | On-demand querying |

### Performance Characteristics

```swift
// Array-based: Good for small graphs
let small = ConnectedGraph(edges: edges)
// O(E) edge lookup, O(E) space

// Hash-based: Better for large graphs
let large = ConnectedHashGraph(edges: edges)
// O(1) edge lookup, O(V+E) space

// Lazy: Best for very large/infinite
let infinite = LazyGraph { node in computeEdges(node) }
// O(1) space, O(computation) edge lookup
```

## Adding Custom Storage

You can create custom storage strategies by conforming to ``GraphComponent``:

```swift
// Example: Database-backed graph
struct DatabaseGraph: GraphComponent {
    let db: Database
    
    func edges(from node: UserID) -> [GraphEdge<UserID, Empty>] {
        db.query("""
            SELECT friend_id FROM friendships 
            WHERE user_id = ?
        """, node).map { friendID in
            GraphEdge(source: node, destination: friendID)
        }
    }
}

// All algorithms immediately work:
let dbGraph = DatabaseGraph(db: database)
let friends = dbGraph.traverse(from: currentUser, strategy: .bfs())
```

### Custom Optimized Storage

```swift
// Example: Compressed sparse row (CSR) format
struct CSRGraph<Node: Hashable, Edge>: Graph {
    let nodes: [Node]
    let edges: [GraphEdge<Node, Edge>]
    let rowPointers: [Int]
    
    func edges(from node: Node) -> [GraphEdge<Node, Edge>] {
        guard let index = nodes.firstIndex(of: node) else { return [] }
        let start = rowPointers[index]
        let end = index + 1 < rowPointers.count ? rowPointers[index + 1] : edges.count
        return Array(edges[start..<end])
    }
    
    var allNodes: [Node] { nodes }
    var allEdges: [GraphEdge<Node, Edge>] { edges }
}
```

## Real-World Example: Multiple Representations

Here's how the same graph problem benefits from different storage:

```swift
// Problem: Social network analysis

// Eager storage: For small friend groups
let friendGroup = ConnectedGraph(edges: [
    "Alice": ["Bob", "Charlie"],
    "Bob": ["Alice", "David"],
    "Charlie": ["Alice"],
    "David": ["Bob"]
])

// Hash storage: For large social network
let socialNetwork = ConnectedHashGraph(
    edges: millionsOfFriendships
)

// Lazy storage: For exploring recommendations
let recommendations = LazyGraph<UserID, Empty> { user in
    // Compute friend suggestions on-demand
    recommendationEngine.suggest(for: user).map { suggested in
        GraphEdge(source: user, destination: suggested)
    }
}

// Same algorithm on all:
func analyzeNetwork(_ network: some GraphComponent<UserID, Empty>) {
    let components = network.stronglyConnectedComponents(using: .tarjan())
    let centrality = network.betweennessCentrality()
}
```

## See Also

- <doc:Architecture>
- <doc:ProtocolOrientedDesign>
- <doc:Composability>
- ``GraphComponent``
- ``Graph``
- ``ConnectedGraph``
- ``LazyGraph``
- ``GridGraph``
