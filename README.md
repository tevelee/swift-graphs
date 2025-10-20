# Swift Graphs

[![Swift](https://img.shields.io/badge/Swift-6.0-orange.svg)](https://swift.org)
[![Platform](https://img.shields.io/badge/Platform-iOS%20%7C%20macOS%20%7C%20watchOS%20%7C%20tvOS%20%7C%20visionOS-lightgrey.svg)](https://swift.org)
[![License](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE.txt)

A comprehensive, high-performance graph algorithms library for Swift, inspired by the Boost Graph Library. Swift Graphs provides flexible graph representations with a small core API and extensive algorithm coverage, designed for maximum performance and type safety. The library is platform-independent and runs on all Swift-supported platforms including iOS, macOS, watchOS, tvOS, and visionOS.

## 🔌 **Pluggable Architecture**

Swift Graphs is built around a powerful plugin architecture where **storage backends**, **property systems**, and **algorithms** are completely pluggable and interchangeable. This design allows you to:

- **Mix and match storage strategies** - Use adjacency lists for sparse graphs, matrices for dense graphs, or custom storage backends
- **Extend property systems** - Add custom vertex/edge properties or use computed properties
- **Swap algorithms** - Choose the best algorithm for your specific use case or implement custom ones
- **Compose graph types** - Combine different capabilities to create specialized graph implementations

## ✨ Features

### 🏗️ **Flexible Graph Representations**
- **Adjacency List** - Optimized for sparse graphs with efficient neighbor access
- **Adjacency Matrix** - Perfect for dense graphs with O(1) edge lookups
- **Grid Graph** - Specialized for 2D pathfinding and spatial algorithms
- **Lazy Graph** - Compute edges on-demand for memory-efficient large graphs
- **Binary Graph** - Specialized for tree structures with left/right child navigation

### 🚀 **Comprehensive Algorithm Suite**

#### **Pathfinding & Shortest Paths**
- **Dijkstra's Algorithm** - Single-source shortest paths with non-negative weights
- **A\* Search** - Heuristic-based pathfinding with customizable distance functions
- **Bellman-Ford** - Handles negative edge weights and detects negative cycles
- **Floyd-Warshall** - All-pairs shortest paths
- **Johnson's Algorithm** - All-pairs shortest paths with negative weights
- **Yen's Algorithm** - K shortest paths between two vertices

#### **Graph Traversal**
- **Depth-First Search (DFS)** - With preorder, postorder, and inorder variants
- **Breadth-First Search (BFS)** - Level-by-level exploration
- **Best-First Search** - Heuristic-guided traversal
- **Iterative Deepening DFS** - Memory-efficient depth-limited search
- **Uniform Cost Search** - Weighted graph traversal

#### **Graph Properties & Analysis**
- **Connectivity** - Connected components, strongly connected components
- **Cycle Detection** - Detect cycles and determine if graph is acyclic
- **Tree Properties** - Check if graph is a tree, forest, or has specific tree properties
- **Planarity** - Boyer-Myrvold planarity testing
- **Bipartiteness** - Detect and analyze bipartite graphs
- **Eulerian Paths** - Find Eulerian cycles and paths
- **Hamiltonian Paths** - Find Hamiltonian cycles and paths

#### **Optimization Algorithms**
- **Minimum Spanning Tree** - Kruskal's, Prim's, and Borůvka's algorithms
- **Maximum Flow** - Ford-Fulkerson, Edmonds-Karp, and Dinic's algorithms
- **Graph Coloring** - Greedy, DSatur, and Welsh-Powell algorithms
- **Topological Sort** - Kahn's algorithm for DAG ordering

#### **Advanced Algorithms**
- **Graph Isomorphism** - VF2 and Weisfeiler-Lehman algorithms
- **Random Graph Generation** - Erdős-Rényi, Barabási-Albert, Watts-Strogatz models
- **Vertex Ordering** - Various ordering strategies for graph algorithms

#### **Clique & Community Detection**
- **Clique Detection** - Bron-Kerbosch algorithm for finding maximal cliques
- **Community Detection** - Louvain algorithm for modularity optimization

### 🎯 **Key Design Principles**

- **Type Safety** - Compile-time constraints ensure algorithms only work with compatible graphs
- **Performance** - Optimized implementations with minimal overhead
- **Extensibility** - Plugin architecture for custom algorithms and graph types
- **Memory Efficiency** - Lazy evaluation and efficient storage backends
- **Platform Independence** - Runs seamlessly across all Swift-supported platforms
- **Swift Integration** - Leverages Swift's type system and modern language features

## 🧬 Core Philosophy: Protocol-Oriented Graph Programming

Swift Graphs is built on the proven design principles of the [Boost Graph Library (BGL)](https://www.boost.org/doc/libs/1_89_0/libs/graph/doc/table_of_contents.html), translated into Swift's protocol-oriented paradigm. This approach provides unmatched flexibility, type safety, and performance.

### **Graph Concepts as Protocols**

Following BGL's concept-based design, Swift Graphs models graph capabilities as protocols:

- **Each protocol represents a specific capability** - `IncidenceGraph` for neighbor access, `BidirectionalGraph` for reverse traversal
- **Graphs implement only what they support** - Not all graphs need all features
- **Algorithms are generic over protocol requirements** - Write once, work with any compatible graph
- **Compile-time safety** - Type system ensures correctness before runtime

### **Protocol Hierarchy**

```
Graph (base: VertexDescriptor, EdgeDescriptor)
├── IncidenceGraph (outgoing edges access)
│   └── BidirectionalGraph (+ incoming edges access)
├── VertexListGraph (iterate all vertices)
├── EdgeListGraph (iterate all edges)
├── AdjacencyGraph (direct vertex adjacency)
├── MutableGraph (add/remove vertices/edges)
│   ├── VertexMutableGraph (add/remove vertices)
│   └── EdgeMutableGraph (add/remove edges)
└── PropertyGraph (vertex/edge properties)
    ├── VertexPropertyGraph (vertex data)
    ├── EdgePropertyGraph (edge data)
    └── MutablePropertyGraph (mutable properties)
```

### **The BGL Heritage**

The Boost Graph Library pioneered generic graph programming in C++, introducing concepts like:

- **Separation of graph structure from algorithms** - Algorithms work with any graph that meets requirements
- **Minimal interface requirements** - Each algorithm specifies exactly what it needs
- **Visitor pattern for instrumentation** - Observe and customize algorithm behavior
- **Property maps for external data** - Separate topology from attributes

Swift Graphs brings these proven patterns to Swift, enhanced with:

- **Protocol-oriented design** - Swift's protocols provide cleaner syntax than C++ concepts
- **Type safety** - Protocol constraints catch errors at compile time
- **Value semantics** - Safer concurrent access and easier reasoning
- **Modern language features** - Generics, associated types, and protocol extensions

### **Design Pattern: Small Core, Rich Extensions**

```swift
// Core protocols are minimal
protocol Graph {
    associatedtype VertexDescriptor
    associatedtype EdgeDescriptor
}

// Capabilities added through refinement
protocol IncidenceGraph: Graph {
    func outgoingEdges(of: VertexDescriptor) -> some Sequence<EdgeDescriptor>
    func destination(of: EdgeDescriptor) -> VertexDescriptor?
}

// Algorithms work with protocol requirements
extension IncidenceGraph where VertexDescriptor: Hashable {
    func traverse(from source: VertexDescriptor, using algorithm: some TraversalAlgorithm) {
        // Works with ANY IncidenceGraph
    }
}
```

This design means:
- **Flexibility** - Implement only what you need
- **Reusability** - Algorithms work across graph types
- **Extensibility** - Add new graphs or algorithms without modifying existing code
- **Type Safety** - Compiler enforces correctness

## 🚀 Quick Start

### Installation

Add Swift Graphs to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/tevelee/swift-graphs.git", from: "1.0.0")
]
```

### Basic Usage

```swift
import Graphs

// Create a simple graph
var graph = AdjacencyList()
graph.add(edges: [
    ("s", "a"),
    ("s", "b"),
    ("a", "c"),
    ("b", "d"),
])

// Find shortest path
let path = graph.shortestPath(from: "s", to: "c", using: .dijkstra())
print("Shortest path: \(path?.vertices)")
// Output: Shortest path: ["s", "a", "c"]
```

### Graph Traversal

```swift
// Depth-first search
let dfsResult = graph.traverse(from: "s", using: .dfs())
print("DFS vertices: \(dfsResult.vertices)")

// Breadth-first search
let bfsResult = graph.traverse(from: "s", using: .bfs())
print("BFS vertices: \(bfsResult.vertices)")
```

### Grid Graph Pathfinding

```swift
// Create a 10x10 grid
let grid = GridGraph(width: 10, height: 10)

// Find path using A* with Manhattan distance
let start = GridGraph.Vertex(x: 0, y: 0)
let goal = GridGraph.Vertex(x: 9, y: 9)

let path = grid.shortestPath(
    from: start, 
    to: goal, 
    using: .aStar(heuristic: .manhattanDistance)
)
```

## 📚 Advanced Examples

### Custom Graph Properties

One of the most powerful features is the ability to add custom properties to graphs. Here's how I can extend graphs with domain-specific properties:

```swift
// Define a custom property for social network analysis
struct SocialMetrics: GraphProperty {
    var influenceScore: Double
    var communityId: Int
    var isInfluencer: Bool { influenceScore > 0.8 }
}

// Create a graph with custom properties
var socialGraph = AdjacencyList()

// Add vertices with social metrics
let alice = socialGraph.addVertex { $0.influenceScore = 0.9; $0.communityId = 1 }
let bob = socialGraph.addVertex { $0.influenceScore = 0.3; $0.communityId = 1 }
let charlie = socialGraph.addVertex { $0.influenceScore = 0.7; $0.communityId = 2 }

// Add weighted connections
socialGraph.addEdge(from: alice, to: bob) { $0.weight = 0.8 }
socialGraph.addEdge(from: alice, to: charlie) { $0.weight = 0.6 }

// Query using custom properties
let influencers = socialGraph.vertices.filter { socialGraph[$0].isInfluencer }
print("Influencers: \(influencers.map { socialGraph[$0].influenceScore })")
```

### Pluggable Storage Backends

I can easily swap storage backends based on graph characteristics:

```swift
// For sparse graphs - use adjacency list
var sparseGraph = AdjacencyList()
sparseGraph.add(edges: [("a", "b"), ("b", "c")])

// For dense graphs - use adjacency matrix
var denseGraph = AdjacencyMatrix()
denseGraph.add(edges: [
    ("a", "b", 5), ("a", "c", 3), ("a", "d", 8),
    ("b", "c", 2), ("b", "d", 4), ("c", "d", 1)
])

// For memory-constrained scenarios - use lazy evaluation
let lazyGraph = LazyGraph { vertex in
    // Compute neighbors on-demand
    return computeNeighbors(for: vertex)
}
```

### Custom Algorithm Implementation

I can implement custom algorithms that leverage the pluggable architecture:

```swift
// Custom algorithm for finding influential nodes
struct InfluenceRanking<Node, Edge>: GraphAlgorithm {
    func findInfluencers(in graph: some GraphComponent<Node, Edge>) -> [Node] {
        // Custom implementation using graph properties
        return graph.vertices
            .sorted { 
                graph[$0].influenceScore > graph[$1].influenceScore 
            }
    }
}

// Use the custom algorithm
let ranking = InfluenceRanking()
let topInfluencers = ranking.findInfluencers(in: socialGraph)
```

### Graph Coloring with Different Strategies

```swift
// Create a complex graph
var graph = AdjacencyList()
graph.add(edges: [
    ("a", "b"), ("a", "c"), ("b", "d"), ("c", "d"), 
    ("d", "e"), ("e", "f"), ("f", "a")
])

// Try different coloring algorithms
let greedyColoring = graph.colorGraph(using: .greedy())
let dsaturColoring = graph.colorGraph(using: .dsatur())
let welshPowellColoring = graph.colorGraph(using: .welshPowell())

print("Greedy colors needed: \(greedyColoring.chromaticNumber)")
print("DSatur colors needed: \(dsaturColoring.chromaticNumber)")
print("Welsh-Powell colors needed: \(welshPowellColoring.chromaticNumber)")
```

### Minimum Spanning Tree with Different Algorithms

```swift
// Create a weighted graph
var weightedGraph = AdjacencyList()
weightedGraph.add(edges: [
    ("a", "b", 4.0), ("a", "c", 2.0), ("b", "c", 1.0),
    ("b", "d", 5.0), ("c", "d", 8.0), ("c", "e", 10.0),
    ("d", "e", 2.0), ("d", "f", 6.0), ("e", "f", 3.0)
])

// Compare different MST algorithms
let kruskalMST = weightedGraph.minimumSpanningTree(using: .kruskal())
let primMST = weightedGraph.minimumSpanningTree(using: .prim())
let boruvkaMST = weightedGraph.minimumSpanningTree(using: .boruvka())

print("Kruskal MST weight: \(kruskalMST.totalWeight)")
print("Prim MST weight: \(primMST.totalWeight)")
print("Borůvka MST weight: \(boruvkaMST.totalWeight)")
```

### Random Graph Generation

```swift
// Generate different types of random graphs
let erdosRenyi = ConnectedGraph.random(
    vertices: 100, 
    using: .erdosRenyi(edgeProbability: 0.1)
)

let barabasiAlbert = ConnectedGraph.random(
    vertices: 100,
    using: .barabasiAlbert(edgesPerVertex: 3)
)

let wattsStrogatz = ConnectedGraph.random(
    vertices: 100,
    using: .wattsStrogatz(neighbors: 4, rewiringProbability: 0.1)
)

// Analyze properties of generated graphs
print("ER graph is connected: \(erdosRenyi.isConnected)")
print("BA graph clustering: \(barabasiAlbert.clusteringCoefficient)")
print("WS graph small world: \(wattsStrogatz.hasSmallWorldProperty)")
```

## 🏗️ Architecture

Swift Graphs follows a **modular architecture** with clear separation of concerns between definitions and implementations:

### **Graph Definitions** (Protocols)

Core protocols defining graph capabilities:
- `Graph` - Base protocol with vertex and edge descriptors
- `IncidenceGraph` - Access to outgoing edges
- `BidirectionalGraph` - Access to incoming edges
- `VertexListGraph` / `EdgeListGraph` - Enumeration capabilities
- `PropertyGraph` - Vertex and edge properties
- `MutableGraph` - Dynamic modification

### **Graph Implementations** (Concrete Types)

Concrete data structures implementing protocols:
- `AdjacencyList` - Sparse graphs (most common)
- `AdjacencyMatrix` - Dense graphs, O(1) edge lookup
- `BipartiteAdjacencyList` - Two-colored graphs
- `GridGraph` - 2D spatial graphs
- `LazyGraph` - Computed on-demand

### **Algorithm Definitions** (Algorithm Protocols)

Algorithm families as protocols:
- `ShortestPathAlgorithm` - Pathfinding strategies
- `TraversalAlgorithm` - Graph exploration
- `ColoringAlgorithm` - Vertex coloring
- `ConnectedComponentsAlgorithm` - Component detection
- `MinimumSpanningTreeAlgorithm` - MST strategies

### **Algorithm Implementations** (Concrete Algorithms)

Specific algorithm implementations:
- Dijkstra, A*, Bellman-Ford (shortest paths)
- DFS, BFS (traversal)
- Greedy, DSatur (coloring)
- Kruskal, Prim (MST)

### **Cross-Cutting Concerns**

**Storage Backends** (Pluggable):
- `VertexStorage` - How vertices are stored
- `EdgeStorage` - How edges are stored
- Swap implementations without changing algorithms

**Property Systems** (Pluggable):
- `PropertyMap` - Associates data with vertices/edges
- `DictionaryPropertyMap` - Hash-based storage
- `ComputedPropertyGraph` - On-demand computation

### **Protocol-Based Design Example**

The library uses Swift's protocol system to provide compile-time safety:

```swift
// Algorithm requires specific graph capabilities
extension IncidenceGraph where Self: VertexListGraph, VertexDescriptor: Hashable {
    func shortestPath<Weight: Numeric & Comparable>(
        from source: VertexDescriptor,
        to destination: VertexDescriptor,
        using algorithm: some ShortestPathAlgorithm<Self, Weight>
    ) -> Path<VertexDescriptor, EdgeDescriptor>?
}

// Usage - type system ensures correctness
let path = graph.shortestPath(
    from: start,
    to: goal,
    using: .dijkstra(weight: .property(\.weight))  // Choose algorithm at call site
)
```

This architecture enables:
- **Separation of concerns** - Structure, data, and algorithms are independent
- **Pluggability** - Swap components without breaking code
- **Type safety** - Compiler catches incompatibilities
- **Extensibility** - Add new components without modifying existing ones

## 📊 Performance

Swift Graphs is designed for high performance:

- **Zero-cost abstractions** where possible
- **Efficient memory usage** with specialized storage backends
- **Optimized algorithms** with careful attention to complexity
- **Lazy evaluation** for memory-efficient large graph processing

## 🤝 Contributing

I welcome contributions! Please see my [Contributing Guidelines](CONTRIBUTING.md) for details.

### Development Setup

1. Clone the repository
2. Open in Xcode or use Swift Package Manager
3. Run tests: `swift test`
4. Format code: `swift format`

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE.txt) file for details.

## 🙏 Acknowledgments

- Inspired by the [Boost Graph Library](https://www.boost.org/doc/libs/1_82_0/libs/graph/doc/)
- Built with [Swift Collections](https://github.com/apple/swift-collections) and [Swift Algorithms](https://github.com/apple/swift-algorithms)
- Community feedback and contributions

<!-- ## 📖 Documentation

- [API Reference](https://tevelee.github.io/swift-graphs/)
- [Algorithm Guide](docs/algorithms.md)
- [Performance Guide](docs/performance.md)
- [Examples](Examples/)
-->

---

**Made with ❤️ for the Swift community**

