# Pluggable Architecture

Learn how Swift Graphs enables swapping storage backends, property systems, and algorithms without breaking code.

## Overview

One of Swift Graphs' most powerful features is **pluggability** - the ability to swap components independently. Storage backends, property systems, and algorithms are all interchangeable through well-defined interfaces.

## What Makes Components Pluggable?

### Dependency Inversion

Components depend on **abstractions** (protocols), not concrete types:

```swift
// ❌ Tight coupling - can't swap
class Graph {
    var storage: ArrayStorage  // Hardcoded to Array
}

// ✅ Loose coupling - pluggable
struct Graph<Storage: VertexStorage> {
    var storage: Storage  // Any storage type
}
```

### Generic Parameters

Swift Graphs uses generics to allow component substitution:

```swift
struct AdjacencyList<
    VertexStore: VertexStorage,              // Pluggable ✅
    EdgeStore: EdgeStorage,                   // Pluggable ✅
    VertexPropertyMap: MutablePropertyMap,    // Pluggable ✅
    EdgePropertyMap: MutablePropertyMap       // Pluggable ✅
>
```

**Result:** Each component can be swapped independently.

## Pluggable Storage Backends

Storage determines how vertices and edges are physically stored in memory.

### Vertex Storage

The `VertexStorage` protocol defines how vertices are stored:

```swift
protocol VertexStorage {
    associatedtype Vertex: Hashable
    
    /// Add a new vertex
    mutating func addVertex() -> Vertex
    
    /// Check if vertex exists
    func contains(vertex: Vertex) -> Bool
    
    /// Iterate all vertices
    func vertices() -> some Sequence<Vertex>
    
    /// Count of vertices
    var vertexCount: Int { get }
}
```

### Built-In Vertex Storage Implementations

#### `OrderedVertexStorage`

Sequential integer IDs (most common):

```swift
struct OrderedVertexStorage: VertexStorage {
    typealias Vertex = Int
    
    private var nextID: Int = 0
    
    mutating func addVertex() -> Int {
        defer { nextID += 1 }
        return nextID
    }
}
```

**Characteristics:**
- Vertices are `Int` (0, 1, 2, ...)
- O(1) creation
- Compact memory
- **Default choice**

### Edge Storage

The `EdgeStorage` protocol defines how edges are stored:

```swift
protocol EdgeStorage {
    associatedtype Vertex: Hashable
    associatedtype Edge: Hashable
    associatedtype Edges: Sequence<Edge>
    
    /// Add an edge
    mutating func addEdge(from source: Vertex, to destination: Vertex) -> Edge
    
    /// Get outgoing edges from a vertex
    func outgoingEdges(of vertex: Vertex) -> Edges
    
    /// Get edge destination
    func destination(of edge: Edge) -> Vertex?
    
    /// Get edge source
    func source(of edge: Edge) -> Vertex?
}
```

### Built-In Edge Storage Implementations

#### `OrderedEdgeStorage`

Sequential edge IDs with adjacency lists:

```swift
struct OrderedEdgeStorage<Vertex: Hashable>: EdgeStorage {
    typealias Edge = Int
    
    private var nextID: Int = 0
    private var adjacency: [Vertex: [Edge]] = [:]
    private var edgeData: [Edge: (Vertex, Vertex)] = [:]
}
```

**Characteristics:**
- Edges are `Int` (0, 1, 2, ...)
- O(1) edge creation
- O(degree) neighbor lookup

#### `CacheInOutEdges` (Wrapper)

Adds incoming edge tracking:

```swift
struct CacheInOutEdges<Base: EdgeStorage>: EdgeStorage {
    var base: Base
    private var incomingCache: [Vertex: [Edge]] = [:]
}
```

**Usage:**

```swift
// Start with basic edge storage
let basic = OrderedEdgeStorage<Int>()

// Wrap to add incoming edge tracking
let bidirectional = basic.cacheInOutEdges()

// Use as normal
var graph = AdjacencyList(edgeStore: bidirectional)
```

**Pattern:** Wrap storage to add capabilities (Decorator pattern).

### Custom Storage Backends

Create your own storage:

```swift
/// Store vertices in a database
struct DatabaseVertexStorage: VertexStorage {
    typealias Vertex = UUID
    
    let database: Database
    
    mutating func addVertex() -> UUID {
        let id = UUID()
        database.execute("INSERT INTO vertices (id) VALUES (?)", id)
        return id
    }
    
    func contains(vertex: UUID) -> Bool {
        database.queryOne("SELECT 1 FROM vertices WHERE id = ?", vertex) != nil
    }
    
    func vertices() -> AnySequence<UUID> {
        AnySequence(database.query("SELECT id FROM vertices"))
    }
}
```

**Use case:** Graphs too large for memory, store in database.

### Composing Storage

Storage types can be composed:

```swift
// Basic storage
let storage = OrderedEdgeStorage<Int>()
    .cacheInOutEdges()           // Add incoming edge cache
    .withLocking()                // Add thread-safety
    .withMetrics()                // Add performance tracking
```

**Pattern:** Chain wrappers to add features.

## Pluggable Property Systems

Properties separate **structure** (graph topology) from **data** (vertex/edge attributes).

### Property Maps

The `PropertyMap` protocol defines how properties are stored:

```swift
protocol PropertyMap {
    associatedtype Key: Hashable
    associatedtype Value
    
    subscript(key: Key) -> Value { get }
}

protocol MutablePropertyMap: PropertyMap {
    subscript(key: Key) -> Value { get set }
}
```

### Built-In Property Map Implementations

#### `DictionaryPropertyMap`

Hash-based storage (default):

```swift
struct DictionaryPropertyMap<Key: Hashable, Value>: MutablePropertyMap {
    private var storage: [Key: Value] = [:]
    private let defaultValue: Value
    
    subscript(key: Key) -> Value {
        get { storage[key] ?? defaultValue }
        set { storage[key] = newValue }
    }
}
```

**Characteristics:**
- O(1) average access
- Sparse - only stores non-default values
- **Default and only built-in implementation**

**Used everywhere:**
```swift
var graph = AdjacencyList()  // Uses DictionaryPropertyMap internally
```

### Computed Properties via Graph Wrappers

For computed properties, use `ComputedVertexPropertyGraph` and `ComputedEdgePropertyGraph`:

```swift
// Compute vertex properties on-demand
let graphWithDegree = graph.withVertexProperty(for: Degree.self) { vertex, graph in
    graph.degree(of: vertex)
}

// Access computed property
let degree = graphWithDegree[vertex][Degree.self]
```

**These are graph wrappers, not property maps** - they wrap the base graph and provide computed properties.

### Creating Custom Property Maps

You can create custom property map implementations by conforming to `PropertyMap` or `MutablePropertyMap`:

```swift
/// Example: Array-based property map for integer keys
struct ArrayPropertyMap<Value>: MutablePropertyMap {
    typealias Key = Int
    
    private var storage: [Value]
    private let defaultValue: Value
    
    init(defaultValue: Value) {
        self.storage = []
        self.defaultValue = defaultValue
    }
    
    subscript(key: Int) -> Value {
        get { key < storage.count ? storage[key] : defaultValue }
        set {
            if key >= storage.count {
                storage.append(contentsOf: repeatElement(defaultValue, count: key - storage.count + 1))
            }
            storage[key] = newValue
        }
    }
}
```

**Use case:** When vertex/edge IDs are sequential integers, array-based storage can be more efficient than dictionary-based.

## Pluggable Algorithms

Algorithms are selected at the call site through the **strategy pattern**.

### Algorithm Selection

Choose algorithm when calling:

```swift
// Choose Dijkstra
let path = graph.shortestPath(from: a, to: b, using: .dijkstra(weight: .property(\.weight)))

// Choose A* with heuristic
let path = graph.shortestPath(from: a, to: b, using: .aStar(
    weight: .property(\.weight),
    heuristic: .manhattanDistance
))

// Choose Bellman-Ford for negative weights
let path = graph.shortestPath(from: a, to: b, using: .bellmanFord(weight: .property(\.weight)))
```

### Multiple Implementations, Same Interface

All implementations conform to the same protocol:

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

// Different implementations
struct Dijkstra: ShortestPathAlgorithm { ... }
struct AStar: ShortestPathAlgorithm { ... }
struct BellmanFord: ShortestPathAlgorithm { ... }
```

**Benefit:** Swap algorithms without changing calling code.

### Custom Algorithms

Implement your own:

```swift
/// Custom bidirectional Dijkstra
struct BidirectionalDijkstra<G: BidirectionalGraph, W: Numeric & Comparable>: ShortestPathAlgorithm {
    typealias Graph = G
    typealias Weight = W
    typealias Visitor = DijkstraVisitor<G>
    
    let weight: CostDefinition<G, W>
    
    func shortestPath(
        from source: G.VertexDescriptor,
        to destination: G.VertexDescriptor,
        in graph: G,
        visitor: Visitor?
    ) -> Path<G.VertexDescriptor, G.EdgeDescriptor>? {
        // Search from both ends simultaneously
        var forwardFrontier = PriorityQueue<(G.VertexDescriptor, W)>()
        var backwardFrontier = PriorityQueue<(G.VertexDescriptor, W)>()
        
        // ... implementation ...
    }
}

// Use it
let path = graph.shortestPath(from: a, to: b, using: BidirectionalDijkstra(weight: .property(\.weight)))
```

**Works automatically** with all compatible graphs!

## Composition Examples

### Custom Graph with Custom Storage

```swift
// Custom sparse graph using database storage
typealias DatabaseGraph = AdjacencyList<
    DatabaseVertexStorage,           // Custom vertex storage
    OrderedEdgeStorage<UUID>,         // Standard edge storage (but with UUIDs)
    DictionaryPropertyMap<UUID, VertexPropertyValues>,
    DictionaryPropertyMap<Int, EdgePropertyValues>
>

let graph = DatabaseGraph(
    vertexStore: DatabaseVertexStorage(database: myDB),
    edgeStore: OrderedEdgeStorage<UUID>(),
    vertexPropertyMap: DictionaryPropertyMap(defaultValue: .init()),
    edgePropertyMap: DictionaryPropertyMap(defaultValue: .init())
)

// Works with all algorithms!
let path = graph.shortestPath(from: uuid1, to: uuid2, using: .dijkstra())
```

### Graph with Computed Properties

```swift
// Use graph wrappers for computed properties
let baseGraph = AdjacencyList()  // Add vertices and edges

// Wrap with computed label property
enum ComputedLabel: VertexProperty {
    static let defaultValue = ""
}

let graphWithLabels = baseGraph.withVertexProperty(for: ComputedLabel.self) { vertex, graph in
    "Vertex \(vertex)"
}

// Access computed property
print(graphWithLabels[vertex][ComputedLabel.self])  // "Vertex 0"
```

### In-Memory vs. Persistent Graph

Same interface, different storage:

```swift
// Development: Fast in-memory graph
typealias DevGraph = AdjacencyList<
    OrderedVertexStorage,
    OrderedEdgeStorage<Int>.CacheInOutEdges,
    DictionaryPropertyMap<Int, VertexPropertyValues>,
    DictionaryPropertyMap<Int, EdgePropertyValues>
>

// Production: Persistent database-backed graph
typealias ProdGraph = AdjacencyList<
    DatabaseVertexStorage,
    DatabaseEdgeStorage,
    DatabasePropertyMap<UUID, VertexPropertyValues>,
    DatabasePropertyMap<UUID, EdgePropertyValues>
>

// Same algorithm code works with both!
func findPath<G: IncidenceGraph>(in graph: G, from: G.VertexDescriptor, to: G.VertexDescriptor) {
    graph.shortestPath(from: from, to: to, using: .dijkstra())
}
```

## Benefits of Pluggability

### 1. Flexibility

Choose components based on requirements:

```swift
// Small graph - simple storage
let small = AdjacencyList()  // Default storage

// Large graph - database backend
let large = AdjacencyList(
    vertexStore: DatabaseVertexStorage(db),
    edgeStore: DatabaseEdgeStorage(db),
    // ...
)

// Bidirectional algorithms - cached incoming edges
let bidirectional = AdjacencyList(
    edgeStore: OrderedEdgeStorage().cacheInOutEdges()
)
```

### 2. Performance Optimization

Swap implementations for performance:

```swift
// Sparse graph - adjacency list (O(V+E) space)
let sparse = AdjacencyList()

// Dense graph - adjacency matrix (O(V²) space, O(1) edge lookup)
let dense = AdjacencyMatrix()

// Same algorithm code, different performance characteristics
```

### 3. Testing

Mock components for testing:

```swift
struct MockVertexStorage: VertexStorage {
    var addVertexCalls: Int = 0
    
    mutating func addVertex() -> Int {
        addVertexCalls += 1
        return 0
    }
}

// Test with mock
var mockStorage = MockVertexStorage()
// ... test code ...
XCTAssertEqual(mockStorage.addVertexCalls, 5)
```

### 4. Extensibility

Add new components without modifying library:

```swift
// Your custom storage
struct MyStorage: VertexStorage { ... }

// Works with existing graph implementations!
let graph = AdjacencyList(vertexStore: MyStorage(), ...)
```

## Common Patterns

### Factory Methods

Convenient constructors for common configurations:

```swift
extension AdjacencyList where
    VertexStore == OrderedVertexStorage,
    EdgeStore == CacheInOutEdges<OrderedEdgeStorage<Int>>
{
    /// Create bidirectional adjacency list
    static func bidirectional() -> Self {
        Self(edgeStore: OrderedEdgeStorage().cacheInOutEdges())
    }
}

// Usage
let graph = AdjacencyList.bidirectional()
```

### Type Aliases

Simplify common combinations:

```swift
/// Standard undirected graph
typealias UndirectedGraph = AdjacencyList<
    OrderedVertexStorage,
    CacheInOutEdges<OrderedEdgeStorage<Int>>,
    DictionaryPropertyMap<Int, VertexPropertyValues>,
    DictionaryPropertyMap<Int, EdgePropertyValues>
>

// Usage
var graph = UndirectedGraph()
```

## Design Guidelines

### When to Use Pluggability

**Use when:**
- Multiple implementations are useful (storage backends, algorithms)
- Performance trade-offs exist (sparse vs. dense)
- Testing requires mocking
- Users might extend with custom implementations

**Don't use when:**
- Only one implementation makes sense
- Abstraction adds complexity without benefit
- Performance cost of indirection is significant

### Designing Pluggable Components

1. **Define minimal protocol** - Only essential operations
2. **Use associated types** - Allow implementation flexibility
3. **Provide defaults** - Common configurations should be easy
4. **Document requirements** - Complexity, thread-safety, etc.
5. **Test with multiple implementations** - Ensure protocol is sufficient

## Next Steps

Now that you understand pluggability:

- Learn about <doc:AlgorithmInterfaces> - Creating custom algorithms
- Explore <doc:PropertiesAndPropertyMaps> - Property system in depth
- Study <doc:Architecture> - How components fit together

## See Also

- <doc:Architecture>
- <doc:AlgorithmInterfaces>
- <doc:PropertiesAndPropertyMaps>
- ``AdjacencyList``
- ``PropertyMap``

