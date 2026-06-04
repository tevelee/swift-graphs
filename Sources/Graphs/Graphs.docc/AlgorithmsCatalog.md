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

### SPFA (Shortest Path Faster Algorithm)

**Best for:** Graphs with negative edge weights, faster than Bellman-Ford on average

```swift
let result = graph.shortestPaths(
    from: source,
    using: .spfa(weight: .property(\.weight))
)

// Access results
if let path = result.path(from: source, to: destination, in: graph) {
    print(path.vertices)
}

// Check for negative cycles
if result.hasNegativeCycle {
    print("Negative cycle detected!")
}
```

**Characteristics:**
- **Time Complexity:** O(V × E) worst case, O(E) average case
- **Space Complexity:** O(V)
- **Requirements:** None (handles negative weights)
- **Detects:** Negative cycles
- **Optimal:** Yes

**Use when:**
- Graph has negative edge weights
- Want faster average performance than Bellman-Ford
- Need single-source shortest paths to all vertices
- Need negative cycle detection

### Floyd-Warshall Algorithm

**Best for:** All-pairs shortest paths, dense graphs

```swift
let allPaths = graph.shortestPathsForAllPairs(
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
let allPaths = graph.shortestPathsForAllPairs(
    using: .johnson(edgeWeight: .property(\.weight))
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

### Contraction Hierarchy

**Best for:** Very fast repeated shortest-path queries on large static graphs

```swift
// One-time preprocessing — build the hierarchy
let ch = graph.contractionHierarchy(weight: .property(\.weight))

// Many fast queries reuse the same preprocessed hierarchy
let path1 = ch.shortestPath(from: a, to: b)
let path2 = ch.shortestPath(from: c, to: d)

// Or use the lazy algorithm adapter (preprocesses on the first call)
let path = graph.shortestPath(
    from: a,
    to: b,
    using: .contractionHierarchy(weight: .property(\.weight))
)

// Custom contraction order (optional — edge-difference heuristic used by default)
let ch2 = graph.contractionHierarchy(
    weight: .property(\.weight),
    vertexRank: { vertex in myRank(vertex) }
)
```

**Characteristics:**
- **Preprocessing:** O(V log V + E) (amortised)
- **Query Time:** O(V log V) in the augmented graph (much faster in practice)
- **Space Complexity:** O(V + E) for shortcuts
- **Requirements:** Non-negative weights, bidirectional graph
- **Optimal:** Yes (exact shortest path)

**Use when:**
- Road-network-style graphs with many repeated queries
- Preprocessing cost can be amortised over many queries
- Need exact results significantly faster than Dijkstra
- Navigation, logistics, large-scale pathfinding

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

## Articulation Points & Bridges

Find critical vertices (cut vertices) and edges (bridges) whose removal disconnects the graph.

### Tarjan's Algorithm

**Best for:** Finding all articulation points and bridges in a single pass

```swift
let result = graph.articulationPoints()

// Check specific vertices and edges
if result.isArticulationPoint(vertex) {
    print("Removing this vertex disconnects the graph")
}
if result.isBridge(edge) {
    print("Removing this edge disconnects the graph")
}

// Access all results
print(result.cutVertices)  // Set of articulation points
print(result.bridges)      // Array of bridge edges
```

**Characteristics:**
- **Time Complexity:** O(V + E)
- **Space Complexity:** O(V)
- **Strategy:** Single DFS pass with low-link values
- **Finds:** Both cut vertices and bridge edges
- **Optimal:** Linear time

**Use when:**
- Network reliability analysis (finding single points of failure)
- Identifying critical infrastructure in transportation networks
- Communication network vulnerability assessment
- Graph decomposition into biconnected components

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
    using: .fordFulkerson(capacityCost: .property(\.capacity))
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
    using: .edmondsKarp(capacityCost: .property(\.capacity))
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
    using: .dinic(capacityCost: .property(\.capacity))
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

## Minimum Cost Flow

Find the cheapest way to route flow through a network, given per-edge capacities and unit costs.

### Successive Shortest Paths

**Best for:** General minimum cost flow problems

```swift
// Minimum cost maximum flow (push as much flow as possible at minimum cost)
let result = graph.minimumCostFlow(
    from: source,
    to: sink,
    capacity: .property(\.capacity),
    unitCost: .property(\.cost)
)
print(result.flowValue)   // total flow achieved
print(result.totalCost)   // minimum cost for that flow

// Minimum cost flow with a demanded amount
let result2 = graph.minimumCostFlow(
    from: source,
    to: sink,
    capacity: .property(\.capacity),
    unitCost: .property(\.cost),
    demand: 10.0           // push exactly this much flow
)
print(result2.isFeasible) // false if demand exceeds max flow capacity

// Using the algorithm explicitly
let flow = graph.minimumCostFlow(
    from: source,
    to: sink,
    demand: nil,
    using: .successiveShortestPaths(
        capacity: .property(\.capacity),
        unitCost: .property(\.cost)
    )
)
```

**Characteristics:**
- **Time Complexity:** O(V × E × log V) per augmentation
- **Space Complexity:** O(V + E)
- **Strategy:** Finds minimum-cost augmenting paths via SPFA
- **Handles:** Flow rerouting via backward edges in the residual graph
- **Demand mode:** Push exactly a specified amount, or `nil` for max flow

**Use when:**
- Route goods through a supply network at minimum cost
- Assignment and transportation problems
- Need minimum cost maximum flow
- Both capacity and per-unit cost are relevant

## Minimum Cut

Find the minimum total edge weight whose removal disconnects the graph, without specifying source or sink vertices.

### Stoer-Wagner Algorithm

**Best for:** Global minimum cut on undirected weighted graphs

```swift
let result = graph.minimumCut(using: .stoerWagner(weight: .property(\.weight)))

// Or use the convenience method (defaults to Stoer-Wagner)
let result = graph.minimumCut(weight: .property(\.weight))

// Access results
if let cut = result {
    print("Cut weight: \(cut.cutWeight)")
    print("Partition A: \(cut.partitionA)")
    print("Partition B: \(cut.partitionB)")
    print("Cut edges: \(cut.cutEdges)")

    // O(1) edge check
    if cut.isCutEdge(someEdge) {
        print("This edge crosses the partition")
    }
}
```

**Characteristics:**
- **Time Complexity:** O(V³)
- **Space Complexity:** O(V²)
- **Strategy:** Maximum adjacency ordering with vertex contraction
- **Supports:** Any `Numeric & Comparable` weight (integers and floating-point)
- **Optimal:** Yes (exact solution)

**Use when:**
- Finding the weakest link that disconnects a network
- Network reliability analysis (complement to articulation points)
- Partitioning graphs into balanced communities
- VLSI circuit design and image segmentation

> Note: Stoer-Wagner operates on undirected graphs. For directed graphs, apply the `.undirected()` view first. The library represents undirected edges as bidirectional directed edges — Stoer-Wagner handles this naturally.

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

## Structural Properties

Test high-level structural characteristics of a graph. Each predicate has a sensible default and an algorithm-selectable form.

```swift
// Is there a cycle?
let cyclic = graph.isCyclic()

// Is the graph a tree (connected and acyclic, V-1 edges)?
let tree = graph.isTree()

// Is the graph connected (every vertex reachable)?
let connected = graph.isConnected()

// Is the graph 2-colorable (no odd cycles)?
let bipartite = graph.isBipartite()
```

**Characteristics:**
- **Time Complexity:** O(V + E) for each predicate
- **Space Complexity:** O(V)
- **Built on:** Traversal and coloring primitives

**Use when:**
- Validating input assumptions before running an algorithm
- Classifying graph structure
- Guarding algorithms that require a tree, DAG, or bipartite graph

> Note: Eulerian, Hamiltonian, and planarity predicates have their own dedicated sections (see *Eulerian Paths and Cycles*, *Hamiltonian Paths and Cycles*, and *Planarity*).

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

## Path Enumeration

Enumerate every simple path between two vertices, not just the shortest one.

### All Paths (DFS)

**Best for:** Listing all distinct routes between two vertices

```swift
// Lazily enumerate every simple path from source to destination
for path in graph.allPaths(from: source, to: destination) {
    print(path.vertices)
}

// Bound the search by path length (number of edges)
let shortRoutes = graph.allPaths(from: source, to: destination, maxLength: 5)

// Or supply an algorithm explicitly
let paths = graph.allPaths(from: source, to: destination, using: .dfs())
```

**Characteristics:**
- **Time Complexity:** O(V!) worst case (exponential — there can be exponentially many paths)
- **Space Complexity:** O(V) per path, lazy sequence
- **Returns:** A lazy sequence of simple (loop-free) paths
- **Bounded:** Optional `maxLength` prunes paths exceeding a given number of edges

**Use when:**
- Need every alternative route, not just the optimal one
- Enumerating possibilities in small graphs
- Reachability analysis with path constraints
- Combine with `maxLength` to keep the search tractable

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

## Centrality Measures

Measure the importance or influence of vertices in a graph.

### Degree Centrality

**Best for:** Simple importance measure based on connections

```swift
let centrality = graph.centrality(using: .degree())
```

**Characteristics:**
- **Time Complexity:** O(V + E)
- **Space Complexity:** O(V)
- **Measures:** Number of outgoing edges
- **Simple:** Fastest centrality measure

**Use when:**
- Need quick importance ranking
- Local influence matters
- Social network analysis
- Default centrality measure

### PageRank

**Best for:** Web graphs and link-based importance

```swift
let centrality = graph.centrality(using: .pageRank(dampingFactor: 0.85))
```

**Characteristics:**
- **Time Complexity:** O(k × (V + E)) where k is iterations until convergence
- **Space Complexity:** O(V)
- **Measures:** Importance based on incoming links
- **Handles:** Dangling nodes (vertices with no outgoing edges)

**Use when:**
- Web graph analysis
- Citation networks
- Influence propagation
- Link-based ranking

### Betweenness Centrality

**Best for:** Identifying bottlenecks and bridge vertices

```swift
let centrality = graph.centrality(using: .betweenness())
```

**Characteristics:**
- **Time Complexity:** O(V × E) for unweighted graphs
- **Space Complexity:** O(V)
- **Measures:** How often vertex appears on shortest paths
- **Algorithm:** Brandes' algorithm

**Use when:**
- Network resilience analysis
- Finding critical nodes
- Transportation networks
- Communication bottlenecks

### Closeness Centrality

**Best for:** Identifying vertices close to all others

```swift
let centrality = graph.centrality(using: .closeness())
```

**Characteristics:**
- **Time Complexity:** O(V × (V + E))
- **Space Complexity:** O(V)
- **Measures:** Average distance to all other vertices
- **Handles:** Disconnected components (returns 0 for unreachable vertices)

**Use when:**
- Information spreading
- Epidemic modeling
- Finding central hubs
- Average reachability analysis

### Eigenvector Centrality

**Best for:** Importance based on neighbors' importance

```swift
let centrality = graph.centrality(using: .eigenvector())
```

**Characteristics:**
- **Time Complexity:** O(k × (V + E)) where k is iterations until convergence
- **Space Complexity:** O(V)
- **Measures:** Recursive importance (important if connected to important vertices)
- **Requires:** BidirectionalGraph (needs incoming edges)

**Use when:**
- Social influence analysis
- Power structures
- Collaborative networks
- Recursive importance needed

## Planarity

Test whether a graph can be drawn in the plane without edge crossings, and compute embeddings and drawings when it can.

### Planarity Testing

**Best for:** Deciding whether a graph is planar

```swift
// Default planarity test (Left-Right algorithm)
let planar = graph.isPlanar()

// Choose a specific algorithm
let planar2 = graph.isPlanar(using: .leftRight())
let planar3 = graph.isPlanar(using: .boyerMyrvold())
let planar4 = graph.isPlanar(using: .hopcroftTarjan())
let planar5 = graph.isPlanar(using: .eulerFormula())
```

**Characteristics:**
- **Time Complexity:** O(V) for Left-Right, Boyer-Myrvold, Hopcroft-Tarjan (linear)
- **Space Complexity:** O(V)
- **Algorithms:** Left-Right (default), Boyer-Myrvold, Hopcroft-Tarjan, Euler-formula bound
- **Optimal:** Exact (Euler-formula is a fast necessary-condition pre-check)

**Use when:**
- Circuit board / VLSI layout feasibility
- Graph drawing and visualization
- Detecting K5 / K3,3 minors

### Planar Embedding

**Best for:** Computing a combinatorial embedding (rotation system) or a non-planarity certificate

```swift
let result = graph.planarEmbedding()              // default: Left-Right
let result2 = graph.planarEmbedding(using: .leftRight())

switch result {
case .planar(let embedding):
    // Clockwise neighbor order around each vertex
    let order = embedding.neighbors(of: vertex)
    let faces = embedding.faces                    // boundary cycles, incl. outer face
case .nonPlanar(let kuratowski):
    // A K5 or K3,3 subdivision proving non-planarity
    print(kuratowski)
}
```

**Characteristics:**
- **Time Complexity:** O(V) (Left-Right)
- **Returns:** `.planar` with a rotation system, or `.nonPlanar` with a Kuratowski subgraph
- **Provides:** Face enumeration from the embedding

**Use when:**
- Need the actual planar structure, not just a yes/no
- Face traversal / dual graph construction
- Producing a certificate of non-planarity

### Planar Drawing

**Best for:** Assigning crossing-free straight-line coordinates

```swift
// Straight-line grid drawing (Chrobak-Payne algorithm)
if let drawing = graph.planarDrawing() {
    for vertex in graph.vertices() {
        let point = drawing.position(of: vertex)   // integer grid coordinate
        print(point)
    }
    print(drawing.width, drawing.height)           // bounding box
}

// Equivalent explicit form
let drawing2 = graph.planarDrawing(using: .chrobakPayne())
```

**Characteristics:**
- **Time Complexity:** O(V)
- **Space Complexity:** O(V)
- **Output:** Integer grid coordinates on an O(V) × O(V) grid, no edge crossings
- **Returns:** `nil` if the graph is not planar

**Use when:**
- Visualizing planar graphs
- Generating layouts for rendering
- Embedding graphs on a coordinate grid

## Vertex Ordering

Compute a linear ordering of vertices to optimize downstream algorithms.

### Smallest-Last Ordering

**Best for:** Improving greedy graph coloring

```swift
let ordering = graph.orderVertices()                   // default: smallest-last
let ordering2 = graph.orderVertices(using: .smallestLastVertex())

let position = ordering.position(of: vertex)           // index in the ordering
let first = ordering.vertex(at: 0)                     // vertex at a position
```

**Characteristics:**
- **Time Complexity:** O(V + E)
- **Space Complexity:** O(V)
- **Strategy:** Repeatedly remove the minimum-degree vertex; reverse the removal order
- **Optimizes:** Greedy coloring quality (bounds colors by graph degeneracy + 1)

**Use when:**
- Pre-ordering vertices before greedy coloring
- Computing graph degeneracy
- Register allocation

### Reverse Cuthill-McKee

**Best for:** Reducing matrix bandwidth

```swift
let ordering = graph.orderVerticesForBandwidthReduction()
let ordering2 = graph.orderVertices(using: .reverseCuthillMcKee())
```

**Characteristics:**
- **Time Complexity:** O(V + E)
- **Space Complexity:** O(V)
- **Strategy:** BFS from a low-degree vertex, then reverse the order
- **Optimizes:** Bandwidth/profile of the adjacency matrix

**Use when:**
- Sparse matrix reordering for numerical solvers
- Cache-friendly graph layouts
- Reducing fill-in for matrix factorization

## Algorithm Selection Guide

### By Problem Type

| Problem | Recommended Algorithm |
|---------|----------------------|
| Unweighted shortest path | BFS |
| Weighted shortest path | Dijkstra or A* |
| Repeated queries on large graph | Contraction Hierarchy |
| Negative weights | Bellman-Ford or SPFA |
| All pairs | Johnson (sparse), Floyd-Warshall (dense) |
| Minimum spanning tree | Kruskal (sparse), Prim (dense) |
| Maximum flow | Edmonds-Karp (general), Dinic (large) |
| Minimum cost flow | Successive Shortest Paths |
| Global minimum cut | Stoer-Wagner |
| Graph coloring | Greedy (fast), DSatur (quality) |
| Bipartite matching | Hopcroft-Karp |
| Topological sort | Kahn or DFS |
| Connected components | DFS (standard), Union-Find (incremental) |
| Articulation points | Tarjan |
| All simple paths | All Paths (DFS) |
| Planarity testing | Left-Right (default), Boyer-Myrvold |
| Planar layout | Chrobak-Payne straight-line drawing |
| Vertex ordering | Smallest-Last (coloring), Reverse Cuthill-McKee (bandwidth) |
| Vertex importance | Degree (fast), PageRank (link-based), Betweenness (bottlenecks) |

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

- <doc:AlgorithmInterfaces>
- <doc:VisitorPattern>
- <doc:Architecture>

