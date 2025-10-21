# Algorithms Catalog

A comprehensive guide to all graph algorithms available in Swift Graphs.

## Overview

Swift Graphs provides a rich collection of graph algorithms organized by problem domain. Each algorithm is available through a protocol-based interface, allowing you to choose the best implementation for your specific use case.

## Shortest Path Algorithms

Find the shortest path between vertices in weighted graphs.

### Dijkstra's Algorithm

**Best for:** Single-source shortest paths with non-negative edge weights

```swift
let path = graph.shortestPath(
    from: source,
    to: destination,
    using: .dijkstra(weight: .property(\.weight))
)
```

**Characteristics:**
- **Time Complexity:** O((V + E) log V) with binary heap
- **Space Complexity:** O(V)
- **Requirements:** Non-negative edge weights
- **Optimal:** Yes, for non-negative weights

**Use when:**
- Edge weights are non-negative
- Need optimal solution
- Graph is moderately sized
- Most common choice for weighted shortest paths

### A\* Search

**Best for:** Pathfinding with heuristic information

```swift
let path = graph.shortestPath(
    from: start,
    to: goal,
    using: .aStar(
        weight: .property(\.weight),
        heuristic: .euclidean
    )
)
```

**Characteristics:**
- **Time Complexity:** O((V + E) log V) - often much better with good heuristic
- **Space Complexity:** O(V)
- **Requirements:** Non-negative weights, admissible heuristic
- **Optimal:** Yes, with admissible heuristic

**Built-in heuristics:**
- `.euclidean` - Straight-line distance
- `.manhattanDistance` - Grid-based distance
- `.chebyshevDistance` - Diagonal distance
- Custom heuristics supported

**Use when:**
- Spatial/geometric graphs
- Have good distance estimate to goal
- Want faster than Dijkstra
- Common in game pathfinding

### Bellman-Ford Algorithm

**Best for:** Graphs with negative edge weights

```swift
let path = graph.shortestPath(
    from: source,
    to: destination,
    using: .bellmanFord(weight: .property(\.weight))
)
```

**Characteristics:**
- **Time Complexity:** O(V × E)
- **Space Complexity:** O(V)
- **Requirements:** None (handles negative weights)
- **Detects:** Negative cycles
- **Optimal:** Yes

**Use when:**
- Graph has negative edge weights
- Need to detect negative cycles
- Graph is not too large
- Only algorithm that handles negative weights

### Floyd-Warshall Algorithm

**Best for:** All-pairs shortest paths, dense graphs

```swift
let allPaths = graph.allPairsShortestPaths(
    using: .floydWarshall(weight: .property(\.weight))
)
```

**Characteristics:**
- **Time Complexity:** O(V³)
- **Space Complexity:** O(V²)
- **Requirements:** None
- **Computes:** Shortest paths between all pairs
- **Optimal:** Yes

**Use when:**
- Need paths between all vertex pairs
- Graph is small (< 500 vertices)
- Dense graphs
- Can afford O(V³) time

### Johnson's Algorithm

**Best for:** All-pairs shortest paths in sparse graphs

```swift
let allPaths = graph.allPairsShortestPaths(
    using: .johnson(weight: .property(\.weight))
)
```

**Characteristics:**
- **Time Complexity:** O(V² log V + VE)
- **Space Complexity:** O(V²)
- **Requirements:** None
- **Uses:** Bellman-Ford + Dijkstra internally
- **Optimal:** Yes

**Use when:**
- Need all-pairs shortest paths
- Graph is sparse (E << V²)
- Faster than Floyd-Warshall for sparse graphs

### Yen's K-Shortest Paths

**Best for:** Finding multiple paths between vertices

```swift
let paths = graph.kShortestPaths(
    from: source,
    to: destination,
    k: 5,
    using: .yen(weight: .property(\.weight))
)
```

**Characteristics:**
- **Time Complexity:** O(k × V × (E + V log V))
- **Space Complexity:** O(V + E)
- **Finds:** K shortest loop-free paths
- **Ordered:** By increasing length

**Use when:**
- Need alternative routes
- Route planning with alternatives
- Network resilience analysis

## Graph Traversal

Systematically visit vertices in a specific order.

### Depth-First Search (DFS)

**Best for:** Exploring deep into graph, detecting cycles

```swift
let result = graph.traverse(from: start, using: .dfs())

// Or with specific order
let result = graph.traverse(from: start, using: .dfs(order: .preorder))
```

**Characteristics:**
- **Time Complexity:** O(V + E)
- **Space Complexity:** O(V)
- **Order:** Preorder, postorder, or inorder (for binary graphs)

**Variants:**
- **Preorder:** Visit vertex before children
- **Postorder:** Visit vertex after children
- **Inorder:** Visit left child, vertex, right child (binary graphs)

**Use when:**
- Topological sorting (postorder)
- Cycle detection
- Strongly connected components
- Memory-efficient traversal

### Breadth-First Search (BFS)

**Best for:** Level-by-level exploration, unweighted shortest paths

```swift
let result = graph.traverse(from: start, using: .bfs())
```

**Characteristics:**
- **Time Complexity:** O(V + E)
- **Space Complexity:** O(V)
- **Order:** Level by level
- **Finds:** Shortest paths in unweighted graphs

**Use when:**
- Unweighted shortest paths
- Level-order traversal
- Finding connected components
- Social network distance analysis

### Best-First Search

**Best for:** Heuristic-guided exploration

```swift
let result = graph.search(
    from: start,
    using: .bestFirst(priority: { vertex, graph in
        heuristicCost(vertex)
    })
)
```

**Characteristics:**
- **Time Complexity:** O((V + E) log V)
- **Space Complexity:** O(V)
- **Order:** By priority function

**Use when:**
- Have heuristic information
- Want to explore promising paths first
- Custom exploration order needed

### Uniform Cost Search

**Best for:** Weighted graphs, early termination

```swift
for vertex in graph.search(from: start, using: .uniformCost(weight: .property(\.weight))) {
    if vertex == goal { break }
}
```

**Characteristics:**
- **Time Complexity:** O((V + E) log V)
- **Space Complexity:** O(V)
- **Returns:** Lazy sequence
- **Allows:** Early termination

**Use when:**
- Want lazy evaluation
- May not need full exploration
- Weighted exploration with early exit

### Depth-Limited Search

**Best for:** Memory-constrained depth searches

```swift
let result = graph.traverse(from: start, using: .depthLimitedDFS(maxDepth: 10))
```

**Characteristics:**
- **Time Complexity:** O(V + E)
- **Space Complexity:** O(depth)
- **Limits:** Search depth
- **Memory efficient:** Yes

**Use when:**
- Known maximum depth
- Memory constrained
- Want to limit exploration

### Iteratively Deepening DFS

**Best for:** Unknown depth, memory efficiency

```swift
let result = graph.search(from: start, using: .iterativelyDeepeningDFS())
```

**Characteristics:**
- **Time Complexity:** O(V + E)
- **Space Complexity:** O(depth)
- **Combines:** BFS completeness + DFS memory efficiency
- **Memory optimal:** Yes for tree-like graphs

**Use when:**
- Don't know maximum depth
- Need memory efficiency of DFS
- Want completeness of BFS

## Connected Components

Identify disconnected subgraphs.

### DFS-Based Connected Components

**Best for:** Most use cases

```swift
let components = graph.connectedComponents(using: .dfs())
```

**Characteristics:**
- **Time Complexity:** O(V + E)
- **Space Complexity:** O(V)
- **Strategy:** Depth-first traversal
- **Default algorithm**

**Use when:**
- Standard component detection
- Simple and efficient
- Most common choice

### Union-Find Connected Components

**Best for:** Incremental graph construction

```swift
let components = graph.connectedComponents(using: .unionFind())
```

**Characteristics:**
- **Time Complexity:** O(E α(V)) where α is inverse Ackermann
- **Space Complexity:** O(V)
- **Strategy:** Disjoint set union
- **Near optimal:** α(V) is effectively constant

**Use when:**
- Building graph incrementally
- Dynamic connectivity queries
- Kruskal's MST (uses internally)

## Strongly Connected Components

Find maximal strongly connected subgraphs in directed graphs.

### Tarjan's Algorithm

**Best for:** Single-pass SCC detection

```swift
let sccs = graph.stronglyConnectedComponents(using: .tarjan())
```

**Characteristics:**
- **Time Complexity:** O(V + E)
- **Space Complexity:** O(V)
- **Passes:** Single DFS pass
- **Optimal:** Yes

**Use when:**
- Directed graphs
- Need efficiency
- Most common choice

### Kosaraju's Algorithm

**Best for:** Conceptual simplicity

```swift
let sccs = graph.stronglyConnectedComponents(using: .kosaraju())
```

**Characteristics:**
- **Time Complexity:** O(V + E)
- **Space Complexity:** O(V)
- **Passes:** Two DFS passes
- **Simpler:** Easier to understand

**Use when:**
- Learning/teaching
- Prefer simple implementation
- Performance difference negligible

## Minimum Spanning Tree

Find minimum-weight tree connecting all vertices.

### Kruskal's Algorithm

**Best for:** Sparse graphs

```swift
let mst = graph.minimumSpanningTree(using: .kruskal(weight: .property(\.weight)))
```

**Characteristics:**
- **Time Complexity:** O(E log E)
- **Space Complexity:** O(V)
- **Strategy:** Edge-based, greedy
- **Uses:** Union-Find internally
- **Optimal:** Yes

**Use when:**
- Sparse graphs (E close to V)
- Have all edges available
- Most common choice

### Prim's Algorithm

**Best for:** Dense graphs

```swift
let mst = graph.minimumSpanningTree(using: .prim(weight: .property(\.weight)))
```

**Characteristics:**
- **Time Complexity:** O((V + E) log V) with binary heap
- **Space Complexity:** O(V)
- **Strategy:** Vertex-based, greedy
- **Optimal:** Yes

**Use when:**
- Dense graphs (E close to V²)
- Need single tree growing process
- Good for online algorithms

### Borůvka's Algorithm

**Best for:** Parallel processing

```swift
let mst = graph.minimumSpanningTree(using: .boruvka(weight: .property(\.weight)))
```

**Characteristics:**
- **Time Complexity:** O(E log V)
- **Space Complexity:** O(V)
- **Strategy:** Component-based
- **Parallelizable:** Yes
- **Optimal:** Yes

**Use when:**
- Can leverage parallelism
- Distributed computing
- Theoretical interest

## Maximum Flow

Compute maximum flow in flow networks.

### Ford-Fulkerson Method

**Best for:** Simple flow networks

```swift
let maxFlow = graph.maximumFlow(
    from: source,
    to: sink,
    using: .fordFulkerson(capacity: .property(\.capacity))
)
```

**Characteristics:**
- **Time Complexity:** O(E × maxFlow)
- **Space Complexity:** O(V + E)
- **Strategy:** Augmenting paths
- **Not polynomial:** Time depends on flow value

**Use when:**
- Small flow values
- Simple networks
- Educational purposes

### Edmonds-Karp Algorithm

**Best for:** General flow problems

```swift
let maxFlow = graph.maximumFlow(
    from: source,
    to: sink,
    using: .edmondsKarp(capacity: .property(\.capacity))
)
```

**Characteristics:**
- **Time Complexity:** O(V × E²)
- **Space Complexity:** O(V + E)
- **Strategy:** BFS-based Ford-Fulkerson
- **Polynomial time:** Yes
- **Most common**

**Use when:**
- General-purpose flow problems
- Network routing
- Matching problems
- Default choice

### Dinic's Algorithm

**Best for:** Large flow networks

```swift
let maxFlow = graph.maximumFlow(
    from: source,
    to: sink,
    using: .dinic(capacity: .property(\.capacity))
)
```

**Characteristics:**
- **Time Complexity:** O(V² × E)
- **Space Complexity:** O(V + E)
- **Strategy:** Level graphs + blocking flows
- **Faster:** Than Edmonds-Karp in practice

**Use when:**
- Large networks
- Need better performance
- Bipartite matching

### Push-Relabel Algorithm

**Best for:** Maximum performance

```swift
let maxFlow = graph.maximumFlow(
    from: source,
    to: sink,
    using: .pushRelabel(capacity: .property(\.capacity))
)
```

**Characteristics:**
- **Time Complexity:** O(V²E) - O(V³) with heuristics
- **Space Complexity:** O(V + E)
- **Strategy:** Preflow-push
- **Fastest:** In practice for many graphs

**Use when:**
- Performance critical
- Very large networks
- Willing to trade complexity for speed

## Graph Coloring

Assign colors to vertices so adjacent vertices differ.

### Greedy Coloring

**Best for:** Fast, simple coloring

```swift
let coloring = graph.colorGraph(using: .greedy())
```

**Characteristics:**
- **Time Complexity:** O(V + E)
- **Space Complexity:** O(V)
- **Quality:** Approximate
- **Chromatic bound:** ≤ Δ + 1 (where Δ is max degree)
- **Default algorithm**

**Use when:**
- Need quick solution
- Approximate is acceptable
- Register allocation
- Scheduling

### DSatur (Degree of Saturation)

**Best for:** Better coloring quality

```swift
let coloring = graph.colorGraph(using: .dsatur())
```

**Characteristics:**
- **Time Complexity:** O(V² + E)
- **Space Complexity:** O(V)
- **Quality:** Better than greedy
- **Strategy:** Color vertex with most colored neighbors first

**Use when:**
- Need better quality
- Can afford extra time
- Timetabling problems
- Frequency assignment

### Welsh-Powell

**Best for:** Degree-based ordering

```swift
let coloring = graph.colorGraph(using: .welshPowell())
```

**Characteristics:**
- **Time Complexity:** O(V log V + E)
- **Space Complexity:** O(V)
- **Quality:** Good for many graphs
- **Strategy:** Color high-degree vertices first

**Use when:**
- Graph has varying degrees
- Want balance of speed/quality
- Practical applications

## Bipartite Matching

Find maximum matching in bipartite graphs.

### Hopcroft-Karp Algorithm

**Best for:** Maximum cardinality matching

```swift
let matching = bipartiteGraph.maximumMatching(using: .hopcroftKarp())
```

**Characteristics:**
- **Time Complexity:** O(E√V)
- **Space Complexity:** O(V)
- **Finds:** Maximum cardinality matching
- **Optimal:** Yes

**Use when:**
- Bipartite graphs
- Job assignment
- Resource allocation
- Fastest bipartite matching

### Hungarian Algorithm

**Best for:** Weighted bipartite matching

```swift
let matching = bipartiteGraph.maximumWeightedMatching(
    using: .hungarian(weight: .property(\.weight))
)
```

**Characteristics:**
- **Time Complexity:** O(V³)
- **Space Complexity:** O(V²)
- **Finds:** Maximum weight matching
- **Optimal:** Yes

**Use when:**
- Weighted assignment problems
- Cost optimization
- Task scheduling with costs

## Topological Sort

Order vertices in directed acyclic graph.

### Kahn's Algorithm

**Best for:** Level-by-level ordering

```swift
let sorted = graph.topologicalSort(using: .kahn())
```

**Characteristics:**
- **Time Complexity:** O(V + E)
- **Space Complexity:** O(V)
- **Strategy:** Remove vertices with no incoming edges
- **Detects cycles:** Yes

**Use when:**
- Need BFS-like ordering
- Build systems (dependencies)
- Task scheduling
- Course prerequisites

### DFS-Based Topological Sort

**Best for:** Postorder-based sorting

```swift
let sorted = graph.topologicalSort(using: .dfs())
```

**Characteristics:**
- **Time Complexity:** O(V + E)
- **Space Complexity:** O(V)
- **Strategy:** DFS postorder, reversed
- **Simpler implementation**

**Use when:**
- Prefer DFS approach
- Already using DFS elsewhere
- Memory efficient

## Cycle Detection

Detect cycles in graphs.

### DFS-Based Cycle Detection

**Best for:** Directed graphs

```swift
let hasCycle = graph.hasCycle(using: .dfs())
```

**Characteristics:**
- **Time Complexity:** O(V + E)
- **Space Complexity:** O(V)
- **Detects:** Back edges
- **Works:** Directed and undirected

### Union-Find Cycle Detection

**Best for:** Undirected graphs

```swift
let hasCycle = graph.hasCycle(using: .unionFind())
```

**Characteristics:**
- **Time Complexity:** O(E α(V))
- **Space Complexity:** O(V)
- **Efficient:** For undirected graphs
- **Online:** Can detect during edge addition

## Eulerian Paths and Cycles

Visit every edge exactly once.

### Hierholzer's Algorithm

**Best for:** Finding Eulerian paths/cycles

```swift
// Eulerian cycle
if let cycle = graph.eulerianCycle(using: .hierholzer()) {
    print("Found Eulerian cycle")
}

// Eulerian path
if let path = graph.eulerianPath(using: .hierholzer()) {
    print("Found Eulerian path")
}
```

**Characteristics:**
- **Time Complexity:** O(V + E)
- **Space Complexity:** O(V + E)
- **Strategy:** Build cycles and merge
- **Optimal:** Linear time

**Use when:**
- Route planning (Chinese Postman)
- Circuit design
- DNA sequencing
- Network traversal

## Hamiltonian Paths and Cycles

Visit every vertex exactly once.

### Backtracking Algorithm

**Best for:** Small graphs

```swift
if let path = graph.hamiltonianPath(using: .backtracking()) {
    print("Found Hamiltonian path")
}
```

**Characteristics:**
- **Time Complexity:** O(V!)
- **Space Complexity:** O(V)
- **Strategy:** Exhaustive search with pruning
- **NP-Complete problem**

**Use when:**
- Small graphs (< 20 vertices)
- Need exact solution
- Traveling Salesman variants

### Dynamic Programming (Held-Karp)

**Best for:** Exact TSP solutions

```swift
let tour = graph.hamiltonianCycle(using: .heldKarp(weight: .property(\.weight)))
```

**Characteristics:**
- **Time Complexity:** O(2^V × V²)
- **Space Complexity:** O(2^V × V)
- **Optimal:** Yes
- **Faster:** Than backtracking for medium graphs

**Use when:**
- Need optimal TSP solution
- Graph has 15-25 vertices
- Can afford exponential time

## Graph Isomorphism

Determine if two graphs are structurally identical.

### VF2 Algorithm

**Best for:** Practical isomorphism testing

```swift
let isomorphic = graph1.isIsomorphic(to: graph2, using: .vf2())
```

**Characteristics:**
- **Time Complexity:** O(V! × V²) worst case, much better in practice
- **Space Complexity:** O(V)
- **Strategy:** State space search with pruning
- **Most efficient:** For practical graphs

**Use when:**
- Chemical structure comparison
- Pattern matching
- Network analysis

### Weisfeiler-Lehman

**Best for:** Quick isomorphism tests

```swift
let areIsomorphic = graph1.weisfeilerLehmanTest(graph2, iterations: 3)
```

**Characteristics:**
- **Time Complexity:** O(E)
- **Space Complexity:** O(V)
- **Sufficient:** For many graph classes
- **Not complete:** May have false negatives

**Use when:**
- Fast test needed
- Most graphs detected
- Can accept occasional false negative

## Random Graph Generation

Generate random graphs with specific properties.

### Erdős-Rényi Model

**Best for:** Random graphs

```swift
let graph = AdjacencyList.randomGraph(
    vertexCount: 100,
    using: .erdosRenyi(edgeProbability: 0.1)
)
```

**Characteristics:**
- **Each edge:** Independent probability
- **Simple:** Easy to analyze
- **Properties:** Predictable average degree

**Use when:**
- Testing algorithms
- Theoretical analysis
- Baseline comparisons

### Barabási-Albert Model

**Best for:** Scale-free networks

```swift
let graph = AdjacencyList.randomGraph(
    vertexCount: 100,
    using: .barabasiAlbert(edgesPerVertex: 3)
)
```

**Characteristics:**
- **Power-law:** Degree distribution
- **Preferential attachment:** Rich get richer
- **Realistic:** Models real networks

**Use when:**
- Social networks
- Web graphs
- Biological networks
- Realistic test data

### Watts-Strogatz Model

**Best for:** Small-world networks

```swift
let graph = AdjacencyList.randomGraph(
    vertexCount: 100,
    using: .wattsStrogatz(neighbors: 4, rewiringProbability: 0.1)
)
```

**Characteristics:**
- **High clustering:** Like regular graphs
- **Short paths:** Like random graphs
- **Small world:** Combines both properties

**Use when:**
- Social networks
- Neural networks
- Realistic connectivity patterns

## Clique Detection

Find complete subgraphs.

### Bron-Kerbosch Algorithm

**Best for:** Finding maximal cliques

```swift
let cliques = graph.maximalCliques(using: .bronKerbosch())
```

**Characteristics:**
- **Time Complexity:** O(3^(V/3))
- **Space Complexity:** O(V)
- **Finds:** All maximal cliques
- **With pivoting:** Practical for sparse graphs

**Use when:**
- Social network analysis
- Protein interaction networks
- Finding communities

## Community Detection

Identify densely connected groups.

### Louvain Method

**Best for:** Large networks

```swift
let communities = graph.detectCommunities(using: .louvain())
```

**Characteristics:**
- **Time Complexity:** O(V log V)
- **Space Complexity:** O(V + E)
- **Strategy:** Modularity optimization
- **Fast:** Handles millions of vertices
- **Hierarchical:** Produces dendrogram

**Use when:**
- Social networks
- Large graphs
- Need hierarchy of communities
- Most popular method

## Planarity Testing

Determine if graph can be drawn without edge crossings.

### Boyer-Myrvold Algorithm

**Best for:** Planarity testing

```swift
let isPlanar = graph.isPlanar(using: .boyerMyrvold())
```

**Characteristics:**
- **Time Complexity:** O(V)
- **Space Complexity:** O(V)
- **Optimal:** Linear time
- **Outputs:** Planar embedding if exists

**Use when:**
- Circuit design
- Geographic networks
- Graph drawing

## Algorithm Selection Guide

### By Problem Type

| Problem | Recommended Algorithm |
|---------|----------------------|
| Unweighted shortest path | BFS |
| Weighted shortest path | Dijkstra or A* |
| Negative weights | Bellman-Ford |
| All pairs | Johnson (sparse), Floyd-Warshall (dense) |
| Minimum spanning tree | Kruskal (sparse), Prim (dense) |
| Maximum flow | Edmonds-Karp (general), Dinic (large) |
| Graph coloring | Greedy (fast), DSatur (quality) |
| Bipartite matching | Hopcroft-Karp |
| Topological sort | Kahn or DFS |
| Connected components | DFS (standard), Union-Find (incremental) |

### By Graph Size

| Vertices | Consider |
|----------|----------|
| < 100 | Any algorithm works |
| 100-1000 | Avoid O(V³) algorithms |
| 1000-10000 | Use O(V + E) algorithms |
| 10000+ | Optimize carefully, consider approximations |

### By Graph Density

| Density | Sparse (E ≈ V) | Dense (E ≈ V²) |
|---------|----------------|----------------|
| MST | Kruskal | Prim |
| All-pairs | Johnson | Floyd-Warshall |
| Storage | AdjacencyList | AdjacencyMatrix |

## See Also

- <doc:Concepts/AlgorithmInterfaces> - Creating custom algorithms
- <doc:Concepts/VisitorPattern> - Observing algorithm execution
- <doc:Concepts/Architecture> - Library architecture overview

