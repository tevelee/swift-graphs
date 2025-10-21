# Architecture

Explore the modular architecture that makes Swift Graphs flexible, extensible, and type-safe.

## Overview

Swift Graphs follows a **modular architecture** with clear separation of concerns between definitions and implementations. This design enables pluggability, testability, and extensibility through well-defined interfaces.

## Architectural Components

Swift Graphs separates **what** things are (protocols/definitions) from **how** they work (concrete implementations):

### Graph Components

**Definitions (Protocols):**
- Define capabilities and interfaces
- No implementation details

**Implementations (Concrete Types):**
- Provide actual data structures
- Implement protocol requirements

### Algorithm Components

**Definitions (Algorithm Protocols):**
- Define algorithm interfaces
- Specify requirements

**Implementations (Concrete Algorithms):**
- Provide specific algorithm logic
- Multiple implementations per interface

### Cross-Cutting Concerns

Two systems span all components:

- **Storage Backends** - How vertices and edges are stored
- **Property Systems** - How data is associated with graph elements

## Graph Definitions (Protocols)

**Location:** `Sources/Graphs/GraphDefinitions/`

Core protocols that define graph capabilities:

### Base Protocol

```swift
/// Foundation for all graphs
protocol Graph {
    associatedtype VertexDescriptor
    associatedtype EdgeDescriptor
}
```

**Purpose:** Define types, no operations yet.

### Structural Protocols

```swift
/// Access outgoing edges
protocol IncidenceGraph: Graph {
    func outgoingEdges(of vertex: VertexDescriptor) -> some Sequence<EdgeDescriptor>
    func destination(of edge: EdgeDescriptor) -> VertexDescriptor?
    func outDegree(of vertex: VertexDescriptor) -> Int
}

/// Access incoming and outgoing edges
protocol BidirectionalGraph: IncidenceGraph {
    func incomingEdges(of vertex: VertexDescriptor) -> some Sequence<EdgeDescriptor>
    func inDegree(of vertex: VertexDescriptor) -> Int
}

/// Enumerate all vertices
protocol VertexListGraph: Graph {
    func vertices() -> some Sequence<VertexDescriptor>
    var vertexCount: Int { get }
}

/// Enumerate all edges
protocol EdgeListGraph: Graph {
    func edges() -> some Sequence<EdgeDescriptor>
    var edgeCount: Int { get }
}

/// Direct neighbor access
protocol AdjacencyGraph: Graph {
    func adjacentVertices(of vertex: VertexDescriptor) -> some Sequence<VertexDescriptor>
}
```

### Mutation Protocols

```swift
/// Add/remove vertices
protocol VertexMutableGraph: Graph {
    mutating func addVertex() -> VertexDescriptor
    mutating func remove(vertex: VertexDescriptor)
}

/// Add/remove edges
protocol EdgeMutableGraph: Graph {
    mutating func addEdge(from: VertexDescriptor, to: VertexDescriptor) -> EdgeDescriptor?
    mutating func remove(edge: EdgeDescriptor)
}

/// Full mutation capability
protocol MutableGraph: VertexMutableGraph, EdgeMutableGraph {}
```

### Property Protocols

```swift
/// Associate data with vertices
protocol VertexPropertyGraph: Graph {
    associatedtype VertexProperties
    associatedtype VertexPropertyMap: PropertyMap
    var vertexPropertyMap: VertexPropertyMap { get }
}

/// Associate data with edges
protocol EdgePropertyGraph: Graph {
    associatedtype EdgeProperties
    associatedtype EdgePropertyMap: PropertyMap
    var edgePropertyMap: EdgePropertyMap { get }
}

/// Both vertex and edge properties
protocol PropertyGraph: VertexPropertyGraph, EdgePropertyGraph {}
```

**Key insight:** Protocols are minimal - each adds exactly one capability.

## Graph Implementations (Concrete Types)

**Location:** `Sources/Graphs/GraphImplementations/`

Concrete data structures implementing the protocols:

### `AdjacencyList`

Most common implementation for sparse graphs:

```swift
struct AdjacencyList<VertexStore, EdgeStore, VertexPropertyMap, EdgePropertyMap>:
    Graph,
    IncidenceGraph,
    BidirectionalGraph,
    VertexListGraph,
    EdgeListGraph,
    AdjacencyGraph,
    MutableGraph,
    PropertyGraph
{
    var vertexStore: VertexStore
    var edgeStore: EdgeStore
    var vertexPropertyMap: VertexPropertyMap
    var edgePropertyMap: EdgePropertyMap
}
```

**Implements:** All major protocols  
**Best for:** Sparse graphs (social networks, road maps)  
**Complexity:** Space O(V+E), Edge lookup O(degree)

### `AdjacencyMatrix`

Dense graph representation:

```swift
struct AdjacencyMatrix<VertexStore, EdgeStore, VertexPropertyMap, EdgePropertyMap>:
    Graph,
    IncidenceGraph,
    BidirectionalGraph,
    VertexListGraph,
    EdgeListGraph,
    MutableGraph,
    PropertyGraph
{
    // Matrix-based storage
}
```

**Implements:** Most protocols  
**Best for:** Dense graphs, fast edge lookup  
**Complexity:** Space O(V²), Edge lookup O(1)

### Specialized Implementations

```swift
/// Two-colored graphs
struct BipartiteAdjacencyList: BipartiteGraph { ... }

/// 2D spatial grids
struct GridGraph: Graph, IncidenceGraph { ... }

/// Computed on-demand
struct LazyIncidenceGraph: Graph, IncidenceGraph { ... }

/// Computed properties
struct ComputedVertexPropertyGraph: PropertyGraph { ... }
```

**Design pattern:** Each implementation chooses which protocols to conform to based on its capabilities.

## Algorithm Definitions (Algorithm Protocols)

**Location:** `Sources/Graphs/AlgorithmDefinitions/`

Protocols defining algorithm families:

### Shortest Path Algorithms

```swift
protocol ShortestPathAlgorithm<Graph, Weight> {
    associatedtype Graph: IncidenceGraph
    associatedtype Weight: AdditiveArithmetic & Comparable
    associatedtype Visitor
    
    func shortestPath(
        from source: Graph.VertexDescriptor,
        to destination: Graph.VertexDescriptor,
        in graph: Graph,
        visitor: Visitor?
    ) -> Path<Graph.VertexDescriptor, Graph.EdgeDescriptor>?
}
```

**Purpose:** Define interface for pathfinding algorithms

### Traversal Algorithms

```swift
protocol TraversalAlgorithm<Graph> {
    associatedtype Graph: IncidenceGraph
    associatedtype Visitor
    
    func traverse(
        from source: Graph.VertexDescriptor,
        in graph: Graph,
        visitor: Visitor?
    ) -> TraversalResult<Graph.VertexDescriptor, Graph.EdgeDescriptor>
}
```

### Search Algorithms

```swift
protocol SearchAlgorithm<Graph> {
    associatedtype Graph: IncidenceGraph
    associatedtype SearchSequence: Sequence
    associatedtype Visitor
    
    func search(
        from source: Graph.VertexDescriptor,
        in graph: Graph,
        visitor: Visitor?
    ) -> SearchSequence
}
```

### Other Algorithm Families

- `ColoringAlgorithm` - Vertex coloring strategies
- `ConnectedComponentsAlgorithm` - Component detection
- `MinimumSpanningTreeAlgorithm` - MST strategies
- `MaxFlowAlgorithm` - Flow computation
- `HamiltonianPathAlgorithm` - Hamiltonian paths/cycles
- `EulerianPathAlgorithm` - Eulerian paths/cycles

**Key insight:** Algorithm families share a common interface, implementations differ.

## Algorithm Implementations (Concrete Algorithms)

**Location:** `Sources/Graphs/AlgorithmImplementations/`

Specific algorithm implementations:

### Shortest Path Implementations

```swift
struct Dijkstra<Graph, Weight>: ShortestPathAlgorithm { ... }
struct AStar<Graph, Weight>: ShortestPathAlgorithm { ... }
struct BellmanFord<Graph, Weight>: ShortestPathAlgorithm { ... }
struct FloydWarshall<Graph, Weight>: ShortestPathAlgorithm { ... }
```

### Traversal Implementations

```swift
struct DepthFirstSearch<Graph>: TraversalAlgorithm { ... }
struct BreadthFirstSearch<Graph>: TraversalAlgorithm { ... }
struct BestFirstSearch<Graph>: SearchAlgorithm { ... }
```

### Component Detection

```swift
struct DFSConnectedComponents<Graph>: ConnectedComponentsAlgorithm { ... }
struct UnionFindConnectedComponents<Graph>: ConnectedComponentsAlgorithm { ... }
```

### MST Implementations

```swift
struct KruskalMST<Graph, Weight>: MinimumSpanningTreeAlgorithm { ... }
struct PrimMST<Graph, Weight>: MinimumSpanningTreeAlgorithm { ... }
struct BoruvkaMST<Graph, Weight>: MinimumSpanningTreeAlgorithm { ... }
```

**Design pattern:** Multiple implementations of same protocol, chosen at call site.

## Cross-Cutting Concern: Storage Backends

Storage systems are pluggable:

### Vertex Storage

```swift
protocol VertexStorage {
    associatedtype Vertex
    
    mutating func addVertex() -> Vertex
    func contains(vertex: Vertex) -> Bool
    func vertices() -> some Sequence<Vertex>
}
```

**Implementations:**
- `OrderedVertexStorage` - Sequential integer IDs
- `ArrayVertexStorage` - Array-based storage
- Custom implementations possible

### Edge Storage

```swift
protocol EdgeStorage {
    associatedtype Vertex
    associatedtype Edge
    
    mutating func addEdge(from: Vertex, to: Vertex) -> Edge
    func outgoingEdges(of vertex: Vertex) -> some Sequence<Edge>
    func destination(of edge: Edge) -> Vertex?
}
```

**Implementations:**
- `OrderedEdgeStorage` - ID-based edges
- `CacheInOutEdges` - Caches incoming edges for bidirectional access
- `BinaryEdgeStorage` - Left/right child for trees

**Composition:** Storage types can wrap each other:

```swift
// Edge storage that caches incoming edges
let edgeStore = OrderedEdgeStorage<Int>()
    .cacheInOutEdges()  // Wrap with caching layer
```

## Cross-Cutting Concern: Property Systems

Properties separate data from structure:

### Property Maps

```swift
protocol PropertyMap {
    associatedtype Key
    associatedtype Value
    
    subscript(key: Key) -> Value { get }
}

protocol MutablePropertyMap: PropertyMap {
    subscript(key: Key) -> Value { get set }
}
```

**Implementation:**
- `DictionaryPropertyMap` - Hash-based storage (default and only built-in)

**For computed properties:**
- `ComputedVertexPropertyGraph` / `ComputedEdgePropertyGraph` - Graph wrappers for on-demand computation

### Property Values

```swift
struct VertexPropertyValues {
    var label: String = ""
    var x: Double = 0.0
    var y: Double = 0.0
    var color: Int = 0
    // Extensible with custom properties
}

struct EdgePropertyValues {
    var weight: Double = 0.0
    var capacity: Double = 0.0
    var label: String = ""
    // Extensible with custom properties
}
```

**Pattern:** Properties stored externally, accessed by descriptor.

## Data Flow

### Example: Finding Shortest Path

```swift
// 1. User creates graph (concrete implementation)
var graph = AdjacencyList()
let a = graph.addVertex()
let b = graph.addVertex()
graph.addEdge(from: a, to: b) { $0.weight = 5.0 }

// 2. User calls algorithm method (protocol extension)
let path = graph.shortestPath(
    from: a,
    to: b,
    using: .dijkstra(weight: .property(\.weight))  // concrete algorithm
)

// 3. Protocol extension dispatches to algorithm
extension IncidenceGraph where Self: EdgePropertyGraph {
    func shortestPath<Algorithm: ShortestPathAlgorithm>(...) -> Path? {
        algorithm.shortestPath(from:to:in:visitor:)
    }
}

// 4. Algorithm implementation executes
struct Dijkstra: ShortestPathAlgorithm {
    func shortestPath(...) -> Path? {
        // Uses protocol operations from graph definitions:
        for edge in graph.outgoingEdges(of: current) {
            let neighbor = graph.destination(of: edge)
            // ...
        }
    }
}
```

**Flow:**
1. User → Concrete graph
2. Concrete graph → Protocol method
3. Protocol method → Algorithm protocol
4. Algorithm protocol → Concrete algorithm
5. Concrete algorithm → Protocol operations

## Benefits of This Architecture

### 1. Separation of Concerns

Each component has a single responsibility:
- **Graph Definitions:** Define what operations exist
- **Graph Implementations:** Implement storage and structure
- **Algorithm Definitions:** Define algorithm interfaces
- **Algorithm Implementations:** Implement algorithm logic

### 2. Pluggability

Swap components without changing others:

```swift
// Same algorithm, different graphs
let sparse = AdjacencyList()
let dense = AdjacencyMatrix()

sparse.shortestPath(from: a, to: b, using: .dijkstra())  // Works
dense.shortestPath(from: a, to: b, using: .dijkstra())   // Also works

// Same graph, different algorithms
graph.shortestPath(from: a, to: b, using: .dijkstra())      // Dijkstra
graph.shortestPath(from: a, to: b, using: .bellmanFord())   // Bellman-Ford
graph.shortestPath(from: a, to: b, using: .aStar())         // A*
```

### 3. Extensibility

Add new components without modifying existing code:

```swift
// Add custom graph implementation
struct MyCustomGraph: IncidenceGraph, VertexListGraph {
    // Works with ALL existing algorithms automatically!
}

// Add custom algorithm
struct MyCustomAlgorithm: ShortestPathAlgorithm {
    // Works with ALL existing graphs automatically!
}
```

### 4. Testability

Mock any component:

```swift
// Mock graph for testing algorithms
struct TestGraph: IncidenceGraph {
    var edges: [Int: [Int]]
}

// Mock algorithm for testing graph operations
struct TestAlgorithm: TraversalAlgorithm {
    var capturedCalls: [String] = []
}
```

### 5. Type Safety

Compiler enforces compatibility:

```swift
// ✅ Valid: Graph implements required protocols
graph.shortestPath(from: a, to: b, using: .dijkstra())

// ❌ Compile error: Graph doesn't implement IncidenceGraph
minimalistGraph.shortestPath(...)  // Error!
```

## Design Patterns in Action

### Strategy Pattern (Algorithms)

Choose algorithm at runtime:

```swift
let algorithm: some ShortestPathAlgorithm = hasNegativeWeights ? .bellmanFord() : .dijkstra()
let path = graph.shortestPath(from: a, to: b, using: algorithm)
```

### Adapter Pattern (Storage)

Wrap storage to add capabilities:

```swift
let storage = BasicEdgeStorage()
    .cacheInOutEdges()     // Add incoming edge cache
    .addParallelStorage()  // Add thread-safe wrapper
```

### Decorator Pattern (Properties)

Compose property maps:

```swift
let properties = DictionaryPropertyMap<Int, Properties>()
    .withComputed(\.customMetric) { /* compute */ }
```

## Directory Structure

```
Sources/Graphs/
├── GraphDefinitions/           # Layer 1
│   ├── Graph.swift
│   ├── IncidenceGraph.swift
│   ├── BidirectionalGraph.swift
│   ├── PropertyGraph.swift
│   └── ...
├── GraphImplementations/       # Layer 2
│   ├── AdjacencyList.swift
│   ├── AdjacencyMatrix.swift
│   ├── GridGraph.swift
│   └── Storage/
│       ├── VertexStorage.swift
│       └── EdgeStorage.swift
├── AlgorithmDefinitions/       # Layer 3
│   ├── ShortestPath.swift
│   ├── Traversal.swift
│   ├── Coloring.swift
│   └── ...
└── AlgorithmImplementations/   # Layer 4
    ├── ShortestPath/
    │   ├── Dijkstra.swift
    │   ├── AStar.swift
    │   └── BellmanFord.swift
    ├── Traversal/
    │   ├── BFS.swift
    │   └── DFS.swift
    └── ...
```

## Next Steps

Now that you understand the architecture:

- Learn about <doc:PluggableArchitecture> - How to swap components
- Explore <doc:AlgorithmInterfaces> - Creating custom algorithms
- Read <doc:PropertiesAndPropertyMaps> - Property system details

## See Also

- <doc:ProtocolOrientedDesign>
- <doc:PluggableArchitecture>
- <doc:AlgorithmInterfaces>
- ``Graph``
- ``IncidenceGraph``

