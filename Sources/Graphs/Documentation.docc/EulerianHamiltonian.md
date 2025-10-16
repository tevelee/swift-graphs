# Eulerian and Hamiltonian Paths

Algorithms for finding special paths and cycles that visit edges or vertices.

## Overview

Eulerian and Hamiltonian paths are classical graph theory problems with different characteristics. While Eulerian paths (visiting every edge once) have polynomial-time solutions, Hamiltonian paths (visiting every vertex once) are NP-complete.

## Eulerian Paths and Cycles

An **Eulerian path** visits every edge exactly once. An **Eulerian cycle** is an Eulerian path that starts and ends at the same vertex.

### Existence Conditions

**Undirected Graphs:**
- **Eulerian cycle**: All vertices have even degree
- **Eulerian path**: Exactly 0 or 2 vertices have odd degree

**Directed Graphs:**
- **Eulerian cycle**: All vertices have equal in-degree and out-degree
- **Eulerian path**: At most one vertex has (out-degree - in-degree = 1), at most one has (in-degree - out-degree = 1)

### Check for Eulerian Path/Cycle

```swift
extension Graph where Node: Hashable {
    func hasEulerianCycle() -> Bool {
        guard isConnected() else { return false }
        
        // All vertices must have even degree
        for node in allNodes {
            if edges(from: node).count % 2 != 0 {
                return false
            }
        }
        
        return true
    }
    
    func hasEulerianPath() -> Bool {
        guard isConnected() else { return false }
        
        var oddDegreeCount = 0
        for node in allNodes {
            if edges(from: node).count % 2 != 0 {
                oddDegreeCount += 1
            }
        }
        
        return oddDegreeCount == 0 || oddDegreeCount == 2
    }
}
```

### Hierholzer's Algorithm

Efficient algorithm for finding Eulerian cycles and paths.

```swift
let graph = ConnectedGraph(edges: [
    "A": ["B"],
    "B": ["C", "D"],
    "C": ["D"],
    "D": ["A"]
]).undirected()

if let cycle = graph.eulerianCycle(using: .hierholzer()) {
    print("Eulerian cycle: \(cycle.map(\.source))")
    // [A, B, C, D, B, D, A] or similar
}
```

**Characteristics:**
- **Time Complexity**: O(E)
- **Space Complexity**: O(E)
- **Guarantee**: Finds cycle if it exists
- **Method**: Iterative cycle building

**How it works:**
1. Start from any vertex
2. Follow edges, removing them as you go
3. When stuck, backtrack to vertex with unused edges
4. Insert new cycles into existing path
5. Continue until all edges used

**Best For:**
- Finding Eulerian cycles/paths
- Route planning (Chinese Postman Problem)
- Network traversal

**Implementation Sketch:**
```swift
struct HierholzerEulerianPathAlgorithm<Node: Hashable>: EulerianPathAlgorithm {
    func eulerianCycle(in graph: some Graph<Node, Empty>) -> [GraphEdge<Node, Empty>]? {
        guard graph.hasEulerianCycle() else { return nil }
        
        var availableEdges = graph.allEdges
        var circuit: [GraphEdge<Node, Empty>] = []
        var stack: [Node] = [graph.allNodes.first!]
        
        while let current = stack.last {
            if let edgeIndex = availableEdges.firstIndex(where: { $0.source == current }) {
                let edge = availableEdges.remove(at: edgeIndex)
                stack.append(edge.destination)
            } else {
                if let node = stack.popLast() {
                    if let prev = stack.last {
                        circuit.append(GraphEdge(source: prev, destination: node))
                    }
                }
            }
        }
        
        return circuit.reversed()
    }
}
```

### Fleury's Algorithm (Alternative)

Backtracking-based Eulerian path algorithm:

```swift
if let path = graph.eulerianPath(using: .backtracking()) {
    print("Eulerian path found")
}
```

**Characteristics:**
- **Time Complexity**: O(E²)
- **Simpler**: Easier to understand
- **Less efficient**: Slower than Hierholzer

## Hamiltonian Paths and Cycles

A **Hamiltonian path** visits every vertex exactly once. A **Hamiltonian cycle** is a Hamiltonian path that returns to the starting vertex.

### NP-Complete Problem

Unlike Eulerian paths, determining if a Hamiltonian path exists is NP-complete. No efficient algorithm exists for general graphs.

### Backtracking Algorithm

Exhaustive search with pruning:

```swift
let graph = ConnectedGraph(edges: [
    "A": ["B", "C"],
    "B": ["A", "C", "D"],
    "C": ["A", "B", "D"],
    "D": ["B", "C"]
])

if let path = graph.hamiltonianPath(using: .backtracking()) {
    print("Hamiltonian path: \(path.map(\.source))")
    // [A, B, D, C] or similar
}
```

**Characteristics:**
- **Time Complexity**: O(n!) worst case
- **Space Complexity**: O(n)
- **Completeness**: Finds path if exists
- **Method**: Depth-first search with backtracking

**How it works:**
1. Start from a vertex
2. Try each unvisited neighbor
3. Recursively continue from neighbor
4. If all vertices visited, success
5. If stuck, backtrack and try another path

**Best For:**
- Small graphs (n < 20)
- Guaranteed solution needed
- When all solutions needed

**Implementation:**
```swift
struct BacktrackingHamiltonianPathAlgorithm<Node: Hashable>: HamiltonianPathAlgorithm {
    func hamiltonianPath(in graph: some Graph<Node, Empty>) -> [Node]? {
        var visited: Set<Node> = []
        var path: [Node] = []
        
        func backtrack(_ node: Node) -> Bool {
            visited.insert(node)
            path.append(node)
            
            if path.count == graph.allNodes.count {
                return true
            }
            
            for edge in graph.edges(from: node) {
                if !visited.contains(edge.destination) {
                    if backtrack(edge.destination) {
                        return true
                    }
                }
            }
            
            visited.remove(node)
            path.removeLast()
            return false
        }
        
        for start in graph.allNodes {
            if backtrack(start) {
                return path
            }
            visited.removeAll()
            path.removeAll()
        }
        
        return nil
    }
}
```

### Heuristic Algorithm

Fast approximation for Hamiltonian paths:

```swift
if let path = graph.hamiltonianPath(using: .heuristic()) {
    print("Found approximate Hamiltonian path")
    print("May not always find path even if exists")
}
```

**Characteristics:**
- **Time Complexity**: O(V²)
- **Approximation**: Not guaranteed to find path
- **Speed**: Much faster than backtracking

**Heuristics:**
- Nearest neighbor
- Greedy degree-based
- Minimum spanning tree based

**Best For:**
- Large graphs
- When approximate solution acceptable
- Time-critical applications

### Hamiltonian Cycle from Path

```swift
extension Graph where Node: Hashable {
    func hamiltonianCycle(using algorithm: some HamiltonianPathAlgorithm<Node>) -> [Node]? {
        guard let path = hamiltonianPath(using: algorithm) else {
            return nil
        }
        
        // Check if path can form cycle
        if let start = path.first, let end = path.last {
            if edges(from: end).contains(where: { $0.destination == start }) {
                return path
            }
        }
        
        return nil
    }
}
```

## Practical Applications

### Seven Bridges of Königsberg

Classic Eulerian path problem:

```swift
// The seven bridges problem
let konigsberg = ConnectedGraph(edges: [
    "North": ["Island", "Island"],
    "South": ["Island", "Island"],
    "East": ["Island"],
    "West": ["Island"],
    "Island": ["North", "North", "South", "South", "East", "West"]
])

if konigsberg.hasEulerianPath() {
    print("Can walk across all bridges exactly once")
} else {
    print("Impossible to cross all bridges exactly once")
    // This is the actual result - impossible!
}
```

### Traveling Salesman Problem (TSP)

Finding shortest Hamiltonian cycle:

```swift
struct City: Hashable {
    let name: String
}

struct Distance: Weighted {
    let km: Double
    var weight: Double { km }
}

let cities = ConnectedGraph(edges: [
    City(name: "A"): [
        City(name: "B"): Distance(km: 10),
        City(name: "C"): Distance(km: 15),
        City(name: "D"): Distance(km: 20)
    ],
    // ... more cities
])

// Find shortest Hamiltonian cycle
var shortestCycle: [City]?
var shortestDistance = Double.infinity

// Try all possible Hamiltonian cycles (brute force for small n)
func tsp(current: City, visited: Set<City>, distance: Double) {
    if visited.count == cities.allNodes.count {
        // Check if can return to start
        if let start = shortestCycle?.first {
            if let returnEdge = cities.edges(from: current).first(where: { $0.destination == start }) {
                let totalDistance = distance + returnEdge.value.km
                if totalDistance < shortestDistance {
                    shortestDistance = totalDistance
                    shortestCycle = Array(visited) + [start]
                }
            }
        }
        return
    }
    
    for edge in cities.edges(from: current) where !visited.contains(edge.destination) {
        var newVisited = visited
        newVisited.insert(edge.destination)
        tsp(current: edge.destination, visited: newVisited, distance: distance + edge.value.km)
    }
}

if let start = cities.allNodes.first {
    tsp(current: start, visited: [start], distance: 0)
}

print("Shortest TSP tour: \(shortestDistance) km")
```

### Knight's Tour

Find Hamiltonian path for knight on chessboard:

```swift
struct Position: Hashable {
    let row, col: Int
}

// Generate knight moves
func knightMoves(from pos: Position) -> [Position] {
    let moves = [
        (2, 1), (2, -1), (-2, 1), (-2, -1),
        (1, 2), (1, -2), (-1, 2), (-1, -2)
    ]
    
    return moves.compactMap { dr, dc in
        let newRow = pos.row + dr
        let newCol = pos.col + dc
        guard newRow >= 0 && newRow < 8 && newCol >= 0 && newCol < 8 else {
            return nil
        }
        return Position(row: newRow, col: newCol)
    }
}

// Build knight graph
var edges: [GraphEdge<Position, Empty>] = []
for row in 0..<8 {
    for col in 0..<8 {
        let pos = Position(row: row, col: col)
        for move in knightMoves(from: pos) {
            edges.append(GraphEdge(source: pos, destination: move))
        }
    }
}

let knightGraph = ConnectedGraph(edges: edges)

// Find knight's tour (Hamiltonian path)
if let tour = knightGraph.hamiltonianPath(from: Position(row: 0, col: 0), using: .backtracking()) {
    print("Knight's tour found!")
    for (i, pos) in tour.enumerated() {
        print("Move \(i): (\(pos.row), \(pos.col))")
    }
}
```

### DNA Sequencing

Eulerian path for sequence assembly:

```swift
struct Kmer: Hashable {
    let sequence: String
    
    var prefix: String { String(sequence.dropLast()) }
    var suffix: String { String(sequence.dropFirst()) }
}

// Build de Bruijn graph from k-mers
func buildDeBruijnGraph(kmers: [Kmer]) -> ConnectedGraph<String, Empty> {
    var edges: [GraphEdge<String, Empty>] = []
    
    for kmer in kmers {
        edges.append(GraphEdge(source: kmer.prefix, destination: kmer.suffix))
    }
    
    return ConnectedGraph(edges: edges)
}

let kmers = [
    Kmer(sequence: "ATG"),
    Kmer(sequence: "TGC"),
    Kmer(sequence: "GCA"),
    Kmer(sequence: "CAT")
]

let graph = buildDeBruijnGraph(kmers: kmers)

if let path = graph.eulerianPath(using: .hierholzer()) {
    // Reconstruct sequence from Eulerian path
    var sequence = path.first?.source ?? ""
    for edge in path {
        sequence += String(edge.destination.last!)
    }
    print("Reconstructed sequence: \(sequence)")
    // ATGCAT
}
```

### Icosian Game

Hamilton's icosian game on dodecahedron:

```swift
// Dodecahedron graph (20 vertices)
let dodecahedron = ConnectedGraph(edges: dodecahedronEdges)

if let cycle = dodecahedron.hamiltonianCycle(using: .backtracking()) {
    print("Found Hamiltonian cycle on dodecahedron")
    print("This proves Hamilton's icosian game is solvable")
}
```

## Special Cases and Optimizations

### Complete Graphs

Complete graphs always have Hamiltonian cycles:

```swift
extension Graph where Node: Hashable {
    func isComplete() -> Bool {
        let n = allNodes.count
        return allEdges.count >= n * (n - 1) / 2
    }
}

if graph.isComplete() {
    print("Complete graph - Hamiltonian cycle guaranteed")
}
```

### Dirac's Theorem

If every vertex has degree ≥ n/2, then Hamiltonian cycle exists:

```swift
extension Graph where Node: Hashable {
    func satisfiesDiracTheorem() -> Bool {
        let n = allNodes.count
        let minDegree = allNodes.map { edges(from: $0).count }.min() ?? 0
        return minDegree >= n / 2
    }
}

if graph.satisfiesDiracTheorem() {
    print("Satisfies Dirac's theorem - Hamiltonian cycle exists")
}
```

### Ore's Theorem

For non-adjacent vertices u, v: deg(u) + deg(v) ≥ n implies Hamiltonian cycle:

```swift
extension Graph where Node: Hashable {
    func satisfiesOreTheorem() -> Bool {
        let n = allNodes.count
        
        for u in allNodes {
            let uNeighbors = Set(edges(from: u).map(\.destination))
            for v in allNodes where u != v && !uNeighbors.contains(v) {
                let degreeSum = edges(from: u).count + edges(from: v).count
                if degreeSum < n {
                    return false
                }
            }
        }
        
        return true
    }
}
```

## Algorithm Selection Guide

### Eulerian Paths

| Scenario | Algorithm | Rationale |
|----------|-----------|-----------|
| General case | Hierholzer | O(E) optimal |
| Simple implementation | Backtracking | Easier to understand |
| Directed graphs | Hierholzer | Handles both |

### Hamiltonian Paths

| Scenario | Algorithm | Rationale |
|----------|-----------|-----------|
| Small graphs (n < 20) | Backtracking | Guaranteed solution |
| Large graphs | Heuristic | Only viable option |
| Complete/dense graphs | Any | Multiple solutions exist |

## See Also

- <doc:TraversalAlgorithms>
- <doc:GraphProperties>
- ``EulerianPathAlgorithm``
- ``HamiltonianPathAlgorithm``
- ``HierholzerEulerianPathAlgorithm``
- ``BacktrackingHamiltonianPathAlgorithm``
