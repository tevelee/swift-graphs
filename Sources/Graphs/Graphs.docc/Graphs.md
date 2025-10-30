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
- **Platform Independent** - iOS, macOS, watchOS, tvOS, and visionOS

## Getting Started

New to Swift Graphs? Start here:

- <doc:GettingStarted>
- <doc:Concepts/GraphConcepts>
- <doc:Concepts/ChoosingGraphType>

## Core Concepts

Learn the foundational ideas behind Swift Graphs:

- <doc:Concepts/ProtocolOrientedDesign>
- <doc:Concepts/Architecture>
- <doc:Concepts/PluggableArchitecture>
- <doc:Concepts/PropertiesAndPropertyMaps>
- <doc:Concepts/AlgorithmInterfaces>
- <doc:Concepts/VisitorPattern>

## Graph Types

Swift Graphs provides multiple graph implementations optimized for different use cases:

### Primary Implementations

- ``AdjacencyList`` - Most common, optimized for sparse graphs
- ``AdjacencyMatrix`` - Dense graphs with O(1) edge lookup
- ``BipartiteAdjacencyList`` - Two-colored graphs for matching problems
- ``GridGraph`` - 2D spatial graphs for pathfinding
- ``LazyIncidenceGraph`` - On-demand computation for large graphs

### Choosing a Graph Type

See <doc:Concepts/ChoosingGraphType> for detailed guidance.

## Algorithms

Swift Graphs includes comprehensive algorithm implementations. See <doc:AlgorithmsCatalog> for a complete guide to all available algorithms.

### Shortest Paths & Pathfinding

- **Dijkstra's Algorithm** - Single-source shortest paths (non-negative weights)
- **A\* Search** - Heuristic-guided pathfinding
- **Bellman-Ford** - Handles negative weights, detects negative cycles
- **Floyd-Warshall** - All-pairs shortest paths
- **Johnson's Algorithm** - All-pairs with sparse graphs

### Graph Traversal

- **Depth-First Search (DFS)** - With preorder, postorder, inorder variants
- **Breadth-First Search (BFS)** - Level-by-level exploration
- **Best-First Search** - Priority-guided traversal
- **Iterative Deepening DFS** - Memory-efficient depth-limited search

### Graph Analysis

- **Connected Components** - Find connected subgraphs
- **Strongly Connected Components** - Directed graph components
- **Cycle Detection** - Identify cycles in graphs
- **Planarity Testing** - Boyer-Myrvold algorithm
- **Bipartiteness** - Two-coloring detection

### Optimization Problems

- **Minimum Spanning Tree** - Kruskal, Prim, Borůvka algorithms
- **Maximum Flow** - Ford-Fulkerson, Edmonds-Karp, Dinic algorithms
- **Graph Coloring** - Greedy, DSatur, Welsh-Powell algorithms
- **Topological Sort** - DAG ordering
- **Matching** - Maximum cardinality matching (Hopcroft-Karp)

### Special Paths

- **Eulerian Paths** - Visit every edge exactly once
- **Hamiltonian Paths** - Visit every vertex exactly once
- **K-Shortest Paths** - Find multiple paths

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
- <doc:Concepts/GraphConcepts>
- <doc:Concepts/ChoosingGraphType>

### Core Concepts

- <doc:Concepts/ProtocolOrientedDesign>
- <doc:Concepts/Architecture>
- <doc:Concepts/PluggableArchitecture>
- <doc:Concepts/AlgorithmInterfaces>
- <doc:Concepts/VisitorPattern>
- <doc:Concepts/PropertiesAndPropertyMaps>

### Graph Implementations

- ``AdjacencyList``
- ``AdjacencyMatrix``
- ``BipartiteAdjacencyList``
- ``GridGraph``
- ``LazyIncidenceGraph``

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
