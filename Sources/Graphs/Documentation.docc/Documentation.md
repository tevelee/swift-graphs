# ``Graphs``

This library provides a robust and flexible foundation for working with graphs. 

## Overview

The package consists of a few core protocols to abstract over various types of graphs and the algorithms they support, as well as some concrete implementation of them.
It's designed to be extensible so users of the library can bring their own algorithms and graph representations if necessary.

Every graph type (and their protocols) are generic over the node and edge values they hold onto. 
This allows algorithms to be constrained over specific conditions (e.g. minimum spanning tree search works on graph with weigted edges).

- ``GraphComponent``: It represents graphs where each node is connected to some other node.
- ``Graph``: A more general representation, which allows standalone nodes to be present in the graph.
- ``BinaryGraphComponent``: A graph with dedicated representation for (optional) left and right edges. 
- ``BipartiteGraph``: Graph with two partitions.
- ``MutableGraph``: A graph allows for adding and removing nodes and edges dynamically.

## Concrete Graphs

### Binary graphs

Generally binary graphs have specialized APIs so they can provide binary edges.
This allows for specific functionality such as inorder DFS traversal.
They conform to ``Graph`` and ``GraphComponent`` too so the same algorithms are available on them.

- ``ConnectedBinaryGraph``
- ``ConnectedBinaryHashGraph``
- ``DisjointBinaryGraph``
- ``DisjointBinaryHashGraph``

### Connected graphs

They implement the ``GraphComponent`` protocol.
They represent graphs where each node is connected to some other node.
It doesn't necessarily mean that the graph is strongly connected.

- ``ConnectedGraph``
- ``ConnectedBinaryGraph``
- ``ConnectedHashGraph``
- ``ConnectedBinaryHashGraph``

### Disjoint graphs

They implement the ``Graph`` protocol.
They reprensent graphs where stanadlone nodes are possible.

- ``DisjointGraph``
- ``DisjointBinaryGraph``
- ``DisjointHashGraph``
- ``DisjointBinaryHashGraph``

### Lazy graphs

They implement the ``GraphComponent`` protocol.
The whole graph is not stored in memory at once, but it allows a lazy representation where the edges can be queried on demand. 

- ``LazyGraph``
- ``LazyBinaryGraph``

### Grid graph

A type of graph where nodes are stored in a two dimensional array and edges connect them in orthogonal and/or diagonal directions.

- ``GridGraph``

### Wrappers

These concrete graph types can wrap other graphs to extend their functionality.

- ``WeightedGraph``: Extends the edge to have a `Comparable` value.
- ``UndirectedGraph``: Duplicated directed edges to achieve bidirectional connections.
- ``ComplementGraph``: Represents the complement of a given base graph.
- ``TransposedGraph``: Transposes the base graph.
- ``ResidualGraph``: Graph to represent residual capacities of a flow network.
- ``PartitionedGraph``: Splits nodes to implement a ``BipartiteGraph``.

## Algorithms

### Traversal

- ``GraphTraversal`` uses a ``GraphTraversalStrategy`` to visit all connected nodes.

Concrete stretegies include:

- ``BreadthFirstSearch``: BFS
- ``DepthFirstSearch``: DFS with support for specialized ordering
  - ``DepthFirstSearchPreorder``
  - ``DepthFirstSearchInorder``
  - ``DepthFirstSearchPostorder``
- ``UniqueTraversalStrategy``: Avoids visiting the same node twice.

### Shortest path(s)

- ``ShortestPathAlgorithm``: Shortest path between two specific nodes.
  - ``DijkstraAlgorithm``
  - ``AStarAlgorithm``
  - ``BellmanFordAlgorithm``
- ``ShortestPathsAlgorithm``: Shortest paths from one node to all others.
  - ``DijkstraAlgorithm``
  - ``BellmanFordAlgorithm``
- ``ShortestPathsForAllPairsAlgorithm``: Shortest paths between all pairs of nodes.
  - ``FloydWarshallAlgorithm``
  - ``JohnsonAlgorithm``

### Minimum spanning tree

- ``MinimumSpanningTreeAlgorithm``
  - ``PrimAlgorithm``
  - ``KruskalAlgorithm``
  - ``BoruvkaAlgorithm``

### Isomorphism check

- ``GraphIsomorphismAlgorithm``
  - ``VF2Algorithm``
  - ``WeisfeilerLehmanAlgorithm``

### Graph coloring

- ``GraphColoringAlgorithm``
  - ``GreedyColoringAlgorithm``
  - ``DSaturAlgorithm``
  - ``WelshPowellAlgorithm``

### Max Flow / Min Cut

- ``MaxFlowAlgorithm``
  - ``DinicAlgorithm``
  - ``EdmondsKarpAlgorithm``
  - ``FordFulkersonAlgorithm``

### Matching

- ``MaximumMatchingAlgorithm``
  - ``HopcroftKarpAlgorithm``

### Graph generation

- ``RandomGraphGeneration``
  - ``ErdosRenyiRandomGraphGenerator``
  - ``BarabasiAlbertRandomGraphGenerator``
  - ``WattsStrogatzRandomGraphGenerator``

### Strongly connected components

- ``StronglyConnectedComponentsAlgorithm``
  - ``KosarajuSCCAlgorithm``
  - ``TarjanSCCAlgorithm``

### Hamiltonian paths and cycles

- ``HamiltonianPathAlgorithm``
  - ``HeuristicHamiltonianPathAlgorithm``
  - ``BacktrackingHamiltonianPathAlgorithm``

### Eulerian paths and cycles

- ``EulerianPathAlgorithm``
  - ``HierholzerEulerianPathAlgorithm``
  - ``BacktrackingEulerianPathAlgorithm``
