# Glossary of Graph Theory Terms

Essential terminology and concepts used throughout the library.

## Basic Concepts

### Graph
A collection of **vertices** (nodes) connected by **edges**. Formally, G = (V, E) where V is the set of vertices and E is the set of edges.

```swift
let graph = ConnectedGraph(edges: [
    "A": ["B", "C"],  // Vertices: A, B, C; Edges: A→B, A→C
    "B": ["C"]         // Edge: B→C
])
```

### Vertex (Node)
A fundamental unit in a graph. Can represent entities like people, cities, web pages, etc.

### Edge (Arc, Link)
A connection between two vertices. Can be:
- **Directed**: Has a direction (A → B)
- **Undirected**: Bidirectional (A ↔ B)
- **Weighted**: Has an associated value/cost

```swift
// Directed edge
GraphEdge(source: "A", destination: "B")

// Weighted edge
GraphEdge(source: "A", destination: "B", value: 5)
```

### Adjacent (Neighbor)
Two vertices are **adjacent** if they are connected by an edge. The set of all neighbors of a vertex is its **neighborhood**.

```swift
let neighbors = graph.edges(from: "A").map(\.destination)
```

### Degree
The number of edges connected to a vertex:
- **In-degree**: Number of incoming edges (directed graphs)
- **Out-degree**: Number of outgoing edges (directed graphs)
- **Degree**: Total edges (undirected graphs)

```swift
let degree = graph.edges(from: node).count
```

## Graph Types

### Directed Graph (Digraph)
A graph where edges have direction (one-way connections).

```swift
let directed = ConnectedGraph(edges: [
    "A": ["B"],  // A → B (but not B → A)
])
```

### Undirected Graph
A graph where edges are bidirectional.

```swift
let undirected = directed.undirected()
// Now: A ↔ B
```

### Weighted Graph
A graph where edges have associated weights/costs.

```swift
let weighted = ConnectedGraph(edges: [
    "A": ["B": 10, "C": 5]  // Edge weights: 10 and 5
])
```

### Complete Graph (Clique)
A graph where every pair of vertices is connected. A complete graph with n vertices has n(n-1)/2 edges.

```swift
extension Graph {
    func isComplete() -> Bool {
        let n = allNodes.count
        return allEdges.count >= n * (n - 1) / 2
    }
}
```

### Bipartite Graph
A graph whose vertices can be divided into two disjoint sets such that every edge connects vertices from different sets.

```swift
let (isBipartite, _) = graph.isBipartite()
```

### Tree
A connected acyclic graph. A tree with n vertices has exactly n-1 edges.

```swift
graph.isTree()  // Connected + Acyclic + V-1 edges
```

### Forest
A disjoint union of trees (acyclic graph, possibly disconnected).

### DAG (Directed Acyclic Graph)
A directed graph with no cycles. Used for dependency resolution, task scheduling.

```swift
!graph.isCyclic()  // True for DAG
```

## Structural Properties

### Path
A sequence of vertices where each adjacent pair is connected by an edge.

```swift
let path = graph.shortestPath(from: "A", to: "D")
print(path?.path ?? [])  // e.g., [A, B, C, D]
```

### Cycle
A path that starts and ends at the same vertex.

```swift
graph.isCyclic()  // Has at least one cycle
```

### Connected
An undirected graph is **connected** if there's a path between every pair of vertices.

```swift
graph.isConnected()
```

### Strongly Connected
A directed graph is **strongly connected** if there's a directed path between every pair of vertices in both directions.

```swift
graph.stronglyConnectedComponents(using: .tarjan())
```

### Weakly Connected
A directed graph is **weakly connected** if it would be connected as an undirected graph.

### Component
A maximal connected subgraph.

```swift
let components = graph.connectedComponents()
```

### Cut Vertex (Articulation Point)
A vertex whose removal increases the number of connected components.

### Bridge
An edge whose removal increases the number of connected components.

### Clique
A subset of vertices where every two vertices are adjacent (complete subgraph).

## Distance and Paths

### Distance
The length of the shortest path between two vertices (number of edges in unweighted graphs, sum of weights in weighted graphs).

```swift
let distance = graph.shortestPath(from: "A", to: "B")?.cost
```

### Diameter
The maximum distance between any pair of vertices in the graph.

```swift
let diameter = graph.diameter()
```

### Eccentricity
For a vertex v, the maximum distance from v to any other vertex.

### Radius
The minimum eccentricity among all vertices.

### Center
The set of vertices with minimum eccentricity.

## Traversal Terms

### BFS (Breadth-First Search)
Explores vertices level by level, visiting all neighbors before going deeper.

```swift
graph.traverse(from: start, strategy: .bfs())
```

### DFS (Depth-First Search)
Explores as far as possible along each branch before backtracking.

```swift
graph.traverse(from: start, strategy: .dfs())
```

### Topological Sort
A linear ordering of vertices in a DAG such that for every edge (u, v), u comes before v.

```swift
let order = dag.topologicalSort()
```

## Special Paths and Cycles

### Eulerian Path
A path that visits every edge exactly once.

```swift
graph.eulerianPath(using: .hierholzer())
```

### Eulerian Cycle
An Eulerian path that starts and ends at the same vertex.

```swift
graph.eulerianCycle(using: .hierholzer())
```

### Hamiltonian Path
A path that visits every vertex exactly once.

```swift
graph.hamiltonianPath(using: .backtracking())
```

### Hamiltonian Cycle
A Hamiltonian path that returns to the starting vertex.

```swift
graph.hamiltonianCycle(using: .backtracking())
```

## Optimization Problems

### Shortest Path
The path between two vertices with minimum total weight.

```swift
graph.shortestPath(from: "A", to: "B", using: .dijkstra())
```

### Spanning Tree
A tree that includes all vertices of the graph.

### Minimum Spanning Tree (MST)
A spanning tree with the minimum sum of edge weights.

```swift
graph.minimumSpanningTree(using: .kruskal())
```

### Maximum Flow
The maximum amount of flow that can be pushed from a source to a sink in a flow network.

```swift
graph.maximumFlow(from: source, to: sink, using: .dinic())
```

### Minimum Cut
The minimum total capacity of edges whose removal disconnects source from sink.

### Matching
A set of edges without common vertices.

### Maximum Matching
A matching with the maximum number of edges.

```swift
bipartite.maximumMatching(using: .hopcroftKarp())
```

### Perfect Matching
A matching that covers all vertices.

## Centrality Measures

### Degree Centrality
Importance based on the number of connections.

```swift
let centrality = graph.degreeCentrality()
```

### Betweenness Centrality
Importance based on the number of shortest paths passing through a vertex.

```swift
let betweenness = graph.betweennessCentrality()
```

### Closeness Centrality
Importance based on average distance to all other vertices.

```swift
let closeness = graph.closenessCentrality()
```

## Graph Coloring

### Graph Coloring
Assigning colors to vertices such that no two adjacent vertices have the same color.

```swift
let coloring = graph.colorNodes(using: .dsatur())
```

### Chromatic Number (χ)
The minimum number of colors needed to color a graph.

### K-Coloring
A coloring using exactly k colors.

## Isomorphism

### Isomorphism
Two graphs are **isomorphic** if they have the same structure (can be transformed into each other by relabeling vertices).

```swift
graph1.isIsomorphic(to: graph2, using: .vf2())
```

### Automorphism
An isomorphism from a graph to itself.

### Subgraph
A graph formed from a subset of vertices and edges of another graph.

### Induced Subgraph
A subgraph containing all edges between its vertices that exist in the original graph.

## Network Models

### Erdős-Rényi Graph
A random graph where each edge appears independently with probability p.

```swift
ConnectedGraph.random(
    nodeCount: 100,
    using: .erdosRenyi(probability: 0.05)
)
```

### Scale-Free Network (Barabási-Albert)
A network where degree distribution follows a power law (few hubs with many connections).

```swift
ConnectedGraph.random(
    nodeCount: 100,
    using: .barabasiAlbert(attachmentCount: 3)
)
```

### Small-World Network (Watts-Strogatz)
A network with high clustering and short average path length.

```swift
ConnectedGraph.random(
    nodeCount: 100,
    using: .wattsStrogatz(neighbors: 4, rewiringProbability: 0.1)
)
```

## Complexity Classes

### P (Polynomial Time)
Problems solvable in polynomial time (e.g., shortest path, MST).

### NP (Nondeterministic Polynomial)
Problems verifiable in polynomial time.

### NP-Complete
Hardest problems in NP (e.g., Hamiltonian path, graph coloring).

### NP-Hard
At least as hard as NP-complete problems.

## Library-Specific Terms

### GraphComponent
Protocol requiring only `edges(from:)` method - minimal graph representation.

### Graph
Protocol adding global `allNodes` and `allEdges` to `GraphComponent`.

### Weighted Protocol
Protocol for types with comparable weights.

```swift
struct Distance: Weighted {
    let meters: Double
    var weight: Double { meters }
}
```

### Graph Transformations
Lazy wrappers that modify graph behavior:
- `transposed()`: Reverses edges
- `undirected()`: Makes bidirectional
- `weighted()`: Adds weights
- `complement()`: Graph complement

### Storage Strategies
- **ConnectedGraph**: Array-based storage
- **ConnectedHashGraph**: Hash-based storage
- **LazyGraph**: On-demand edge computation
- **GridGraph**: 2D grid structure

## Common Abbreviations

- **BFS**: Breadth-First Search
- **DFS**: Depth-First Search
- **MST**: Minimum Spanning Tree
- **SCC**: Strongly Connected Components
- **DAG**: Directed Acyclic Graph
- **TSP**: Traveling Salesman Problem

## See Also

- <doc:Architecture>
- <doc:CodeExamples>
- <doc:QuickReference>
