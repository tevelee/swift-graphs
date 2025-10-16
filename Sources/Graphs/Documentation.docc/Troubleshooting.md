# Troubleshooting and FAQ

Common issues, solutions, and frequently asked questions.

## Common Compilation Errors

### "Method unavailable for this graph type"

**Problem:**
```swift
let graph = ConnectedGraph(edges: [...])
let path = graph.shortestPath(from: "A", to: "B")
// Error: Value of type 'ConnectedGraph<String, Empty>' has no member 'shortestPath'
```

**Cause:** The method requires weighted edges, but your graph has `Empty` edge type.

**Solution:** Add weights to your graph:
```swift
let weighted = graph.weighted { _ in 1 }  // Unit weights
// or
let weighted = ConnectedGraph(edges: [
    "A": ["B": 5, "C": 3]  // Explicit weights
])
```

### "Cannot convert value of type X to expected argument type"

**Problem:**
```swift
graph.shortestPath(from: "A", to: "B", using: .dijkstra())
// Error: Edge.Weight.Magnitude must equal Edge.Weight
```

**Cause:** Dijkstra requires non-negative weights (magnitude equals value).

**Solution:** Use Bellman-Ford for negative weights:
```swift
graph.shortestPath(from: "A", to: "B", using: .bellmanFord())
```

Or ensure weights are non-negative:
```swift
struct Distance: Weighted {
    let value: Double
    var weight: Double { abs(value) }  // Always non-negative
}
```

### "Type 'X' does not conform to protocol 'Hashable'"

**Problem:**
```swift
struct Node {
    let data: String
}

let graph = ConnectedGraph<Node, Empty>(...)
graph.stronglyConnectedComponents()  // Error: Node must be Hashable
```

**Solution:** Make your type hashable:
```swift
struct Node: Hashable {
    let data: String
}
```

Or use a hash function wrapper:
```swift
let hashedGraph = graph.withHashValue(\.data.hashValue)
hashedGraph.stronglyConnectedComponents()
```

## Performance Issues

### Slow shortest path computation

**Problem:** Dijkstra is slow on your graph.

**Diagnosis:**
```swift
print("Nodes: \(graph.allNodes.count)")
print("Edges: \(graph.allEdges.count)")
print("Density: \(graph.density())")
```

**Solutions:**

1. **Use hash-based graph for large graphs:**
```swift
// Instead of
let graph = ConnectedGraph(edges: edges)

// Use
let graph = ConnectedHashGraph(edges: edges, hashValue: \.id)
```

2. **Try bidirectional search for long paths:**
```swift
let path = graph.shortestPath(from: start, to: goal, using: .bidirectionalDijkstra())
```

3. **Use A* with good heuristic:**
```swift
let path = graph.shortestPath(
    from: start,
    to: goal,
    using: .aStar(heuristic: .euclideanDistance(of: \.coordinates))
)
```

### Traversal hangs or takes forever

**Problem:** BFS/DFS never completes.

**Cause:** Infinite graph or very large graph without limits.

**Solution:** Add depth limit or unique visiting:
```swift
// Limit depth
let nodes = graph.traverse(from: start, strategy: .bfs().limited(depth: 100))

// Visit each node once
let nodes = graph.traverse(from: start, strategy: .bfs().visitEachNodeOnce())
```

### Memory issues with large graphs

**Problem:** Out of memory errors.

**Solutions:**

1. **Use lazy graph for procedural graphs:**
```swift
let lazy = LazyGraph<(Int, Int), Empty> { (x, y) in
    // Compute edges on-demand
    neighbors(of: (x, y))
}
```

2. **Use database-backed graph:**
```swift
struct DBGraph: GraphComponent {
    let db: Database
    func edges(from node: ID) -> [GraphEdge<ID, Empty>] {
        db.query("SELECT destination FROM edges WHERE source = ?", node)
    }
}
```

3. **Process graph in chunks:**
```swift
for component in graph.connectedComponents() {
    let subgraph = graph.induced(by: component)
    process(subgraph)
}
```

## Algorithm Issues

### MST algorithm fails

**Problem:** Minimum spanning tree returns wrong result.

**Cause:** Graph is directed, but MST requires undirected.

**Solution:**
```swift
let mst = graph.undirected().minimumSpanningTree(using: .kruskal())
```

### Flow algorithm returns 0

**Problem:** Maximum flow is always 0.

**Diagnosis:**
```swift
// Check if path exists
let hasPath = graph.shortestPathBFS(from: source, to: sink) != nil
print("Path exists: \(hasPath)")

// Check capacities
for edge in graph.allEdges {
    print("\(edge.source) → \(edge.destination): capacity \(edge.value.weight)")
}
```

**Solutions:**

1. **Verify graph connectivity:**
```swift
let reachable = graph.traverse(from: source, strategy: .bfs())
if !reachable.contains(sink) {
    print("Sink not reachable from source")
}
```

2. **Check edge directions:**
```swift
// Flow graphs are directed - ensure edges go toward sink
```

### Coloring uses too many colors

**Problem:** Graph coloring uses more colors than expected.

**Solutions:**

1. **Try better algorithms:**
```swift
// Instead of greedy
let coloring1 = graph.colorNodes(using: .greedy())

// Try DSatur (usually better)
let coloring2 = graph.colorNodes(using: .dsatur())

// Or Welsh-Powell
let coloring3 = graph.colorNodes(using: .welshPowell())
```

2. **Check if graph is bipartite:**
```swift
if graph.isBipartite().0 {
    print("Graph is bipartite - needs only 2 colors")
}
```

## Type System Issues

### Cannot infer generic parameter

**Problem:**
```swift
let path = graph.shortestPath(from: start, to: goal, using: .dijkstra())
// Error: Cannot infer complex closure return type
```

**Solution:** Add explicit types:
```swift
let algorithm = DijkstraAlgorithm<String, Int>()
let path = graph.shortestPath(from: start, to: goal, using: algorithm)
```

### Protocol composition issues

**Problem:** Cannot use graph with multiple protocol requirements.

**Solution:** Use type constraints:
```swift
func analyze<G>(_ graph: G) 
where G: Graph, G.Node: Hashable, G.Edge: Weighted {
    // Both Graph protocol and constraints
}
```

## FAQ

### Q: How do I choose between ConnectedGraph and ConnectedHashGraph?

**A:** Use this guideline:
- **ConnectedGraph**: Small graphs (<1000 nodes), simple use cases
- **ConnectedHashGraph**: Large graphs, frequent edge lookups, when you need O(1) access

```swift
// Small graph
let small = ConnectedGraph(edges: edges)

// Large graph
let large = ConnectedHashGraph(edges: edges, hashValue: \.id)
```

### Q: Can I modify a graph while traversing?

**A:** No, it's unsafe. Create a new graph instead:

```swift
// Don't do this
var graph = ConnectedGraph(edges: edges)
for node in graph.traverse(from: start, strategy: .bfs()) {
    graph.addEdge(...)  // ❌ Unsafe
}

// Do this instead
var newEdges = graph.allEdges
for node in graph.traverse(from: start, strategy: .bfs()) {
    newEdges.append(...)
}
let newGraph = ConnectedGraph(edges: newEdges)
```

### Q: How do I handle disconnected graphs?

**A:** Process each component separately:

```swift
let components = graph.connectedComponents()
for component in components {
    let subgraph = graph.induced(by: Set(component))
    process(subgraph)
}
```

### Q: Why is my weighted graph not working?

**A:** Ensure your edge type conforms to `Weighted`:

```swift
// ❌ Won't work
struct Edge {
    let weight: Int
}

// ✓ Works
struct Edge: Weighted {
    let value: Int
    var weight: Int { value }
}
```

### Q: How do I visualize my graph?

**A:** Export to common formats:

```swift
extension Graph where Node: CustomStringConvertible {
    func toDOT() -> String {
        var dot = "digraph {\n"
        for edge in allEdges {
            dot += "  \"\(edge.source)\" -> \"\(edge.destination)\"\n"
        }
        dot += "}"
        return dot
    }
}

// Save and visualize with Graphviz
let dot = graph.toDOT()
try dot.write(to: URL(fileURLWithPath: "graph.dot"))
// Run: dot -Tpng graph.dot -o graph.png
```

### Q: Can I use this library with SwiftUI?

**A:** Yes! Use `@State` or `ObservableObject`:

```swift
@Observable
class GraphViewModel {
    var graph: ConnectedGraph<String, Int>
    
    func updateGraph() {
        // Modifications create new graph
        self.graph = ConnectedGraph(edges: newEdges)
    }
}

struct GraphView: View {
    @State private var viewModel = GraphViewModel()
    
    var body: some View {
        // Visualize graph
    }
}
```

### Q: How do I handle very large graphs?

**A:** Use lazy evaluation or database-backed graphs:

```swift
// Lazy for procedural graphs
let lazy = LazyGraph<Position, Empty> { pos in
    computeNeighbors(pos)
}

// Database for persistent graphs
struct DBGraph: GraphComponent {
    let db: Database
    func edges(from node: ID) -> [GraphEdge<ID, Empty>] {
        db.query("SELECT * FROM edges WHERE source = ?", node)
    }
}
```

### Q: Can I run algorithms in parallel?

**A:** Some algorithms can be parallelized:

```swift
// Process components in parallel
let components = graph.connectedComponents()
DispatchQueue.concurrentPerform(iterations: components.count) { i in
    let result = processComponent(components[i])
    // Handle result thread-safely
}
```

### Q: How do I debug algorithm results?

**A:** Add logging and validation:

```swift
let path = graph.shortestPath(from: start, to: goal, using: .dijkstra())

if let path = path {
    print("Path found: \(path.path)")
    print("Cost: \(path.cost)")
    
    // Validate
    var totalCost = 0
    for edge in path.edges {
        totalCost += edge.value.weight
        print("  \(edge.source) → \(edge.destination): \(edge.value.weight)")
    }
    assert(totalCost == path.cost)
} else {
    print("No path exists")
    
    // Check why
    let reachable = graph.traverse(from: start, strategy: .bfs())
    if !reachable.contains(goal) {
        print("Goal is not reachable from start")
    }
}
```

## Getting Help

### Check the documentation
- <doc:QuickReference> - Fast lookup
- <doc:CodeExamples> - Working examples
- <doc:Architecture> - Design principles

### Enable debugging
```swift
// Add logging
extension GraphComponent {
    func debugPrint() {
        print("Graph with \(allNodes.count) nodes and \(allEdges.count) edges")
        for node in allNodes {
            let degree = edges(from: node).count
            print("  \(node): degree \(degree)")
        }
    }
}
```

### Create minimal reproduction
```swift
// Simplify to minimal failing case
let simple = ConnectedGraph(edges: [
    "A": ["B": 1],
    "B": []
])

let result = simple.shortestPath(from: "A", to: "B")
print(result)  // Should work
```

## See Also

- <doc:QuickReference>
- <doc:CodeExamples>
- <doc:AdvancedTopics>
