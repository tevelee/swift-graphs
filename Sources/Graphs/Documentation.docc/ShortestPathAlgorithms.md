# Shortest Path Algorithms

Complete guide to finding shortest paths in weighted and unweighted graphs.

## Overview

The library provides a comprehensive suite of shortest path algorithms, each optimized for different graph properties and use cases. All algorithms work through a common protocol-based interface while offering specialized optimizations.

## Algorithm Categories

The library organizes shortest path algorithms into three categories:

1. **Single-Pair Shortest Path**: Find path between two specific nodes
2. **Single-Source Shortest Paths**: Find paths from one node to all others
3. **All-Pairs Shortest Paths**: Find shortest paths between all node pairs

## Single-Pair Shortest Path

### Dijkstra's Algorithm

The most commonly used shortest path algorithm for graphs with non-negative weights.

```swift
let graph = ConnectedGraph(edges: [
    "A": ["B": 4, "C": 2],
    "B": ["D": 5],
    "C": ["B": 1, "D": 8],
    "D": []
])

let path = graph.shortestPath(from: "A", to: "D", using: .dijkstra())
// Path: A -> C -> B -> D, Cost: 8
```

**Characteristics:**
- **Time Complexity**: O((V + E) log V) with binary heap
- **Space Complexity**: O(V)
- **Requirement**: Non-negative edge weights
- **Optimality**: Always finds optimal path

**How it works:**
1. Maintain a priority queue of nodes by distance
2. Always explore the closest unvisited node
3. Update distances to neighbors if shorter path found
4. Terminate when destination reached

**Type Constraints:**
```swift
struct DijkstraAlgorithm<Node: Hashable, Edge: Weighted>: ShortestPathAlgorithm
where Edge.Weight: Numeric, Edge.Weight.Magnitude == Edge.Weight {
    // Edge.Weight.Magnitude == Edge.Weight ensures non-negative
}
```

**Best For:**
- Road networks
- Network routing
- General graphs with positive weights
- When you need guaranteed optimal solution

### A* (A-Star) Algorithm

Dijkstra enhanced with heuristic guidance for faster pathfinding.

```swift
struct Location: Hashable {
    let x, y: Double
}

let cityMap = GridGraph(grid: cityLayout)

let path = cityMap.shortestPath(
    from: home,
    to: work,
    using: .aStar(heuristic: .euclideanDistance(of: \.coordinates))
)
```

**Characteristics:**
- **Time Complexity**: O((V + E) log V) - often faster in practice
- **Space Complexity**: O(V)
- **Requirement**: Non-negative weights + admissible heuristic
- **Optimality**: Optimal if heuristic is admissible (never overestimates)

**Built-in Heuristics:**

```swift
// Euclidean distance (straight-line distance)
.aStar(heuristic: .euclideanDistance(of: \.coordinates))

// Manhattan distance (grid/city-block distance)
.aStar(heuristic: .manhattanDistance(of: \.coordinates))

// Chebyshev distance (chessboard distance)
.aStar(heuristic: .chebyshevDistance(of: \.coordinates))

// Custom heuristic
.aStar(heuristic: .custom { from, to in
    estimatedCost(from: from, to: to)
})
```

**Heuristic Requirements:**
- **Admissible**: Never overestimate the true cost
- **Consistent**: h(n) ≤ cost(n, n') + h(n')

**Best For:**
- Grid-based pathfinding (games, robotics)
- Geographic routing
- When you have domain knowledge for heuristics
- Need fast pathfinding in practice

### Bellman-Ford Algorithm

Handles graphs with negative edge weights and detects negative cycles.

```swift
let graph = ConnectedGraph(edges: [
    "A": ["B": 4, "C": 2],
    "B": ["C": -3, "D": 2],
    "C": ["D": 3],
    "D": []
])

if let path = graph.shortestPath(from: "A", to: "D", using: .bellmanFord()) {
    print("Path found: \(path)")
} else {
    print("Negative cycle detected")
}
```

**Characteristics:**
- **Time Complexity**: O(VE)
- **Space Complexity**: O(V)
- **Requirement**: No requirement on edge weights
- **Capability**: Detects negative cycles

**How it works:**
1. Initialize distances to infinity (except source = 0)
2. Relax all edges V-1 times
3. Check for negative cycles on Vth iteration

**Best For:**
- Graphs with negative weights
- Currency arbitrage detection
- When negative cycles need detection
- Constraint satisfaction problems

**Type Constraints:**
```swift
struct BellmanFordAlgorithm<Node: Hashable, Edge: Weighted>: ShortestPathAlgorithm
where Edge.Weight: SignedNumeric {
    // SignedNumeric allows negative weights
}
```

### Bidirectional Dijkstra

Searches from both source and destination simultaneously.

```swift
let path = graph.shortestPath(
    from: start,
    to: goal,
    using: .bidirectionalDijkstra()
)
```

**Characteristics:**
- **Time Complexity**: O((V + E) log V) - faster in practice
- **Space Complexity**: O(V)
- **Speedup**: Often 2x faster than standard Dijkstra
- **Requirement**: Non-negative weights

**How it works:**
1. Start search from both source and destination
2. Expand both frontiers simultaneously
3. Stop when frontiers meet
4. Reconstruct path from meeting point

**Best For:**
- Long-distance routing
- Social network "degrees of separation"
- When start and goal are far apart
- Large graphs needing optimization

## Single-Source Shortest Paths

Find shortest paths from one node to **all** other nodes.

### Dijkstra for All Destinations

```swift
let paths = graph.shortestPaths(from: "A", using: .dijkstra())
// Returns: [Node: Path<Node, Edge>]

for (destination, path) in paths {
    print("To \(destination): \(path.cost)")
}
```

**Use Cases:**
- Router distance tables
- Centrality calculations
- All destinations from single source

### Bellman-Ford for All Destinations

```swift
let paths = graph.shortestPaths(from: "A", using: .bellmanFord())
```

**Use Cases:**
- Negative weight graphs
- All paths with cycle detection

## All-Pairs Shortest Paths

Find shortest paths between **all** pairs of nodes.

### Floyd-Warshall Algorithm

Dynamic programming approach for all-pairs shortest paths.

```swift
let allPaths = graph.shortestPathsForAllPairs(using: .floydWarshall())
// Returns: [Node: [Node: Path<Node, Edge>]]

let pathAtoD = allPaths["A"]?["D"]
print("A to D: \(pathAtoD?.cost ?? .infinity)")
```

**Characteristics:**
- **Time Complexity**: O(V³)
- **Space Complexity**: O(V²)
- **Requirement**: No negative cycles
- **Output**: Distance matrix for all pairs

**How it works:**
1. Initialize distance matrix with edge weights
2. For each intermediate node k:
   - For each pair (i, j):
     - If path through k is shorter, update dist[i][j]

**Best For:**
- Dense graphs
- When you need all-pairs distances
- Small to medium graphs (V < 1000)
- Transitive closure

### Johnson's Algorithm

Combines Bellman-Ford and Dijkstra for all-pairs paths.

```swift
let allPaths = graph.shortestPathsForAllPairs(using: .johnson())
```

**Characteristics:**
- **Time Complexity**: O(V²log V + VE)
- **Space Complexity**: O(V²)
- **Requirement**: No negative cycles
- **Advantage**: Better than Floyd-Warshall for sparse graphs

**How it works:**
1. Add new node connected to all others with weight 0
2. Run Bellman-Ford from new node to reweight edges
3. Run Dijkstra from each node with reweighted edges
4. Adjust distances back to original weights

**Best For:**
- Sparse graphs
- Large graphs needing all-pairs paths
- Negative weights (but no negative cycles)

## K-Shortest Paths

Find the k shortest paths (not just the shortest).

### Yen's Algorithm

```swift
let paths = graph.kShortestPaths(
    from: "A",
    to: "D",
    k: 3,
    using: .yen()
)

for (i, path) in paths.enumerated() {
    print("Path \(i+1): \(path.path), Cost: \(path.cost)")
}
// Path 1: [A, C, B, D], Cost: 8
// Path 2: [A, B, D], Cost: 9
// Path 3: [A, C, D], Cost: 10
```

**Characteristics:**
- **Time Complexity**: O(kV(E + V log V))
- **Finds**: k shortest loopless paths
- **Ordered**: Paths returned in increasing cost order

**Use Cases:**
- Alternative route planning
- Backup paths
- Route diversity
- Risk analysis

## Specialized Shortest Path Algorithms

### Shortest Path Until Condition

Find shortest path until a condition is met (not to a specific node):

```swift
let pathToAny = graph.shortestPathUntil(
    from: "A",
    until: { node in node.hasProperty },
    using: .dijkstra()
)
```

**Use Cases:**
- Find nearest node with property
- Goal testing without knowing exact destination
- Multiple valid destinations

### All Shortest Paths

Find **all** shortest paths (not just one):

```swift
let allShortestPaths = graph.allShortestPaths(from: "A", to: "D")

for path in allShortestPaths {
    print(path.path)
}
// [A, C, B, D]
// [A, B, D] (if same cost)
```

**Use Cases:**
- Route alternatives
- Redundancy planning
- Analyzing path diversity

## Comparison and Selection Guide

### Algorithm Selection Matrix

| Scenario | Best Algorithm | Rationale |
|----------|---------------|-----------|
| Non-negative weights, single path | Dijkstra | Optimal and efficient |
| Grid/spatial with heuristic | A* | Faster with good heuristic |
| Negative weights | Bellman-Ford | Only handles negatives |
| Very long paths | Bidirectional Dijkstra | Faster in practice |
| All destinations from source | Dijkstra (all paths) | One run gets all |
| All pairs, dense graph | Floyd-Warshall | O(V³) acceptable |
| All pairs, sparse graph | Johnson's | Better complexity |
| Alternative routes | Yen's k-shortest | Multiple paths |

### Performance Comparison

```swift
// Small dense graph: Floyd-Warshall
let dense = CompleteGraph(nodes: 100)
let allPairsDense = dense.shortestPathsForAllPairs(using: .floydWarshall())

// Large sparse graph: Johnson's
let sparse = ConnectedGraph(edges: sparseEdgeList)  // 10000 nodes, 20000 edges
let allPairsSparse = sparse.shortestPathsForAllPairs(using: .johnson())

// Single path: Dijkstra
let singlePath = graph.shortestPath(from: start, to: goal, using: .dijkstra())

// With good heuristic: A*
let heuristicPath = gridGraph.shortestPath(
    from: start, 
    to: goal,
    using: .aStar(heuristic: .manhattanDistance(of: \.position))
)
```

## Practical Examples

### Road Network Navigation

```swift
struct Road: Weighted {
    let distance: Double  // km
    let time: TimeInterval  // seconds
    let toll: Decimal  // cost
    
    var weight: Double { distance }  // or time, or convert toll
}

let roadNetwork = ConnectedHashGraph<City, Road>(edges: roads)

// Shortest distance
let byDistance = roadNetwork.shortestPath(
    from: sanFrancisco,
    to: newYork,
    using: .dijkstra()
)

// Fastest route (weighted by time)
let byTime = roadNetwork
    .weighted(by: \.time)
    .shortestPath(from: sanFrancisco, to: newYork)

// Cheapest route (weighted by toll)
let byCost = roadNetwork
    .weighted(by: \.toll)
    .shortestPath(from: sanFrancisco, to: newYork)
```

### Game Pathfinding

```swift
let gameMap = GridGraph(
    grid: mapTiles,
    availableDirections: .all  // includes diagonals
).weightedByDistance()

// A* with Manhattan distance
let path = gameMap.shortestPath(
    from: playerPosition,
    to: targetPosition,
    using: .aStar(heuristic: .manhattanDistance(of: \.coordinates))
)

// Animate character along path
for position in path.path {
    moveCharacter(to: position)
    await Task.sleep(for: .milliseconds(100))
}
```

### Network Routing with Negative Costs

```swift
// Negative costs represent "rewards" or "credits"
struct Connection: Weighted {
    let cost: Int  // Can be negative (credit/reward)
    var weight: Int { cost }
}

let network = ConnectedGraph(edges: [
    "A": ["B": Connection(cost: 5), "C": Connection(cost: -2)],  // C gives credit
    "C": ["D": Connection(cost: 3)],
    "B": ["D": Connection(cost: 2)]
])

// Must use Bellman-Ford for negative weights
if let path = network.shortestPath(from: "A", to: "D", using: .bellmanFord()) {
    print("Best path cost: \(path.cost)")  // Includes credits
}
```

### Social Network Analysis

```swift
let socialGraph = ConnectedHashGraph<User, Empty>(edges: friendships)

// Find shortest connection path
let connection = socialGraph.shortestPathBFS(from: alice, to: bob)
print("\(alice.name) is \(connection.count - 1) degrees from \(bob.name)")

// Find mutual friend (bidirectional search)
let mutualPath = socialGraph.shortestPath(
    from: alice,
    to: bob,
    using: .bidirectionalDijkstra()
)
```

### Multi-Criteria Routing

```swift
struct MultiRoute: Weighted {
    let distance: Double
    let time: Double
    let cost: Double
    
    // Weighted combination
    var weight: Double {
        0.5 * distance + 0.3 * time + 0.2 * cost
    }
}

let routes = ConnectedGraph<Location, MultiRoute>(edges: routeData)
let balanced = routes.shortestPath(from: home, to: work)

// Or find k alternatives and let user choose
let alternatives = routes.kShortestPaths(from: home, to: work, k: 5)
let chosen = userSelectsRoute(alternatives)
```

## Implementation Details

### Path Reconstruction

All algorithms return a ``Path`` structure:

```swift
public struct Path<Node, Edge> {
    public let source: Node
    public let destination: Node
    public let edges: [GraphEdge<Node, Edge>]
    
    public var path: [Node] {
        [source] + edges.map(\.destination)
    }
    
    public var cost: Edge.Weight where Edge: Weighted, Edge.Weight: Numeric {
        edges.map(\.value.weight).reduce(0, +)
    }
}
```

### Distance Tracking

Internal distance maps track best-known distances:

```swift
var distances: [Node: Weight] = [source: .zero]
var previous: [Node: GraphEdge<Node, Edge>] = [:]

// Update if better path found
if newDistance < distances[neighbor] ?? .infinity {
    distances[neighbor] = newDistance
    previous[neighbor] = edge
}
```

## See Also

- <doc:TraversalAlgorithms>
- <doc:GraphProperties>
- ``ShortestPathAlgorithm``
- ``DijkstraAlgorithm``
- ``AStarAlgorithm``
- ``BellmanFordAlgorithm``
- ``FloydWarshallAlgorithm``
- ``Path``
