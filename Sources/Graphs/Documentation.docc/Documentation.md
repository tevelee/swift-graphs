# ``Graphs``

A comprehensive, protocol-oriented graph library for Swift that provides flexible abstractions, efficient algorithms, and composable graph transformations.

## Overview

The Graphs library offers a powerful, type-safe foundation for graph-based computation. Built on protocol-oriented design principles inspired by the Boost Graph Library (BGL), it separates graph storage from algorithms, enabling unprecedented flexibility and reusability.

### Key Features

- **Protocol-Oriented Design**: Minimal protocols with maximum flexibility
- **Storage Independence**: Algorithms work on any graph representation
- **Type Safety**: Generic constraints prevent algorithm misuse at compile time
- **Composable Transformations**: Lazy graph wrappers without data duplication
- **Comprehensive Algorithms**: From basic traversals to advanced flow networks
- **Multiple Implementations**: Choose the best algorithm for your use case

### Core Protocols

- ``GraphComponent``: Minimal graph protocol - only requires edge enumeration from a node
- ``Graph``: Adds global node and edge access to ``GraphComponent``
- ``BinaryGraphComponent``: Specialized protocol for binary tree operations
- ``BipartiteGraph``: Two-partition graphs for matching problems
- ``MutableGraph``: Dynamic graphs supporting node and edge insertion/removal

## Topics

### Understanding the Library

Learn the fundamental concepts and design philosophy behind the library.

- <doc:Architecture>
- <doc:ProtocolOrientedDesign>
- <doc:StorageAndAlgorithms>
- <doc:GenericConstraints>
- <doc:Composability>

### Getting Started

- <doc:QuickReference>
- <doc:CodeExamples>

### Algorithm Categories

Comprehensive algorithm implementations organized by problem type.

#### Traversal and Search
- <doc:TraversalAlgorithms>
- <doc:ShortestPathAlgorithms>

#### Optimization Algorithms
- <doc:MinimumSpanningTree>
- <doc:FlowAndMatching>

#### Graph Analysis
- <doc:GraphProperties>
- <doc:GraphColoring>

#### Special Paths
- <doc:EulerianHamiltonian>

#### Graph Generation
- <doc:RandomGraphGeneration>

### Concrete Graph Types

The library provides multiple graph implementations, each optimized for different use cases.

#### Storage-Based Graphs

Different storage strategies for different performance characteristics.

- ``ConnectedGraph`` - Array-based storage, simple and efficient for small graphs
- ``ConnectedHashGraph`` - Hash-based storage, O(1) edge lookup for large graphs
- ``DisjointGraph`` - Supports standalone nodes without edges
- ``DisjointHashGraph`` - Hash-based with standalone nodes

#### Specialized Structures

- ``GridGraph`` - 2D grid with orthogonal/diagonal connections, perfect for pathfinding
- ``LazyGraph`` - On-demand edge computation, ideal for infinite or procedural graphs
- ``ConnectedBinaryGraph`` - Binary tree with specialized traversals
- ``LazyBinaryGraph`` - Lazy binary tree evaluation

#### Graph Transformations

Composable wrappers that modify graph behavior without copying data.

- ``WeightedGraph`` - Adds weights to edges
- ``UndirectedGraph`` - Makes all edges bidirectional
- ``TransposedGraph`` - Reverses all edge directions
- ``ComplementGraph`` - Represents the graph complement
- ``ResidualGraph`` - Tracks flow network residual capacities
- ``PartitionedGraph`` - Creates bipartite graph from partitions

### Algorithm Reference

#### Traversal Strategies

- ``GraphTraversal`` - Lazy sequence for graph traversal
- ``GraphTraversalStrategy`` - Protocol for custom traversal strategies
- ``BreadthFirstSearch`` - Level-by-level exploration
- ``DepthFirstSearch`` - Deep exploration with ordering variants
  - ``DepthFirstSearchPreorder`` - Visit node before children
  - ``DepthFirstSearchInorder`` - Binary tree inorder traversal
  - ``DepthFirstSearchPostorder`` - Visit node after children
- ``UniqueTraversalStrategy`` - Ensures each node visited once

#### Shortest Path Algorithms

**Single-Pair Shortest Path**
- ``ShortestPathAlgorithm`` - Protocol for shortest path algorithms
- ``DijkstraAlgorithm`` - O((V+E)log V), non-negative weights
- ``AStarAlgorithm`` - Dijkstra with heuristic guidance
- ``BellmanFordAlgorithm`` - O(VE), handles negative weights

**All-Pairs Shortest Paths**
- ``FloydWarshallAlgorithm`` - O(V³), dense graphs
- ``JohnsonAlgorithm`` - O(V²log V + VE), sparse graphs

**Specialized**
- K-shortest paths with ``YenAlgorithm``
- Bidirectional Dijkstra for long paths

#### Optimization Algorithms

**Minimum Spanning Tree**
- ``MinimumSpanningTreeAlgorithm`` - Protocol for MST algorithms
- ``KruskalAlgorithm`` - O(E log E), edge-based, best for sparse
- ``PrimAlgorithm`` - O(E log V), vertex-based, best for dense
- ``BoruvkaAlgorithm`` - O(E log V), parallel-friendly

**Maximum Flow**
- ``MaxFlowAlgorithm`` - Protocol for flow algorithms
- ``FordFulkersonAlgorithm`` - O(E × f), basic augmenting paths
- ``EdmondsKarpAlgorithm`` - O(VE²), shortest augmenting paths
- ``DinicAlgorithm`` - O(V²E), blocking flows, best for dense

**Bipartite Matching**
- ``MaximumMatchingAlgorithm`` - Protocol for matching algorithms
- ``HopcroftKarpAlgorithm`` - O(E√V), optimal bipartite matching

#### Graph Analysis

**Connectivity**
- ``StronglyConnectedComponentsAlgorithm`` - Protocol for SCC algorithms
- ``TarjanSCCAlgorithm`` - O(V+E), single DFS
- ``KosarajuSCCAlgorithm`` - O(V+E), two DFS passes

**Graph Coloring**
- ``GraphColoringAlgorithm`` - Protocol for coloring algorithms
- ``GreedyColoringAlgorithm`` - O(V+E), fast approximation
- ``DSaturAlgorithm`` - O(V²), better quality
- ``WelshPowellAlgorithm`` - O(V log V + E), degree-ordered

**Special Paths**
- ``EulerianPathAlgorithm`` - Protocol for Eulerian paths
- ``HierholzerEulerianPathAlgorithm`` - O(E), optimal for Eulerian cycles
- ``HamiltonianPathAlgorithm`` - Protocol for Hamiltonian paths (NP-complete)
- ``BacktrackingHamiltonianPathAlgorithm`` - Exhaustive search
- ``HeuristicHamiltonianPathAlgorithm`` - Fast approximation

**Graph Isomorphism**
- ``GraphIsomorphismAlgorithm`` - Protocol for isomorphism testing
- ``VF2Algorithm`` - Efficient subgraph isomorphism
- ``WeisfeilerLehmanAlgorithm`` - Hash-based isomorphism test

#### Random Graph Generation

- ``RandomGraphGeneration`` - Protocol for random graphs
- ``ErdosRenyiRandomGraphGenerator`` - G(n,p) random graphs
- ``BarabasiAlbertRandomGraphGenerator`` - Scale-free networks
- ``WattsStrogatzRandomGraphGenerator`` - Small-world networks
