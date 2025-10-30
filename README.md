# Swift Graphs

[![Swift Package Index](https://img.shields.io/endpoint?url=https://swiftpackageindex.com/api/packages/tevelee/swift-graphs/badge?type=swift-versions)](https://swiftpackageindex.com/tevelee/swift-graphs)
[![Swift Package Index](https://img.shields.io/endpoint?url=https://swiftpackageindex.com/api/packages/tevelee/swift-graphs/badge?type=platforms)](https://swiftpackageindex.com/tevelee/swift-graphs)
[![License](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE.txt)

A comprehensive, high-performance graph algorithms library for Swift, inspired by the [Boost Graph Library](https://www.boost.org/doc/libs/1_89_0/libs/graph/doc/table_of_contents.html). Built on protocol-oriented design for maximum flexibility, type safety, and performance across all Swift platforms.

📖 **[Full Documentation](https://swiftpackageindex.com/tevelee/swift-graphs/0.4.0/documentation/graphs)**

## Quick Start

```swift
import Graphs

// Create a graph
var graph = AdjacencyList()
graph.add(edges: [
    ("s", "a", 3.0),
    ("s", "b", 5.0),
    ("a", "c", 2.0),
    ("b", "c", 1.0),
    ("c", "d", 4.0)
])

// Find shortest path
let path = graph.shortestPath(from: "s", to: "d", using: .dijkstra())
print(path?.vertices) // ["s", "b", "c", "d"]

// Traverse the graph
let dfs = graph.traverse(from: "s", using: .dfs())
print(dfs.vertices) // ["s", "a", "c", "d", "b"]

// Grid pathfinding with A*
let grid = GridGraph(width: 10, height: 10)
let path = grid.shortestPath(
    from: .init(x: 0, y: 0),
    to: .init(x: 9, y: 9),
    using: .aStar(heuristic: .manhattanDistance)
)
```

## API Showcase

Build a city transportation network and explore all available algorithms:

```swift
import Graphs

// Create a transportation network
var cityNetwork = AdjacencyList()

// Add cities as vertices with population data
let sanFrancisco = cityNetwork.addVertex { $0.name = "San Francisco"; $0.population = 815201 }
let losAngeles = cityNetwork.addVertex { $0.name = "Los Angeles"; $0.population = 3820914 }
let sanDiego = cityNetwork.addVertex { $0.name = "San Diego"; $0.population = 1381611 }
let lasVegas = cityNetwork.addVertex { $0.name = "Las Vegas"; $0.population = 641903 }
let phoenix = cityNetwork.addVertex { $0.name = "Phoenix"; $0.population = 1608139 }
let denver = cityNetwork.addVertex { $0.name = "Denver"; $0.population = 715522 }

// Add routes with distances (in miles)
cityNetwork.addEdge(from: sanFrancisco, to: losAngeles) { $0.weight = 380.0 }
cityNetwork.addEdge(from: losAngeles, to: sanDiego) { $0.weight = 120.0 }
cityNetwork.addEdge(from: losAngeles, to: lasVegas) { $0.weight = 270.0 }
cityNetwork.addEdge(from: lasVegas, to: phoenix) { $0.weight = 300.0 }
cityNetwork.addEdge(from: phoenix, to: denver) { $0.weight = 600.0 }
cityNetwork.addEdge(from: sanFrancisco, to: lasVegas) { $0.weight = 570.0 }
cityNetwork.addEdge(from: sanDiego, to: phoenix) { $0.weight = 355.0 }

// Graph Traversal - explores vertices in different orders
cityNetwork.traverse(from: sanFrancisco)
cityNetwork.traverse(from: sanFrancisco, using: .bfs())
cityNetwork.traverse(from: sanFrancisco, using: .dfs())
cityNetwork.traverse(from: sanFrancisco, using: .dfs(order: .preorder))
cityNetwork.traverse(from: sanFrancisco, using: .dfs(order: .postorder))
cityNetwork.traverse(from: sanFrancisco, using: .bestFirst(heuristic: { _ in 0 }))
cityNetwork.traverse(from: sanFrancisco, using: .depthLimitedDFS(maxDepth: 3))
cityNetwork.traverse(from: sanFrancisco, using: .iterativelyDeepeningDFS(maxDepth: 5))

// Search - lazy sequence iteration for on-demand exploration
cityNetwork.search(from: sanFrancisco)
cityNetwork.search(from: sanFrancisco, using: .dfs())
cityNetwork.search(from: sanFrancisco, using: .bfs())

// Shortest Paths - find optimal routes between cities
cityNetwork.shortestPath(from: sanFrancisco, to: denver, using: .dijkstra(weight: .property(\.weight)))
cityNetwork.shortestPath(from: sanFrancisco, to: denver, using: .aStar(weight: .property(\.weight), heuristic: { _, _ in 0 }))
cityNetwork.shortestPath(from: sanFrancisco, to: denver, using: .bellmanFord(weight: .property(\.weight)))
cityNetwork.shortestPath(from: sanFrancisco, to: denver, using: .bidirectionalDijkstra(weight: .property(\.weight)))

// K Shortest Paths - find multiple alternative routes
cityNetwork.kShortestPaths(from: sanFrancisco, to: denver, k: 3, using: .yen(weight: .property(\.weight)))

// All-Pairs Shortest Paths - distances between all city pairs
cityNetwork.shortestPathsForAllPairs(using: .floydWarshall(weight: .property(\.weight)))
cityNetwork.shortestPathsForAllPairs(using: .johnson(edgeWeight: .property(\.weight)))

// Minimum Spanning Tree - minimum cost to connect all cities
cityNetwork.minimumSpanningTree(using: .kruskal(weight: .property(\.weight)))
cityNetwork.minimumSpanningTree(using: .prim(weight: .property(\.weight)))
cityNetwork.minimumSpanningTree(using: .boruvka(weight: .property(\.weight)))

// Maximum Flow - capacity/throughput analysis
cityNetwork.maximumFlow(from: sanFrancisco, to: denver, using: .fordFulkerson(capacityCost: .property(\.weight)))
cityNetwork.maximumFlow(from: sanFrancisco, to: denver, using: .edmondsKarp(capacityCost: .property(\.weight)))
cityNetwork.maximumFlow(from: sanFrancisco, to: denver, using: .dinic(capacityCost: .property(\.weight)))

// Connectivity & Components - analyze network structure
cityNetwork.connectedComponents()
cityNetwork.connectedComponents(using: .dfs())
cityNetwork.connectedComponents(using: .unionFind())
cityNetwork.stronglyConnectedComponents()
cityNetwork.stronglyConnectedComponents(using: .kosaraju())
cityNetwork.stronglyConnectedComponents(using: .tarjan())

// Graph Coloring - assign colors to vertices with no adjacent same colors
cityNetwork.colorGraph()
cityNetwork.colorGraph(using: .greedy())
cityNetwork.colorGraph(using: .dsatur())
cityNetwork.colorGraph(using: .welshPowell())

// Topological Sort - order vertices respecting dependencies (DAGs)
cityNetwork.topologicalSort()
cityNetwork.topologicalSort(using: .dfs())
cityNetwork.topologicalSort(using: .kahn())

// Graph Properties - test structural characteristics
cityNetwork.isCyclic()
cityNetwork.isTree()
cityNetwork.isConnected()
cityNetwork.isBipartite()

// Eulerian Paths & Cycles - paths visiting every edge exactly once
cityNetwork.hasEulerianPath()
cityNetwork.hasEulerianCycle()
cityNetwork.eulerianPath()
cityNetwork.eulerianPath(using: .hierholzer())
cityNetwork.eulerianCycle()
cityNetwork.eulerianCycle(using: .hierholzer())

// Hamiltonian Paths & Cycles - paths visiting every vertex exactly once
cityNetwork.hamiltonianPath()
cityNetwork.hamiltonianPath(using: .backtracking())
cityNetwork.hamiltonianPath(using: .heuristic())
cityNetwork.hamiltonianPath(from: sanFrancisco)
cityNetwork.hamiltonianPath(from: sanFrancisco, to: denver)
cityNetwork.hamiltonianCycle()
cityNetwork.hamiltonianCycle(using: .backtracking())
cityNetwork.hamiltonianCycle(using: .heuristic())

// Clique Detection - find groups of fully connected vertices
cityNetwork.findCliques()
cityNetwork.findCliques(using: .bronKerbosch())

// Community Detection - identify clusters/groups in the network
cityNetwork.detectCommunities()
cityNetwork.detectCommunities(using: .louvain())

// Graph Isomorphism - check if two graphs have the same structure
var anotherNetwork = AdjacencyList()
// ... build another network
cityNetwork.isIsomorphic(to: anotherNetwork)
cityNetwork.isIsomorphic(to: anotherNetwork, using: .vf2())
cityNetwork.isIsomorphic(to: anotherNetwork, using: .weisfeilerLehman())

// Random Graph Generation - create synthetic networks
let randomNetwork = AdjacencyList.randomGraph(vertexCount: 50, using: .erdosRenyi(edgeProbability: 0.1))
let scaleFreeNetwork = AdjacencyList.randomGraph(vertexCount: 50, using: .barabasiAlbert(edgesPerVertex: 3))
let smallWorldNetwork = AdjacencyList.randomGraph(vertexCount: 50, using: .wattsStrogatz(neighbors: 4, rewiringProbability: 0.1))
```

## Installation

Add to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/tevelee/swift-graphs.git", from: "0.4.0")
]
```

## Features

### 🏗️ Flexible Graph Types
- **AdjacencyList** - Sparse graphs (most common)
- **AdjacencyMatrix** - Dense graphs, O(1) edge lookup
- **GridGraph** - 2D pathfinding and spatial algorithms
- **LazyIncidenceGraph** - Computed on-demand for large graphs
- **BipartiteAdjacencyList** - Two-colored graphs

### 🚀 Comprehensive Algorithms

**Shortest Paths** - Dijkstra, Bidirectional Dijkstra, A*, Bellman-Ford, Floyd-Warshall, Johnson, Yen (K-shortest)

**Traversal & Search** - DFS (preorder/postorder), BFS, Best-First, Depth-Limited DFS, Iterative Deepening DFS

**Connectivity** - Connected Components (DFS, Union-Find), Strongly Connected Components (Tarjan, Kosaraju)

**Graph Properties** - Tree Detection, Cycle Detection, Bipartiteness, Connectivity, Eulerian Paths/Cycles, Hamiltonian Paths/Cycles (Backtracking, Heuristic)

**Optimization** - Minimum Spanning Tree (Kruskal, Prim, Borůvka), Maximum Flow (Ford-Fulkerson, Edmonds-Karp, Dinic), Graph Coloring (Greedy, DSatur, Welsh-Powell, Sequential), Matching (Hopcroft-Karp), Topological Sort (DFS, Kahn)

**Advanced** - Graph Isomorphism (VF2, Weisfeiler-Lehman), Clique Detection (Bron-Kerbosch), Community Detection (Louvain), Random Graphs (Erdős-Rényi, Barabási-Albert, Watts-Strogatz)

## Design Philosophy

Swift Graphs follows a **protocol-oriented architecture** inspired by the Boost Graph Library:

- **Pluggable Components** - Mix and match storage backends, property systems, and algorithms
- **Type Safety** - Compile-time constraints ensure correctness
- **Performance** - Zero-cost abstractions and optimized implementations
- **Extensibility** - Add custom graphs and algorithms without modifying existing code

### Protocol Hierarchy

Swift Graphs uses fine-grained protocols that compose together:

**Core Protocols:**
```
Graph (base: VertexDescriptor, EdgeDescriptor)
├── IncidenceGraph (outgoing edges, source/destination)
│   ├── BidirectionalGraph (+ incoming edges)
│   └── BinaryIncidenceGraph (left/right children for trees)
├── VertexListGraph (iterate all vertices)
├── EdgeListGraph (iterate all edges)
├── AdjacencyGraph (direct neighbor access)
└── EdgeLookupGraph (O(1) edge existence check)
```

**Mutability Protocols:**
```
Graph
├── VertexMutableGraph (add/remove vertices)
├── EdgeMutableGraph (add/remove edges)
└── MutableGraph (both vertices and edges)
    └── MutableBinaryIncidenceGraph (binary tree mutation)
```

**Property Protocols:**
```
Graph
├── VertexPropertyGraph (vertex data)
├── EdgePropertyGraph (edge data)
└── PropertyGraph (both)
    ├── VertexMutablePropertyGraph (mutable vertex properties)
    ├── EdgeMutablePropertyGraph (mutable edge properties)
    └── MutablePropertyGraph (fully mutable)
```

**Specialized Protocols:**
```
Graph
├── BipartiteGraph (two-colored graphs)
│   └── MutableBipartiteGraph (+ mutation)
└── Storage-backed (internal implementation helpers)
```

Algorithms work with any graph implementing the required protocols:

```swift
extension IncidenceGraph where Self: VertexListGraph, VertexDescriptor: Hashable {
    func shortestPath<Weight: AdditiveArithmetic & Comparable>(
        from source: VertexDescriptor,
        to destination: VertexDescriptor,
        using algorithm: some ShortestPathAlgorithm<Self, Weight>
    ) -> Path<VertexDescriptor, EdgeDescriptor>? {
        // Works with ANY compatible graph
    }
}
```

## Advanced Examples

### Custom Properties

Adding custom properties is straightforward with the type-safe property system:

```swift
// Define custom property types
enum Population: VertexProperty {
    static let defaultValue = 0
}

enum IsCapital: VertexProperty {
    static let defaultValue = false
}

enum Distance: EdgeProperty {
    static let defaultValue = 0.0
}

// Extend property containers for convenient access
extension VertexPropertyValues {
    var population: Int {
        get { self[Population.self] }
        set { self[Population.self] = newValue }
    }
    
    var isCapital: Bool {
        get { self[IsCapital.self] }
        set { self[IsCapital.self] = newValue }
    }
}

extension EdgePropertyValues {
    var distance: Double {
        get { self[Distance.self] }
        set { self[Distance.self] = newValue }
    }
}

// Use your custom properties
var cities = AdjacencyList()
let sanFrancisco = cities.addVertex {
    $0.population = 815201
    $0.isCapital = false
}
let sacramento = cities.addVertex {
    $0.population = 524943
    $0.isCapital = true
}

cities.addEdge(from: sanFrancisco, to: sacramento) {
    $0.distance = 87.0
}

// Query using custom properties
let capitals = cities.vertices().filter { cities[$0].isCapital }
let largeCities = cities.vertices().filter { cities[$0].population > 500000 }
```

## Documentation

📖 **[Full API Documentation](https://swiftpackageindex.com/tevelee/swift-graphs/0.4.0/documentation/graphs)**

- [Getting Started Guide](https://swiftpackageindex.com/tevelee/swift-graphs/0.4.0/documentation/graphs/gettingstarted)
- [Algorithms Catalog](https://swiftpackageindex.com/tevelee/swift-graphs/0.4.0/documentation/graphs/algorithmscatalog)
- [Core Concepts](https://swiftpackageindex.com/tevelee/swift-graphs/0.4.0/documentation/graphs)

## Contributing

Contributions are welcome!

### Development

```bash
# Clone and test
git clone https://github.com/tevelee/swift-graphs.git
cd swift-graphs
swift test
```

## License

MIT License - see [LICENSE](LICENSE.txt) file for details.

## Acknowledgments

- Inspired by the [Boost Graph Library](https://www.boost.org/doc/libs/1_82_0/libs/graph/doc/)
- Built with [Swift Collections](https://github.com/apple/swift-collections) and [Swift Algorithms](https://github.com/apple/swift-algorithms)

---

**Made with ❤️ for the Swift community**
