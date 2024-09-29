# Graph Library for Swift

## Overview

This Swift library provides a composable and extensible foundation for working with graphs. 
Whether you're constructing binary trees, performing complex graph traversals, or optimizing pathfinding algorithms on weighted graphs, this library offers the dynamic flexibility needed for a wide range of graph-related use cases. 

While some features are still in early development stages, the project is actively evolving, and contributions are highly encouraged.

## Key Features

- **Multiple Graph Types**: Supports general graphs, binary graphs, grid graphs, and lazy graphs (on-demand edge computation).
- **Weighted Graphs**: Handles graphs with weighted edges, enabling specialized algorithms like shortest pathfinding.
- **Traversals**: Breadth-First Search (BFS), Depth-First Search (DFS), with support for preorder, inorder, and postorder traversals.
- **Traversal Strategies**: Includes unique node visiting, and depth, path, and cost tracking during traversals.
- **Shortest Path Algorithms**: Dijkstra, Bellman-Ford, and A* algorithms for finding efficient routes.
- **Eulerian and Hamiltonian Paths/Cycles**: Support for backtracking, heuristic-based, and Hierholzer's algorithm for Eulerian paths.
- **Max Flow/Min Cut Algorithms**: Ford-Fulkerson, Edmonds-Karp, and Dinic's algorithms for network flow analysis.
- **Minimum Spanning Tree Algorithms**: Kruskal's, Prim's, and Borůvka's algorithms for constructing minimum spanning trees.
- **Strongly Connected Components**: Kosaraju’s and Tarjan’s algorithms for identifying strongly connected components.
- **Graph Coloring**: Greedy algorithm for efficient node coloring.
- **Isomorphism**: Determine if two graphs are isomorphic using VF2 or Weisfeiler-Lehman algorithm
- **Maximum Bipartite Matching**: Hopcroft-Karp algorithm for bipartite matching.

### Example Usage

```swift
let graph = Graph(edges: [
    "Root": ["A", "B", "C"],
    "B": ["X", "Y", "Z"]
])

graph.traverse(from: "Root", strategy: .bfs())
graph.traverse(from: "Root", strategy: .dfs())

graph.traverse(from: "Root", strategy: .bfs(.trackPath()))
graph.traverse(from: "Root", strategy: .dfs(order: .postorder()))
graph.traverse(from: "Root", strategy: .dfs().visitEachNodeOnce())

graph.shortestPath(from: "Root", to: "Z", using: .dijkstra()) // or .aStar() or .bellmanFord()
graph.shortestPaths(from: "Root", using: .dijkstra()) // or .bellmanFord()
graph.shortestPathsForAllPairs(using: .floydWarshall()) // or .johnson()
graph.minimumSpanningTree(using: .kruskal()) // or .prim() or .boruvka()
graph.maximumFlow(using: .fordFulkerson()) // or .edmondsKarp() or .dinic()
graph.stronglyConnectedComponents(using: .kosaraju()) // or .tarjan()
graph.colorNodes(using: .greedy()) // or .dsatur() or .welshPowell()
graph.isIsomorphoc(to: graph2, using: .vf2()) // or .weisfeilerLehman()

graph.isCyclic()
graph.isTree()
graph.isConnected()
graph.isPlanar()
graph.isBipartite()
graph.topologicalSort()

let lazyGraph = LazyGraph { node in
    dynamicNeighbors(of: node)
}

let gridGraph = GridGraph(grid: [
    ["A", "B", "C", "D", "E"],
    ["F", "G", "H", "I", "J"],
    ["K", "L", "M", "N", "O"],
    ["P", "Q", "R", "S", "T"],
    ["U", "V", "W", "X", "Y"]
], availableDirections: .orthogonal).weightedByDistance()

gridGraph.shortestPath(from: GridPosition(x: 0, y: 0), to: GridPosition(x: 4, y: 4), using: .aStar(heuristic: .euclideanDistance(of: \.coordinates)))
gridGraph.shortestPaths(from: GridPosition(x: 0, y: 0))
gridGraph.shortestPathsForAllPairs()

gridGraph.eulerianCycle()
gridGraph.eulerianPath()

gridGraph.hamiltonianCycle()
gridGraph.hamiltonianPath()
gridGraph.hamiltonianPath(from: GridPosition(x: 0, y: 0))
gridGraph.hamiltonianPath(from: GridPosition(x: 0, y: 0), to: GridPosition(x: 4, y: 4))

let binaryGraph = BinaryGraph(edges: [
    "Root": (lhs: "A", rhs: "B"),
    "A": (lhs: "X", rhs: "Y"),
    "Y": (lhs: nil, rhs: "Z")
])
binaryGraph.traverse(from: "Root", strategy: .dfs(order: .inorder()))

let bipartite = Graph(edges: [
    GraphEdge(source: "u1", destination: "v1"),
    GraphEdge(source: "u1", destination: "v2"),
    GraphEdge(source: "u2", destination: "v1"),
    GraphEdge(source: "u3", destination: "v2"),
    GraphEdge(source: "u3", destination: "v3"),
]).bipartite(leftPartition: ["u1", "u2", "u3"], rightPartition: ["v1", "v2", "v3"])

bipartite.maximumMatching(using: .hopcroftKarp())
```

## Design Considerations

### Generic Structure

The library is built on a fully generic structure, allowing all nodes and edges to be defined as generic types without constraints. 
This flexibility enables seamless integration of various algorithms on specialized graphs, such as weighted graphs. 
By using generics, the library ensures that algorithms remain broadly applicable while optimized for specific graph types.

For example, binary graphs can leverage specialized inorder depth-first search, while layered traversal strategies—such as unique node visits or path tracking—can be easily added to any algorithm. 
Generic constraints help formalize requirements, ensuring algorithms like Dijkstra's avoid negative weights for optimal performance.

### Composable Components and Algorithms

This library is designed with composability in mind. 
Similar to how Swift’s standard library transforms collections (e.g., `ReversedCollection`), this library provides efficient graph transformations such as `TransposedGraph` or `UndirectedGraph`. 
Algorithms can be layered and extended dynamically.

### Strong Defaults with Flexibility

Graphs in this library are directed by default, allowing for undirected (bidirectional) edges to be layered as transformations. 
Sensible algorithm defaults are provided, so users can easily get started without needing to specify algorithms manually. 
However, users retain the flexibility to override defaults with specific solutions when required.

### Extensible Algorithms

Algorithms in the library are built as abstract definitions with several built-in defaults. 
However, the architecture allows users to plug in their own algorithms if needed. 
For example, while Kruskal's and Prim's algorithms are provided for finding minimum spanning trees, users could implement their own reverse-delete algorithm, maintaining compatibility with the same API.

### Flexible Graph Declarations

The foundation of the library is the `GraphProtocol`, which requires only one method: defining the outgoing edges from a node. 
This minimalist design enables a wide range of algorithms – such as traversals, shortest paths, and minimum spanning trees – without requiring a complex interface.

Multiple concrete graph types conform to this protocol, including eager representations (`Graph`, `BinaryGraph`) and optimized lazy evaluations (`LazyGraph`, `LazyBinaryGraph`). 
Specialized types like `WeightedGraph` manage weighted edges, while `GridGraph` provides a convenient structure for 2D grid-based graphs.

## Contributions

While the core library provides a solid foundation, certain areas are still under development and not fully production-tested. 
Contributions, suggestions, and feedback are highly encouraged. 
Feel free to submit issues, start discussions for feature requests, and contribute code via pull requests.
