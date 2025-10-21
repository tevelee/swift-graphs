# Getting Started

Install Swift Graphs and create your first graph in minutes.

## Overview

This guide will walk you through installing Swift Graphs, creating your first graph, and running your first algorithm. By the end, you'll understand the basics of working with graphs in Swift.

## Installation

### Swift Package Manager

Add Swift Graphs to your `Package.swift` file:

```swift
// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "MyProject",
    dependencies: [
        .package(url: "https://github.com/tevelee/swift-graphs.git", from: "1.0.0")
    ],
    targets: [
        .target(
            name: "MyProject",
            dependencies: [
                .product(name: "Graphs", package: "swift-graphs")
            ]
        )
    ]
)
```

### Xcode

1. Open your project in Xcode
2. Go to **File → Add Package Dependencies...**
3. Enter the repository URL: `https://github.com/tevelee/swift-graphs.git`
4. Select the version or branch
5. Click **Add Package**

## Your First Graph

Let's create a simple graph representing a social network:

```swift
import Graphs

// Step 1: Create a graph
var socialNetwork = AdjacencyList()

// Step 2: Add vertices (people)
let alice = socialNetwork.addVertex { $0.label = "Alice" }
let bob = socialNetwork.addVertex { $0.label = "Bob" }
let carol = socialNetwork.addVertex { $0.label = "Carol" }
let dave = socialNetwork.addVertex { $0.label = "Dave" }

// Step 3: Add edges (friendships)
socialNetwork.addEdge(from: alice, to: bob)
socialNetwork.addEdge(from: alice, to: carol)
socialNetwork.addEdge(from: bob, to: dave)
socialNetwork.addEdge(from: carol, to: dave)

print("Social network has \(socialNetwork.vertexCount) people")
print("and \(socialNetwork.edgeCount) friendships")
```

### Understanding the Code

1. **`AdjacencyList()`** - Creates a new graph using adjacency list representation (most common)
2. **`addVertex { $0.label = "Alice" }`** - Adds a vertex with properties (label in this case)
3. **`addEdge(from:to:)`** - Creates a connection between two vertices
4. **Descriptors** - Variables like `alice` are vertex descriptors, used to reference vertices

## Adding Properties

Vertices and edges can have properties (data associated with them):

```swift
var cityMap = AdjacencyList()

// Add cities with coordinates
let sanFrancisco = cityMap.addVertex {
    $0.label = "San Francisco"
    $0.x = 37.7749
    $0.y = -122.4194
}

let losAngeles = cityMap.addVertex {
    $0.label = "Los Angeles"
    $0.x = 34.0522
    $0.y = -118.2437
}

// Add road with distance
cityMap.addEdge(from: sanFrancisco, to: losAngeles) {
    $0.weight = 383.0  // miles
}

// Access properties
print(cityMap[sanFrancisco].label)  // "San Francisco"
```

### Default Properties

Swift Graphs provides common properties out of the box:

**Vertex Properties:**
- `label: String` - Human-readable name
- `x, y, z: Double` - Spatial coordinates
- `color: Int` - For coloring algorithms

**Edge Properties:**
- `weight: Double` - Edge cost/distance
- `capacity: Double` - For flow algorithms
- `label: String` - Edge description

## Running Your First Algorithm

Let's find the shortest path in our city map:

```swift
// Find shortest path using Dijkstra's algorithm
if let path = cityMap.shortestPath(
    from: sanFrancisco,
    to: losAngeles,
    using: .dijkstra(weight: .property(\.weight))
) {
    print("Distance: \(path.edges.count) segments")
    
    // Print the route
    for vertex in path.vertices {
        print("→ \(cityMap[vertex].label)")
    }
}
```

### Algorithm Selection

Swift Graphs uses a **strategy pattern** - you choose the algorithm at the call site:

```swift
// Dijkstra for non-negative weights (fastest)
.dijkstra(weight: .property(\.weight))

// A* with heuristic (for spatial graphs)
.aStar(weight: .property(\.weight), heuristic: .euclidean)

// Bellman-Ford for negative weights
.bellmanFord(weight: .property(\.weight))
```

## Graph Traversal

Explore a graph systematically:

```swift
// Breadth-first search
let bfsResult = socialNetwork.traverse(from: alice, using: .bfs())
print("BFS order:", bfsResult.vertices.map { socialNetwork[$0].label })

// Depth-first search
let dfsResult = socialNetwork.traverse(from: alice, using: .dfs())
print("DFS order:", dfsResult.vertices.map { socialNetwork[$0].label })
```

## Complete Example: Route Planning

Here's a complete example putting it all together:

```swift
import Graphs

// Create a transportation network
var transit = AdjacencyList()

// Add stations
let downtown = transit.addVertex { $0.label = "Downtown" }
let airport = transit.addVertex { $0.label = "Airport" }
let university = transit.addVertex { $0.label = "University" }
let mall = transit.addVertex { $0.label = "Shopping Mall" }
let beach = transit.addVertex { $0.label = "Beach" }

// Add routes with travel times (in minutes)
transit.addEdge(from: downtown, to: airport) { $0.weight = 25.0 }
transit.addEdge(from: downtown, to: university) { $0.weight = 15.0 }
transit.addEdge(from: downtown, to: mall) { $0.weight = 10.0 }
transit.addEdge(from: university, to: airport) { $0.weight = 20.0 }
transit.addEdge(from: mall, to: beach) { $0.weight = 20.0 }
transit.addEdge(from: airport, to: beach) { $0.weight = 35.0 }

// Find fastest route
if let route = transit.shortestPath(
    from: university,
    to: beach,
    using: .dijkstra(weight: .property(\.weight))
) {
    print("Fastest route from University to Beach:")
    
    var totalTime = 0.0
    for (index, vertex) in route.vertices.enumerated() {
        if index < route.edges.count {
            let edge = route.edges[index]
            let time = transit[edge].weight
            totalTime += time
            
            print("  \(transit[vertex].label) →[\(time) min]")
        } else {
            print("  \(transit[vertex].label)")
        }
    }
    
    print("Total travel time: \(totalTime) minutes")
}
```

Output:
```
Fastest route from University to Beach:
  University →[20.0 min]
  Airport →[35.0 min]
  Beach
Total travel time: 55.0 minutes
```

## What's Next?

Now that you've created your first graph, explore these topics:

### Learn Core Concepts

- <doc:Concepts/GraphConcepts>
- <doc:Concepts/ProtocolOrientedDesign>
- <doc:Concepts/PropertiesAndPropertyMaps>

### Choose the Right Graph Type

- <doc:Concepts/ChoosingGraphType>

### Explore Algorithms

- <doc:AlgorithmsCatalog>

### Advanced Topics

- <doc:Concepts/AlgorithmInterfaces>
- <doc:Concepts/VisitorPattern>
- <doc:Concepts/PluggableArchitecture>

## Common Patterns

### Building from Edge List

```swift
var graph = AdjacencyList()

// Add all vertices first
let vertices = ["A", "B", "C", "D"].map { label in
    graph.addVertex { $0.label = label }
}

// Then add edges
let edges = [
    (0, 1), (1, 2), (2, 3), (3, 0)  // Indices into vertices array
]

for (from, to) in edges {
    graph.addEdge(from: vertices[from], to: vertices[to])
}
```

### Querying Graph Properties

```swift
// Check if graph is connected
let components = graph.connectedComponents()
if components.componentCount == 1 {
    print("Graph is connected")
}

// Check vertex degree
let degree = graph.degree(of: alice)
print("Alice has \(degree) connections")

// Find all neighbors
let neighbors = graph.successors(of: alice)
for neighbor in neighbors {
    print("  → \(graph[neighbor].label)")
}
```

### Working with Weighted Graphs

```swift
// Uniform weights (all edges have same cost)
let path = graph.shortestPath(
    from: start,
    to: goal,
    using: .dijkstra(weight: .uniform(1.0))
)

// Custom weight calculation
let path = graph.shortestPath(
    from: start,
    to: goal,
    using: .dijkstra(weight: .init { edge, graph in
        // Custom logic
        return graph[edge].weight * 1.5
    })
)
```

## Tips for Success

1. **Start with `AdjacencyList`** - It works well for most use cases
2. **Use descriptive labels** - Makes debugging easier
3. **Choose algorithms wisely** - Different algorithms for different constraints
4. **Leverage properties** - Store application-specific data in vertex/edge properties
5. **Explore the protocol hierarchy** - Understanding protocols helps you use the library effectively

## Getting Help

- Read the <doc:Concepts/GraphConcepts> for deeper understanding
- Check the algorithm documentation for usage examples
- Review the test suite in the repository for more examples

Ready to dive deeper? Continue with <doc:Concepts/GraphConcepts>.
