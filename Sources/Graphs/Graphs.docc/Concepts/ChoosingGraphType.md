# Choosing a Graph Type

Select the right graph implementation for your use case with this comprehensive guide.

## Overview

Swift Graphs provides multiple graph implementations, each optimized for different scenarios. Choosing the right implementation impacts both performance and memory usage. This guide helps you make the best choice.

## Graph Implementations

### `AdjacencyList` - The Default Choice

**Best for:** Most use cases, sparse graphs

```swift
var graph = AdjacencyList()
let a = graph.addVertex { $0.label = "A" }
let b = graph.addVertex { $0.label = "B" }
graph.addEdge(from: a, to: b)
```

**Characteristics:**
- **Space complexity:** O(V + E)
- **Add vertex:** O(1)
- **Add edge:** O(1)
- **Remove vertex:** O(E)
- **Remove edge:** Depends on storage (O(degree) for basic storage)
- **Edge lookup:** Depends on storage (O(degree) for basic storage, can be optimized)
- **Iterate neighbors:** O(degree)

**Advantages:**
- ✅ Memory efficient for sparse graphs
- ✅ Fast vertex/edge insertion
- ✅ Efficient traversal
- ✅ Supports all graph operations
- ✅ Storage backends can be optimized (e.g., `CacheInOutEdges` for bidirectional access)

**Disadvantages:**
- ⚠️ Edge existence check depends on storage backend
- ❌ Not optimal for very dense graphs

**Use when:**
- Social networks (average degree << V)
- Road networks
- Web graphs
- Dependency graphs
- **Default choice for most applications**

**Example use cases:**
```swift
// Social network (sparse)
var facebook = AdjacencyList()  // Person has ~150 friends out of billions

// Road map (sparse)
var roadNetwork = AdjacencyList()  // City connected to ~5 cities

// File dependencies (sparse)
var buildSystem = AdjacencyList()  // File depends on ~10 files
```

### `AdjacencyMatrix` - Dense Graphs

**Best for:** Dense graphs, need O(1) edge lookup

```swift
var graph = AdjacencyMatrix()
let a = graph.addVertex()
let b = graph.addVertex()
graph.addEdge(from: a, to: b)
```

**Characteristics:**
- **Space complexity:** O(V²)
- **Add vertex:** O(V) (resize matrix)
- **Add edge:** O(1)
- **Remove vertex:** O(V²)
- **Remove edge:** O(1)
- **Edge lookup:** O(1)
- **Iterate neighbors:** O(V)

**Advantages:**
- ✅ O(1) edge existence check
- ✅ O(1) edge insertion/removal
- ✅ Efficient for dense graphs
- ✅ Simple implementation

**Disadvantages:**
- ❌ O(V²) space even if sparse
- ❌ Slow neighbor iteration
- ❌ Expensive to add vertices

**Use when:**
- Complete or near-complete graphs
- Small graphs (< 1000 vertices)
- Need frequent edge existence checks
- Edge lookup dominates operations

**Example use cases:**
```swift
// Complete graph (every vertex connected to every other)
var tournament = AdjacencyMatrix()  // Round-robin tournament

// Dense similarity graph
var clustering = AdjacencyMatrix()  // Points within threshold distance

// Small state machine
var fsm = AdjacencyMatrix()  // Small finite state machine
```

### `BipartiteAdjacencyList` - Two-Colored Graphs

**Best for:** Bipartite graphs, matching problems

```swift
var graph = BipartiteAdjacencyList()
let a = graph.addVertex(to: .left) { $0.label = "Job A" }
let b = graph.addVertex(to: .right) { $0.label = "Worker B" }
graph.addEdge(from: a, to: b)
```

**Characteristics:**
- Two separate vertex sets
- Edges only between sets
- Specialized for matching algorithms

**Advantages:**
- ✅ Enforces bipartite structure
- ✅ Optimized for matching algorithms
- ✅ Clear partition separation

**Disadvantages:**
- ❌ Only for bipartite graphs
- ❌ Cannot add edges within same partition

**Use when:**
- Job-worker assignment
- Student-course enrollment
- Recommendation systems (users-items)
- Network flow source-sink problems

**Example use cases:**
```swift
// Job assignment
var jobMatching = BipartiteAdjacencyList()
// Left: workers, Right: jobs

// Recommendation system
var recommendations = BipartiteAdjacencyList()
// Left: users, Right: products

// Course enrollment
var enrollment = BipartiteAdjacencyList()
// Left: students, Right: courses
```

### `GridGraph` - 2D Spatial Graphs

**Best for:** Pathfinding in 2D grids, tile-based games

```swift
let grid = GridGraph(width: 10, height: 10)
let start = GridGraph.Vertex(x: 0, y: 0)
let goal = GridGraph.Vertex(x: 9, y: 9)

let path = grid.shortestPath(
    from: start,
    to: goal,
    using: .aStar(heuristic: .manhattanDistance)
)
```

**Characteristics:**
- **Space complexity:** O(1) (computed)
- **Vertices:** Grid coordinates
- **Edges:** Computed from neighbors (4 or 8 directions)
- Implicit structure, not stored

**Advantages:**
- ✅ Memory efficient (no edge storage)
- ✅ Fast neighbor computation
- ✅ Built-in spatial heuristics
- ✅ Perfect for pathfinding

**Disadvantages:**
- ❌ Only regular grids
- ❌ No dynamic modification
- ❌ No weights on edges (or uniform weights)

**Use when:**
- Tile-based games
- Robot path planning
- Image processing
- Map navigation on regular grids

**Example use cases:**
```swift
// Game map
let gameMap = GridGraph(width: 100, height: 100)
// Find path avoiding obstacles

// Robot navigation
let warehouse = GridGraph(width: 50, height: 50)
// Find shortest path for robot

// Image region growing
let image = GridGraph(width: 640, height: 480)
// Process neighboring pixels
```

### `LazyGraph` - Computed On-Demand

**Best for:** Large/infinite graphs, expensive edge computation

```swift
let lazyGraph = LazyGraph { vertex in
    // Compute neighbors on-demand
    return computeNeighbors(for: vertex)
}
```

**Characteristics:**
- **Space complexity:** O(1) for structure
- Edges computed when needed
- Can represent infinite graphs

**Advantages:**
- ✅ Minimal memory usage
- ✅ Can represent infinite graphs
- ✅ Defer expensive computations
- ✅ Generate graphs procedurally

**Disadvantages:**
- ❌ Recomputation if not cached
- ❌ Harder to reason about
- ❌ No edge/vertex enumeration

**Use when:**
- Graph too large for memory
- Edges expensive to compute
- Graph structure is algorithmic
- Exploring search spaces

**Example use cases:**
```swift
// State space search
let chessPositions = LazyGraph { position in
    // Generate legal moves
    return legalMoves(from: position)
}

// Large generated graph
let fractal = LazyGraph { point in
    // Compute fractal neighbors
    return fractalNeighbors(point)
}
```

## Performance Comparison

### Space Complexity

| Implementation | Space | Best For |
|----------------|-------|----------|
| AdjacencyList | O(V + E) | Sparse graphs (E << V²) |
| AdjacencyMatrix | O(V²) | Dense graphs (E ≈ V²) |
| BipartiteAdjacencyList | O(V + E) | Bipartite graphs |
| GridGraph | O(1) | Regular 2D grids |
| LazyGraph | O(1) | Computed graphs |

### Operation Complexity

| Operation | AdjacencyList | AdjacencyMatrix | GridGraph |
|-----------|---------------|-----------------|-----------|
| Add vertex | O(1) | O(V) | N/A |
| Add edge | O(1) | O(1) | N/A |
| Remove vertex | O(E) | O(V²) | N/A |
| Remove edge | O(degree)* | O(1) | N/A |
| Edge exists | O(degree)* | O(1) | O(1) |
| Get neighbors | O(degree) | O(V) | O(1) |

\* Can be optimized with different storage backends (e.g., hash-based edge storage)

### Memory Usage (Approximate)

For a graph with 1000 vertices:

| Density | Edges | AdjacencyList | AdjacencyMatrix |
|---------|-------|---------------|-----------------|
| Very Sparse | 2,000 | ~24 KB | ~1 MB |
| Sparse | 10,000 | ~120 KB | ~1 MB |
| Dense | 100,000 | ~1.2 MB | ~1 MB |
| Very Dense | 500,000 | ~6 MB | ~1 MB |

**Rule of thumb:** Use `AdjacencyMatrix` when `E > V²/2`.

## Specialized Use Cases

### Directed vs. Undirected Graphs

All implementations support directed graphs. For undirected:

```swift
// Simulate undirected: add edges in both directions
graph.addEdge(from: a, to: b)
graph.addEdge(from: b, to: a)
```

### Weighted Graphs

All implementations support weights through properties:

```swift
graph.addEdge(from: a, to: b) { $0.weight = 5.0 }
```

### Multi-Graphs (Multiple Edges Between Vertices)

`AdjacencyList` naturally supports multi-graphs:

```swift
let e1 = graph.addEdge(from: a, to: b) { $0.label = "Road 1" }
let e2 = graph.addEdge(from: a, to: b) { $0.label = "Road 2" }
```

### Read-Only vs. Mutable Graphs

All standard implementations support mutation. For read-only graphs:

```swift
let graph = createGraph()  // Create and populate with 'var'
// Use 'let' to make immutable - compiler enforces
// graph.addVertex() // ❌ Compile error - cannot mutate immutable value
```

The compiler enforces immutability: `mutating` functions (like `addVertex()`, `addEdge()`) cannot be called on graphs declared with `let`.

## Migration Between Types

### Converting Between Implementations

```swift
// Convert AdjacencyList to AdjacencyMatrix
func convert(from list: AdjacencyList) -> AdjacencyMatrix {
    var matrix = AdjacencyMatrix()
    
    // Copy vertices
    var vertexMap: [Int: Int] = [:]
    for vertex in list.vertices() {
        let newVertex = matrix.addVertex()
        vertexMap[vertex] = newVertex
    }
    
    // Copy edges
    for edge in list.edges() {
        if let src = list.source(of: edge),
           let dst = list.destination(of: edge),
           let newSrc = vertexMap[src],
           let newDst = vertexMap[dst] {
            matrix.addEdge(from: newSrc, to: newDst)
        }
    }
    
    return matrix
}
```

## Making the Final Decision

### Questions to Ask

1. **How many vertices and edges?**
   - Small (< 1000 V): Any implementation
   - Large (> 100K V): Consider memory carefully

2. **What's the density?**
   - E < V: Sparse → `AdjacencyList`
   - E > V²/2: Dense → `AdjacencyMatrix`

3. **What operations dominate?**
   - Edge existence checks: `AdjacencyMatrix`
   - Traversal: `AdjacencyList`
   - Spatial queries: `GridGraph`

4. **Is it a special structure?**
   - 2D grid: `GridGraph`
   - Bipartite: `BipartiteAdjacencyList`
   - Computed: `LazyGraph`

5. **Memory constraints?**
   - Limited memory: `AdjacencyList` or `LazyGraph`
   - Plentiful memory: `AdjacencyMatrix` for simplicity

### Common Scenarios

| Scenario | Recommended |
|----------|-------------|
| Social network | `AdjacencyList` |
| Complete graph | `AdjacencyMatrix` |
| Game map | `GridGraph` |
| Job matching | `BipartiteAdjacencyList` |
| Web crawler | `LazyGraph` |
| Road network | `AdjacencyList` |
| Small state machine | `AdjacencyMatrix` |
| Search space | `LazyGraph` |

### Default Recommendation

**When in doubt, use `AdjacencyList`:**
- Works well for most graphs in practice
- Efficient memory usage
- Good performance across operations
- Supports all features

## Performance Tuning

### For `AdjacencyList`

```swift
// Use bidirectional storage for reverse traversal
let graph = AdjacencyList(
    edgeStore: OrderedEdgeStorage().cacheInOutEdges()
)

// Note: Different storage backends offer different performance characteristics
// - Basic OrderedEdgeStorage: O(degree) edge lookups
// - With caching/hashing: Can achieve better edge lookup performance
// - CacheInOutEdges: Optimizes bidirectional access at cost of extra memory
```

### For `AdjacencyMatrix`

```swift
// Pre-size if you know vertex count
var graph = AdjacencyMatrix(reservingCapacity: 1000)
```

### For `LazyGraph`

```swift
// Cache computed edges if they're expensive
class CachedLazyGraph {
    var cache: [Vertex: [Vertex]] = [:]
    
    func neighbors(of v: Vertex) -> [Vertex] {
        if let cached = cache[v] {
            return cached
        }
        let computed = expensiveComputation(v)
        cache[v] = computed
        return computed
    }
}
```

## Next Steps

Now that you've chosen a graph type:

- Learn about <doc:GraphConcepts> - Understanding graph terminology
- Explore <doc:PropertiesAndPropertyMaps> - Adding data to graphs
- Study algorithm documentation - Running algorithms on your graph

## See Also

- <doc:GraphConcepts>
- <doc:Architecture>
- <doc:PropertiesAndPropertyMaps>
- ``AdjacencyList``
- ``AdjacencyMatrix``
- ``GridGraph``

