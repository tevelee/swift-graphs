# Graph Properties and Analysis

Analyzing structural properties and characteristics of graphs.

## Overview

Understanding graph properties is essential for algorithm selection and problem solving. The library provides comprehensive property analysis methods to characterize graphs and validate assumptions.

## Connectivity Properties

### Is Connected

Determine if all nodes are reachable from any starting node:

```swift
let graph = ConnectedGraph(edges: [
    "A": ["B"],
    "B": ["C"],
    "C": ["A"],
    "D": ["E"]  // Separate component
])

print(graph.isConnected())  // false
```

**For Undirected Graphs:**
```swift
if graph.undirected().isConnected() {
    print("Graph is connected")
}
```

**Implementation:**
```swift
extension Graph where Node: Hashable {
    func isConnected() -> Bool {
        guard let start = allNodes.first else { return true }
        let reachable = Set(traverse(from: start, strategy: .bfs().visitEachNodeOnce()))
        return reachable.count == allNodes.count
    }
}
```

### Connected Components

Find all connected components:

```swift
let components = graph.connectedComponents()
// [[A, B, C], [D, E]]

print("Number of components: \(components.count)")
for (i, component) in components.enumerated() {
    print("Component \(i): \(component)")
}
```

**Use Cases:**
- Network partitioning
- Cluster detection
- Island counting in grids

### Strongly Connected Components

For directed graphs, find maximal strongly connected subgraphs:

```swift
let directed = ConnectedGraph(edges: [
    "A": ["B"],
    "B": ["C"],
    "C": ["A"],
    "D": ["E"],
    "E": ["D"]
])

let sccs = directed.stronglyConnectedComponents(using: .tarjan())
// [[A, B, C], [D, E]]
```

**Algorithms:**
- **Tarjan's Algorithm**: O(V + E), single DFS
- **Kosaraju's Algorithm**: O(V + E), two DFS passes

```swift
// Tarjan's algorithm
let sccs = graph.stronglyConnectedComponents(using: .tarjan())

// Kosaraju's algorithm
let sccs = graph.stronglyConnectedComponents(using: .kosaraju())
```

**Applications:**
- Web graph analysis
- Call graph analysis
- Social network communities

## Cycle Detection

### Has Cycle

Detect if graph contains cycles:

```swift
let graph = ConnectedGraph(edges: [
    "A": ["B"],
    "B": ["C"],
    "C": ["A"]  // Cycle!
])

print(graph.isCyclic())  // true
```

**For Undirected:**
```swift
extension Graph where Node: Hashable {
    func isCyclic() -> Bool {
        var visited: Set<Node> = []
        var recursionStack: Set<Node> = []
        
        func hasCycle(_ node: Node, parent: Node?) -> Bool {
            visited.insert(node)
            recursionStack.insert(node)
            
            for edge in edges(from: node) {
                let neighbor = edge.destination
                if !visited.contains(neighbor) {
                    if hasCycle(neighbor, parent: node) {
                        return true
                    }
                } else if recursionStack.contains(neighbor) && neighbor != parent {
                    return true
                }
            }
            
            recursionStack.remove(node)
            return false
        }
        
        for node in allNodes where !visited.contains(node) {
            if hasCycle(node, parent: nil) {
                return true
            }
        }
        
        return false
    }
}
```

### Find Cycles

Get actual cycles:

```swift
let cycles = graph.findCycles()
for cycle in cycles {
    print("Cycle: \(cycle.map(\.source).joined(separator: " → "))")
}
```

## Tree Properties

### Is Tree

A tree is a connected acyclic graph:

```swift
extension Graph where Node: Hashable {
    func isTree() -> Bool {
        // Must be connected
        guard isConnected() else { return false }
        
        // Must be acyclic
        guard !isCyclic() else { return false }
        
        // Must have V-1 edges
        return allEdges.count == allNodes.count - 1
    }
}

let tree = ConnectedGraph(edges: [
    "Root": ["A", "B"],
    "A": ["C", "D"],
    "B": ["E"]
])

print(tree.isTree())  // true
```

### Is Forest

Collection of disjoint trees:

```swift
extension Graph where Node: Hashable {
    func isForest() -> Bool {
        !isCyclic()
    }
}
```

### Tree Properties

```swift
extension Graph where Node: Hashable {
    // Height of tree
    func height(from root: Node) -> Int {
        var maxDepth = 0
        for visit in traversal(from: root, strategy: .bfs().trackDistance()) {
            maxDepth = max(maxDepth, visit.distance)
        }
        return maxDepth
    }
    
    // Leaves (degree 1)
    func leaves() -> [Node] {
        allNodes.filter { edges(from: $0).count == 1 }
    }
    
    // Is balanced (all leaves at similar depth)
    func isBalanced(from root: Node) -> Bool {
        let depths = traversal(from: root, strategy: .bfs().trackDistance())
            .filter { edges(from: $0.node).isEmpty }  // leaves
            .map(\.distance)
        
        guard let min = depths.min(), let max = depths.max() else {
            return true
        }
        
        return max - min <= 1
    }
}
```

## Graph Types

### Is Bipartite

Can nodes be partitioned into two sets with edges only between sets?

```swift
extension Graph where Node: Hashable {
    func isBipartite() -> (Bool, [Node: Int]?) {
        var colors: [Node: Int] = [:]
        
        func dfs(_ node: Node, color: Int) -> Bool {
            colors[node] = color
            
            for edge in edges(from: node) {
                let neighbor = edge.destination
                if let neighborColor = colors[neighbor] {
                    if neighborColor == color {
                        return false  // Same color, not bipartite
                    }
                } else {
                    if !dfs(neighbor, color: 1 - color) {
                        return false
                    }
                }
            }
            
            return true
        }
        
        for node in allNodes where colors[node] == nil {
            if !dfs(node, color: 0) {
                return (false, nil)
            }
        }
        
        return (true, colors)
    }
}

let graph = ConnectedGraph(edges: [
    "A": ["B", "C"],
    "B": ["A", "D"],
    "C": ["A", "D"],
    "D": ["B", "C"]
])

let (isBipartite, partition) = graph.isBipartite()
if isBipartite {
    print("Bipartite with partitions: \(partition!)")
}
```

**Applications:**
- Job assignment
- Matching problems
- Two-coloring

### Is Complete

Every pair of vertices is connected:

```swift
extension Graph where Node: Hashable {
    func isComplete() -> Bool {
        let n = allNodes.count
        let expectedEdges = n * (n - 1)  // For directed
        return allEdges.count == expectedEdges
    }
}
```

### Is Planar

Can be drawn without edge crossings (complex):

```swift
extension Graph where Node: Hashable {
    func isPlanar() -> Bool {
        // Use Kuratowski's theorem or planarity testing algorithm
        // Simplified check: V - E + F = 2 (Euler's formula)
        // For planar: E ≤ 3V - 6
        
        let v = allNodes.count
        let e = allEdges.count
        
        if e > 3 * v - 6 {
            return false
        }
        
        // Full planarity testing requires more sophisticated algorithm
        // This is a necessary but not sufficient condition
        return true  // Approximation
    }
}
```

## Degree Properties

### Degree Distribution

```swift
extension Graph where Node: Hashable {
    func degreeDistribution() -> [Int: Int] {
        var distribution: [Int: Int] = [:]
        
        for node in allNodes {
            let degree = edges(from: node).count
            distribution[degree, default: 0] += 1
        }
        
        return distribution
    }
    
    func averageDegree() -> Double {
        let totalDegree = allNodes.reduce(0) { $0 + edges(from: $1).count }
        return Double(totalDegree) / Double(allNodes.count)
    }
    
    func maxDegree() -> Int {
        allNodes.map { edges(from: $0).count }.max() ?? 0
    }
    
    func minDegree() -> Int {
        allNodes.map { edges(from: $0).count }.min() ?? 0
    }
}

let dist = graph.degreeDistribution()
print("Degree distribution: \(dist)")
print("Average degree: \(graph.averageDegree())")
```

### Degree Sequence

```swift
extension Graph where Node: Hashable {
    func degreeSequence() -> [Int] {
        allNodes.map { edges(from: $0).count }.sorted(by: >)
    }
}

print("Degree sequence: \(graph.degreeSequence())")
// [4, 3, 3, 2, 1]
```

## Topological Ordering

Order vertices in directed acyclic graph (DAG):

```swift
extension Graph where Node: Hashable {
    func topologicalSort() -> [Node]? {
        guard !isCyclic() else { return nil }
        
        var result: [Node] = []
        var visited: Set<Node> = []
        
        func dfs(_ node: Node) {
            visited.insert(node)
            
            for edge in edges(from: node) {
                if !visited.contains(edge.destination) {
                    dfs(edge.destination)
                }
            }
            
            result.insert(node, at: 0)
        }
        
        for node in allNodes where !visited.contains(node) {
            dfs(node)
        }
        
        return result
    }
}

let dag = ConnectedGraph(edges: [
    "A": ["C"],
    "B": ["C", "D"],
    "C": ["E"],
    "D": ["E"],
    "E": []
])

if let order = dag.topologicalSort() {
    print("Topological order: \(order)")
    // [B, D, A, C, E] or [A, B, C, D, E] etc.
}
```

**Applications:**
- Task scheduling
- Build systems
- Course prerequisites
- Dependency resolution

## Centrality Measures

### Degree Centrality

Importance based on number of connections:

```swift
extension Graph where Node: Hashable {
    func degreeCentrality() -> [Node: Double] {
        let n = Double(allNodes.count - 1)
        var centrality: [Node: Double] = [:]
        
        for node in allNodes {
            let degree = Double(edges(from: node).count)
            centrality[node] = degree / n
        }
        
        return centrality
    }
}
```

### Betweenness Centrality

Importance based on shortest paths passing through:

```swift
extension Graph where Node: Hashable {
    func betweennessCentrality() -> [Node: Double] {
        var centrality: [Node: Double] = Dictionary(uniqueKeysWithValues: allNodes.map { ($0, 0.0) })
        
        for source in allNodes {
            // Find all shortest paths from source
            var stack: [Node] = []
            var paths: [Node: [Node]] = [:]
            var sigma: [Node: Int] = Dictionary(uniqueKeysWithValues: allNodes.map { ($0, 0) })
            sigma[source] = 1
            
            var distance: [Node: Int] = [:]
            distance[source] = 0
            
            var queue: [Node] = [source]
            
            while !queue.isEmpty {
                let v = queue.removeFirst()
                stack.append(v)
                
                for edge in edges(from: v) {
                    let w = edge.destination
                    
                    if distance[w] == nil {
                        distance[w] = distance[v]! + 1
                        queue.append(w)
                    }
                    
                    if distance[w] == distance[v]! + 1 {
                        sigma[w]! += sigma[v]!
                        paths[w, default: []].append(v)
                    }
                }
            }
            
            var delta: [Node: Double] = Dictionary(uniqueKeysWithValues: allNodes.map { ($0, 0.0) })
            
            while let w = stack.popLast() {
                for v in paths[w] ?? [] {
                    delta[v]! += (Double(sigma[v]!) / Double(sigma[w]!)) * (1 + delta[w]!)
                }
                if w != source {
                    centrality[w]! += delta[w]!
                }
            }
        }
        
        return centrality
    }
}
```

### Closeness Centrality

Importance based on average distance to all other nodes:

```swift
extension Graph where Node: Hashable, Edge: Weighted, Edge.Weight: Numeric {
    func closenessCentrality() -> [Node: Double] {
        var centrality: [Node: Double] = [:]
        
        for node in allNodes {
            let paths = shortestPaths(from: node, using: .dijkstra())
            let totalDistance = paths.values.reduce(0.0) { $0 + Double($1.cost) }
            centrality[node] = Double(allNodes.count - 1) / totalDistance
        }
        
        return centrality
    }
}
```

## Density and Sparsity

```swift
extension Graph {
    func density() -> Double {
        let v = Double(allNodes.count)
        let e = Double(allEdges.count)
        let maxEdges = v * (v - 1)  // Directed graph
        return e / maxEdges
    }
    
    func isSparse() -> Bool {
        // Sparse if E = O(V)
        allEdges.count < allNodes.count * 10
    }
    
    func isDense() -> Bool {
        // Dense if E = O(V²)
        density() > 0.5
    }
}
```

## Practical Examples

### Dependency Analysis

```swift
struct Package: Hashable {
    let name: String
}

let dependencies = ConnectedGraph(edges: [
    Package(name: "App"): [Package(name: "NetworkKit"), Package(name: "UI")],
    Package(name: "NetworkKit"): [Package(name: "Core")],
    Package(name: "UI"): [Package(name: "Core")],
    Package(name: "Core"): []
])

// Check for circular dependencies
if dependencies.isCyclic() {
    print("ERROR: Circular dependency detected!")
}

// Get build order
if let buildOrder = dependencies.topologicalSort() {
    print("Build order: \(buildOrder.map(\.name))")
}

// Find critical packages (high betweenness)
let centrality = dependencies.betweennessCentrality()
let critical = centrality.max { $0.value < $1.value }
print("Most critical package: \(critical?.key.name ?? "none")")
```

### Social Network Analysis

```swift
let socialNetwork = ConnectedHashGraph<User, Empty>(edges: friendships)

// Find communities
let communities = socialNetwork.undirected().stronglyConnectedComponents()
print("Found \(communities.count) communities")

// Find influencers (high degree centrality)
let influence = socialNetwork.degreeCentrality()
let top5 = influence.sorted { $0.value > $1.value }.prefix(5)
print("Top influencers:")
for (user, score) in top5 {
    print("  \(user.name): \(score)")
}

// Find bridges between communities (high betweenness)
let bridges = socialNetwork.betweennessCentrality()
let topBridges = bridges.sorted { $0.value > $1.value }.prefix(5)
print("Key connectors:")
for (user, score) in topBridges {
    print("  \(user.name): \(score)")
}
```

### Network Reliability

```swift
let network = loadNetworkTopology()

// Is network connected?
if !network.isConnected() {
    print("WARNING: Network has partitions")
}

// Find critical links (bridges)
let bridges = network.findBridges()
print("Critical links (single points of failure): \(bridges.count)")

// Find redundancy (biconnected components)
let biconnected = network.biconnectedComponents()
print("Biconnected components: \(biconnected.count)")

// Analyze robustness
let density = network.density()
print("Network density: \(density)")
if density > 0.5 {
    print("Highly redundant network")
} else {
    print("Sparse network - consider adding links")
}
```

## See Also

- <doc:TraversalAlgorithms>
- <doc:ShortestPathAlgorithms>
- <doc:GraphColoring>
- ``Graph``
- ``GraphComponent``
