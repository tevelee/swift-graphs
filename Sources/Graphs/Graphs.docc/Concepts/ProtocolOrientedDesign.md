# Protocol-Oriented Design

Understand how Swift Graphs uses protocols to achieve flexibility, type safety, and reusability.

## Overview

Swift Graphs follows a **protocol-oriented design** where graph capabilities are defined as protocols rather than concrete classes. This approach, inspired by the Boost Graph Library (BGL) and adapted for Swift, provides unprecedented flexibility while maintaining compile-time type safety.

## Why Protocol-Oriented Design?

### The Problem with Inheritance

Traditional object-oriented design uses inheritance hierarchies:

```swift
// ❌ Rigid inheritance hierarchy
class Graph { ... }
class DirectedGraph: Graph { ... }
class WeightedDirectedGraph: DirectedGraph { ... }
class MutableWeightedDirectedGraph: WeightedDirectedGraph { ... }
```

**Problems:**
- Must choose ONE inheritance path
- Can't mix capabilities freely
- Adds features you don't need
- Difficult to extend without modification

### The Protocol Solution

Protocol-oriented design uses composition of capabilities:

```swift
// ✅ Flexible protocol composition
protocol Graph { ... }
protocol IncidenceGraph: Graph { ... }
protocol WeightedGraph: Graph { ... }
protocol MutableGraph: Graph { ... }

// Mix and match as needed
struct MyGraph: IncidenceGraph, WeightedGraph, MutableGraph { ... }
```

**Benefits:**
- Implement only what you need
- Compose capabilities freely
- Add new protocols without breaking existing code
- Algorithms work with ANY type that meets requirements

## BGL's Influence on Swift Graphs

### The Boost Graph Library Legacy

The [Boost Graph Library (BGL)](https://www.boost.org/doc/libs/1_89_0/libs/graph/doc/table_of_contents.html) pioneered **generic graph programming** in C++:

**BGL's Key Ideas:**
1. **Concepts, not classes** - Define what operations are required, not inheritance
2. **Minimal requirements** - Algorithms specify exactly what they need
3. **Separation of concerns** - Structure separate from data separate from algorithms
4. **Generic programming** - Work with any graph that meets requirements

### From C++ Concepts to Swift Protocols

Swift Graphs translates BGL concepts into Swift protocols:

| BGL Concept | Swift Protocol | Purpose |
|-------------|---------------|---------|
| Graph | `Graph` | Basic vertex/edge types |
| IncidenceGraph | `IncidenceGraph` | Outgoing edge access |
| BidirectionalGraph | `BidirectionalGraph` | Bidirectional traversal |
| VertexListGraph | `VertexListGraph` | Enumerate vertices |
| EdgeListGraph | `EdgeListGraph` | Enumerate edges |
| AdjacencyMatrix | `AdjacencyMatrix` | Dense representation |
| PropertyMap | `PropertyMap` | External properties |

**Swift's advantages over C++ concepts:**
- Cleaner, more intuitive syntax
- Built-in language support (not template metaprogramming)
- Better error messages
- Protocol extensions for default implementations

## Protocol Hierarchy in Detail

### Level 1: Base Protocol

The foundation that all graphs build upon:

```swift
/// The most basic graph protocol
protocol Graph {
    /// Type used to identify vertices
    associatedtype VertexDescriptor
    
    /// Type used to identify edges
    associatedtype EdgeDescriptor
}
```

**What it provides:**
- Type safety through associated types
- No required operations (intentionally minimal)
- Foundation for refinement

### Level 2: Structural Protocols

Add specific graph capabilities:

#### `IncidenceGraph` - Outgoing Edge Access

```swift
protocol IncidenceGraph: Graph {
    associatedtype OutgoingEdges: Sequence<EdgeDescriptor>
    
    func outgoingEdges(of vertex: VertexDescriptor) -> OutgoingEdges
    func destination(of edge: EdgeDescriptor) -> VertexDescriptor?
    func outDegree(of vertex: VertexDescriptor) -> Int
}
```

**Enables:** Graph traversal, neighbor exploration, pathfinding

#### `BidirectionalGraph` - Bidirectional Access

```swift
protocol BidirectionalGraph: IncidenceGraph {
    associatedtype IncomingEdges: Sequence<EdgeDescriptor>
    
    func incomingEdges(of vertex: VertexDescriptor) -> IncomingEdges
    func inDegree(of vertex: VertexDescriptor) -> Int
}
```

**Enables:** Reverse traversal, predecessor queries, flow algorithms

#### `VertexListGraph` - Vertex Enumeration

```swift
protocol VertexListGraph: Graph {
    associatedtype Vertices: Sequence<VertexDescriptor>
    
    func vertices() -> Vertices
    var vertexCount: Int { get }
}
```

**Enables:** Algorithms that process all vertices

### Level 3: Property and Mutation Protocols

#### `PropertyGraph` - Associated Data

```swift
protocol PropertyGraph: Graph {
    associatedtype VertexProperties
    associatedtype EdgeProperties
    associatedtype VertexPropertyMap: PropertyMap
    associatedtype EdgePropertyMap: PropertyMap
}
```

**Enables:** Storing labels, weights, colors, application data

#### `MutableGraph` - Dynamic Modification

```swift
protocol MutableGraph: Graph {
    mutating func addVertex() -> VertexDescriptor
    mutating func addEdge(from: VertexDescriptor, to: VertexDescriptor) -> EdgeDescriptor?
    mutating func remove(vertex: VertexDescriptor)
    mutating func remove(edge: EdgeDescriptor)
}
```

**Enables:** Graph construction, runtime modifications

## How Algorithms Use Protocols

### Generic Constraints

Algorithms specify their requirements through protocol constraints:

```swift
// Dijkstra requires:
// 1. IncidenceGraph (to traverse edges)
// 2. VertexListGraph (to initialize distances)
// 3. Hashable vertices (for efficient lookups)
extension IncidenceGraph where Self: VertexListGraph, VertexDescriptor: Hashable {
    func shortestPath<Weight: Numeric & Comparable>(
        from source: VertexDescriptor,
        to destination: VertexDescriptor,
        using algorithm: some ShortestPathAlgorithm<Self, Weight>
    ) -> Path<VertexDescriptor, EdgeDescriptor>? {
        algorithm.shortestPath(from: source, to: destination, in: self, visitor: nil)
    }
}
```

**What this means:**
- Works with **any** graph that meets requirements
- Compiler enforces requirements at compile time
- Can't accidentally call with incompatible graph

### Example: BFS Traversal

```swift
// BFS requires IncidenceGraph + Hashable vertices
extension IncidenceGraph where VertexDescriptor: Hashable {
    func traverse(from source: VertexDescriptor, using: BFSAlgorithm) {
        // Implementation works with ANY IncidenceGraph
    }
}

// ✅ Works - AdjacencyList implements IncidenceGraph
let graph = AdjacencyList()
graph.traverse(from: start, using: .bfs())

// ❌ Compile error if graph doesn't implement IncidenceGraph
```

## Default Implementations Through Extensions

Protocols can provide default implementations:

```swift
extension IncidenceGraph {
    /// Default implementation: get successors from outgoing edges
    func successors(of vertex: VertexDescriptor) -> some Sequence<VertexDescriptor> {
        outgoingEdges(of: vertex).lazy.compactMap(destination)
    }
    
    /// Default implementation: check if vertex is a sink
    func isSink(vertex: VertexDescriptor) -> Bool {
        outDegree(of: vertex) == 0
    }
}
```

**Benefits:**
- Implement once, available to all conforming types
- Can be overridden for optimization
- Reduces boilerplate

## Composition Over Inheritance

### Multiple Protocol Conformance

Types can conform to multiple protocols:

```swift
struct AdjacencyList:
    Graph,
    IncidenceGraph,
    BidirectionalGraph,
    VertexListGraph,
    EdgeListGraph,
    AdjacencyGraph,
    MutableGraph,
    PropertyGraph
{
    // Implements all required operations
}
```

**Flexibility:** Each protocol adds only what's needed.

### Conditional Conformance

Protocols can conditionally conform based on constraints:

```swift
// AdjacencyList is binary incidence graph IF edge storage supports it
extension AdjacencyList: BinaryIncidenceGraph where EdgeStore: BinaryEdgeStorage {
    // Inherits binary tree operations
}
```

## Type Safety and Compile-Time Guarantees

### Algorithm-Graph Compatibility

The type system prevents misuse:

```swift
// ✅ Type-safe: Dijkstra works with this graph
let graph: some IncidenceGraph & VertexListGraph = AdjacencyList()
let path = graph.shortestPath(from: a, to: b, using: .dijkstra())

// ❌ Compile error: Can't use shortest path without IncidenceGraph
let badGraph: some Graph = CustomMinimalGraph()
let path = badGraph.shortestPath(...)  // ERROR: missing requirements
```

### Associated Type Constraints

Associated types ensure consistency:

```swift
protocol PropertyGraph: Graph {
    associatedtype VertexPropertyMap: PropertyMap where
        VertexPropertyMap.Key == VertexDescriptor  // ✅ Must match
}
```

Compiler enforces that property map keys match vertex descriptors.

## Real-World Benefits

### 1. Flexibility

Implement a graph with exactly the features you need:

```swift
// Minimal read-only graph
struct ImmutableGraph: Graph, IncidenceGraph, VertexListGraph {
    // No mutation, no properties - perfect for static data
}

// Full-featured graph
struct FullGraph: Graph, IncidenceGraph, BidirectionalGraph, 
                   VertexListGraph, MutableGraph, PropertyGraph {
    // All features available
}
```

### 2. Reusability

Algorithms work across implementations:

```swift
// Same algorithm, different graph types
let sparse = AdjacencyList()
let dense = AdjacencyMatrix()
let grid = GridGraph(width: 10, height: 10)

// All support shortest path (all implement IncidenceGraph)
let path1 = sparse.shortestPath(from: a, to: b, using: .dijkstra())
let path2 = dense.shortestPath(from: c, to: d, using: .dijkstra())
let path3 = grid.shortestPath(from: start, to: goal, using: .aStar(heuristic: .manhattan))
```

### 3. Extensibility

Add new graphs without modifying library:

```swift
// Your custom graph
struct DatabaseBackedGraph: Graph, IncidenceGraph, VertexListGraph {
    // Load from database on-demand
    
    func outgoingEdges(of vertex: VertexDescriptor) -> [EdgeDescriptor] {
        database.query("SELECT edges WHERE source = ?", vertex)
    }
}

// ✅ Works with all IncidenceGraph algorithms
let path = dbGraph.shortestPath(from: a, to: b, using: .dijkstra())
```

### 4. Testability

Easy to mock for testing:

```swift
// Simple test graph
struct TestGraph: IncidenceGraph, VertexListGraph {
    var edges: [Int: [Int]] = [:]
    
    func outgoingEdges(of vertex: Int) -> [Int] {
        edges[vertex] ?? []
    }
}

// Use in tests
func testAlgorithm() {
    let graph = TestGraph(edges: [0: [1, 2], 1: [3]])
    let result = graph.traverse(from: 0, using: .bfs())
    // Assert on result
}
```

## Design Patterns

### Small Core, Rich Extensions

**Core protocol is minimal:**

```swift
protocol Graph {
    associatedtype VertexDescriptor
    associatedtype EdgeDescriptor
}
```

**Extensions add convenience:**

```swift
extension IncidenceGraph {
    // Derived from required operations
    func successors(of vertex: VertexDescriptor) -> some Sequence<VertexDescriptor> {
        outgoingEdges(of: vertex).lazy.compactMap(destination)
    }
}
```

### Refinement Hierarchy

Protocols build on each other:

```
Graph (base)
  └─ IncidenceGraph (adds outgoing edges)
       └─ BidirectionalGraph (adds incoming edges)
```

Each level adds new capabilities without breaking previous levels.

### Where Clauses for Specificity

Constrain algorithms to specific scenarios:

```swift
// Only for graphs with Hashable vertices
extension IncidenceGraph where VertexDescriptor: Hashable {
    func depthFirstSearch(from: VertexDescriptor) { ... }
}

// Only for weighted graphs
extension IncidenceGraph where Self: EdgePropertyGraph {
    func dijkstra(from: VertexDescriptor) { ... }
}
```

## Comparison with Other Approaches

| Approach | Flexibility | Type Safety | Boilerplate | Extensibility |
|----------|------------|-------------|-------------|---------------|
| Inheritance | ❌ Low | ✅ High | ✅ Low | ❌ Low |
| Duck Typing | ✅ High | ❌ None | ✅ Low | ✅ High |
| **Protocols** | **✅ High** | **✅ High** | **⚠️ Medium** | **✅ High** |

Swift Graphs chooses protocols for the best combination of safety and flexibility.

## Next Steps

Now that you understand protocol-oriented design:

- Explore <doc:Architecture> - See how protocols fit into the overall structure
- Read <doc:PluggableArchitecture> - Learn about swappable components
- Study <doc:AlgorithmInterfaces> - Understand algorithm protocols

## See Also

- <doc:GraphConcepts>
- <doc:Architecture>
- <doc:AlgorithmInterfaces>
- ``Graph``
- ``IncidenceGraph``
- ``BidirectionalGraph``

