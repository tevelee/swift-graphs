# Flow and Matching Algorithms

Network flow and bipartite matching algorithms for optimization problems.

## Overview

Flow and matching algorithms solve optimization problems in networks. The library provides maximum flow algorithms for general networks and specialized matching algorithms for bipartite graphs.

## Maximum Flow Algorithms

Maximum flow algorithms find the maximum amount of "flow" that can be pushed from a source to a sink in a flow network.

### Network Flow Concepts

**Flow Network**: A directed graph where:
- Each edge has a **capacity** (maximum flow)
- Flow must satisfy:
  - **Capacity constraint**: Flow on edge ≤ capacity
  - **Conservation**: Flow in = flow out (except source/sink)

**Applications**:
- Network routing (data, traffic, fluids)
- Bipartite matching
- Image segmentation
- Airline scheduling
- Project selection

### Ford-Fulkerson Algorithm

The foundational maximum flow algorithm using augmenting paths.

```swift
struct Capacity: Weighted {
    let max: Int
    var weight: Int { max }
}

let network = ConnectedGraph(edges: [
    "S": ["A": Capacity(max: 10), "B": Capacity(max: 5)],
    "A": ["B": Capacity(max: 15), "T": Capacity(max: 10)],
    "B": ["T": Capacity(max: 10)],
    "T": []
])

let result = network.maximumFlow(
    from: "S",
    to: "T",
    using: .fordFulkerson()
)

print("Maximum flow: \(result.maxFlow)")
print("Min-cut capacity: \(result.minCutCapacity)")
```

**Characteristics:**
- **Time Complexity**: O(E × max_flow) - depends on flow value!
- **Space Complexity**: O(V + E)
- **Method**: Augmenting paths (any path)
- **Warning**: May not terminate with irrational capacities

**How it works:**
1. Start with zero flow
2. While there exists augmenting path from source to sink:
   - Find path in residual graph
   - Determine bottleneck (minimum capacity on path)
   - Augment flow along path
3. Return maximum flow

**Best For:**
- Small networks
- Integer capacities
- Educational purposes
- Understanding flow algorithms

### Edmonds-Karp Algorithm

Ford-Fulkerson with BFS for finding augmenting paths.

```swift
let result = network.maximumFlow(
    from: "S",
    to: "T",
    using: .edmondsKarp()
)
```

**Characteristics:**
- **Time Complexity**: O(VE²) - polynomial time!
- **Space Complexity**: O(V + E)
- **Method**: Shortest augmenting paths (BFS)
- **Guarantee**: Always terminates

**How it works:**
1. Same as Ford-Fulkerson
2. But use BFS to find **shortest** augmenting path
3. This guarantees polynomial time

**Best For:**
- General networks
- Guaranteed polynomial time
- When flow values are large
- Production use

**Implementation Detail:**
```swift
struct EdmondsKarpAlgorithm<Node: Hashable, Edge: Weighted>: MaxFlowAlgorithm
where Edge.Weight: Numeric & Comparable {
    func maximumFlow(
        from source: Node,
        to sink: Node,
        in graph: some GraphComponent<Node, Edge>
    ) -> MaxFlowResult<Node, Edge> {
        var residual = graph.residual()
        var maxFlow: Edge.Weight = .zero
        
        // BFS to find augmenting path
        while let path = residual.shortestPath(from: source, to: sink, using: .bfs()) {
            // Find bottleneck
            let bottleneck = path.edges.map(\.value.weight).min()!
            
            // Augment flow
            for edge in path.edges {
                residual.addFlow(bottleneck, along: edge)
            }
            
            maxFlow += bottleneck
        }
        
        return MaxFlowResult(maxFlow: maxFlow, residualGraph: residual)
    }
}
```

### Dinic's Algorithm

Optimized flow algorithm using level graphs and blocking flows.

```swift
let result = network.maximumFlow(
    from: "S",
    to: "T",
    using: .dinic()
)
```

**Characteristics:**
- **Time Complexity**: O(V²E) - best for dense graphs
- **Space Complexity**: O(V + E)
- **Method**: Level graph + blocking flows
- **Special case**: O(E × sqrt(V)) for unit capacities

**How it works:**
1. Build level graph using BFS
2. Find blocking flow in level graph using DFS
3. Repeat until no augmenting path exists

**Phases:**
- **Level graph**: Nodes at distance d from source
- **Blocking flow**: No more augmenting paths in level graph

**Best For:**
- Dense graphs
- Unit capacity networks
- Bipartite matching
- High-performance needs

### Comparison of Flow Algorithms

| Algorithm | Time Complexity | Best Use Case |
|-----------|----------------|---------------|
| Ford-Fulkerson | O(E × f) | Small, integer capacities |
| Edmonds-Karp | O(VE²) | General purpose |
| Dinic | O(V²E) | Dense graphs, unit capacities |

where f is maximum flow value.

### Maximum Flow Result

All flow algorithms return a `MaxFlowResult`:

```swift
struct MaxFlowResult<Node, Edge> {
    let maxFlow: Edge.Weight
    let residualGraph: ResidualGraph<Node, Edge>
    
    // Compute minimum cut
    var minCut: Set<GraphEdge<Node, Edge>> {
        // Edges from reachable to unreachable nodes
    }
    
    // Flow on each edge
    func flow(on edge: GraphEdge<Node, Edge>) -> Edge.Weight {
        residualGraph.flow(on: edge)
    }
}
```

## Min-Cut Max-Flow Theorem

The maximum flow equals the minimum cut capacity.

```swift
let result = network.maximumFlow(from: "S", to: "T", using: .dinic())

print("Max flow: \(result.maxFlow)")
print("Min cut: \(result.minCut)")
print("Are they equal? \(result.maxFlow == result.minCutCapacity)")  // Always true!
```

**Minimum Cut**: Smallest total capacity of edges whose removal disconnects source from sink.

**Applications:**
- Network reliability
- Image segmentation
- Community detection

## Bipartite Matching

Matching algorithms find maximum set of non-adjacent edges in bipartite graphs.

### Maximum Bipartite Matching

```swift
struct Job: Hashable {
    let id: String
}

struct Worker: Hashable {
    let name: String
}

let assignments = [
    (Worker(name: "Alice"), Job(id: "Job1")),
    (Worker(name: "Alice"), Job(id: "Job2")),
    (Worker(name: "Bob"), Job(id: "Job2")),
    (Worker(name: "Bob"), Job(id: "Job3")),
    (Worker(name: "Charlie"), Job(id: "Job1")),
    (Worker(name: "Charlie"), Job(id: "Job3"))
]

let graph = ConnectedGraph(edges: assignments.map {
    GraphEdge(source: $0.0, destination: $0.1)
})

let bipartite = graph.bipartite(
    leftPartition: [Worker(name: "Alice"), Worker(name: "Bob"), Worker(name: "Charlie")],
    rightPartition: [Job(id: "Job1"), Job(id: "Job2"), Job(id: "Job3")]
)

let matching = bipartite.maximumMatching(using: .hopcroftKarp())

print("Maximum matching size: \(matching.count)")
for (worker, job) in matching {
    print("\(worker.name) → \(job.id)")
}
```

### Hopcroft-Karp Algorithm

Fastest algorithm for maximum bipartite matching.

**Characteristics:**
- **Time Complexity**: O(E × sqrt(V))
- **Space Complexity**: O(V)
- **Optimality**: Finds maximum matching
- **Method**: Augmenting paths with phases

**How it works:**
1. Start with empty matching
2. Find maximal set of shortest augmenting paths
3. Augment along all paths simultaneously
4. Repeat until no augmenting paths

**Best For:**
- Bipartite matching
- Assignment problems
- Resource allocation
- Job scheduling

## Practical Applications

### Network Routing

Maximum data flow through network:

```swift
struct Bandwidth: Weighted {
    let mbps: Double
    var weight: Double { mbps }
}

let network = ConnectedHashGraph<Router, Bandwidth>(edges: links)

let result = network.maximumFlow(
    from: sourceRouter,
    to: destinationRouter,
    using: .dinic()
)

print("Maximum bandwidth: \(result.maxFlow) Mbps")

// Find bottleneck links (minimum cut)
for edge in result.minCut {
    print("Bottleneck: \(edge.source) → \(edge.destination): \(edge.value.mbps) Mbps")
}
```

### Image Segmentation

Separate foreground from background:

```swift
struct Pixel {
    let x, y: Int
}

let image = GridGraph<Pixel>(grid: pixelGrid)

// Add source (foreground) and sink (background)
var networkEdges: [GraphEdge<Node, Double>] = []

for pixel in image.allNodes {
    // Connect to source based on foreground likelihood
    let foregroundWeight = foregroundProbability(pixel)
    networkEdges.append(GraphEdge(source: "source", destination: pixel, value: foregroundWeight))
    
    // Connect to sink based on background likelihood
    let backgroundWeight = backgroundProbability(pixel)
    networkEdges.append(GraphEdge(source: pixel, destination: "sink", value: backgroundWeight))
    
    // Connect neighboring pixels (edge weights based on similarity)
    for neighbor in image.edges(from: pixel) {
        let similarity = pixelSimilarity(pixel, neighbor.destination)
        networkEdges.append(GraphEdge(source: pixel, destination: neighbor.destination, value: similarity))
    }
}

let network = ConnectedGraph(edges: networkEdges)
let result = network.maximumFlow(from: "source", to: "sink", using: .dinic())

// Min-cut gives segmentation
let foregroundPixels = result.reachableFromSource
let backgroundPixels = result.unreachableFromSource
```

### Job Assignment

Assign workers to jobs:

```swift
let workers = ["Alice", "Bob", "Charlie", "David"]
let jobs = ["Job1", "Job2", "Job3", "Job4", "Job5"]

// Alice can do Job1, Job2
// Bob can do Job2, Job3
// etc.
let capabilities = [
    "Alice": ["Job1", "Job2"],
    "Bob": ["Job2", "Job3"],
    "Charlie": ["Job1", "Job3", "Job4"],
    "David": ["Job4", "Job5"]
]

var edges: [GraphEdge<String, Empty>] = []
for (worker, jobs) in capabilities {
    for job in jobs {
        edges.append(GraphEdge(source: worker, destination: job))
    }
}

let graph = ConnectedGraph(edges: edges)
let bipartite = graph.bipartite(
    leftPartition: workers,
    rightPartition: jobs
)

let assignment = bipartite.maximumMatching(using: .hopcroftKarp())

print("Assigned \(assignment.count) jobs:")
for (worker, job) in assignment {
    print("\(worker) → \(job)")
}

// Check if all jobs assigned
if assignment.count == jobs.count {
    print("All jobs assigned!")
} else {
    print("Need more workers or relaxed constraints")
}
```

### Supply Chain Optimization

```swift
struct Warehouse: Hashable {
    let id: String
}

struct Store: Hashable {
    let id: String
}

struct Supply: Weighted {
    let quantity: Int
    var weight: Int { quantity }
}

// Warehouses with supply capacity
let warehouses = [
    Warehouse(id: "W1"),
    Warehouse(id: "W2"),
    Warehouse(id: "W3")
]

// Stores with demand
let stores = [
    Store(id: "S1"),
    Store(id: "S2"),
    Store(id: "S3"),
    Store(id: "S4")
]

// Build flow network
var flowEdges: [GraphEdge<String, Supply>] = []

// Source to warehouses (supply capacity)
flowEdges.append(GraphEdge(source: "source", destination: "W1", value: Supply(quantity: 100)))
flowEdges.append(GraphEdge(source: "source", destination: "W2", value: Supply(quantity: 150)))
flowEdges.append(GraphEdge(source: "source", destination: "W3", value: Supply(quantity: 120)))

// Warehouses to stores (shipping capacity)
flowEdges.append(GraphEdge(source: "W1", destination: "S1", value: Supply(quantity: 80)))
flowEdges.append(GraphEdge(source: "W1", destination: "S2", value: Supply(quantity: 50)))
// ... more edges

// Stores to sink (demand)
flowEdges.append(GraphEdge(source: "S1", destination: "sink", value: Supply(quantity: 70)))
flowEdges.append(GraphEdge(source: "S2", destination: "sink", value: Supply(quantity: 90)))
// ... more edges

let network = ConnectedGraph(edges: flowEdges)
let result = network.maximumFlow(from: "source", to: "sink", using: .edmondsKarp())

print("Total items shipped: \(result.maxFlow)")

// Get actual flow on each route
for warehouse in warehouses {
    for store in stores {
        if let edge = flowEdges.first(where: { $0.source == warehouse.id && $0.destination == store.id }) {
            let flow = result.flow(on: edge)
            if flow > 0 {
                print("\(warehouse.id) → \(store.id): \(flow) items")
            }
        }
    }
}
```

### Baseball Elimination

Determine if a team can still win the division:

```swift
struct Team: Hashable {
    let name: String
    let wins: Int
    let remaining: Int
}

func canWinDivision(team: Team, opponents: [Team], games: [[Team]: Int]) -> Bool {
    // Team can win if: team.wins + team.remaining >= other.wins + flow(team, other)
    
    // Build flow network
    // Source → games
    // games → teams
    // teams → sink (capacity = max wins - current wins)
    
    let maxPossibleWins = team.wins + team.remaining
    var edges: [GraphEdge<String, Int>] = []
    
    // Source to game nodes
    for (matchup, count) in games {
        let gameNode = "\(matchup[0].name)_vs_\(matchup[1].name)"
        edges.append(GraphEdge(source: "source", destination: gameNode, value: count))
        
        // Game nodes to teams
        edges.append(GraphEdge(source: gameNode, destination: matchup[0].name, value: count))
        edges.append(GraphEdge(source: gameNode, destination: matchup[1].name, value: count))
    }
    
    // Teams to sink
    for opponent in opponents {
        let capacity = max(0, maxPossibleWins - opponent.wins)
        edges.append(GraphEdge(source: opponent.name, destination: "sink", value: capacity))
    }
    
    let network = ConnectedGraph(edges: edges)
    let result = network.maximumFlow(from: "source", to: "sink", using: .dinic())
    
    let totalGames = games.values.reduce(0, +)
    return result.maxFlow == totalGames
}
```

## Advanced Techniques

### Multi-Source Multi-Sink Flow

Add super-source and super-sink:

```swift
func multiSourceSinkFlow<G: GraphComponent>(
    graph: G,
    sources: [G.Node],
    sinks: [G.Node]
) -> G.Edge.Weight where G.Edge: Weighted {
    var edges = graph.allEdges
    
    // Add super-source with infinite capacity to all sources
    for source in sources {
        edges.append(GraphEdge(source: "super_source", destination: source, value: .max))
    }
    
    // Add super-sink with infinite capacity from all sinks
    for sink in sinks {
        edges.append(GraphEdge(source: sink, destination: "super_sink", value: .max))
    }
    
    let augmented = ConnectedGraph(edges: edges)
    let result = augmented.maximumFlow(from: "super_source", to: "super_sink", using: .dinic())
    
    return result.maxFlow
}
```

### Minimum Cost Flow

Find flow that minimizes cost (more advanced):

```swift
struct CostCapacity: Weighted {
    let capacity: Int
    let costPerUnit: Double
    
    var weight: Int { capacity }
}

// Use min-cost max-flow algorithm (extension)
let result = network.minimumCostMaximumFlow(
    from: source,
    to: sink,
    using: .successiveShortestPath()
)
```

### Vertex Capacities

Convert vertex capacity to edge capacities:

```swift
func withVertexCapacities<G: Graph>(
    graph: G,
    capacity: (G.Node) -> G.Edge.Weight
) -> ConnectedGraph<String, G.Edge> {
    var edges: [GraphEdge<String, G.Edge>] = []
    
    for node in graph.allNodes {
        // Split node into in and out
        let nodeIn = "\(node)_in"
        let nodeOut = "\(node)_out"
        
        // Add edge with vertex capacity
        edges.append(GraphEdge(
            source: nodeIn,
            destination: nodeOut,
            value: capacity(node)
        ))
        
        // Redirect edges
        for edge in graph.edges(from: node) {
            edges.append(GraphEdge(
                source: nodeOut,
                destination: "\(edge.destination)_in",
                value: edge.value
            ))
        }
    }
    
    return ConnectedGraph(edges: edges)
}
```

## See Also

- <doc:ShortestPathAlgorithms>
- <doc:GraphProperties>
- ``MaxFlowAlgorithm``
- ``MaximumMatchingAlgorithm``
- ``FordFulkersonAlgorithm``
- ``EdmondsKarpAlgorithm``
- ``DinicAlgorithm``
- ``HopcroftKarpAlgorithm``
- ``BipartiteGraph``
