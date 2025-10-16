# Minimum Spanning Tree Algorithms

Finding the minimum cost tree that connects all nodes in a graph.

## Overview

A **Minimum Spanning Tree (MST)** is a subset of edges that connects all vertices in an undirected graph with the minimum total edge weight, without forming cycles. The library provides three classic MST algorithms, each with different performance characteristics and use cases.

## What is a Spanning Tree?

A spanning tree of a graph is a subgraph that:
1. **Includes all vertices** of the original graph
2. **Is a tree** (connected and acyclic)
3. **Is minimal** - has exactly V-1 edges for V vertices

A **Minimum** Spanning Tree additionally has the **minimum total edge weight** among all possible spanning trees.

## Core MST Algorithms

### Kruskal's Algorithm

Builds MST by adding edges in order of increasing weight, avoiding cycles.

```swift
let graph = ConnectedGraph(edges: [
    "A": ["B": 4, "C": 2],
    "B": ["C": 1, "D": 5],
    "C": ["D": 8, "E": 10],
    "D": ["E": 2]
]).undirected()  // MST requires undirected graph

let mst = graph.minimumSpanningTree(using: .kruskal())
// MST edges: {C-B:1, A-C:2, D-E:2, B-D:5}
// Total weight: 10
```

**Characteristics:**
- **Time Complexity**: O(E log E) or O(E log V)
- **Space Complexity**: O(V)
- **Approach**: Greedy (edge-based)
- **Data Structure**: Disjoint-set (Union-Find)

**How it works:**
1. Sort all edges by weight (ascending)
2. Initialize disjoint-set for cycle detection
3. For each edge in sorted order:
   - If edge connects different components (no cycle)
   - Add edge to MST
   - Union the components
4. Stop when V-1 edges added

**Best For:**
- Sparse graphs (E is much less than V²)
- When edges are already sorted
- Simple implementation needs

**Implementation Sketch:**
```swift
struct KruskalAlgorithm<Node: Hashable, Edge: Weighted>: MinimumSpanningTreeAlgorithm {
    func minimumSpanningTree(in graph: some Graph<Node, Edge>) -> Set<GraphEdge<Node, Edge>> {
        var mst: Set<GraphEdge<Node, Edge>> = []
        var uf = UnionFind(nodes: graph.allNodes)
        
        let sortedEdges = graph.allEdges.sorted { $0.weight < $1.weight }
        
        for edge in sortedEdges {
            if uf.find(edge.source) != uf.find(edge.destination) {
                mst.insert(edge)
                uf.union(edge.source, edge.destination)
            }
            
            if mst.count == graph.allNodes.count - 1 {
                break
            }
        }
        
        return mst
    }
}
```

### Prim's Algorithm

Grows MST from a starting vertex by adding minimum weight edge to tree.

```swift
let mst = graph.minimumSpanningTree(using: .prim())
// Same result, different approach
```

**Characteristics:**
- **Time Complexity**: O((V + E) log V) with binary heap
- **Space Complexity**: O(V)
- **Approach**: Greedy (vertex-based)
- **Data Structure**: Priority queue

**How it works:**
1. Start with arbitrary vertex
2. Maintain priority queue of edges from tree to non-tree vertices
3. Repeat:
   - Extract minimum weight edge to unvisited vertex
   - Add edge to MST
   - Add new edges from new vertex to queue
4. Stop when all vertices included

**Best For:**
- Dense graphs (E close to V²)
- When starting vertex matters
- Incremental MST construction

**Implementation Sketch:**
```swift
struct PrimAlgorithm<Node: Hashable, Edge: Weighted>: MinimumSpanningTreeAlgorithm {
    func minimumSpanningTree(in graph: some Graph<Node, Edge>) -> Set<GraphEdge<Node, Edge>> {
        var mst: Set<GraphEdge<Node, Edge>> = []
        var visited: Set<Node> = []
        var pq = Heap<GraphEdge<Node, Edge>>()
        
        let start = graph.allNodes.first!
        visited.insert(start)
        
        for edge in graph.edges(from: start) {
            pq.insert(edge)
        }
        
        while let edge = pq.popMin() {
            if visited.contains(edge.destination) { continue }
            
            mst.insert(edge)
            visited.insert(edge.destination)
            
            for nextEdge in graph.edges(from: edge.destination) {
                if !visited.contains(nextEdge.destination) {
                    pq.insert(nextEdge)
                }
            }
        }
        
        return mst
    }
}
```

### Borůvka's Algorithm

Simultaneously grows multiple components into MST.

```swift
let mst = graph.minimumSpanningTree(using: .boruvka())
```

**Characteristics:**
- **Time Complexity**: O(E log V)
- **Space Complexity**: O(V)
- **Approach**: Parallel-friendly
- **Parallelization**: Each component can work independently

**How it works:**
1. Start with each vertex as separate component
2. Repeat until one component:
   - For each component, find minimum weight outgoing edge
   - Add all such edges to MST (in parallel)
   - Merge connected components
3. Number of components halves each iteration

**Best For:**
- Parallel/distributed computing
- When parallelism is important
- Theoretical interest (oldest MST algorithm)

**Implementation Sketch:**
```swift
struct BoruvkaAlgorithm<Node: Hashable, Edge: Weighted>: MinimumSpanningTreeAlgorithm {
    func minimumSpanningTree(in graph: some Graph<Node, Edge>) -> Set<GraphEdge<Node, Edge>> {
        var mst: Set<GraphEdge<Node, Edge>> = []
        var uf = UnionFind(nodes: graph.allNodes)
        
        while uf.componentCount > 1 {
            var cheapest: [Node: GraphEdge<Node, Edge>] = [:]
            
            // Find cheapest edge for each component
            for edge in graph.allEdges {
                let compSource = uf.find(edge.source)
                let compDest = uf.find(edge.destination)
                
                if compSource != compDest {
                    if cheapest[compSource] == nil || edge.weight < cheapest[compSource]!.weight {
                        cheapest[compSource] = edge
                    }
                }
            }
            
            // Add cheapest edges and merge components
            for edge in cheapest.values {
                if uf.find(edge.source) != uf.find(edge.destination) {
                    mst.insert(edge)
                    uf.union(edge.source, edge.destination)
                }
            }
        }
        
        return mst
    }
}
```

## Algorithm Comparison

### Time Complexity Comparison

| Algorithm | Time Complexity | Best For |
|-----------|----------------|----------|
| Kruskal | O(E log E) | Sparse graphs |
| Prim | O(E log V) with heap | Dense graphs |
| Borůvka | O(E log V) | Parallel processing |

### Space Complexity

All three algorithms use **O(V)** space.

### Practical Performance

```swift
// Sparse graph (E ≈ V): Kruskal often fastest
let sparseGraph = ConnectedGraph(edges: sparseEdges).undirected()
let kruskalMST = sparseGraph.minimumSpanningTree(using: .kruskal())

// Dense graph (E ≈ V²): Prim often fastest
let denseGraph = CompleteGraph(nodes: nodes).undirected()
let primMST = denseGraph.minimumSpanningTree(using: .prim())

// Parallel environment: Borůvka
let parallelMST = graph.minimumSpanningTree(using: .boruvka())
```

## Undirected Graphs Requirement

MST algorithms require **undirected graphs**. Use the `undirected()` transformation:

```swift
// Directed graph
let directed = ConnectedGraph(edges: [
    "A": ["B": 4],
    "B": ["C": 2]
])

// Convert to undirected for MST
let undirected = directed.undirected()
let mst = undirected.minimumSpanningTree(using: .kruskal())
```

The `undirected()` transformation automatically adds reverse edges:
- A → B becomes A ↔ B
- B → C becomes B ↔ C

## MST Properties and Theorems

### Cut Property

For any cut (partition of vertices), the minimum weight edge crossing the cut is in some MST.

**Application**: All three algorithms use this property.

### Cycle Property

For any cycle, the maximum weight edge in the cycle is not in any MST.

**Application**: Kruskal uses union-find to detect cycles.

### Uniqueness

An MST is unique if all edge weights are distinct.

```swift
// Check if MST is unique
func isMSTUnique<G: Graph>(graph: G) -> Bool where G.Edge: Weighted {
    let weights = graph.allEdges.map(\.weight)
    return Set(weights).count == weights.count  // All unique
}
```

## Practical Applications

### Network Design

Minimize cost of connecting all locations:

```swift
struct Cable: Weighted {
    let length: Double
    let cost: Decimal
    
    var weight: Double { length }  // or cost
}

let cities = ["NYC", "LA", "Chicago", "Houston", "Phoenix"]
let connections = ConnectedGraph<String, Cable>(edges: possibleConnections)
    .undirected()

let network = connections.minimumSpanningTree(using: .prim())

let totalCost = network.reduce(0) { $0 + $1.value.cost }
print("Minimum network cost: $\(totalCost)")
```

### Road Network Planning

```swift
struct Road: Weighted {
    let distance: Double
    let constructionCost: Decimal
    
    var weight: Decimal { constructionCost }
}

let cities = loadCities()
let possibleRoads = generateAllPossibleRoads(between: cities)

let roadNetwork = ConnectedGraph(edges: possibleRoads).undirected()
let minimalNetwork = roadNetwork.minimumSpanningTree(using: .kruskal())

print("Build these roads:")
for edge in minimalNetwork {
    print("\(edge.source) — \(edge.destination): $\(edge.value.constructionCost)")
}
```

### Cluster Analysis

MST can identify clusters by removing expensive edges:

```swift
struct Similarity: Weighted {
    let score: Double
    var weight: Double { -score }  // Negate for MST (we want max similarity)
}

let dataPoints = loadDataPoints()
let similarities = computeSimilarities(dataPoints)

let graph = ConnectedGraph(edges: similarities).undirected()
let mst = graph.minimumSpanningTree(using: .prim())

// Find clusters by removing k-1 most expensive edges
let k = 3  // number of clusters
let sortedEdges = mst.sorted { $0.weight > $1.weight }
let edgesToRemove = sortedEdges.prefix(k - 1)

let clusters = findConnectedComponents(removing: edgesToRemove, from: mst)
```

### Maze Generation

MST creates perfect mazes (single path between any two points):

```swift
let grid = GridGraph(
    grid: Array(repeating: Array(repeating: ".", count: 20), count: 20),
    availableDirections: .orthogonal
).undirected()
    .weighted { _ in Double.random(in: 0...1) }  // Random weights

let mazeMST = grid.minimumSpanningTree(using: .kruskal())

// Render maze: walls where edges aren't in MST
func renderMaze(grid: GridGraph, mst: Set<GraphEdge<GridPosition, Double>>) -> String {
    // Implementation
}
```

### Approximation for TSP

MST provides 2-approximation for Traveling Salesman Problem:

```swift
// 1. Find MST
let mst = graph.minimumSpanningTree(using: .prim())

// 2. DFS on MST to get tour
let tour = mst.depthFirstTraversal(from: start)

// 3. Tour cost ≤ 2 × MST cost ≤ 2 × optimal TSP
```

## Advanced Usage

### Minimum Bottleneck Spanning Tree

Find tree minimizing the maximum edge weight:

```swift
// Use MST algorithms - they also minimize bottleneck!
let mbst = graph.minimumSpanningTree(using: .kruskal())
let bottleneck = mbst.max { $0.weight < $1.weight }?.weight
```

**Property**: Any MST is also a minimum bottleneck spanning tree.

### Degree-Constrained MST

Limit maximum degree of vertices (more complex, approximation):

```swift
func degreeConstrainedMST<G: Graph>(
    graph: G,
    maxDegree: Int
) -> Set<GraphEdge<G.Node, G.Edge>> where G.Node: Hashable, G.Edge: Weighted {
    var mst: Set<GraphEdge<G.Node, G.Edge>> = []
    var degrees: [G.Node: Int] = [:]
    
    let sortedEdges = graph.allEdges.sorted { $0.weight < $1.weight }
    
    for edge in sortedEdges {
        let sourceDegree = degrees[edge.source, default: 0]
        let destDegree = degrees[edge.destination, default: 0]
        
        if sourceDegree < maxDegree && destDegree < maxDegree {
            // Check if adding edge creates cycle (use Union-Find)
            mst.insert(edge)
            degrees[edge.source, default: 0] += 1
            degrees[edge.destination, default: 0] += 1
        }
    }
    
    return mst
}
```

### Dynamic MST

Update MST when edges are added/removed (advanced):

```swift
struct DynamicMST<Node: Hashable, Edge: Weighted> {
    private var mst: Set<GraphEdge<Node, Edge>>
    
    mutating func insertEdge(_ edge: GraphEdge<Node, Edge>) {
        // If edge creates cycle, remove max weight edge in cycle
        if let cycleMaxEdge = findMaxInCycle(adding: edge) {
            if edge.weight < cycleMaxEdge.weight {
                mst.remove(cycleMaxEdge)
                mst.insert(edge)
            }
        } else {
            mst.insert(edge)
        }
    }
    
    mutating func removeEdge(_ edge: GraphEdge<Node, Edge>) {
        mst.remove(edge)
        // Reconnect with minimum replacement edge if needed
        if let replacement = findMinReplacementEdge(for: edge) {
            mst.insert(replacement)
        }
    }
}
```

## Verification and Analysis

### Verify MST Properties

```swift
func verifyMST<G: Graph>(
    graph: G,
    mst: Set<GraphEdge<G.Node, G.Edge>>
) -> Bool where G.Node: Hashable {
    // 1. Check edge count: must be V-1
    guard mst.count == graph.allNodes.count - 1 else {
        return false
    }
    
    // 2. Check connectivity: MST must connect all nodes
    let mstGraph = ConnectedGraph(edges: Array(mst))
    guard mstGraph.isConnected() else {
        return false
    }
    
    // 3. Check acyclicity: tree has no cycles
    guard !mstGraph.isCyclic() else {
        return false
    }
    
    return true
}
```

### Calculate Total Weight

```swift
extension Set where Element == GraphEdge<Node, Edge>, Edge: Weighted, Edge.Weight: Numeric {
    var totalWeight: Edge.Weight {
        reduce(into: .zero) { $0 += $1.weight }
    }
}

let mst = graph.minimumSpanningTree(using: .kruskal())
print("Total MST weight: \(mst.totalWeight)")
```

## Performance Optimization Tips

### For Sparse Graphs

```swift
// Use Kruskal - better for E << V²
let mst = sparseGraph.minimumSpanningTree(using: .kruskal())
```

### For Dense Graphs

```swift
// Use Prim with efficient priority queue
let mst = denseGraph.minimumSpanningTree(using: .prim())
```

### For Parallel Processing

```swift
// Use Borůvka - naturally parallelizable
let mst = graph.minimumSpanningTree(using: .boruvka())
```

### Pre-sorted Edges

```swift
// If edges already sorted, Kruskal is very efficient
let sortedGraph = ConnectedGraph(edges: preSortedEdges)
let mst = sortedGraph.minimumSpanningTree(using: .kruskal())
```

## See Also

- <doc:ShortestPathAlgorithms>
- <doc:GraphProperties>
- ``MinimumSpanningTreeAlgorithm``
- ``KruskalAlgorithm``
- ``PrimAlgorithm``
- ``BoruvkaAlgorithm``
- ``UndirectedGraph``
