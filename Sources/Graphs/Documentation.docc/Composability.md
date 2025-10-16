# Composability and Graph Transformations

How the library enables powerful graph transformations through composable wrappers and lazy adaptors.

## Overview

The Graphs library embraces Swift's composability patterns, allowing you to transform graph behavior through lightweight wrappers without copying data or modifying the underlying structure. This approach, inspired by Swift's `Collection` transformations like `ReversedCollection`, provides powerful capabilities with minimal overhead.

## The Composability Pattern

### Traditional Approach (Data Copying)

```swift
// Traditional: Create new graph with reversed edges
func transpose(graph: Graph) -> Graph {
    var newGraph = Graph()
    for edge in graph.allEdges {
        newGraph.addEdge(from: edge.destination, to: edge.source, weight: edge.weight)
    }
    return newGraph
}
```

**Problems:**
- O(V + E) time to create
- O(V + E) additional space
- Data duplication
- Mutations don't reflect in original

### Composable Approach (Lazy Wrappers)

```swift
// This library: Lazy wrapper
struct TransposedGraph<Base: GraphComponent>: GraphComponent {
    let base: Base
    
    func edges(from node: Node) -> [GraphEdge<Node, Edge>] {
        // Dynamically compute reversed edges
        base.allEdges
            .filter { $0.destination == node }
            .map(\.reversed)
    }
}

let transposed = graph.transposed()  // O(1) time and space!
```

**Benefits:**
- O(1) creation time
- O(1) additional space (just holds reference)
- Changes to base reflected automatically
- Composable with other transformations

## Core Graph Transformations

### TransposedGraph

Reverses all edge directions:

```swift
let graph = ConnectedGraph(edges: [
    "A": ["B", "C"],
    "B": ["D"],
    "C": ["D"]
])

let transposed = graph.transposed()
// Now: D -> B, D -> C, B -> A, C -> A

// Use case: Finding incoming edges
let incomingToD = transposed.edges(from: "D")
```

**Applications:**
- Computing incoming edges
- Reverse pathfinding
- Strongly connected components (Kosaraju's algorithm)

### UndirectedGraph

Makes all edges bidirectional:

```swift
let directed = ConnectedGraph(edges: [
    "A": ["B"],
    "B": ["C"]
])

let undirected = directed.undirected()
// Now: A <-> B <-> C

// Original directed path
directed.edges(from: "B")    // [B -> C]
// Undirected adds reverse
undirected.edges(from: "B")  // [B -> C, B -> A]
```

**Applications:**
- Undirected graph algorithms on directed graphs
- Social networks (mutual friendships)
- Road networks (bidirectional roads)

### ComplementGraph

Represents the graph's complement:

```swift
let graph = ConnectedGraph(edges: [
    "A": ["B"],
    "B": ["C"],
    "C": ["A"]
])

let complement = graph.complement()
// Edges in complement: A->C, B->A, C->B (all missing edges)
```

**Applications:**
- Independent set problems
- Clique finding
- Graph theory algorithms

### WeightedGraph

Adds weights to unweighted graphs:

```swift
let unweighted = ConnectedGraph(edges: [
    "A": ["B", "C"],
    "B": ["D"]
])

let weighted = unweighted.weighted { edge in
    // Assign weight based on edge
    edge.source.distance(to: edge.destination)
}

// Or with constant weights
let unitWeighted = unweighted.weightedByConstant(1)
```

**Applications:**
- Adding edge costs
- Distance metrics
- Enabling weighted algorithms

### ResidualGraph

Tracks residual capacities for flow networks:

```swift
let network = ConnectedGraph(edges: [
    "S": ["A": 10, "B": 5],
    "A": ["T": 10],
    "B": ["T": 5]
])

let residual = network.residual()
// Tracks flow and updates capacities automatically
```

**Applications:**
- Maximum flow algorithms
- Network optimization
- Capacity planning

### PartitionedGraph

Splits nodes into bipartite partitions:

```swift
let graph = ConnectedGraph(edges: [
    GraphEdge(source: "u1", destination: "v1"),
    GraphEdge(source: "u2", destination: "v2"),
    GraphEdge(source: "u1", destination: "v2")
])

let bipartite = graph.bipartite(
    leftPartition: ["u1", "u2"],
    rightPartition: ["v1", "v2"]
)

// Now can use bipartite algorithms
bipartite.maximumMatching(using: .hopcroftKarp())
```

**Applications:**
- Job assignment problems
- Bipartite matching
- Two-coloring

## Composition Chains

Transformations can be chained for powerful combinations:

### Example 1: Undirected Weighted Graph

```swift
let directed = ConnectedGraph(edges: ["A": ["B"], "B": ["C"]])

let undirectedWeighted = directed
    .undirected()
    .weighted { edge in
        computeWeight(from: edge.source, to: edge.destination)
    }

// Now: undirected AND weighted
let mst = undirectedWeighted.minimumSpanningTree(using: .kruskal())
```

### Example 2: Transposed with Complement

```swift
let graph = ConnectedGraph(edges: [...])

let reversed = graph
    .transposed()          // Reverse edges
    .complement()          // Take complement
    .undirected()          // Make bidirectional

// Complex transformation applied lazily
```

### Example 3: Filtered Subgraph

```swift
let fullGraph = ConnectedGraph(edges: cityRoads)

let filteredGraph = fullGraph
    .filtered { edge in
        edge.value.distance < 50  // Only short roads
    }
    .undirected()
    .weighted(by: \.value.time)   // Weight by travel time

let quickRoute = filteredGraph.shortestPath(from: home, to: work)
```

## Grid Graph Transformations

``GridGraph`` has specialized transformations:

```swift
let grid = GridGraph(grid: [
    ["A", "B", "C"],
    ["D", "E", "F"],
    ["G", "H", "I"]
], availableDirections: .orthogonal)

// Add diagonal connections
let withDiagonals = grid.with(directions: .all)

// Add weights based on grid values
let weightedGrid = grid.weightedByDistance()

// Add terrain costs
let terrainGrid = grid.weighted { edge in
    terrainCost(at: edge.destination)
}
```

## Custom Transformations

You can create your own graph transformations:

### Filtered Graph

```swift
struct FilteredGraph<Base: GraphComponent>: GraphComponent {
    let base: Base
    let predicate: (GraphEdge<Node, Edge>) -> Bool
    
    func edges(from node: Node) -> [GraphEdge<Node, Edge>] {
        base.edges(from: node).filter(predicate)
    }
}

extension GraphComponent {
    func filtered(_ predicate: @escaping (GraphEdge<Node, Edge>) -> Bool) 
        -> FilteredGraph<Self> {
        FilteredGraph(base: self, predicate: predicate)
    }
}

// Usage
let highway = roadNetwork.filtered { $0.value.type == .highway }
```

### Mapped Graph

```swift
struct MappedGraph<Base: GraphComponent, NewEdge>: GraphComponent {
    let base: Base
    let transform: (Base.Edge) -> NewEdge
    
    func edges(from node: Node) -> [GraphEdge<Node, NewEdge>] {
        base.edges(from: node).map { edge in
            edge.mapEdge(transform)
        }
    }
}

extension GraphComponent {
    func mapEdges<NewEdge>(_ transform: @escaping (Edge) -> NewEdge) 
        -> MappedGraph<Self, NewEdge> {
        MappedGraph(base: self, transform: transform)
    }
}

// Usage
let distances = routes.mapEdges(\.distance)
```

### Cached Graph

```swift
struct CachedGraph<Base: GraphComponent>: GraphComponent where Base.Node: Hashable {
    let base: Base
    var cache: [Node: [GraphEdge<Node, Edge>]] = [:]
    
    mutating func edges(from node: Node) -> [GraphEdge<Node, Edge>] {
        if let cached = cache[node] {
            return cached
        }
        let edges = base.edges(from: node)
        cache[node] = edges
        return edges
    }
}
```

## Transformation Performance

All transformations are **lazy** and have minimal overhead:

| Transformation | Creation Cost | Space Overhead | Edge Lookup Impact |
|---------------|---------------|----------------|-------------------|
| `transposed()` | O(1) | O(1) | O(E) per lookup |
| `undirected()` | O(1) | O(1) | 2x edges returned |
| `complement()` | O(1) | O(1) | O(V) per lookup |
| `weighted()` | O(1) | O(1) | Same + transform |
| `bipartite()` | O(1) | O(V) for partitions | Same as base |
| `filtered()` | O(1) | O(1) | Same + filter |

## Real-World Examples

### Social Network Analysis

```swift
// Start with directed follows
let follows = ConnectedGraph<User, Empty>(edges: followData)

// Analyze mutual connections
let mutual = follows
    .undirected()  // Make bidirectional
    .filtered { edge in
        follows.edges(from: edge.destination).contains { $0.destination == edge.source }
    }

// Find communities
let communities = mutual.stronglyConnectedComponents()
```

### Route Planning with Constraints

```swift
let roads = ConnectedHashGraph<Location, Route>(edges: roadData)

// Find accessible route (no tolls, wheelchair accessible)
let accessible = roads
    .filtered { $0.value.toll == 0 && $0.value.accessible }
    .weighted(by: \.value.distance)

let route = accessible.shortestPath(
    from: start,
    to: destination,
    using: .dijkstra()
)
```

### Multi-Modal Transportation

```swift
let walking = ConnectedGraph<Location, Distance>(edges: walkingPaths)
let bus = ConnectedGraph<Location, BusRoute>(edges: busRoutes)
let train = ConnectedGraph<Location, TrainRoute>(edges: trainRoutes)

// Combine into multi-modal graph
let combined = walking
    .union(bus.weighted(by: \.travelTime))
    .union(train.weighted(by: \.travelTime))
    .weighted { edge in
        // Add transfer penalties
        edge.value + transferPenalty(for: edge)
    }

let bestRoute = combined.shortestPath(from: home, to: work)
```

### Network Flow with Preferences

```swift
let network = ConnectedGraph<Node, Capacity>(edges: capacities)

// Prefer certain paths
let preferred = network.weighted { edge in
    edge.value.capacity * (isPreferred(edge) ? 0.8 : 1.0)
}

let maxFlow = preferred.maximumFlow(
    from: source,
    to: sink,
    using: .dinic()
)
```

## Materialization

Sometimes you want to materialize a transformed graph:

```swift
let transformed = graph
    .transposed()
    .undirected()
    .filtered { $0.value > 10 }

// Materialize into concrete graph
let materialized = ConnectedGraph(
    edges: transformed.allEdges
)

// Or into hash graph for better performance
let hashedMaterialized = ConnectedHashGraph(
    edges: transformed.allEdges,
    hashValue: \.hashValue
)
```

## Lazy Graphs and Transformations

Transformations work especially well with ``LazyGraph``:

```swift
let infinite = LazyGraph<(Int, Int), Empty> { (x, y) in
    [(x+1, y), (x-1, y), (x, y+1), (x, y-1)]
        .map { GraphEdge(source: (x, y), destination: $0) }
}

let weighted = infinite.weighted { edge in
    // Compute weight dynamically
    distance(from: edge.source, to: edge.destination)
}

let bounded = weighted.filtered { edge in
    // Bound the infinite graph
    abs(edge.destination.0) < 100 && abs(edge.destination.1) < 100
}

// Now can use on bounded, weighted, lazy graph
let path = bounded.shortestPath(
    from: (0, 0),
    to: (50, 50),
    using: .aStar(heuristic: .manhattanDistance)
)
```

## Benefits of Composability

### Memory Efficiency
- No data duplication
- Transformations share underlying storage
- Perfect for large graphs

### Performance
- Lazy evaluation
- Only compute what's needed
- Optimizations propagate through chain

### Expressiveness
- Declarative transformations
- Clear intent
- Chainable operations

### Flexibility
- Mix and match transformations
- Create custom transformations easily
- Reuse across different graph types

## See Also

- <doc:Architecture>
- <doc:StorageAndAlgorithms>
- ``TransposedGraph``
- ``UndirectedGraph``
- ``WeightedGraph``
- ``ComplementGraph``
