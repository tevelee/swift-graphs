# Generic Constraints and Type Safety

How the library uses Swift's type system to ensure correctness and prevent misuse at compile time.

## Overview

The Graphs library leverages Swift's powerful generic constraints to provide compile-time guarantees about algorithm applicability and correctness. This approach prevents common graph algorithm errors before code even runs.

## The Problem with Runtime Checking

Traditional graph libraries often rely on runtime validation:

```swift
// Traditional approach - runtime errors
class Graph {
    func dijkstra(from: Node, to: Node) -> Path? {
        for edge in edges {
            if edge.weight < 0 {
                fatalError("Dijkstra doesn't work with negative weights!")
            }
        }
        // ... algorithm
    }
}
```

**Problems:**
- Errors discovered at runtime
- Need extensive testing to catch issues
- Documentation must explain constraints
- Performance overhead from checking

## Type-Safe Approach

This library uses generic constraints to enforce requirements at compile time:

```swift
// This library - compile-time safety
extension GraphComponent where 
    Node: Hashable,
    Edge: Weighted,
    Edge.Weight: Numeric,
    Edge.Weight.Magnitude == Edge.Weight {  // Non-negative
    
    public func shortestPath(from: Node, to: Node) -> Path<Node, Edge>? {
        shortestPath(from: from, to: to, using: .dijkstra())
    }
}
```

If you try to use Dijkstra with the wrong graph type, **the code won't compile**.

## The Weighted Protocol

At the core of many constraints is the ``Weighted`` protocol:

```swift
public protocol Weighted {
    associatedtype Weight: Comparable
    var weight: Weight { get }
}
```

This protocol represents anything with a comparable weight:

```swift
// Built-in conformances
extension Int: Weighted {}     // weight is self
extension Double: Weighted {}  // weight is self

// Custom types
struct Distance: Weighted {
    let meters: Double
    var weight: Double { meters }
}

struct Cost: Weighted {
    let dollars: Decimal
    var weight: Decimal { dollars }
}
```

## Progressive Enhancement Through Constraints

Methods become available as types satisfy more constraints:

### Level 1: Basic GraphComponent

```swift
protocol GraphComponent<Node, Edge> {
    func edges(from: Node) -> [GraphEdge<Node, Edge>]
}

// Available to ALL graphs:
graph.traverse(from: start, strategy: .bfs())
graph.traverse(from: start, strategy: .dfs())
```

### Level 2: Equatable Nodes

```swift
extension GraphComponent where Node: Equatable {
    // Now available:
    func contains(node: Node) -> Bool
    func neighbors(of: Node) -> [Node]
    func path(from: Node, to: Node) -> [Node]?
}
```

### Level 3: Hashable Nodes

```swift
extension GraphComponent where Node: Hashable {
    // Now available (needs efficient lookup):
    func stronglyConnectedComponents() -> [[Node]]
    func topologicalSort() -> [Node]?
    func isCyclic() -> Bool
}
```

### Level 4: Weighted Edges

```swift
extension GraphComponent where Edge: Weighted {
    // Now available (needs edge weights):
    func shortestPath(from: Node, to: Node, 
                     using: some ShortestPathAlgorithm<Node, Edge>) -> Path?
}
```

### Level 5: Weighted + Hashable + Numeric

```swift
extension GraphComponent where 
    Node: Hashable,
    Edge: Weighted,
    Edge.Weight: Numeric,
    Edge.Weight.Magnitude == Edge.Weight {
    
    // Default Dijkstra (non-negative weights):
    func shortestPath(from: Node, to: Node) -> Path<Node, Edge>?
}
```

### Level 6: Complete Constraints for MST

```swift
extension Graph where 
    Node: Hashable,
    Edge: Weighted,
    Edge.Weight: Numeric {
    
    // Minimum spanning tree:
    func minimumSpanningTree(
        using: some MinimumSpanningTreeAlgorithm<Node, Edge>
    ) -> Set<GraphEdge<Node, Edge>>
}
```

## Algorithm-Specific Constraints

Each algorithm defines precisely what it needs:

### Dijkstra's Algorithm

```swift
struct DijkstraAlgorithm<Node: Hashable, Edge: Weighted>: ShortestPathAlgorithm
where Edge.Weight: Numeric, Edge.Weight.Magnitude == Edge.Weight {
    // Edge.Weight.Magnitude == Edge.Weight ensures non-negative weights
}
```

**Why these constraints?**
- `Node: Hashable` - needs efficient node lookup in priority queue
- `Edge: Weighted` - requires edge weights
- `Edge.Weight: Numeric` - needs arithmetic operations (addition)
- `Edge.Weight.Magnitude == Edge.Weight` - ensures non-negative (magnitude equals value)

### Bellman-Ford Algorithm

```swift
struct BellmanFordAlgorithm<Node: Hashable, Edge: Weighted>: ShortestPathAlgorithm
where Edge.Weight: Numeric & SignedNumeric {
    // SignedNumeric allows negative weights
}
```

**Difference from Dijkstra:**
- Uses `SignedNumeric` instead of magnitude constraint
- Explicitly allows negative weights

### A* Algorithm

```swift
struct AStarAlgorithm<Node: Hashable, Edge: Weighted, Heuristic>: ShortestPathAlgorithm
where 
    Edge.Weight: Numeric,
    Edge.Weight.Magnitude == Edge.Weight,
    Heuristic: AStarHeuristic,
    Heuristic.Node == Node,
    Heuristic.Cost == Edge.Weight {
    
    let heuristic: Heuristic
}
```

**Additional constraint:**
- Heuristic cost must match edge weight type

## Preventing Misuse

### Example 1: Negative Weights

```swift
let graph = ConnectedGraph(edges: [
    "A": ["B": -5, "C": 3],  // Negative weight!
    "B": ["D": 2]
])

// Won't compile - Dijkstra requires non-negative weights:
// graph.shortestPath(from: "A", to: "D", using: .dijkstra())

// Must use Bellman-Ford:
graph.shortestPath(from: "A", to: "D", using: .bellmanFord()) // ✓
```

### Example 2: Unweighted Graphs

```swift
let socialNetwork = ConnectedGraph(edges: [
    "Alice": ["Bob", "Charlie"],
    "Bob": ["David"]
])

// Won't compile - no weights:
// socialNetwork.shortestPath(from: "Alice", to: "David")

// Use BFS for unweighted shortest path:
let path = socialNetwork.shortestPathBFS(from: "Alice", to: "David") // ✓
```

### Example 3: Non-Hashable Nodes

```swift
struct CustomNode {
    let data: SomeComplexType
    // No Hashable conformance
}

let graph = ConnectedGraph<CustomNode, Empty>(...)

// Won't compile - needs Hashable for efficient lookup:
// graph.stronglyConnectedComponents()

// Either make CustomNode hashable, or use hash wrapper:
let hashGraph = graph.withHashValue(\.data.id)
hashGraph.stronglyConnectedComponents() // ✓
```

## Compile-Time Algorithm Selection

The type system can select algorithms automatically:

```swift
extension GraphComponent where 
    Node: Hashable,
    Edge: Weighted,
    Edge.Weight: Numeric,
    Edge.Weight.Magnitude == Edge.Weight {
    
    public func shortestPath(from: Node, to: Node) -> Path<Node, Edge>? {
        // Automatically uses Dijkstra
        shortestPath(from: from, to: to, using: .dijkstra())
    }
}

extension GraphComponent where 
    Node: Hashable,
    Edge: Weighted,
    Edge.Weight: SignedNumeric {
    
    public func shortestPathWithNegativeEdges(from: Node, to: Node) -> Path<Node, Edge>? {
        // Explicitly uses Bellman-Ford for signed weights
        shortestPath(from: from, to: to, using: .bellmanFord())
    }
}
```

## Conditional Conformance

Graph wrappers gain capabilities based on wrapped graph:

```swift
// TransposedGraph gains methods based on base graph
extension TransposedGraph: Graph where Base: Graph {
    var allNodes: [Node] { base.allNodes }
    var allEdges: [GraphEdge<Node, Edge>] {
        base.allEdges.map(\.reversed)
    }
}

// WeightedGraph adds Weighted conformance
extension WeightedGraph.EdgeValue: Weighted where Weight: Comparable {
    var weight: Weight { self.weight }
}
```

## Custom Constraint Combinations

You can create your own constrained extensions:

```swift
// Extension for graphs suitable for Dijkstra
extension GraphComponent where 
    Node: Hashable,
    Edge: Weighted,
    Edge.Weight: Numeric & Comparable,
    Edge.Weight.Magnitude == Edge.Weight {
    
    func efficientShortestPaths(from start: Node) -> [Node: Edge.Weight] {
        // Custom logic combining multiple algorithms
        let paths = shortestPaths(from: start, using: .dijkstra())
        return paths.mapValues(\.cost)
    }
}

// Extension for integer-weighted graphs
extension GraphComponent where Edge == Int {
    func shortestPathUnweighted(from: Node, to: Node) -> Path<Node, Int>? {
        // Optimized for unit weights
        shortestPath(from: from, to: to, using: .bfs())
    }
}
```

## Practical Examples

### Social Network Analysis

```swift
struct User: Hashable {
    let id: UUID
    let name: String
}

// Unweighted graph - use BFS
let friendships = ConnectedGraph<User, Empty>(edges: friendshipData)
let closeFriends = friendships.shortestPathBFS(from: alice, to: bob)

// Weighted by interaction count
struct Interaction: Weighted {
    let count: Int
    var weight: Int { count }
}

let interactions = ConnectedGraph<User, Interaction>(edges: interactionData)
let strongestConnection = interactions.shortestPath(from: alice, to: bob)
```

### Route Planning

```swift
struct Location: Hashable {
    let latitude: Double
    let longitude: Double
}

struct Route: Weighted {
    let distance: Double      // km
    let time: TimeInterval    // seconds
    let toll: Decimal         // currency
    
    var weight: Double { distance }
}

let roadNetwork = ConnectedHashGraph<Location, Route>(edges: routes)

// Type-safe: can only use on weighted graphs
let fastestRoute = roadNetwork.shortestPath(
    from: home,
    to: work,
    using: .aStar(heuristic: .euclideanDistance(of: \.coordinates))
)
```

### Network Flow

```swift
struct Capacity: Weighted {
    let maxFlow: Int
    var weight: Int { maxFlow }
}

let network = ConnectedGraph<String, Capacity>(edges: [
    "Source": ["A": Capacity(maxFlow: 10), "B": Capacity(maxFlow: 5)],
    "A": ["Sink": Capacity(maxFlow: 10)],
    "B": ["Sink": Capacity(maxFlow: 5)]
])

// Type-safe: only available on weighted graphs
let maxFlow = network.maximumFlow(
    from: "Source",
    to: "Sink",
    using: .edmondsKarp()
)
```

## Benefits Summary

### Compile-Time Safety
- Impossible operations don't compile
- No runtime errors from algorithm misuse
- Clear API through type constraints

### Self-Documenting
- Types express requirements
- No need to read docs to know what's needed
- Xcode shows only applicable methods

### Performance
- No runtime type checking
- Compiler optimizations based on constraints
- Zero overhead abstractions

### Correctness
- Algorithms guaranteed to have required properties
- Can't accidentally use wrong algorithm
- Type system prevents logic errors

## See Also

- <doc:Architecture>
- <doc:ProtocolOrientedDesign>
- <doc:StorageAndAlgorithms>
- ``Weighted``
- ``GraphComponent``
- ``Graph``
