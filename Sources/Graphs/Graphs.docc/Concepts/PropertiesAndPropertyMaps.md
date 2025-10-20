# Properties and Property Maps

Learn how to associate data with vertices and edges using the property system.

## Overview

Swift Graphs separates **graph structure** (connectivity) from **graph data** (attributes). The property system allows you to attach arbitrary data to vertices and edges without modifying the graph structure itself.

## Why Separate Structure from Data?

### The Problem

Traditional approaches mix structure and data:

```swift
// ❌ Tightly coupled
struct Vertex {
    var neighbors: [Vertex]  // Structure
    var label: String        // Data
    var weight: Double       // Data
    var customData: MyType   // Data
}
```

**Problems:**
- Can't change data without affecting structure
- All vertices must have same properties
- Hard to add temporary data for algorithms
- Memory wasted on unused properties

### The Solution

Swift Graphs uses **external properties**:

```swift
// ✅ Separated concerns
struct Graph {
    // Structure only
    var vertices: Set<VertexID>
    var edges: [(VertexID, VertexID)]
}

// Data separate
var properties: PropertyMap<VertexID, Properties>
properties[vertex].label = "Node A"
```

**Benefits:**
- Structure independent of data
- Different property sets for different uses
- Add temporary properties without modifying graph
- Memory efficient (store only what you need)

## Built-In Properties

Swift Graphs provides common properties out of the box:

### Vertex Properties

```swift
struct VertexPropertyValues {
    var label: String = ""        // Human-readable name
    var x: Double = 0.0           // Spatial coordinate
    var y: Double = 0.0           // Spatial coordinate
    var z: Double = 0.0           // 3D coordinate
    var color: Int = 0            // Color assignment
}
```

**Usage:**

```swift
let vertex = graph.addVertex { properties in
    properties.label = "City A"
    properties.x = 37.7749
    properties.y = -122.4194
}

// Access properties
print(graph[vertex].label)  // "City A"
```

### Edge Properties

```swift
struct EdgePropertyValues {
    var weight: Double = 0.0      // Cost, distance, time
    var capacity: Double = 0.0    // Max flow capacity
    var label: String = ""        // Description
}
```

**Usage:**

```swift
graph.addEdge(from: a, to: b) { properties in
    properties.weight = 5.0
    properties.label = "Highway 101"
}

// Access properties
let edge = graph.edges().first!
print(graph[edge].weight)  // 5.0
```

## Property Maps

The `PropertyMap` protocol defines how properties are stored:

### The Protocol

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

### Built-In Implementation

#### `DictionaryPropertyMap`

Hash-based storage:

```swift
var properties = DictionaryPropertyMap<Int, VertexPropertyValues>(
    defaultValue: VertexPropertyValues()
)

properties[0].label = "Vertex 0"
properties[1].label = "Vertex 1"
```

**Characteristics:**
- O(1) average access
- Sparse storage (only non-default values)
- Default implementation
- Used internally by all standard graph types

## Custom Properties

Extend property types with your own data using the type-safe property system:

### Defining Custom Properties (Recommended)

Define property types that conform to `VertexProperty` or `EdgeProperty`:

```swift
// Define a custom vertex property type
enum Population: VertexProperty {
    static let defaultValue = 0
}

enum IsCapital: VertexProperty {
    static let defaultValue = false
}

// Extend VertexPropertyValues for convenient access
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

// Use with full type safety
graph[city].population = 883305
graph[city].isCapital = true

// Or access directly by type
graph[city][Population.self] = 883305
graph[city][IsCapital.self] = true
```

**Pros:** Type-safe, compile-time checking, default values  
**Cons:** Requires property type definition

### Edge Properties

Same pattern for edges:

```swift
enum TrafficLevel: EdgeProperty {
    static let defaultValue = 0.0
}

extension EdgePropertyValues {
    var trafficLevel: Double {
        get { self[TrafficLevel.self] }
        set { self[TrafficLevel.self] = newValue }
    }
}

// Use
graph[edge].trafficLevel = 0.8
```

### Alternative: Custom Property Struct (Advanced)

Define your own property type:

```swift
struct CityProperties {
    var name: String = ""
    var population: Int = 0
    var latitude: Double = 0.0
    var longitude: Double = 0.0
    var isCapital: Bool = false
}

// Use with custom graph
typealias CityGraph = AdjacencyList<
    OrderedVertexStorage,
    CacheInOutEdges<OrderedEdgeStorage<Int>>,
    DictionaryPropertyMap<Int, CityProperties>,  // Custom!
    DictionaryPropertyMap<Int, EdgePropertyValues>
>

var cities = CityGraph(
    vertexStore: OrderedVertexStorage(),
    edgeStore: OrderedEdgeStorage<Int>().cacheInOutEdges(),
    vertexPropertyMap: .init(defaultValue: CityProperties()),
    edgePropertyMap: .init(defaultValue: EdgePropertyValues())
)

// Use with full type safety
let sf = cities.addVertex { $0.population = 883305 }
print(cities[sf].population)  // Fully typed!
```

**Pros:** Complete type safety, best performance  
**Cons:** More setup, less flexible

## Computed Properties

For properties that should be computed on-demand rather than stored, use graph wrappers:

```swift
// Define a computed property type
enum Degree: VertexProperty {
    static let defaultValue = 0
}

// Wrap graph with computed property
let graphWithDegree = graph.withVertexProperty(for: Degree.self) { vertex, graph in
    graph.degree(of: vertex)
}

// Access computed property
print(graphWithDegree[vertex][Degree.self])  // Computed on access
```

### Use Cases for Computed Properties

**1. Derived values:**

```swift
enum Centrality: VertexProperty {
    static let defaultValue = 0.0
}

let graphWithCentrality = graph.withVertexProperty(for: Centrality.self) { vertex, graph in
    Double(graph.degree(of: vertex)) / Double(graph.vertexCount - 1)
}
```

**2. Expensive computations:**

```swift
enum PageRank: VertexProperty {
    static let defaultValue = 0.0
}

let graphWithPageRank = graph.withVertexProperty(for: PageRank.self) { vertex, graph in
    computePageRank(for: vertex, in: graph)
}
```

**Note:** `ComputedVertexPropertyGraph` and `ComputedEdgePropertyGraph` are graph wrappers, not standalone property maps.

## Property Access Patterns

### Direct Access

```swift
// Read property
let name = graph[vertex].label

// Write property
graph[vertex].label = "Updated"
```

### Batch Access

```swift
// Update multiple properties
for vertex in graph.vertices() {
    graph[vertex].color = computeColor(vertex)
}
```

### Conditional Access

```swift
// Access only if condition met
for vertex in graph.vertices() where graph[vertex].population > 1_000_000 {
    print("Large city: \(graph[vertex].label)")
}
```

### Querying by Property

```swift
// Find vertices matching criteria
let capitals = graph.vertices().filter { vertex in
    graph[vertex].isCapital
}
```

## Advanced Patterns

### Multiple Property Sets

Different properties for different purposes:

```swift
var graph = AdjacencyList()

// Visual properties
var visualProps: [VertexID: VisualProperties] = [:]
visualProps[v] = VisualProperties(color: .red, size: 10)

// Semantic properties
var semanticProps: [VertexID: SemanticProperties] = [:]
semanticProps[v] = SemanticProperties(category: "Type A")

// Algorithm workspace
var algorithmProps: [VertexID: AlgorithmData] = [:]
algorithmProps[v] = AlgorithmData(distance: .infinity)
```

**Use case:** Different views of same graph.

### Computed Properties

Properties can be computed from other properties:

```swift
enum DisplayLabel: VertexProperty {
    static let defaultValue = ""
}

extension VertexPropertyValues {
    var displayLabel: String {
        get {
            if !label.isEmpty {
                return label
            }
            return "Vertex \(x), \(y)"  // Fallback computed from coordinates
        }
    }
}
```

### Lazy Property Initialization

Initialize properties only when needed:

```swift
class LazyPropertyMap<Key: Hashable, Value> {
    private var storage: [Key: Value] = [:]
    private let factory: () -> Value
    
    subscript(key: Key) -> Value {
        get {
            if let existing = storage[key] {
                return existing
            }
            let value = factory()
            storage[key] = value
            return value
        }
        set {
            storage[key] = newValue
        }
    }
}
```

## Property Maps for Algorithms

Algorithms often use properties:

### Distance Map (Dijkstra)

```swift
// Store distances externally
var distances: [VertexID: Double] = [:]

for vertex in graph.vertices() {
    distances[vertex] = .infinity
}
distances[source] = 0

// Update during algorithm
for edge in graph.outgoingEdges(of: current) {
    let neighbor = graph.destination(of: edge)!
    let newDist = distances[current]! + graph[edge].weight
    
    if newDist < distances[neighbor]! {
        distances[neighbor] = newDist
    }
}
```

### Color Map (Graph Coloring)

```swift
// Store vertex colors
var colors: [VertexID: Int] = [:]

for vertex in graph.vertices() {
    // Find unused color
    var usedColors: Set<Int> = []
    for neighbor in graph.successors(of: vertex) {
        if let color = colors[neighbor] {
            usedColors.insert(color)
        }
    }
    
    // Assign first unused color
    var color = 0
    while usedColors.contains(color) {
        color += 1
    }
    colors[vertex] = color
}
```

### Predecessor Map (Path Reconstruction)

```swift
// Store predecessors for path reconstruction
var predecessors: [VertexID: VertexID] = [:]

// Build during traversal
for edge in graph.outgoingEdges(of: current) {
    let neighbor = graph.destination(of: edge)!
    predecessors[neighbor] = current
}

// Reconstruct path
func reconstructPath(to vertex: VertexID) -> [VertexID] {
    var path: [VertexID] = [vertex]
    var current = vertex
    
    while let pred = predecessors[current] {
        path.insert(pred, at: 0)
        current = pred
    }
    
    return path
}
```

## Performance Considerations

### Memory Usage

```swift
// DictionaryPropertyMap: Only stores non-default values
var properties = DictionaryPropertyMap<Int, Properties>(defaultValue: .init())
// Memory: O(# of modified vertices) - sparse storage
```

### Access Speed

```swift
// DictionaryPropertyMap: O(1) average
let value = graph[vertex].label

// Computed properties: O(computation cost)
let degree = graphWithDegree[vertex][Degree.self]  // Recomputes each time
```

### Optimization Tips

1. **Use DictionaryPropertyMap** - The default is efficient for most cases
2. **Cache computed properties** - Store results if accessed frequently
3. **Batch operations** - Update multiple properties together
4. **Clean up temporary properties** - Remove algorithm workspace after use

## Common Patterns

### Temporary Algorithm State

```swift
func runAlgorithm(on graph: AdjacencyList) {
    // Temporary properties for algorithm
    var visited: Set<VertexID> = []
    var distances: [VertexID: Double] = [:]
    
    // Run algorithm using temporary state
    // ...
    
    // State is discarded after function returns
}
// ✅ No permanent modification to graph
```

### Persistent Metadata

```swift
// Store long-term properties in graph
for vertex in graph.vertices() {
    graph[vertex].label = loadLabel(for: vertex)
    graph[vertex].x = loadX(for: vertex)
}

// Properties persist with graph
saveGraph(graph)  // Properties saved too
```

### Property Validation

```swift
enum Population: VertexProperty {
    static let defaultValue = 0
}

extension VertexPropertyValues {
    var population: Int {
        get { self[Population.self] }
        set {
            precondition(newValue >= 0, "Population must be non-negative")
            self[Population.self] = newValue
        }
    }
}
```

## Next Steps

Now that you understand the property system:

- Learn about <doc:GraphConcepts> - Core graph concepts
- Explore <doc:PluggableArchitecture> - How property maps plug in
- Study specific algorithms - How they use properties

## See Also

- <doc:GraphConcepts>
- <doc:PluggableArchitecture>
- <doc:ChoosingGraphType>
- ``PropertyGraph``
- ``PropertyMap``

