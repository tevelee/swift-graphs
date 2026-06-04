# ``Graphs``

A comprehensive, high-performance graph algorithms library for Swift, inspired by the Boost Graph Library.

## Overview

Swift Graphs provides flexible graph representations with a small core API and extensive algorithm coverage, designed for maximum performance and type safety. Built on protocol-oriented design principles, it brings the proven patterns of the Boost Graph Library (BGL) to Swift's modern type system.

### Key Features

- **Protocol-Oriented Design** - Graph capabilities as composable protocols
- **Pluggable Architecture** - Swap storage backends, property systems, and algorithms
- **Compile-Time Safety** - Type system ensures algorithm compatibility
- **Comprehensive Algorithms** - Shortest paths, traversals, coloring, MST, flow, and more
- **BGL Heritage** - Decades of proven graph library design
- **Modular Builds** - SPM traits (Swift 6.2+) for including only the features you need
- **Platform Independent** - iOS, macOS, watchOS, tvOS, and visionOS

## Getting Started

New to Swift Graphs? Start here:

- <doc:GettingStarted>
- <doc:GraphConcepts>
- <doc:ChoosingGraphType>

## Core Concepts

Learn the foundational ideas behind Swift Graphs:

- <doc:ProtocolOrientedDesign>
- <doc:Architecture>
- <doc:PluggableArchitecture>
- <doc:PropertiesAndPropertyMaps>
- <doc:AlgorithmInterfaces>
- <doc:VisitorPattern>

## Guides

- <doc:AddingAnAlgorithm>
- <doc:ChoosingStorageBackend>

## Graph Types

Swift Graphs provides multiple graph implementations optimized for different use cases:

### Primary Implementations

- ``AdjacencyList`` - Most common, optimized for sparse graphs
- ``AdjacencyMatrix`` - Dense graphs with O(1) edge lookup
- ``BipartiteAdjacencyList`` - Two-colored graphs for matching problems
- ``GridGraph`` - 2D spatial graphs for pathfinding
- ``LazyIncidenceGraph`` - On-demand computation for large graphs

### Graph Families

Zero-storage generator graphs for standard graph-theory structures:

- ``CompleteGraph`` - Complete graph K_n (every pair connected)
- ``PathGraph`` - Directed path P_n: 0→1→2→…→(n-1)
- ``CycleGraph`` - Directed cycle C_n
- ``StarGraph`` - Hub-and-spokes S_n (hub vertex `n`, leaves `0..<n`)
- ``WheelGraph`` - Hub connected to a cycle W_n
- ``LadderGraph`` - 2×n ladder with rungs
- ``HypercubeGraph`` - Boolean hypercube Q_n
- ``CompleteBipartiteGraph`` - Complete bipartite K_{m,n}
- ``PetersonGraph`` - The classic Petersen graph

### Graph Views

Lazy, zero-copy views that wrap an existing graph:

- **Product views** - ``CartesianProductGraph``, ``TensorProductGraph``, ``StrongProductGraph``, ``LexicographicProductGraph``
- **Structural views** - Filtered, Reversed, Undirected, Complement

### Choosing a Graph Type

See <doc:ChoosingGraphType> for detailed guidance.

## Algorithms

Swift Graphs includes comprehensive algorithm implementations. See <doc:AlgorithmsCatalog> for a complete guide to all available algorithms.

### Shortest Paths & Pathfinding

- **Dijkstra's Algorithm** - Single-source shortest paths (non-negative weights)
- **A\* Search** - Heuristic-guided pathfinding
- **Bellman-Ford** - Handles negative weights, detects negative cycles
- **SPFA** - Faster alternative to Bellman-Ford for negative weights
- **Floyd-Warshall** - All-pairs shortest paths
- **Johnson's Algorithm** - All-pairs with sparse graphs
- **Contraction Hierarchy** - Preprocess once for very fast repeated queries

### Graph Traversal

- **Depth-First Search (DFS)** - With preorder, postorder, inorder variants
- **Breadth-First Search (BFS)** - Level-by-level exploration
- **Best-First Search** - Priority-guided traversal
- **Iterative Deepening DFS** - Memory-efficient depth-limited search

### Graph Analysis

- **Connected Components** - Find connected subgraphs
- **Strongly Connected Components** - Directed graph components
- **Articulation Points & Bridges** - Find critical vertices and edges
- **Cycle Detection** - Identify cycles in graphs
- **Bipartiteness** - Two-coloring detection
- **Planarity** - Planarity testing, embedding, and straight-line drawing
- **Vertex Ordering** - Smallest-last and Reverse Cuthill-McKee orderings

### Optimization Problems

- **Minimum Spanning Tree** - Kruskal, Prim, Borůvka algorithms
- **Maximum Flow** - Ford-Fulkerson, Edmonds-Karp, Dinic algorithms
- **Minimum Cost Flow** - Successive Shortest Paths algorithm
- **Minimum Cut** - Stoer-Wagner global minimum cut
- **Graph Coloring** - Greedy, DSatur, Welsh-Powell algorithms
- **Topological Sort** - DAG ordering
- **Matching** - Maximum cardinality matching (Hopcroft-Karp)

### Special Paths

- **Eulerian Paths** - Visit every edge exactly once
- **Hamiltonian Paths** - Visit every vertex exactly once
- **K-Shortest Paths** - Find multiple paths
- **All Paths** - Enumerate every simple path between two vertices

### Centrality Measures

- **Degree Centrality** - Simple importance based on connections
- **PageRank** - Link-based importance for web graphs
- **Betweenness Centrality** - Bottleneck and bridge identification
- **Closeness Centrality** - Average distance to all vertices
- **Eigenvector Centrality** - Recursive importance measure

### Random Graphs

- **Erdős-Rényi** - Random edge probability
- **Barabási-Albert** - Scale-free networks
- **Watts-Strogatz** - Small-world networks

## Topics

### Essentials

- <doc:GettingStarted>
- <doc:GraphConcepts>
- <doc:ChoosingGraphType>

### Core Concepts

- <doc:ProtocolOrientedDesign>
- <doc:Architecture>
- <doc:PluggableArchitecture>
- <doc:AlgorithmInterfaces>
- <doc:VisitorPattern>
- <doc:PropertiesAndPropertyMaps>

### Guides

- <doc:AddingAnAlgorithm>
- <doc:ChoosingStorageBackend>

### Graph Implementations

- ``AdjacencyList``
- ``AdjacencyMatrix``
- ``BipartiteAdjacencyList``
- ``GridGraph``
- ``LazyIncidenceGraph``

### Graph Families

- ``CompleteGraph``
- ``PathGraph``
- ``CycleGraph``
- ``StarGraph``
- ``WheelGraph``
- ``LadderGraph``
- ``HypercubeGraph``
- ``CompleteBipartiteGraph``
- ``PetersonGraph``

### Graph Product Views

- ``CartesianProductGraph``
- ``TensorProductGraph``
- ``StrongProductGraph``
- ``LexicographicProductGraph``

### Graph Protocols

- ``Graph``
- ``IncidenceGraph``
- ``BidirectionalGraph``
- ``VertexListGraph``
- ``EdgeListGraph``
- ``AdjacencyGraph``
- ``MutableGraph``
- ``PropertyGraph``

### Algorithms

- <doc:AlgorithmsCatalog>

### Supporting Types

- ``Path``
- ``TraversalResult``
- ``GraphColoring``
- ``ConnectedComponentsResult``
- ``MinCostFlowResult``
- ``PlanarEmbedding``
- ``PlanarEmbeddingResult``
- ``PlanarDrawing``
- ``VertexOrdering``
