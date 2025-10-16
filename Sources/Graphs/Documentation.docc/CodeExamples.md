# Code Examples and Snippets

Practical, runnable examples demonstrating the library's capabilities.

## Getting Started

### Basic Graph Creation

```swift
import Graphs

// Simple graph with string nodes
let graph = ConnectedGraph(edges: [
    "A": ["B", "C"],
    "B": ["D"],
    "C": ["D"]
])

// Traverse the graph
let nodes = graph.traverse(from: "A", strategy: .bfs())
print(nodes)  // [A, B, C, D]
```

### Weighted Graphs

```swift
// Graph with weighted edges
let weighted = ConnectedGraph(edges: [
    "A": ["B": 4, "C": 2],
    "B": ["D": 5],
    "C": ["B": 1, "D": 8],
    "D": []
])

// Find shortest path
let path = weighted.shortestPath(from: "A", to: "D", using: .dijkstra())
print("Path: \(path?.path ?? [])")
print("Cost: \(path?.cost ?? 0)")
```

## Traversal Examples

### Breadth-First Search

```swift
let tree = ConnectedGraph(edges: [
    "Root": ["A", "B"],
    "A": ["C", "D"],
    "B": ["E", "F"],
    "C": [],
    "D": [],
    "E": [],
    "F": []
])

// Simple BFS
let bfsOrder = tree.traverse(from: "Root", strategy: .bfs())
// [Root, A, B, C, D, E, F]

// BFS with path tracking
for visit in tree.traversal(from: "Root", strategy: .bfs().trackPath()) {
    print("\(visit.node): path = \(visit.path)")
}
// Root: path = [Root]
// A: path = [Root, A]
// B: path = [Root, B]
// ...
```

### Depth-First Search

```swift
// DFS traversal
let dfsOrder = tree.traverse(from: "Root", strategy: .dfs())

// Binary tree with inorder traversal
let binaryTree = ConnectedBinaryGraph(edges: [
    "F": (lhs: "B", rhs: "G"),
    "B": (lhs: "A", rhs: "D"),
    "D": (lhs: "C", rhs: "E"),
    "G": (lhs: nil, rhs: "I"),
    "I": (lhs: "H", rhs: nil)
])

let inorder = binaryTree.traverse(from: "F", strategy: .dfs(order: .inorder()))
// [A, B, C, D, E, F, G, H, I]
```

### Finding Shortest Path (Unweighted)

```swift
// Find shortest path using BFS
func findPath<G: GraphComponent>(
    in graph: G,
    from start: G.Node,
    to goal: G.Node
) -> [G.Node]? where G.Node: Equatable {
    for visit in graph.traversal(from: start, strategy: .bfs().trackPath()) {
        if visit.node == goal {
            return visit.path
        }
    }
    return nil
}

let path = findPath(in: graph, from: "A", to: "D")
print(path ?? [])  // [A, B, D]
```

## Shortest Path Examples

### Dijkstra's Algorithm

```swift
struct City: Hashable {
    let name: String
}

struct Road: Weighted {
    let distance: Double
    var weight: Double { distance }
}

let cities = ConnectedGraph(edges: [
    City(name: "SF"): [
        City(name: "LA"): Road(distance: 380),
        City(name: "Portland"): Road(distance: 630)
    ],
    City(name: "LA"): [
        City(name: "Vegas"): Road(distance: 270),
        City(name: "Phoenix"): Road(distance: 370)
    ],
    City(name: "Portland"): [
        City(name: "Seattle"): Road(distance: 175)
    ],
    City(name: "Vegas"): [
        City(name: "Phoenix"): Road(distance: 300)
    ],
    City(name: "Phoenix"): [],
    City(name: "Seattle"): []
])

let sf = City(name: "SF")
let phoenix = City(name: "Phoenix")

if let route = cities.shortestPath(from: sf, to: phoenix, using: .dijkstra()) {
    print("Route: \(route.path.map(\.name))")
    print("Distance: \(route.cost) miles")
}
// Route: [SF, LA, Vegas, Phoenix]
// Distance: 920 miles
```

### A* Algorithm with Grid

```swift
let grid = GridGraph(grid: [
    [".", ".", ".", ".", "."],
    [".", "#", "#", ".", "."],
    [".", ".", ".", "#", "."],
    [".", ".", ".", ".", "."],
    [".", ".", ".", ".", "."]
], availableDirections: .orthogonal)
    .weightedByDistance()

let start = GridPosition(x: 0, y: 0)
let goal = GridPosition(x: 4, y: 4)

let path = grid.shortestPath(
    from: start,
    to: goal,
    using: .aStar(heuristic: .manhattanDistance(of: \.coordinates))
)

print("Path length: \(path?.edges.count ?? 0)")
```

### Bellman-Ford with Negative Weights

```swift
let graph = ConnectedGraph(edges: [
    "A": ["B": 4, "C": 2],
    "B": ["C": -3, "D": 2],
    "C": ["D": 3],
    "D": []
])

if let path = graph.shortestPath(from: "A", to: "D", using: .bellmanFord()) {
    print("Path with negative edges: \(path.path)")
    print("Total cost: \(path.cost)")
}
```

## Minimum Spanning Tree Examples

### Kruskal's Algorithm

```swift
struct Connection: Weighted {
    let cost: Double
    var weight: Double { cost }
}

let network = ConnectedGraph(edges: [
    "A": ["B": Connection(cost: 4), "C": Connection(cost: 2)],
    "B": ["C": Connection(cost: 1), "D": Connection(cost: 5)],
    "C": ["D": Connection(cost: 8), "E": Connection(cost: 10)],
    "D": ["E": Connection(cost: 2)],
    "E": []
]).undirected()

let mst = network.minimumSpanningTree(using: .kruskal())

let totalCost = mst.reduce(0.0) { $0 + $1.value.cost }
print("MST cost: \(totalCost)")
// MST cost: 10.0

print("MST edges:")
for edge in mst.sorted(by: { $0.value.cost < $1.value.cost }) {
    print("\(edge.source) — \(edge.destination): \(edge.value.cost)")
}
```

### Network Design Problem

```swift
let cities = ["NYC", "LA", "Chicago", "Houston", "Phoenix"]
var connections: [GraphEdge<String, Double>] = []

// Generate all possible connections with distances
for i in 0..<cities.count {
    for j in i+1..<cities.count {
        let distance = calculateDistance(cities[i], cities[j])
        connections.append(GraphEdge(source: cities[i], destination: cities[j], value: distance))
        connections.append(GraphEdge(source: cities[j], destination: cities[i], value: distance))
    }
}

let allConnections = ConnectedGraph(edges: connections)
let minimalNetwork = allConnections.minimumSpanningTree(using: .prim())

print("Build these connections:")
for edge in minimalNetwork {
    print("\(edge.source) ↔ \(edge.destination): \(edge.value) miles")
}
```

## Flow and Matching Examples

### Maximum Flow

```swift
struct Capacity: Weighted {
    let max: Int
    var weight: Int { max }
}

let flowNetwork = ConnectedGraph(edges: [
    "Source": [
        "A": Capacity(max: 10),
        "B": Capacity(max: 5)
    ],
    "A": [
        "C": Capacity(max: 15),
        "Sink": Capacity(max: 10)
    ],
    "B": [
        "A": Capacity(max: 4),
        "Sink": Capacity(max: 10)
    ],
    "C": [
        "Sink": Capacity(max: 10)
    ],
    "Sink": []
])

let result = flowNetwork.maximumFlow(
    from: "Source",
    to: "Sink",
    using: .edmondsKarp()
)

print("Maximum flow: \(result.maxFlow)")

// Get flow on each edge
for edge in flowNetwork.allEdges {
    let flow = result.flow(on: edge)
    if flow > 0 {
        print("\(edge.source) → \(edge.destination): \(flow)/\(edge.value.max)")
    }
}
```

### Bipartite Matching

```swift
struct Student: Hashable {
    let name: String
}

struct Project: Hashable {
    let title: String
}

let preferences: [GraphEdge<Student, Empty>] = [
    GraphEdge(source: Student(name: "Alice"), destination: Project(title: "AI")),
    GraphEdge(source: Student(name: "Alice"), destination: Project(title: "Web")),
    GraphEdge(source: Student(name: "Bob"), destination: Project(title: "AI")),
    GraphEdge(source: Student(name: "Bob"), destination: Project(title: "Mobile")),
    GraphEdge(source: Student(name: "Charlie"), destination: Project(title: "Web")),
    GraphEdge(source: Student(name: "Charlie"), destination: Project(title: "Mobile"))
]

let graph = ConnectedGraph(edges: preferences)
let bipartite = graph.bipartite(
    leftPartition: [Student(name: "Alice"), Student(name: "Bob"), Student(name: "Charlie")],
    rightPartition: [Project(title: "AI"), Project(title: "Web"), Project(title: "Mobile")]
)

let matching = bipartite.maximumMatching(using: .hopcroftKarp())

print("Assignments:")
for (student, project) in matching {
    print("\(student.name) → \(project.title)")
}
```

## Graph Properties Examples

### Checking Connectivity

```swift
let graph = ConnectedGraph(edges: [
    "A": ["B", "C"],
    "B": ["C"],
    "C": ["A"],
    "D": ["E"],
    "E": ["D"]
])

print("Is connected: \(graph.isConnected())")  // false

let components = graph.connectedComponents()
print("Components: \(components.count)")  // 2
```

### Cycle Detection

```swift
let dag = ConnectedGraph(edges: [
    "A": ["B", "C"],
    "B": ["D"],
    "C": ["D"],
    "D": []
])

print("Is cyclic: \(dag.isCyclic())")  // false

let cyclic = ConnectedGraph(edges: [
    "A": ["B"],
    "B": ["C"],
    "C": ["A"]
])

print("Is cyclic: \(cyclic.isCyclic())")  // true
```

### Topological Sort

```swift
let tasks = ConnectedGraph(edges: [
    "Get dressed": ["Leave house"],
    "Eat breakfast": ["Leave house"],
    "Brush teeth": ["Leave house"],
    "Wake up": ["Get dressed", "Eat breakfast", "Brush teeth"],
    "Leave house": []
])

if let order = tasks.topologicalSort() {
    print("Task order:")
    for task in order {
        print("- \(task)")
    }
}
// Wake up
// Get dressed
// Eat breakfast  
// Brush teeth
// Leave house
```

### Strongly Connected Components

```swift
let directed = ConnectedGraph(edges: [
    "A": ["B"],
    "B": ["C", "E"],
    "C": ["D"],
    "D": ["C"],
    "E": ["A", "F"],
    "F": ["G"],
    "G": ["E"]
])

let sccs = directed.stronglyConnectedComponents(using: .tarjan())
print("Strongly connected components: \(sccs.count)")
for (i, scc) in sccs.enumerated() {
    print("Component \(i): \(scc)")
}
```

## Graph Coloring Examples

### Basic Coloring

```swift
let graph = ConnectedGraph(edges: [
    "A": ["B", "C"],
    "B": ["A", "C", "D"],
    "C": ["A", "B", "D"],
    "D": ["B", "C"]
]).undirected()

let coloring = graph.colorNodes(using: .dsatur())

print("Colors used: \(Set(coloring.values).count)")
for (node, color) in coloring.sorted(by: { $0.key < $1.key }) {
    print("\(node): color \(color)")
}
```

### Exam Scheduling

```swift
struct Exam: Hashable {
    let course: String
}

// Build conflict graph (students taking both courses)
let conflicts = ConnectedGraph(edges: [
    Exam(course: "Math"): [Exam(course: "Physics")],
    Exam(course: "Physics"): [Exam(course: "Math"), Exam(course: "Chemistry")],
    Exam(course: "Chemistry"): [Exam(course: "Physics"), Exam(course: "Biology")],
    Exam(course: "Biology"): [Exam(course: "Chemistry")],
    Exam(course: "History"): [Exam(course: "English")],
    Exam(course: "English"): [Exam(course: "History")]
]).undirected()

let schedule = conflicts.colorNodes(using: .welshPowell())

var timeSlots: [Int: [Exam]] = [:]
for (exam, slot) in schedule {
    timeSlots[slot, default: []].append(exam)
}

print("Minimum time slots needed: \(timeSlots.count)")
for (slot, exams) in timeSlots.sorted(by: { $0.key < $1.key }) {
    print("Slot \(slot + 1): \(exams.map(\.course).joined(separator: ", "))")
}
```

## Random Graph Examples

### Erdős-Rényi Random Graph

```swift
let random = ConnectedGraph<Int, Empty>.random(
    nodeCount: 50,
    using: .erdosRenyi(probability: 0.1)
)

print("Nodes: \(random.allNodes.count)")
print("Edges: \(random.allEdges.count)")
print("Average degree: \(random.averageDegree())")
```

### Scale-Free Network

```swift
let scaleFree = ConnectedGraph<Int, Empty>.random(
    nodeCount: 100,
    using: .barabasiAlbert(attachmentCount: 3)
)

let degrees = scaleFree.degreeSequence()
print("Degree distribution (top 10):")
for (i, degree) in degrees.prefix(10).enumerated() {
    print("Node \(i): degree \(degree)")
}
```

### Small World Network

```swift
let smallWorld = ConnectedGraph<Int, Empty>.random(
    nodeCount: 100,
    using: .wattsStrogatz(neighbors: 4, rewiringProbability: 0.1)
)

print("Clustering coefficient: \(smallWorld.clusteringCoefficient())")
print("Average path length: \(smallWorld.averageShortestPathLength())")
```

## Advanced Examples

### Lazy Infinite Graph

```swift
// Infinite grid graph computed on-demand
let infiniteGrid = LazyGraph<(Int, Int), Empty> { (x, y) in
    [
        GraphEdge(source: (x, y), destination: (x+1, y)),
        GraphEdge(source: (x, y), destination: (x-1, y)),
        GraphEdge(source: (x, y), destination: (x, y+1)),
        GraphEdge(source: (x, y), destination: (x, y-1))
    ]
}

// BFS on infinite graph (will explore forever unless limited)
let nearby = infiniteGrid.traverse(
    from: (0, 0),
    strategy: .bfs().visitEachNodeOnce().limited(depth: 5)
)
print("Nodes within 5 steps: \(nearby.count)")
```

### Graph Transformations

```swift
let directed = ConnectedGraph(edges: [
    "A": ["B", "C"],
    "B": ["D"],
    "C": ["D"]
])

// Make undirected
let undirected = directed.undirected()

// Transpose (reverse edges)
let transposed = directed.transposed()

// Complement
let complement = directed.complement()

// Chain transformations
let complex = directed
    .undirected()
    .filtered { edge in
        // Only certain edges
        edge.source < edge.destination
    }
    .weighted { _ in Double.random(in: 1...10) }

let mst = complex.minimumSpanningTree(using: .kruskal())
```

### Custom Graph Type

```swift
// Database-backed graph
struct DatabaseGraph: GraphComponent {
    let database: Database
    
    func edges(from userID: Int) -> [GraphEdge<Int, Empty>] {
        database.query("""
            SELECT friend_id FROM friendships 
            WHERE user_id = ?
        """, userID).map { friendID in
            GraphEdge(source: userID, destination: friendID)
        }
    }
}

let socialNetwork = DatabaseGraph(database: myDatabase)

// All algorithms work automatically
let friends = socialNetwork.traverse(from: currentUserID, strategy: .bfs())
```

## See Also

- <doc:TraversalAlgorithms>
- <doc:ShortestPathAlgorithms>
- <doc:MinimumSpanningTree>
- <doc:FlowAndMatching>
- <doc:GraphColoring>
- <doc:RandomGraphGeneration>
