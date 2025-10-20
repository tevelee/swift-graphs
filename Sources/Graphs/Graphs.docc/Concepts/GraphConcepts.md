# Graph Concepts

Understand the fundamental concepts of graph theory and how they're represented in Swift Graphs.

## Overview

A **graph** is a mathematical structure used to model relationships between objects. Swift Graphs provides type-safe, protocol-oriented implementations of graph data structures and algorithms.

## What is a Graph?

A graph consists of two main components:

### Vertices (Nodes)

**Vertices** (also called **nodes** or **points**) represent entities in your domain:
- People in a social network
- Cities in a map
- Web pages on the internet
- States in a finite automaton

```swift
var graph = AdjacencyList()

// Add vertices
let alice = graph.addVertex { $0.label = "Alice" }
let bob = graph.addVertex { $0.label = "Bob" }
```

### Edges (Links)

**Edges** (also called **links**, **arcs**, or **connections**) represent relationships:
- Friendships between people
- Roads between cities
- Hyperlinks between pages
- Transitions between states

```swift
// Add an edge connecting two vertices
graph.addEdge(from: alice, to: bob)
```

## Directed vs. Undirected Graphs

### Directed Graphs (Digraphs)

In a **directed graph**, edges have direction - they go **from** one vertex **to** another:

```
A → B  (A to B, but not B to A)
```

**Examples:**
- Twitter following (Alice follows Bob ≠ Bob follows Alice)
- One-way streets
- Dependencies (Task A must complete before Task B)

```swift
var digraph = AdjacencyList()
let a = digraph.addVertex { $0.label = "A" }
let b = digraph.addVertex { $0.label = "B" }

// Directed edge: A → B
digraph.addEdge(from: a, to: b)
```

### Undirected Graphs

In an **undirected graph**, edges are bidirectional:

```
A — B  (connection goes both ways)
```

**Examples:**
- Facebook friendships (mutual)
- Undirected roads
- Chemical bonds

```swift
var ugraph = AdjacencyList()
let a = ugraph.addVertex { $0.label = "A" }
let b = ugraph.addVertex { $0.label = "B" }

// Simulate undirected by adding edges in both directions
ugraph.addEdge(from: a, to: b)
ugraph.addEdge(from: b, to: a)
```

## Graph Terminology

### Neighbors and Adjacency

Two vertices are **adjacent** (neighbors) if they're connected by an edge:

```swift
// Find neighbors of a vertex
for neighbor in graph.successors(of: alice) {
    print("Alice is connected to \(graph[neighbor].label)")
}
```

### Degree

The **degree** of a vertex is the number of edges connected to it:

```swift
let degree = graph.outDegree(of: alice)
print("Alice has \(degree) outgoing connections")
```

For directed graphs:
- **Out-degree**: Number of edges leaving the vertex
- **In-degree**: Number of edges entering the vertex

```swift
let outDegree = digraph.outDegree(of: alice)
let inDegree = digraph.inDegree(of: alice)
let totalDegree = digraph.degree(of: alice)  // in + out
```

### Paths

A **path** is a sequence of edges connecting vertices:

```
A → B → C → D
```

```swift
// Find shortest path
if let path = graph.shortestPath(from: a, to: d, using: .dijkstra(weight: .unit)) {
    print("Path length: \(path.edges.count)")
    print("Vertices:", path.vertices)
}
```

### Cycles

A **cycle** is a path that starts and ends at the same vertex:

```
A → B → C → A
```

```swift
// Check if graph has cycles
let hasCycle = graph.hasCycle()
```

### Connected Graphs

A graph is **connected** if there's a path between every pair of vertices:

```swift
let components = graph.connectedComponents()
if components.componentCount == 1 {
    print("Graph is connected")
}
```

### Weighted Graphs

Graphs can have **weights** (costs, distances) on edges:

```swift
graph.addEdge(from: sanFrancisco, to: losAngeles) {
    $0.weight = 383.0  // miles
}
```

## Descriptors: References to Graph Elements

Swift Graphs uses **descriptors** as opaque identifiers for vertices and edges:

### Vertex Descriptors

A `VertexDescriptor` is a type-safe reference to a vertex:

```swift
// alice is a VertexDescriptor
let alice = graph.addVertex { $0.label = "Alice" }

// Use the descriptor to reference the vertex
print(graph[alice].label)  // Access properties
```

**Key Points:**
- Descriptors are lightweight (often just integers)
- They're specific to a particular graph
- Don't mix descriptors from different graphs!

### Edge Descriptors

An `EdgeDescriptor` references an edge:

```swift
// edge is an EdgeDescriptor
let edge = graph.addEdge(from: alice, to: bob)!

// Use the descriptor
let source = graph.source(of: edge)
let destination = graph.destination(of: edge)
print(graph[edge].weight)
```

## Graph Protocols in Swift Graphs

Swift Graphs defines graph capabilities as protocols. Each protocol represents a specific feature:

### Base Protocol: `Graph`

The foundational protocol that all graphs conform to:

```swift
protocol Graph {
    associatedtype VertexDescriptor
    associatedtype EdgeDescriptor
}
```

Every graph has vertex and edge descriptor types, but no required operations yet.

### `IncidenceGraph`: Exploring Outgoing Edges

Access edges leaving a vertex:

```swift
protocol IncidenceGraph: Graph {
    func outgoingEdges(of: VertexDescriptor) -> some Sequence<EdgeDescriptor>
    func destination(of: EdgeDescriptor) -> VertexDescriptor?
    func outDegree(of: VertexDescriptor) -> Int
}
```

**Use case:** Traversing from a vertex to its successors.

```swift
// Find all vertices reachable from alice
for edge in graph.outgoingEdges(of: alice) {
    if let neighbor = graph.destination(of: edge) {
        print("Can reach: \(graph[neighbor].label)")
    }
}
```

### `BidirectionalGraph`: Two-Way Traversal

Access both outgoing and incoming edges:

```swift
protocol BidirectionalGraph: IncidenceGraph {
    func incomingEdges(of: VertexDescriptor) -> some Sequence<EdgeDescriptor>
    func inDegree(of: VertexDescriptor) -> Int
}
```

**Use case:** Algorithms that need to traverse edges backwards.

```swift
// Find all vertices that connect TO alice
for edge in graph.incomingEdges(of: alice) {
    if let predecessor = graph.source(of: edge) {
        print("\(graph[predecessor].label) connects to Alice")
    }
}
```

### `VertexListGraph`: Enumerate All Vertices

Iterate over all vertices in the graph:

```swift
protocol VertexListGraph: Graph {
    func vertices() -> some Sequence<VertexDescriptor>
    var vertexCount: Int { get }
}
```

**Use case:** Algorithms that process every vertex.

```swift
// Print all vertices
for vertex in graph.vertices() {
    print(graph[vertex].label)
}
```

### `EdgeListGraph`: Enumerate All Edges

Iterate over all edges:

```swift
protocol EdgeListGraph: Graph {
    func edges() -> some Sequence<EdgeDescriptor>
    var edgeCount: Int { get }
}
```

**Use case:** Algorithms that examine every edge.

### `AdjacencyGraph`: Direct Neighbor Access

Get adjacent vertices without going through edges:

```swift
protocol AdjacencyGraph: Graph {
    func adjacentVertices(of: VertexDescriptor) -> some Sequence<VertexDescriptor>
}
```

**Use case:** Simplified neighbor queries.

### `MutableGraph`: Dynamic Modification

Add and remove vertices and edges:

```swift
protocol MutableGraph: Graph {
    mutating func addVertex() -> VertexDescriptor
    mutating func addEdge(from: VertexDescriptor, to: VertexDescriptor) -> EdgeDescriptor?
    mutating func remove(vertex: VertexDescriptor)
    mutating func remove(edge: EdgeDescriptor)
}
```

### `PropertyGraph`: Associated Data

Attach data to vertices and edges:

```swift
protocol PropertyGraph: Graph {
    associatedtype VertexProperties
    associatedtype EdgeProperties
}
```

**Use case:** Storing labels, weights, colors, etc.

```swift
// Access properties
let name = graph[vertex].label
let distance = graph[edge].weight
```

## When to Use Which Protocol?

Different algorithms require different protocols:

### Traversal Algorithms

**Require:** `IncidenceGraph` (need to explore outgoing edges)

```swift
extension IncidenceGraph where VertexDescriptor: Hashable {
    func traverse(from source: VertexDescriptor, using algorithm: some TraversalAlgorithm)
}
```

### Shortest Path Algorithms

**Require:** `IncidenceGraph`, often with `EdgePropertyGraph` for weights

```swift
extension IncidenceGraph where Self: EdgePropertyGraph, VertexDescriptor: Hashable {
    func shortestPath(from:to:using:)
}
```

### Component Detection

**Require:** `IncidenceGraph` + `VertexListGraph` (need all vertices)

```swift
extension IncidenceGraph where Self: VertexListGraph, VertexDescriptor: Hashable {
    func connectedComponents()
}
```

## Graph Representations

Swift Graphs provides multiple implementations:

### `AdjacencyList`

- **Best for:** Sparse graphs (few edges relative to vertices)
- **Space:** O(V + E)
- **Edge lookup:** O(degree)
- **Use case:** Social networks, road maps, most general-purpose graphs

### `AdjacencyMatrix`

- **Best for:** Dense graphs (many edges)
- **Space:** O(V²)
- **Edge lookup:** O(1)
- **Use case:** Complete graphs, dense connectivity

### Specialized Types

- **`GridGraph`** - 2D spatial grids
- **`BipartiteAdjacencyList`** - Two-colored graphs
- **`LazyGraph`** - Computed on-demand

See <doc:ChoosingGraphType> for detailed comparison.

## Special Graph Types

### Trees

A **tree** is a connected, acyclic graph:
- Exactly one path between any two vertices
- Has V-1 edges for V vertices

```swift
if graph.isTree() {
    print("This graph is a tree")
}
```

### Directed Acyclic Graphs (DAGs)

A DAG has directed edges but no cycles:
- Common in task scheduling
- Enables topological sorting

```swift
if graph.isAcyclic() {
    let sorted = graph.topologicalSort()
}
```

### Bipartite Graphs

Vertices can be divided into two disjoint sets:
- Every edge connects vertices from different sets
- Important for matching problems

```swift
if let partition = graph.bipartition() {
    print("Left set: \(partition.left.count)")
    print("Right set: \(partition.right.count)")
}
```

### Complete Graphs

Every pair of vertices is connected:
- K₅ = complete graph on 5 vertices
- Maximum number of edges: V(V-1)/2

## Properties and Property Maps

Swift Graphs separates **structure** (topology) from **data** (properties):

```swift
// Structure: Add vertices and edges
let v1 = graph.addVertex()
let v2 = graph.addVertex()
graph.addEdge(from: v1, to: v2)

// Data: Attach properties
graph[v1].label = "Vertex 1"
graph[v2].label = "Vertex 2"
```

See <doc:PropertiesAndPropertyMaps> for details.

## Graph Patterns in Practice

### Social Network

```swift
var social = AdjacencyList()
let alice = social.addVertex { $0.label = "Alice" }
let bob = social.addVertex { $0.label = "Bob" }
social.addEdge(from: alice, to: bob)  // Alice follows Bob
```

### Road Network

```swift
var roads = AdjacencyList()
let sf = roads.addVertex { $0.label = "San Francisco" }
let la = roads.addVertex { $0.label = "Los Angeles" }
roads.addEdge(from: sf, to: la) { $0.weight = 383.0 }
```

### Dependency Graph

```swift
var dependencies = AdjacencyList()
let taskA = dependencies.addVertex { $0.label = "Task A" }
let taskB = dependencies.addVertex { $0.label = "Task B" }
dependencies.addEdge(from: taskA, to: taskB)  // B depends on A
```

## Next Steps

Now that you understand graph concepts:

- Learn about <doc:ProtocolOrientedDesign> - How protocols enable flexibility
- Explore <doc:ChoosingGraphType> - Select the right implementation
- Study <doc:AlgorithmInterfaces> - Using and creating algorithms

## See Also

- <doc:ProtocolOrientedDesign>
- <doc:ChoosingGraphType>
- <doc:Architecture>
- ``Graph``
- ``IncidenceGraph``
- ``VertexListGraph``

