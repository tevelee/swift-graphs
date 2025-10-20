# Visitor Pattern

Learn how to observe and customize algorithm execution using the visitor pattern.

## Overview

The **visitor pattern** allows you to observe algorithm execution without modifying the algorithm itself. Inspired by the Boost Graph Library (BGL), Swift Graphs uses visitors to provide hooks into algorithm behavior for debugging, statistics collection, early termination, and custom behavior.

## What is the Visitor Pattern?

### The Problem

You want to:
- See what an algorithm is doing (debugging)
- Collect statistics (vertices visited, edges examined)
- Terminate early when a condition is met
- Inject custom behavior at specific points

**Without visitors:**
- Modify algorithm source code (breaks library)
- Copy algorithm and customize (duplication)
- Add flags/callbacks (messy API)

**With visitors:**
- Pass visitor object
- Algorithm calls visitor methods at key points
- Zero impact when not used

### The Solution

```swift
// Algorithm provides hooks
protocol TraversalAlgorithm {
    associatedtype Visitor
    
    func traverse(from source: VertexDescriptor, visitor: Visitor?) {
        visitor?.startVertex(source)  // Hook
        
        for edge in graph.outgoingEdges(of: source) {
            visitor?.examineEdge(edge)  // Hook
            
            let neighbor = graph.destination(of: edge)
            visitor?.discoverVertex(neighbor)  // Hook
        }
        
        visitor?.finishVertex(source)  // Hook
    }
}

// You provide implementations
struct MyVisitor {
    func startVertex(_ v: VertexDescriptor) {
        print("Starting from \(v)")
    }
    
    func discoverVertex(_ v: VertexDescriptor) {
        print("Discovered \(v)")
    }
}
```

## Event Hooks

Different algorithms provide different hooks:

### BFS/DFS Visitor Events

```swift
struct DFSVisitor<Graph: IncidenceGraph> {
    /// Called when algorithm starts processing a vertex
    var startVertex: ((Graph.VertexDescriptor) -> Void)?
    
    /// Called when a vertex is first discovered
    var discoverVertex: ((Graph.VertexDescriptor) -> Void)?
    
    /// Called when examining a vertex (before processing neighbors)
    var examineVertex: ((Graph.VertexDescriptor) -> Void)?
    
    /// Called when examining an edge
    var examineEdge: ((Graph.EdgeDescriptor) -> Void)?
    
    /// Called when a tree edge is identified
    var treeEdge: ((Graph.EdgeDescriptor) -> Void)?
    
    /// Called when a back edge is found (cycle detected)
    var backEdge: ((Graph.EdgeDescriptor) -> Void)?
    
    /// Called when a forward/cross edge is found
    var forwardOrCrossEdge: ((Graph.EdgeDescriptor) -> Void)?
    
    /// Called when finished processing a vertex
    var finishVertex: ((Graph.VertexDescriptor) -> Void)?
}
```

### Dijkstra Visitor Events

```swift
struct DijkstraVisitor<Graph: IncidenceGraph> {
    /// Called when algorithm starts
    var initializeVertex: ((Graph.VertexDescriptor) -> Void)?
    
    /// Called when discovering a vertex
    var discoverVertex: ((Graph.VertexDescriptor) -> Void)?
    
    /// Called when examining a vertex
    var examineVertex: ((Graph.VertexDescriptor) -> Void)?
    
    /// Called when examining an edge
    var examineEdge: ((Graph.EdgeDescriptor) -> Void)?
    
    /// Called when edge is not relaxed
    var edgeNotRelaxed: ((Graph.EdgeDescriptor) -> Void)?
    
    /// Called when edge is relaxed (shorter path found)
    var edgeRelaxed: ((Graph.EdgeDescriptor) -> Void)?
    
    /// Called when finished processing a vertex
    var finishVertex: ((Graph.VertexDescriptor) -> Void)?
}
```

## Basic Usage

### Creating a Visitor

```swift
import Graphs

var graph = AdjacencyList()
let a = graph.addVertex { $0.label = "A" }
let b = graph.addVertex { $0.label = "B" }
let c = graph.addVertex { $0.label = "C" }

graph.addEdge(from: a, to: b)
graph.addEdge(from: b, to: c)

// Create visitor
var visitedVertices: [String] = []

let result = graph.traverse(
    from: a,
    using: .bfs().withVisitor(.init(
        discoverVertex: { vertex in
            visitedVertices.append(graph[vertex].label)
        }
    ))
)

print(visitedVertices)  // ["A", "B", "C"]
```

### Multiple Event Hooks

```swift
var discoveries: [String] = []
var examinations: [String] = []

graph.traverse(
    from: a,
    using: .dfs().withVisitor(.init(
        discoverVertex: { v in
            discoveries.append(graph[v].label)
        },
        examineVertex: { v in
            examinations.append(graph[v].label)
        },
        finishVertex: { v in
            print("Finished: \(graph[v].label)")
        }
    ))
)
```

## Composing Visitors

Visitors can be chained to combine behavior:

### Multiple Visitors

```swift
let path = graph.shortestPath(
    from: start,
    to: goal,
    using: .dijkstra(weight: .property(\.weight))
        .withVisitor(.init(
            examineVertex: { v in print("Examining \(v)") }
        ))
        .withVisitor(.init(
            edgeRelaxed: { e in print("Relaxed edge \(e)") }
        ))
)
```

**Both visitors receive events!**

### Building Composite Visitors

```swift
struct CompositeVisitor<Graph: IncidenceGraph> {
    var visitors: [DFSVisitor<Graph>]
    
    func discoverVertex(_ v: Graph.VertexDescriptor) {
        for visitor in visitors {
            visitor.discoverVertex?(v)
        }
    }
    
    func examineVertex(_ v: Graph.VertexDescriptor) {
        for visitor in visitors {
            visitor.examineVertex?(v)
        }
    }
}
```

## Common Use Cases

### 1. Debugging - See Algorithm Execution

```swift
// Print every step of DFS
graph.traverse(
    from: start,
    using: .dfs().withVisitor(.init(
        startVertex: { v in print("Start: \(v)") },
        discoverVertex: { v in print("  Discover: \(v)") },
        examineEdge: { e in print("    Examine edge: \(e)") },
        treeEdge: { e in print("      Tree edge: \(e)") },
        backEdge: { e in print("      Back edge (cycle!): \(e)") },
        finishVertex: { v in print("  Finish: \(v)") }
    ))
)
```

### 2. Collecting Statistics

```swift
// Count vertices and edges visited
struct Stats {
    var verticesVisited = 0
    var edgesExamined = 0
}

var stats = Stats()

graph.shortestPath(
    from: start,
    to: goal,
    using: .dijkstra(weight: .property(\.weight))
        .withVisitor(.init(
            examineVertex: { _ in stats.verticesVisited += 1 },
            examineEdge: { _ in stats.edgesExamined += 1 }
        ))
)

print("Visited \(stats.verticesVisited) vertices")
print("Examined \(stats.edgesExamined) edges")
```

### 3. Early Termination

```swift
// Stop search when target found
var found = false

for vertex in graph.search(from: start, using: .bfs()) {
    if vertex == target {
        found = true
        break  // Early termination!
    }
}
```

### 4. Cycle Detection

```swift
// Detect cycles using back edge detection
var hasCycle = false

graph.traverse(
    from: start,
    using: .dfs().withVisitor(.init(
        backEdge: { _ in
            hasCycle = true
        }
    ))
)

print("Graph has cycle: \(hasCycle)")
```

### 5. Building Data Structures

```swift
// Build predecessor map for path reconstruction
var predecessors: [VertexID: VertexID] = [:]

graph.traverse(
    from: start,
    using: .bfs().withVisitor(.init(
        treeEdge: { edge in
            if let source = graph.source(of: edge),
               let dest = graph.destination(of: edge) {
                predecessors[dest] = source
            }
        }
    ))
)

// Reconstruct path using predecessors
func reconstructPath(to vertex: VertexID) -> [VertexID] {
    var path: [VertexID] = []
    var current: VertexID? = vertex
    
    while let v = current {
        path.append(v)
        current = predecessors[v]
    }
    
    return path.reversed()
}
```

### 6. Custom Metrics

```swift
// Track depth and branching factor
var depths: [VertexID: Int] = [start: 0]
var branchingFactors: [Int] = []

graph.traverse(
    from: start,
    using: .bfs().withVisitor(.init(
        examineVertex: { vertex in
            let degree = graph.outDegree(of: vertex)
            branchingFactors.append(degree)
        },
        treeEdge: { edge in
            if let source = graph.source(of: edge),
               let dest = graph.destination(of: edge),
               let sourceDepth = depths[source] {
                depths[dest] = sourceDepth + 1
            }
        }
    ))
)

let avgBranching = Double(branchingFactors.reduce(0, +)) / Double(branchingFactors.count)
print("Average branching factor: \(avgBranching)")
```

## Advanced Patterns

### State-Carrying Visitors

Visitors can maintain state:

```swift
class PathRecorder<Graph: IncidenceGraph> {
    var paths: [[Graph.VertexDescriptor]] = []
    var currentPath: [Graph.VertexDescriptor] = []
    
    lazy var visitor: DFSVisitor<Graph> = .init(
        discoverVertex: { [weak self] v in
            self?.currentPath.append(v)
        },
        finishVertex: { [weak self] v in
            self?.currentPath.removeLast()
        }
    )
}

let recorder = PathRecorder<AdjacencyList>()
graph.traverse(from: start, using: .dfs().withVisitor(recorder.visitor))
```

### Conditional Visitors

Apply logic based on graph state:

```swift
let visitor = DFSVisitor<AdjacencyList>(
    examineVertex: { vertex in
        let degree = graph.outDegree(of: vertex)
        
        if degree > 10 {
            print("Hub vertex: \(vertex)")
        } else if degree == 1 {
            print("Leaf vertex: \(vertex)")
        }
    }
)
```

### Visitor with Custom Types

```swift
struct TimestampVisitor<Graph: IncidenceGraph> {
    var startTimes: [Graph.VertexDescriptor: Date] = [:]
    var endTimes: [Graph.VertexDescriptor: Date] = [:]
    
    var visitor: DFSVisitor<Graph> {
        .init(
            discoverVertex: { [self] v in
                var mutableSelf = self
                mutableSelf.startTimes[v] = Date()
            },
            finishVertex: { [self] v in
                var mutableSelf = self
                mutableSelf.endTimes[v] = Date()
            }
        )
    }
}
```

## Performance Considerations

### Zero-Cost Abstraction

When no visitor is provided, there's no performance penalty:

```swift
// No visitor - no overhead
let result = graph.traverse(from: start, using: .bfs())

// With visitor - small overhead for closure calls
let result = graph.traverse(
    from: start,
    using: .bfs().withVisitor(.init(discoverVertex: { v in ... }))
)
```

### Minimizing Overhead

**Efficient:**

```swift
// Closure captures nothing, minimal overhead
.withVisitor(.init(
    examineVertex: { _ in count += 1 }  // Mutate local variable
))
```

**Less efficient:**

```swift
// Closure allocates/processes complex data
.withVisitor(.init(
    examineVertex: { v in
        heavyComputation(v)  // Expensive operation
    }
))
```

## Visitor Design Guidelines

### When to Use Visitors

**Use when:**
- Debugging algorithm execution
- Collecting statistics
- Early termination conditions
- Custom behavior without modifying algorithm

**Don't use when:**
- Core algorithm logic belongs there
- Performance is critical and visitor adds overhead
- Simpler alternatives exist (e.g., return values)

### Designing Custom Visitors

1. **Provide relevant events** - What points matter?
2. **Use optional closures** - Allow partial implementation
3. **Document when events fire** - Clear semantics
4. **Consider composability** - Can visitors be chained?

```swift
struct MyAlgorithmVisitor<Graph: IncidenceGraph> {
    /// Called at start of algorithm
    var begin: (() -> Void)?
    
    /// Called when processing vertex (called for every vertex)
    var examineVertex: ((Graph.VertexDescriptor) -> Void)?
    
    /// Called at end of algorithm
    var end: (() -> Void)?
}
```

## Real-World Example: Profiling

```swift
/// Profile algorithm execution
class AlgorithmProfiler<Graph: IncidenceGraph> {
    var startTime: Date?
    var endTime: Date?
    var verticesVisited = 0
    var edgesExamined = 0
    
    var visitor: DFSVisitor<Graph> {
        .init(
            startVertex: { [weak self] _ in
                self?.startTime = Date()
            },
            examineVertex: { [weak self] _ in
                self?.verticesVisited += 1
            },
            examineEdge: { [weak self] _ in
                self?.edgesExamined += 1
            },
            finishVertex: { [weak self] v in
                if self?.startTime != nil && self?.endTime == nil {
                    self?.endTime = Date()
                }
            }
        )
    }
    
    func printStats() {
        if let start = startTime, let end = endTime {
            let duration = end.timeIntervalSince(start)
            print("Duration: \(duration)s")
            print("Vertices: \(verticesVisited)")
            print("Edges: \(edgesExamined)")
            print("Edges/sec: \(Double(edgesExamined) / duration)")
        }
    }
}

// Use it
let profiler = AlgorithmProfiler<AdjacencyList>()
graph.traverse(from: start, using: .dfs().withVisitor(profiler.visitor))
profiler.printStats()
```

## Comparison with Other Patterns

| Pattern | Flexibility | Performance | Complexity |
|---------|------------|-------------|------------|
| Visitor | ✅ High | ⚠️ Good | 🔵 Medium |
| Callbacks | ⚠️ Medium | ✅ Excellent | 🟢 Low |
| Subclassing | ❌ Low | ✅ Excellent | 🔴 High |
| Return Values | ❌ Low | ✅ Excellent | 🟢 Low |

Visitors provide the best balance for observing algorithm execution.

## Next Steps

Now that you understand the visitor pattern:

- Explore <doc:AlgorithmInterfaces> - Algorithm protocols that support visitors
- Learn about specific algorithm visitors in the algorithm documentation
- Study <doc:Architecture> - How visitors fit into the overall design

## See Also

- <doc:AlgorithmInterfaces>
- <doc:PluggableArchitecture>
- <doc:Architecture>

