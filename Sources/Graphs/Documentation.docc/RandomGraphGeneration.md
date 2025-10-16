# Random Graph Generation

Generate random graphs for testing, simulation, and modeling real-world networks.

## Overview

Random graph generation is essential for algorithm testing, network modeling, and understanding complex systems. The library provides classical random graph models that capture different network properties.

## Random Graph Models

### Erdős-Rényi Model

Generate random graphs where each edge appears independently with probability p.

```swift
let random = ConnectedGraph<Int, Empty>.random(
    nodeCount: 100,
    using: .erdosRenyi(probability: 0.05)
)

print("Nodes: \(random.allNodes.count)")
print("Edges: \(random.allEdges.count)")
print("Expected edges: ~\(100 * 99 / 2 * 0.05)")
```

**Characteristics:**
- **Model**: G(n, p) - n nodes, edge probability p
- **Degree Distribution**: Binomial (approaches Poisson for large n)
- **Clustering**: Low
- **Diameter**: O(log n)

**Parameters:**
- `nodeCount`: Number of vertices
- `probability`: Edge probability (0.0 to 1.0)

**Properties:**
- Random structure
- No clustering
- Homogeneous degree distribution
- Fast mixing time

**Best For:**
- Baseline comparisons
- Testing algorithms
- Random baseline networks
- Statistical mechanics models

**Implementation:**
```swift
extension ConnectedGraph where Node == Int, Edge == Empty {
    static func random(
        nodeCount: Int,
        using generator: ErdosRenyiRandomGraphGenerator
    ) -> Self {
        var edges: [GraphEdge<Int, Empty>] = []
        
        for i in 0..<nodeCount {
            for j in i+1..<nodeCount {
                if Double.random(in: 0...1) < generator.probability {
                    edges.append(GraphEdge(source: i, destination: j))
                    edges.append(GraphEdge(source: j, destination: i))  // Undirected
                }
            }
        }
        
        return ConnectedGraph(edges: edges)
    }
}
```

### Barabási-Albert Model (Preferential Attachment)

Generate scale-free networks where new nodes preferentially attach to high-degree nodes.

```swift
let scaleFree = ConnectedGraph<Int, Empty>.random(
    nodeCount: 100,
    using: .barabasiAlbert(attachmentCount: 3)
)

// Analyze degree distribution
let degrees = scaleFree.degreeSequence()
print("Degree distribution follows power law")
print("Max degree: \(degrees.first ?? 0)")
print("Min degree: \(degrees.last ?? 0)")
```

**Characteristics:**
- **Model**: Start with m₀ nodes, each new node connects to m existing nodes
- **Degree Distribution**: Power law P(k) ~ k⁻ᵞ
- **Clustering**: Higher than Erdős-Rényi
- **Hubs**: Few nodes with very high degree

**Parameters:**
- `nodeCount`: Final number of nodes
- `attachmentCount`: Edges per new node (m)

**Properties:**
- Scale-free (power law degree distribution)
- Robust to random failures
- Vulnerable to targeted attacks (hub removal)
- Small world property

**Best For:**
- Social networks
- Internet topology
- Citation networks
- Biological networks
- World Wide Web modeling

**How it works:**
1. Start with small initial graph
2. Add nodes one at a time
3. Each new node connects to m existing nodes
4. Probability of connecting to node i: P(i) = degree(i) / Σ degrees

**Implementation:**
```swift
extension ConnectedGraph where Node == Int, Edge == Empty {
    static func random(
        nodeCount: Int,
        using generator: BarabasiAlbertRandomGraphGenerator
    ) -> Self {
        var edges: [GraphEdge<Int, Empty>] = []
        var degrees: [Int: Int] = [:]
        
        let m = generator.attachmentCount
        
        // Initial complete graph
        for i in 0..<m {
            for j in i+1..<m {
                edges.append(GraphEdge(source: i, destination: j))
                edges.append(GraphEdge(source: j, destination: i))
                degrees[i, default: 0] += 1
                degrees[j, default: 0] += 1
            }
        }
        
        // Add remaining nodes
        for newNode in m..<nodeCount {
            let totalDegree = degrees.values.reduce(0, +)
            var targets: Set<Int> = []
            
            while targets.count < m {
                let r = Double.random(in: 0...1) * Double(totalDegree)
                var sum = 0.0
                
                for (node, degree) in degrees {
                    sum += Double(degree)
                    if sum >= r && !targets.contains(node) {
                        targets.insert(node)
                        break
                    }
                }
            }
            
            for target in targets {
                edges.append(GraphEdge(source: newNode, destination: target))
                edges.append(GraphEdge(source: target, destination: newNode))
                degrees[newNode, default: 0] += 1
                degrees[target, default: 0] += 1
            }
        }
        
        return ConnectedGraph(edges: edges)
    }
}
```

### Watts-Strogatz Model (Small World)

Generate small-world networks with high clustering and short path lengths.

```swift
let smallWorld = ConnectedGraph<Int, Empty>.random(
    nodeCount: 100,
    using: .wattsStrogatz(
        neighbors: 4,
        rewiringProbability: 0.1
    )
)

let avgPathLength = smallWorld.averageShortestPathLength()
let clustering = smallWorld.clusteringCoefficient()

print("Average path length: \(avgPathLength)")  // Small
print("Clustering: \(clustering)")  // High
```

**Characteristics:**
- **Model**: Start with ring, rewire edges with probability p
- **Degree Distribution**: Almost regular (most nodes have similar degree)
- **Clustering**: High
- **Path Length**: Small (like random graphs)

**Parameters:**
- `nodeCount`: Number of nodes
- `neighbors`: Each node connected to k neighbors in ring
- `rewiringProbability`: Probability to rewire (0 = ring, 1 = random)

**Properties:**
- High clustering (like regular lattice)
- Short paths (like random graph)
- "Small world" property
- Interpolates between regular and random

**Best For:**
- Social networks
- Neural networks
- Power grids
- C. elegans neural network
- Six degrees of separation

**How it works:**
1. Create ring lattice: each node connected to k nearest neighbors
2. For each edge:
   - With probability p, rewire to random node
   - Avoid self-loops and duplicate edges
3. Result: clustered network with shortcuts

**Implementation:**
```swift
extension ConnectedGraph where Node == Int, Edge == Empty {
    static func random(
        nodeCount: Int,
        using generator: WattsStrogatzRandomGraphGenerator
    ) -> Self {
        var edges: [GraphEdge<Int, Empty>] = []
        let k = generator.neighbors
        let p = generator.rewiringProbability
        
        // Create ring lattice
        for i in 0..<nodeCount {
            for j in 1...k/2 {
                let neighbor = (i + j) % nodeCount
                edges.append(GraphEdge(source: i, destination: neighbor))
                edges.append(GraphEdge(source: neighbor, destination: i))
            }
        }
        
        // Rewire edges
        var edgeSet = Set(edges)
        
        for i in 0..<nodeCount {
            for j in 1...k/2 {
                if Double.random(in: 0...1) < p {
                    let oldNeighbor = (i + j) % nodeCount
                    var newNeighbor: Int
                    
                    repeat {
                        newNeighbor = Int.random(in: 0..<nodeCount)
                    } while newNeighbor == i || edgeSet.contains(GraphEdge(source: i, destination: newNeighbor))
                    
                    // Remove old edge
                    edgeSet.remove(GraphEdge(source: i, destination: oldNeighbor))
                    edgeSet.remove(GraphEdge(source: oldNeighbor, destination: i))
                    
                    // Add new edge
                    edgeSet.insert(GraphEdge(source: i, destination: newNeighbor))
                    edgeSet.insert(GraphEdge(source: newNeighbor, destination: i))
                }
            }
        }
        
        return ConnectedGraph(edges: Array(edgeSet))
    }
}
```

## Model Comparison

### Properties Comparison

| Model | Degree Dist. | Clustering | Path Length | Best Models |
|-------|-------------|------------|-------------|-------------|
| Erdős-Rényi | Binomial/Poisson | Low | Small | Random baseline |
| Barabási-Albert | Power law | Medium | Small | Social networks, WWW |
| Watts-Strogatz | Regular-like | High | Small | Social, biological |

### Visual Comparison

```swift
// Generate all three models
let er = ConnectedGraph<Int, Empty>.random(nodeCount: 100, using: .erdosRenyi(probability: 0.05))
let ba = ConnectedGraph<Int, Empty>.random(nodeCount: 100, using: .barabasiAlbert(attachmentCount: 3))
let ws = ConnectedGraph<Int, Empty>.random(nodeCount: 100, using: .wattsStrogatz(neighbors: 4, rewiringProbability: 0.1))

// Compare properties
func analyze(_ graph: ConnectedGraph<Int, Empty>, name: String) {
    print("\n\(name):")
    print("  Edges: \(graph.allEdges.count)")
    print("  Avg degree: \(graph.averageDegree())")
    print("  Max degree: \(graph.maxDegree())")
    print("  Clustering: \(graph.clusteringCoefficient())")
    print("  Diameter: \(graph.diameter())")
}

analyze(er, name: "Erdős-Rényi")
analyze(ba, name: "Barabási-Albert")
analyze(ws, name: "Watts-Strogatz")
```

## Practical Applications

### Testing Algorithms

Generate random graphs for algorithm testing:

```swift
// Test shortest path on various graph types
for _ in 0..<100 {
    let graph = ConnectedGraph<Int, Int>.random(
        nodeCount: 50,
        using: .erdosRenyi(probability: 0.1)
    ).weighted { _ in Int.random(in: 1...10) }
    
    let start = 0
    let goal = 49
    
    let dijkstra = graph.shortestPath(from: start, to: goal, using: .dijkstra())
    let astar = graph.shortestPath(from: start, to: goal, using: .aStar(heuristic: .zero))
    
    assert(dijkstra?.cost == astar?.cost, "Algorithms should agree")
}
```

### Network Simulation

Simulate information spread:

```swift
let network = ConnectedGraph<Int, Empty>.random(
    nodeCount: 1000,
    using: .barabasiAlbert(attachmentCount: 3)
)

// Simulate epidemic spread
var infected: Set<Int> = [0]  // Patient zero
var newInfections: Set<Int> = [0]

for generation in 0..<10 {
    var nextGeneration: Set<Int> = []
    
    for node in newInfections {
        for edge in network.edges(from: node) {
            if !infected.contains(edge.destination) && Double.random(in: 0...1) < 0.3 {
                nextGeneration.insert(edge.destination)
            }
        }
    }
    
    infected.formUnion(nextGeneration)
    newInfections = nextGeneration
    
    print("Generation \(generation): \(infected.count) infected")
}
```

### Benchmarking

Compare algorithm performance on different network types:

```swift
import Foundation

func benchmark<G: Graph>(
    _ algorithm: String,
    on graphType: String,
    generator: () -> G
) {
    let start = Date()
    let graph = generator()
    
    // Run algorithm
    if let first = graph.allNodes.first, let last = graph.allNodes.last {
        _ = graph.shortestPath(from: first, to: last, using: .dijkstra())
    }
    
    let elapsed = Date().timeIntervalSince(start)
    print("\(algorithm) on \(graphType): \(elapsed)s")
}

benchmark("Dijkstra", on: "Erdős-Rényi") {
    ConnectedGraph<Int, Int>.random(nodeCount: 1000, using: .erdosRenyi(probability: 0.01))
        .weighted { _ in 1 }
}

benchmark("Dijkstra", on: "Barabási-Albert") {
    ConnectedGraph<Int, Int>.random(nodeCount: 1000, using: .barabasiAlbert(attachmentCount: 5))
        .weighted { _ in 1 }
}
```

### Social Network Modeling

Model friend recommendations:

```swift
// Generate social network
let socialNetwork = ConnectedGraph<Int, Empty>.random(
    nodeCount: 500,
    using: .barabasiAlbert(attachmentCount: 5)
)

// Find communities
let communities = socialNetwork.undirected().stronglyConnectedComponents()

// Recommend friends: friends of friends not already friends
func recommendFriends(for user: Int) -> [Int] {
    let friends = Set(socialNetwork.edges(from: user).map(\.destination))
    var recommendations: [Int: Int] = [:]  // user -> count of mutual friends
    
    for friend in friends {
        for friendOfFriend in socialNetwork.edges(from: friend).map(\.destination) {
            if friendOfFriend != user && !friends.contains(friendOfFriend) {
                recommendations[friendOfFriend, default: 0] += 1
            }
        }
    }
    
    return recommendations.sorted { $0.value > $1.value }.prefix(10).map(\.key)
}

let suggestions = recommendFriends(for: 42)
print("Friend recommendations for user 42: \(suggestions)")
```

### Resilience Analysis

Test network robustness:

```swift
func testResilience(_ graph: ConnectedGraph<Int, Empty>) {
    var g = graph
    var removedCount = 0
    
    while g.isConnected() {
        // Remove random node
        let toRemove = g.allNodes.randomElement()!
        g = ConnectedGraph(edges: g.allEdges.filter { 
            $0.source != toRemove && $0.destination != toRemove 
        })
        removedCount += 1
    }
    
    print("Network fragmented after removing \(removedCount) nodes")
}

print("Erdős-Rényi resilience:")
testResilience(ConnectedGraph.random(nodeCount: 100, using: .erdosRenyi(probability: 0.05)))

print("\nBarabási-Albert resilience:")
testResilience(ConnectedGraph.random(nodeCount: 100, using: .barabasiAlbert(attachmentCount: 3)))
```

## Advanced Random Graphs

### Configuration Model

Generate graph with specific degree sequence:

```swift
extension ConnectedGraph where Node == Int, Edge == Empty {
    static func configuration(degreeSequence: [Int]) -> Self? {
        guard degreeSequence.reduce(0, +) % 2 == 0 else {
            return nil  // Must be even sum
        }
        
        var stubs: [Int] = []
        for (node, degree) in degreeSequence.enumerated() {
            stubs.append(contentsOf: Array(repeating: node, count: degree))
        }
        
        var edges: [GraphEdge<Int, Empty>] = []
        stubs.shuffle()
        
        for i in stride(from: 0, to: stubs.count - 1, by: 2) {
            let u = stubs[i]
            let v = stubs[i + 1]
            if u != v {  // Avoid self-loops
                edges.append(GraphEdge(source: u, destination: v))
            }
        }
        
        return ConnectedGraph(edges: edges)
    }
}

// Create graph with power law degree distribution
let powerLawDegrees = (0..<100).map { _ in 
    Int(pow(Double.random(in: 0...1), -1.0/2.5))
}
if let graph = ConnectedGraph<Int, Empty>.configuration(degreeSequence: powerLawDegrees) {
    print("Created graph with custom degree sequence")
}
```

### Weighted Random Graphs

```swift
extension ConnectedGraph where Node == Int {
    static func randomWeighted<W: Weighted>(
        nodeCount: Int,
        probability: Double,
        weightGenerator: () -> W
    ) -> ConnectedGraph<Int, W> {
        var edges: [GraphEdge<Int, W>] = []
        
        for i in 0..<nodeCount {
            for j in i+1..<nodeCount {
                if Double.random(in: 0...1) < probability {
                    let weight = weightGenerator()
                    edges.append(GraphEdge(source: i, destination: j, value: weight))
                    edges.append(GraphEdge(source: j, destination: i, value: weight))
                }
            }
        }
        
        return ConnectedGraph(edges: edges)
    }
}

let weighted = ConnectedGraph<Int, Double>.randomWeighted(
    nodeCount: 50,
    probability: 0.1,
    weightGenerator: { Double.random(in: 1...10) }
)
```

## Graph Properties Analysis

```swift
extension Graph where Node: Hashable {
    func clusteringCoefficient() -> Double {
        var totalCoefficient = 0.0
        
        for node in allNodes {
            let neighbors = Set(edges(from: node).map(\.destination))
            guard neighbors.count > 1 else { continue }
            
            var triangles = 0
            for n1 in neighbors {
                for n2 in neighbors where n1 != n2 {
                    if edges(from: n1).contains(where: { $0.destination == n2 }) {
                        triangles += 1
                    }
                }
            }
            
            let possible = neighbors.count * (neighbors.count - 1)
            totalCoefficient += Double(triangles) / Double(possible)
        }
        
        return totalCoefficient / Double(allNodes.count)
    }
    
    func diameter() -> Int {
        var maxDistance = 0
        
        for source in allNodes {
            for visit in traversal(from: source, strategy: .bfs().trackDistance()) {
                maxDistance = max(maxDistance, visit.distance)
            }
        }
        
        return maxDistance
    }
}
```

## See Also

- <doc:GraphProperties>
- <doc:TraversalAlgorithms>
- ``RandomGraphGeneration``
- ``ErdosRenyiRandomGraphGenerator``
- ``BarabasiAlbertRandomGraphGenerator``
- ``WattsStrogatzRandomGraphGenerator``
