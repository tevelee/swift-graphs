# Architecture Overview

A comprehensive guide to the design philosophy and architectural principles of the Graphs library.

## Overview

The Graphs library is built on a foundation of protocol-oriented design, drawing inspiration from the Boost Graph Library (BGL) and Swift's standard library. The architecture emphasizes separation of concerns, composability, and type safety while maintaining performance and flexibility.

## Core Design Principles

### 1. Protocol-Oriented Architecture

At the heart of the library is ``GraphComponent``, a minimal protocol that defines the essential contract for graph-like structures:

```swift
protocol GraphComponent<Node, Edge> {
    associatedtype Node
    associatedtype Edge = Empty
    
    func edges(from node: Node) -> [GraphEdge<Node, Edge>]
}
```

This single requirement—providing edges from a node—is sufficient to support a vast array of graph algorithms. By keeping the protocol minimal, we enable maximum flexibility in how graphs are represented and computed.

### 2. Separation of Storage and Algorithms

Similar to BGL's separation of graph data structures from algorithms, this library completely decouples:

- **Storage strategies**: How graph data is stored (array-based, hash-based, lazy evaluation, etc.)
- **Algorithm implementations**: How graph problems are solved (Dijkstra, DFS, Kruskal, etc.)

This separation allows:
- The same algorithm to work on any conforming graph type
- Multiple storage strategies optimized for different use cases
- Easy addition of new graph types without modifying algorithms

### 3. Generic Constraints for Type Safety

The library uses Swift's powerful type system to enforce correctness at compile time:

```swift
// Shortest path requires weighted edges
extension GraphComponent where Edge: Weighted {
    func shortestPath(from: Node, to: Node, 
                     using: some ShortestPathAlgorithm<Node, Edge>)
}

// Dijkstra requires non-negative weights
struct DijkstraAlgorithm<Node: Hashable, Edge: Weighted>: ShortestPathAlgorithm
    where Edge.Weight: Numeric, Edge.Weight.Magnitude == Edge.Weight
```

These constraints prevent misuse (like running Dijkstra on graphs with negative weights) while maintaining flexibility.

### 4. Composable Abstractions

The library provides composable wrappers that transform graph behavior without changing the underlying data:

- ``WeightedGraph``: Adds weights to edges
- ``UndirectedGraph``: Makes edges bidirectional
- ``TransposedGraph``: Reverses edge directions
- ``ComplementGraph``: Represents the graph's complement
- ``ResidualGraph``: Tracks residual capacities for flow networks

These transformations are lazy and efficient, following Swift's standard library patterns like `ReversedCollection`.

## Hierarchy of Graph Abstractions

The library defines a hierarchy of protocols, each building on the previous:

```
GraphComponent (minimal: edges from a node)
    ↓
Graph (adds: all nodes and edges enumeration)
    ↓
MutableGraph (adds: node/edge insertion and removal)

Specialized variants:
    - BinaryGraphComponent (binary tree operations)
    - BipartiteGraph (two-partition graphs)
```

## Algorithm Organization

Algorithms are organized by category and share common patterns:

### Protocol-Based Algorithms

Each algorithm category defines a protocol:

```swift
protocol ShortestPathAlgorithm<Node, Edge> {
    func shortestPath(from: Node, to: Node, 
                     in graph: some GraphComponent<Node, Edge>) -> Path<Node, Edge>?
}
```

### Multiple Implementations

Each protocol has multiple concrete implementations:

- **Shortest Path**: Dijkstra, A*, Bellman-Ford, Bidirectional Dijkstra
- **MST**: Kruskal, Prim, Borůvka
- **Max Flow**: Ford-Fulkerson, Edmonds-Karp, Dinic

### Consistent API

Users interact with algorithms through uniform APIs:

```swift
// Generic version
graph.shortestPath(from: start, to: goal, using: .dijkstra())

// Default algorithm (when constraints are met)
graph.shortestPath(from: start, to: goal)
```

## Performance Considerations

The library balances flexibility with performance:

1. **Generic specialization**: Swift's generics specialize at compile time for optimal performance
2. **Inline hints**: Critical paths use `@inlinable` for cross-module optimization
3. **Lazy evaluation**: Algorithms work with sequences when possible to avoid materialization
4. **Caching**: Strategic caching of expensive computations (like `allNodes` in `ConnectedGraph`)

## Extensibility Points

The architecture provides multiple extension points:

### Custom Graph Types

Implement ``GraphComponent`` to create custom graph representations:

```swift
struct DatabaseGraph: GraphComponent {
    func edges(from node: UserID) -> [GraphEdge<UserID, Empty>] {
        // Query database for user's connections
        database.query("SELECT friend_id FROM friendships WHERE user_id = ?", node)
            .map { GraphEdge(source: node, destination: $0) }
    }
}
```

### Custom Algorithms

Implement algorithm protocols to provide alternative implementations:

```swift
struct MyCustomShortestPath: ShortestPathAlgorithm {
    func shortestPath(from: Node, to: Node, 
                     in graph: some GraphComponent<Node, Edge>) -> Path<Node, Edge>? {
        // Your implementation
    }
}

// Use it like any other algorithm
graph.shortestPath(from: a, to: b, using: MyCustomShortestPath())
```

### Custom Traversal Strategies

Implement ``GraphTraversalStrategy`` for custom traversal behavior:

```swift
struct CustomStrategy: GraphTraversalStrategy {
    // Define how nodes are visited
}

graph.traverse(from: start, strategy: CustomStrategy())
```

## Comparison to Boost Graph Library (BGL)

The library draws several concepts from BGL while adapting them to Swift:

| BGL Concept | Swift Graphs Equivalent | Notes |
|-------------|------------------------|-------|
| Graph concepts | `GraphComponent`, `Graph` protocols | Protocol-oriented instead of concept checking |
| Property maps | `Weighted` protocol, edge values | Type-safe through generics |
| Visitors | `GraphTraversalStrategy`, visitor extensions | Composable strategies |
| Graph adaptors | `TransposedGraph`, `UndirectedGraph`, etc. | Lazy wrappers |
| Algorithm objects | `ShortestPathAlgorithm`, etc. | Protocol-based polymorphism |

## See Also

- <doc:ProtocolOrientedDesign>
- <doc:StorageAndAlgorithms>
- <doc:GenericConstraints>
- <doc:Composability>
