# Algorithm Interfaces

Learn how algorithm protocols enable the strategy pattern and how to create custom algorithms.

## Overview

Swift Graphs defines **algorithm families as protocols**. This design allows multiple implementations of the same algorithm type, selected at the call site. You can use built-in algorithms or create your own that work seamlessly with all compatible graphs.

## Algorithm Protocol Pattern

### The Core Idea

Instead of hard-coding algorithms into graphs, Swift Graphs makes algorithms:

1. **External** - Algorithms are separate types
2. **Interchangeable** - Multiple implementations of same interface
3. **Selectable** - Choose at call site
4. **Generic** - Work with any compatible graph

```swift
// ❌ Old approach: Algorithm baked into graph
class Graph {
    func dijkstra() -> Path { ... }
    func aStar() -> Path { ... }
    // Graph knows about specific algorithms
}

// ✅ Swift Graphs: Algorithm as parameter
extension IncidenceGraph {
    func shortestPath(
        using algorithm: some ShortestPathAlgorithm  // Inject strategy
    ) -> Path? {
        algorithm.shortestPath(in: self)
    }
}
```

### Benefits

- **Flexibility** - Add new algorithms without modifying graphs
- **Testability** - Mock algorithms for testing
- **Choice** - Pick best algorithm for your use case
- **Extensibility** - Users can add custom algorithms

## Common Algorithm Families

Swift Graphs defines several algorithm protocol families:

### Shortest Path Algorithms

```swift
protocol ShortestPathAlgorithm<Graph, Weight>: AlgorithmObserving {
    associatedtype Graph: IncidenceGraph
    associatedtype Weight: AdditiveArithmetic & Comparable
    associatedtype Event
    
    func shortestPath(
        from source: Graph.VertexDescriptor,
        to destination: Graph.VertexDescriptor,
        in graph: Graph,
        observation: AlgorithmObservation<Event>?
    ) -> Path<Graph.VertexDescriptor, Graph.EdgeDescriptor>?
}
```

**Implementations:**
- `Dijkstra` - Non-negative weights, O((V + E) log V)
- `AStar` - With heuristic, often faster than Dijkstra
- `BellmanFord` - Handles negative weights, O(V × E)
- `FloydWarshall` - All-pairs, O(V³)
- `Johnson` - All-pairs for sparse graphs

**Usage:**

```swift
// Choose at call site
let path = graph.shortestPath(
    from: start,
    to: goal,
    using: .dijkstra(weight: .property(\.weight))
)
```

### Traversal Algorithms

```swift
protocol TraversalAlgorithm<Graph>: AlgorithmObserving {
    associatedtype Graph: IncidenceGraph
    associatedtype Event
    
    func traverse(
        from source: Graph.VertexDescriptor,
        in graph: Graph,
        observation: AlgorithmObservation<Event>?
    ) -> TraversalResult<Graph.VertexDescriptor, Graph.EdgeDescriptor>
}
```

**Implementations:**
- `DepthFirstSearch` - DFS with preorder/postorder/inorder
- `BreadthFirstSearch` - BFS level-by-level
- `BestFirstSearch` - Priority-guided traversal

**Usage:**

```swift
let result = graph.traverse(from: start, using: .dfs(order: .preorder))
```

### Search Algorithms

```swift
protocol SearchAlgorithm<Graph>: AlgorithmObserving {
    associatedtype Graph: IncidenceGraph
    associatedtype SearchSequence: Sequence
    associatedtype Event
    
    func search(
        from source: Graph.VertexDescriptor,
        in graph: Graph,
        observation: AlgorithmObservation<Event>?
    ) -> SearchSequence
}
```

**Difference from Traversal:** Returns a **sequence** that can be iterated, allowing early termination.

**Implementations:**
- `DepthFirstSearch` - Also conforms to SearchAlgorithm
- `BreadthFirstSearch` - Also conforms to SearchAlgorithm
- `UniformCostSearch` - Cost-based exploration
- `IterativelyDeepeningDFS` - Memory-efficient depth search

**Usage:**

```swift
// Process results lazily
for vertex in graph.search(from: start, using: .bfs()) {
    if vertex == target {
        break  // Early termination
    }
}
```

### Coloring Algorithms

```swift
protocol ColoringAlgorithm<Graph, Color>: AlgorithmObserving {
    associatedtype Graph: IncidenceGraph & VertexListGraph
    associatedtype Color: Hashable & Equatable
    associatedtype Event
    
    func color(
        graph: Graph,
        observation: AlgorithmObservation<Event>?
    ) -> GraphColoring<Graph.VertexDescriptor, Color>
}
```

**Implementations:**
- `GreedyColoring` - Simple, fast
- `DSaturColoring` - Better quality, slower
- `WelshPowellColoring` - Degree-based ordering

**Usage:**

```swift
let coloring = graph.colorGraph(using: .dsatur())
print("Chromatic number: \(coloring.chromaticNumber)")
```

### Connected Components Algorithms

```swift
protocol ConnectedComponentsAlgorithm<Graph>: AlgorithmObserving {
    associatedtype Graph: IncidenceGraph & VertexListGraph
    associatedtype Event
    
    func connectedComponents(
        in graph: Graph,
        observation: AlgorithmObservation<Event>?
    ) -> ConnectedComponentsResult<Graph.VertexDescriptor>
}
```

**Implementations:**
- `DFSConnectedComponents` - DFS-based, O(V + E)
- `UnionFindConnectedComponents` - Union-Find, O(E α(V))

**Usage:**

```swift
let components = graph.connectedComponents(using: .unionFind())
```

### Articulation Points Algorithms

```swift
protocol ArticulationPointsAlgorithm<Graph>: AlgorithmObserving {
    associatedtype Graph: IncidenceGraph
    associatedtype Event

    func articulationPoints(
        in graph: Graph,
        observation: AlgorithmObservation<Event>?
    ) -> ArticulationPointsResult<Graph.VertexDescriptor, Graph.EdgeDescriptor>
}
```

**Implementations:**
- `TarjanArticulationPointsAlgorithm` - Single DFS pass, O(V + E)

**Usage:**

```swift
let result = graph.articulationPoints(using: .tarjan())
print("Cut vertices: \(result.cutVertices)")
print("Bridges: \(result.bridges)")
```

### Minimum Spanning Tree Algorithms

```swift
protocol MinimumSpanningTreeAlgorithm<Graph, Weight>: AlgorithmObserving {
    associatedtype Graph: IncidenceGraph
    associatedtype Weight: Numeric & Comparable
    associatedtype Event
    
    func minimumSpanningTree(
        in graph: Graph,
        observation: AlgorithmObservation<Event>?
    ) -> SpanningTree<Graph.VertexDescriptor, Graph.EdgeDescriptor>
}
```

**Implementations:**
- `KruskalMST` - Edge-based, good for sparse graphs
- `PrimMST` - Vertex-based, good for dense graphs
- `BoruvkaMST` - Parallel-friendly

### Minimum Cut Algorithms

```swift
protocol MinimumCutAlgorithm<Graph, Weight>: AlgorithmObserving {
    associatedtype Graph: IncidenceGraph & VertexListGraph
    associatedtype Weight: Numeric & Comparable
    associatedtype Event

    func minimumCut(
        in graph: Graph,
        observation: AlgorithmObservation<Event>?
    ) -> MinimumCutResult<Graph.VertexDescriptor, Graph.EdgeDescriptor, Weight>?
}
```

**Implementations:**
- `StoerWagner` - Maximum adjacency ordering, O(V³)

**Usage:**

```swift
let result = graph.minimumCut(using: .stoerWagner(weight: .property(\.weight)))
print("Cut weight: \(result?.cutWeight)")
print("Partition A: \(result?.partitionA)")
print("Partition B: \(result?.partitionB)")
```

## Creating Custom Algorithms

### Step 1: Define Algorithm Type

Conform to appropriate protocol:

```swift
/// Custom bidirectional Dijkstra
struct BidirectionalDijkstra<G: BidirectionalGraph, W: Numeric & Comparable>:
    ShortestPathAlgorithm
{
    typealias Graph = G
    typealias Weight = W
    enum Event {
        case vertexExamined(G.VertexDescriptor)
    }
    
    let weight: CostDefinition<G, W>
    
    init(weight: CostDefinition<G, W>) {
        self.weight = weight
    }
}
```

### Step 2: Implement Required Methods

```swift
extension BidirectionalDijkstra {
    func shortestPath(
        from source: G.VertexDescriptor,
        to destination: G.VertexDescriptor,
        in graph: G,
        observation: AlgorithmObservation<Event>?
    ) -> Path<G.VertexDescriptor, G.EdgeDescriptor>? {
        // Search from both source and destination simultaneously
        var forwardDist: [G.VertexDescriptor: W] = [source: .zero]
        var backwardDist: [G.VertexDescriptor: W] = [destination: .zero]
        
        var forwardQueue = PriorityQueue<(G.VertexDescriptor, W)>()
        var backwardQueue = PriorityQueue<(G.VertexDescriptor, W)>()
        
        forwardQueue.push((source, .zero))
        backwardQueue.push((destination, .zero))
        
        var bestPath: W? = nil
        var meetingVertex: G.VertexDescriptor? = nil
        
        while !forwardQueue.isEmpty && !backwardQueue.isEmpty {
            // Forward search step
            if let (u, distU) = forwardQueue.pop() {
                observation?.receive(.vertexExamined(u))
                
                for edge in graph.outgoingEdges(of: u) {
                    guard let v = graph.destination(of: edge) else { continue }
                    let edgeWeight = weight.costToExplore(edge, graph)
                    let newDist = distU + edgeWeight
                    
                    if forwardDist[v] == nil || newDist < forwardDist[v]! {
                        forwardDist[v] = newDist
                        forwardQueue.push((v, newDist))
                        
                        // Check if paths meet
                        if let backDist = backwardDist[v] {
                            let totalDist = newDist + backDist
                            if bestPath == nil || totalDist < bestPath! {
                                bestPath = totalDist
                                meetingVertex = v
                            }
                        }
                    }
                }
            }
            
            // Backward search step (symmetric)
            // ... similar code for backward direction ...
        }
        
        // Reconstruct path if found
        if let meeting = meetingVertex {
            return reconstructPath(forward: forwardDist, backward: backwardDist, meeting: meeting)
        }
        
        return nil
    }
}
```

### Step 3: Add Convenience Factory

```swift
extension ShortestPathAlgorithm where Self == BidirectionalDijkstra<some BidirectionalGraph, some Numeric & Comparable> {
    static func bidirectionalDijkstra<G: BidirectionalGraph, W: Numeric & Comparable>(
        weight: CostDefinition<G, W>
    ) -> BidirectionalDijkstra<G, W> {
        BidirectionalDijkstra(weight: weight)
    }
}
```

### Step 4: Use It

```swift
// Works with any bidirectional graph!
let path = graph.shortestPath(
    from: start,
    to: goal,
    using: .bidirectionalDijkstra(weight: .property(\.weight))
)
```

## Algorithm Selection Strategies

### Based on Graph Properties

```swift
func chooseShortestPathAlgorithm<G: IncidenceGraph>(
    graph: G,
    hasNegativeWeights: Bool
) -> some ShortestPathAlgorithm<G, Double> {
    if hasNegativeWeights {
        return .bellmanFord(weight: .property(\.weight))
    } else {
        return .dijkstra(weight: .property(\.weight))
    }
}
```

### Based on Performance Requirements

```swift
func chooseMSTAlgorithm<G: IncidenceGraph>(
    graph: G
) -> some MinimumSpanningTreeAlgorithm<G, Double> {
    if graph.edgeCount < graph.vertexCount * graph.vertexCount / 4 {
        // Sparse: use Kruskal
        return .kruskal(weight: .property(\.weight))
    } else {
        // Dense: use Prim
        return .prim(weight: .property(\.weight))
    }
}
```

### Based on Available Heuristics

```swift
func choosePathfinding<G: IncidenceGraph>(
    graph: G,
    hasHeuristic: Bool
) -> some ShortestPathAlgorithm<G, Double> {
    if hasHeuristic {
        return .aStar(weight: .property(\.weight), heuristic: .euclidean)
    } else {
        return .dijkstra(weight: .property(\.weight))
    }
}
```

## Advanced: Parameterized Algorithms

### Cost Definitions

Algorithms that need edge weights use `CostDefinition`:

```swift
struct CostDefinition<Graph: Graphs.Graph, Cost> {
    let costToExplore: (Graph.EdgeDescriptor, Graph) -> Cost
}
```

**Built-in factories:**

```swift
// Extract from properties
.property(\.weight)

// Uniform cost
.uniform(1.0)

// Custom computation
.init { edge, graph in
    let distance = graph[edge].weight
    let traffic = graph[edge].traffic
    return distance * traffic  // Consider traffic
}
```

### Heuristic Functions

A* and best-first search use heuristics:

```swift
struct Heuristic<Graph: Graphs.Graph, Cost> {
    let estimate: (Graph.VertexDescriptor, Graph.VertexDescriptor, Graph) -> Cost
}
```

**Built-in heuristics for spatial graphs:**

```swift
// Euclidean distance
.euclidean

// Manhattan distance
.manhattanDistance

// Chebyshev distance
.chebyshevDistance

// Custom heuristic
.init { from, to, graph in
    let fromPos = graph[from]
    let toPos = graph[to]
    return abs(fromPos.x - toPos.x) + abs(fromPos.y - toPos.y)
}
```

## Observation Integration

Algorithm protocols publish an `Event` associated type and accept a typed observation:

```swift
protocol ShortestPathAlgorithm: AlgorithmObserving {
    associatedtype Event
    
    func shortestPath(..., observation: AlgorithmObservation<Event>?) -> Path?
}
```

**Usage:**

```swift
let path = graph.shortestPath(
    from: start,
    to: goal,
    using: DijkstraShortestPathAlgorithm<AdjacencyList, Double>(
        weight: .property(\.weight)
    )
    .observing(.vertexExamined) {
        print("Examining \($0)")
    }
)
```

See <doc:ObservingAlgorithms> for details.

## Design Guidelines

### When to Create a Protocol

Create an algorithm protocol when:

1. **Multiple implementations exist** - DFS, BFS, etc.
2. **Trade-offs differ** - Kruskal vs. Prim
3. **Users might extend** - Custom search strategies

### When to Use Concrete Types

Use concrete types when:

1. **Only one implementation** - Unique algorithm
2. **No extensibility needed** - Internal helper
3. **Performance critical** - Avoid indirection

### Protocol Design Best Practices

1. **Minimal requirements** - Only essential methods
2. **Associated types** - Allow implementation flexibility
3. **Typed observation** - Enable passive instrumentation
4. **Generic constraints** - Specify graph requirements

```swift
// ✅ Good: Minimal, flexible
protocol MyAlgorithm<Graph> {
    associatedtype Graph: IncidenceGraph where Graph.VertexDescriptor: Hashable
    func run(in graph: Graph) -> Result
}

// ❌ Bad: Too many requirements
protocol MyAlgorithm {
    func run(in graph: AdjacencyList) -> Result  // Hardcoded type
    func preprocess()  // Unnecessary
    func postprocess()  // Unnecessary
}
```

## Real-World Example: Custom Search

Let's implement a custom best-first search with custom priority:

```swift
/// Best-first search with custom priority function
struct CustomBestFirstSearch<G: IncidenceGraph>: SearchAlgorithm
where G.VertexDescriptor: Hashable
{
    typealias Graph = G
    typealias SearchSequence = AnySequence<G.VertexDescriptor>
    enum Event {
        case vertexExamined(G.VertexDescriptor)
        case vertexDiscovered(G.VertexDescriptor)
    }
    
    let priority: (G.VertexDescriptor, G) -> Double
    
    func search(
        from source: G.VertexDescriptor,
        in graph: G,
        observation: AlgorithmObservation<Event>?
    ) -> SearchSequence {
        var visited: Set<G.VertexDescriptor> = []
        var queue = PriorityQueue<(G.VertexDescriptor, Double)>()
        
        queue.push((source, priority(source, graph)))
        visited.insert(source)
        
        return AnySequence {
            AnyIterator {
                guard let (vertex, _) = queue.pop() else { return nil }
                
                observation?.receive(.vertexExamined(vertex))
                
                for edge in graph.outgoingEdges(of: vertex) {
                    guard let neighbor = graph.destination(of: edge) else { continue }
                    
                    if !visited.contains(neighbor) {
                        visited.insert(neighbor)
                        let pri = self.priority(neighbor, graph)
                        queue.push((neighbor, pri))
                        observation?.receive(.vertexDiscovered(neighbor))
                    }
                }
                
                return vertex
            }
        }
    }
}

// Use it
for vertex in graph.search(from: start, using: CustomBestFirstSearch { vertex, graph in
    // Prioritize by degree (visit high-degree vertices first)
    -Double(graph.outDegree(of: vertex))
}) {
    print("Visited: \(vertex)")
}
```

## Next Steps

Now that you understand algorithm interfaces:

- Learn about <doc:ObservingAlgorithms> - Observing algorithm execution
- Explore <doc:PluggableArchitecture> - Component composition
- Study specific algorithms in the algorithm documentation

## See Also

- <doc:ObservingAlgorithms>
- <doc:PluggableArchitecture>
- <doc:Architecture>
- ``ShortestPathAlgorithm``
- ``TraversalAlgorithm``
- ``SearchAlgorithm``
