# Quick Reference Guide

Fast lookup for common tasks and algorithm selection.

## Common Tasks

### Creating a Graph

```swift
// Simple graph
let graph = ConnectedGraph(edges: [
    "A": ["B", "C"],
    "B": ["D"]
])

// Weighted graph
let weighted = ConnectedGraph(edges: [
    "A": ["B": 5, "C": 3],
    "C": ["D": 2]
])

// From edge list
let edges = [
    GraphEdge(source: "A", destination: "B", value: 5),
    GraphEdge(source: "B", destination: "C", value: 3)
]
let graph = ConnectedGraph(edges: edges)

// Grid graph
let grid = GridGraph(grid: [
    [".", ".", "."],
    [".", "#", "."],
    [".", ".", "."]
], availableDirections: .orthogonal)

// Lazy graph
let lazy = LazyGraph<Int, Empty> { node in
    [(node * 2), (node * 2 + 1)].map { 
        GraphEdge(source: node, destination: $0)
    }
}
```

### Traversing a Graph

```swift
// BFS
let bfs = graph.traverse(from: start, strategy: .bfs())

// DFS
let dfs = graph.traverse(from: start, strategy: .dfs())

// With path tracking
for visit in graph.traversal(from: start, strategy: .bfs().trackPath()) {
    print("\(visit.node): \(visit.path)")
}
```

### Finding Shortest Paths

```swift
// Single path (Dijkstra)
let path = graph.shortestPath(from: "A", to: "D")

// With specific algorithm
let path = graph.shortestPath(from: "A", to: "D", using: .aStar(heuristic: ...))

// All paths from source
let paths = graph.shortestPaths(from: "A", using: .dijkstra())

// All pairs
let allPaths = graph.shortestPathsForAllPairs(using: .floydWarshall())
```

### Graph Properties

```swift
// Connectivity
graph.isConnected()
graph.connectedComponents()
graph.stronglyConnectedComponents(using: .tarjan())

// Cycles
graph.isCyclic()
graph.findCycles()

// Structure
graph.isTree()
graph.isBipartite()
graph.topologicalSort()

// Metrics
graph.degreeDistribution()
graph.clusteringCoefficient()
graph.diameter()
```

### Optimization Problems

```swift
// Minimum spanning tree
let mst = graph.undirected().minimumSpanningTree(using: .kruskal())

// Maximum flow
let flow = network.maximumFlow(from: source, to: sink, using: .dinic())

// Bipartite matching
let matching = bipartite.maximumMatching(using: .hopcroftKarp())

// Graph coloring
let coloring = graph.colorNodes(using: .dsatur())
```

## Algorithm Selection

### Which Shortest Path Algorithm?

| Scenario | Use | Complexity |
|----------|-----|------------|
| Non-negative weights | `Dijkstra` | O((V+E)log V) |
| Grid with heuristic | `A*` | O((V+E)log V) |
| Negative weights | `BellmanFord` | O(VE) |
| All pairs, dense | `FloydWarshall` | O(V³) |
| All pairs, sparse | `Johnson` | O(V²log V + VE) |
| Long paths | `BidirectionalDijkstra` | O((V+E)log V) |

```swift
// Examples
graph.shortestPath(from: a, to: b, using: .dijkstra())
graph.shortestPath(from: a, to: b, using: .aStar(heuristic: .euclidean))
graph.shortestPath(from: a, to: b, using: .bellmanFord())
```

### Which MST Algorithm?

| Graph Type | Use | Complexity |
|------------|-----|------------|
| Sparse (E ≈ V) | `Kruskal` | O(E log E) |
| Dense (E ≈ V²) | `Prim` | O(E log V) |
| Parallel needs | `Boruvka` | O(E log V) |

```swift
graph.minimumSpanningTree(using: .kruskal())
graph.minimumSpanningTree(using: .prim())
graph.minimumSpanningTree(using: .boruvka())
```

### Which Flow Algorithm?

| Network Type | Use | Complexity |
|--------------|-----|------------|
| General | `EdmondsKarp` | O(VE²) |
| Dense | `Dinic` | O(V²E) |
| Integer capacities | `FordFulkerson` | O(E × f) |

```swift
network.maximumFlow(from: s, to: t, using: .edmondsKarp())
network.maximumFlow(from: s, to: t, using: .dinic())
```

### Which Traversal Strategy?

| Goal | Use |
|------|-----|
| Shortest path (unweighted) | `BFS` |
| Deep exploration | `DFS` |
| Topological order | `DFS(postorder)` |
| Binary tree sorted | `DFS(inorder)` |
| Priority-based | `Priority` |
| Limited depth | `Limited` |

```swift
graph.traverse(from: start, strategy: .bfs())
graph.traverse(from: start, strategy: .dfs(order: .postorder()))
graph.traverse(from: start, strategy: .priority { $0.priority })
```

## Graph Type Selection

### Storage Strategy

| Scenario | Use |
|----------|-----|
| Small graph (<1000 nodes) | `ConnectedGraph` |
| Large with lookups | `ConnectedHashGraph` |
| Infinite/procedural | `LazyGraph` |
| 2D grid/map | `GridGraph` |
| Binary tree | `ConnectedBinaryGraph` |

```swift
ConnectedGraph(edges: edges)
ConnectedHashGraph(edges: edges, hashValue: \.id)
LazyGraph { node in computeEdges(node) }
GridGraph(grid: grid, availableDirections: .all)
```

### Graph Transformations

| Need | Use |
|------|-----|
| Bidirectional edges | `.undirected()` |
| Reverse edges | `.transposed()` |
| Add weights | `.weighted { ... }` |
| Filter edges | `.filtered { ... }` |
| Graph complement | `.complement()` |

```swift
directed.undirected()
graph.transposed()
graph.weighted { edge in computeWeight(edge) }
graph.filtered { edge in edge.value > threshold }
```

## Common Patterns

### Path Finding

```swift
// Simple path
if let path = graph.shortestPath(from: start, to: goal) {
    print("Path: \(path.path)")
    print("Cost: \(path.cost)")
}

// Multiple alternatives
let alternatives = graph.kShortestPaths(from: start, to: goal, k: 5)
```

### Network Analysis

```swift
// Community detection
let communities = network.stronglyConnectedComponents(using: .tarjan())

// Centrality
let centrality = network.betweennessCentrality()
let important = centrality.max { $0.value < $1.value }

// Structure
let density = network.density()
let clustering = network.clusteringCoefficient()
```

### Scheduling

```swift
// Task dependencies
let tasks = ConnectedGraph(edges: dependencies)

if let order = tasks.topologicalSort() {
    for task in order {
        execute(task)
    }
}
```

### Assignment Problems

```swift
// Workers to jobs
let bipartite = graph.bipartite(
    leftPartition: workers,
    rightPartition: jobs
)
let assignment = bipartite.maximumMatching(using: .hopcroftKarp())
```

### Testing and Simulation

```swift
// Generate test graphs
let random = ConnectedGraph<Int, Empty>.random(
    nodeCount: 100,
    using: .erdosRenyi(probability: 0.05)
)

let scaleFree = ConnectedGraph<Int, Empty>.random(
    nodeCount: 100,
    using: .barabasiAlbert(attachmentCount: 3)
)

let smallWorld = ConnectedGraph<Int, Empty>.random(
    nodeCount: 100,
    using: .wattsStrogatz(neighbors: 4, rewiringProbability: 0.1)
)
```

## Type Constraints Quick Reference

### Requirements for Common Operations

```swift
// Shortest path needs:
// - Node: Hashable
// - Edge: Weighted
// - Edge.Weight: Numeric

// MST needs:
// - Node: Hashable
// - Edge: Weighted
// - Edge.Weight: Comparable

// Flow needs:
// - Node: Hashable
// - Edge: Weighted
// - Edge.Weight: Numeric

// Coloring needs:
// - Node: Hashable
// - Usually unweighted (Edge == Empty)
```

## Performance Tips

### Optimization Checklist

1. **Choose right storage**:
   - Large graphs → `ConnectedHashGraph`
   - Sparse graphs → `ConnectedGraph`
   - Procedural → `LazyGraph`

2. **Choose right algorithm**:
   - Sparse MST → Kruskal
   - Dense MST → Prim
   - Non-negative paths → Dijkstra
   - Negative weights → Bellman-Ford

3. **Use transformations wisely**:
   - Chain transformations are lazy (O(1))
   - Materialize only when needed
   - Filter before expensive operations

4. **Leverage type system**:
   - Let compiler specialize generics
   - Use `@inlinable` for custom algorithms
   - Constrain types appropriately

## Error Handling

```swift
// Check preconditions
guard graph.isConnected() else {
    throw GraphError.notConnected
}

guard !graph.isCyclic() else {
    throw GraphError.containsCycle
}

// Handle optional results
if let path = graph.shortestPath(from: a, to: b) {
    // Path found
} else {
    // No path exists
}

// Validate algorithms
if graph.hasEulerianCycle() {
    let cycle = graph.eulerianCycle(using: .hierholzer())!
}
```

## See Also

- <doc:CodeExamples>
- <doc:Architecture>
- <doc:TraversalAlgorithms>
- <doc:ShortestPathAlgorithms>
- <doc:MinimumSpanningTree>
- <doc:FlowAndMatching>
