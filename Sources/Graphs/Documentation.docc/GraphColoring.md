# Graph Coloring Algorithms

Algorithms for assigning colors to graph vertices with optimization constraints.

## Overview

Graph coloring assigns colors (or labels) to graph vertices such that no two adjacent vertices share the same color. The library provides several coloring algorithms, each with different optimality guarantees and performance characteristics.

## The Graph Coloring Problem

**Goal**: Color vertices with minimum number of colors such that adjacent vertices have different colors.

**Chromatic Number** (χ): Minimum number of colors needed for a valid coloring.

**NP-Complete**: Finding χ is NP-complete for general graphs, so we use approximation algorithms.

## Core Coloring Algorithms

### Greedy Coloring

Simple, fast heuristic that colors vertices in order.

```swift
let graph = ConnectedGraph(edges: [
    "A": ["B", "C"],
    "B": ["A", "C", "D"],
    "C": ["A", "B", "D"],
    "D": ["B", "C"]
]).undirected()

let coloring = graph.colorNodes(using: .greedy())
// Example result: [A: 0, B: 1, C: 2, D: 0]

print("Colors used: \(Set(coloring.values).count)")
```

**Characteristics:**
- **Time Complexity**: O(V + E)
- **Space Complexity**: O(V)
- **Approximation**: Uses at most Δ + 1 colors (Δ = max degree)
- **Guarantee**: Always valid coloring

**How it works:**
1. Order vertices (arbitrary or specific order)
2. For each vertex:
   - Find colors used by neighbors
   - Assign smallest available color

**Best For:**
- Quick coloring needs
- When approximate solution acceptable
- Online coloring
- Simple implementation

**Implementation:**
```swift
struct GreedyColoringAlgorithm<Node: Hashable>: GraphColoringAlgorithm {
    func colorNodes(in graph: some Graph<Node, Empty>) -> [Node: Int] {
        var colors: [Node: Int] = [:]
        
        for node in graph.allNodes {
            // Find colors used by neighbors
            var usedColors: Set<Int> = []
            for edge in graph.edges(from: node) {
                if let color = colors[edge.destination] {
                    usedColors.insert(color)
                }
            }
            
            // Assign smallest available color
            var color = 0
            while usedColors.contains(color) {
                color += 1
            }
            colors[node] = color
        }
        
        return colors
    }
}
```

### DSatur (Degree of Saturation)

Improved heuristic that prioritizes vertices with most colored neighbors.

```swift
let coloring = graph.colorNodes(using: .dsatur())
```

**Characteristics:**
- **Time Complexity**: O(V²)
- **Space Complexity**: O(V)
- **Approximation**: Often better than greedy
- **Heuristic**: Color vertex with highest saturation first

**Saturation Degree**: Number of different colors used by neighbors.

**How it works:**
1. Color vertex with highest saturation degree
2. Break ties by choosing highest degree
3. Update saturation degrees
4. Repeat until all colored

**Best For:**
- Better approximations than greedy
- Register allocation
- Scheduling problems
- When quality matters more than speed

**Implementation:**
```swift
struct DSaturAlgorithm<Node: Hashable>: GraphColoringAlgorithm {
    func colorNodes(in graph: some Graph<Node, Empty>) -> [Node: Int] {
        var colors: [Node: Int] = [:]
        var saturation: [Node: Set<Int>] = [:]
        
        while colors.count < graph.allNodes.count {
            // Find node with highest saturation
            let nextNode = graph.allNodes
                .filter { colors[$0] == nil }
                .max { lhs, rhs in
                    let lhsSat = saturation[lhs]?.count ?? 0
                    let rhsSat = saturation[rhs]?.count ?? 0
                    if lhsSat != rhsSat {
                        return lhsSat < rhsSat
                    }
                    return graph.edges(from: lhs).count < graph.edges(from: rhs).count
                }!
            
            // Color with smallest available
            let used = saturation[nextNode] ?? []
            var color = 0
            while used.contains(color) { color += 1 }
            colors[nextNode] = color
            
            // Update saturation of neighbors
            for edge in graph.edges(from: nextNode) {
                saturation[edge.destination, default: []].insert(color)
            }
        }
        
        return colors
    }
}
```

### Welsh-Powell Algorithm

Orders vertices by degree before coloring.

```swift
let coloring = graph.colorNodes(using: .welshPowell())
```

**Characteristics:**
- **Time Complexity**: O(V log V + E)
- **Space Complexity**: O(V)
- **Heuristic**: High-degree vertices first
- **Quality**: Often better than random-order greedy

**How it works:**
1. Sort vertices by degree (descending)
2. Apply greedy coloring in this order

**Why it works**:
- High-degree vertices are hardest to color
- Coloring them first uses fewer colors

**Best For:**
- Simple improvement over greedy
- When vertex ordering matters
- Preprocessing for other algorithms

## Applications

### Register Allocation

Assign CPU registers to variables:

```swift
struct Variable: Hashable {
    let name: String
}

// Build interference graph: edge if variables are live simultaneously
var interferenceEdges: [GraphEdge<Variable, Empty>] = []
for (v1, v2) in findInterferences(in: program) {
    interferenceEdges.append(GraphEdge(source: v1, destination: v2))
}

let graph = ConnectedGraph(edges: interferenceEdges).undirected()
let allocation = graph.colorNodes(using: .dsatur())

// Map colors to registers
let registers = ["r0", "r1", "r2", "r3", "r4", "r5"]
for (variable, color) in allocation {
    if color < registers.count {
        print("\(variable.name) → \(registers[color])")
    } else {
        print("\(variable.name) → spill to memory")
    }
}
```

### Scheduling

Schedule tasks avoiding conflicts:

```swift
struct Task: Hashable {
    let id: String
}

// Build conflict graph: edge if tasks can't run simultaneously
let conflicts = ConnectedGraph<Task, Empty>(edges: conflictEdges).undirected()
let schedule = conflicts.colorNodes(using: .dsatur())

// Group by time slot
var timeSlots: [Int: [Task]] = [:]
for (task, slot) in schedule {
    timeSlots[slot, default: []].append(task)
}

print("Minimum time slots needed: \(timeSlots.count)")
for (slot, tasks) in timeSlots.sorted(by: { $0.key < $1.key }) {
    print("Slot \(slot): \(tasks.map(\.id).joined(separator: ", "))")
}
```

### Map Coloring

Color regions so adjacent regions differ:

```swift
struct Region: Hashable {
    let name: String
}

let map = ConnectedGraph(edges: [
    Region(name: "USA"): [Region(name: "Canada"), Region(name: "Mexico")],
    Region(name: "Canada"): [Region(name: "USA")],
    Region(name: "Mexico"): [Region(name: "USA")]
]).undirected()

let colors = map.colorNodes(using: .greedy())

let colorNames = ["Red", "Blue", "Green", "Yellow"]
for (region, colorIndex) in colors {
    print("\(region.name): \(colorNames[colorIndex])")
}
```

### Frequency Assignment

Assign radio frequencies avoiding interference:

```swift
struct Transmitter: Hashable {
    let id: String
    let location: (x: Double, y: Double)
}

func interferes(_ t1: Transmitter, _ t2: Transmitter) -> Bool {
    let dx = t1.location.x - t2.location.x
    let dy = t1.location.y - t2.location.y
    let distance = sqrt(dx*dx + dy*dy)
    return distance < 100  // interference radius
}

let transmitters = loadTransmitters()
var edges: [GraphEdge<Transmitter, Empty>] = []
for t1 in transmitters {
    for t2 in transmitters where t1 != t2 && interferes(t1, t2) {
        edges.append(GraphEdge(source: t1, destination: t2))
    }
}

let interferenceGraph = ConnectedGraph(edges: edges).undirected()
let assignment = interferenceGraph.colorNodes(using: .dsatur())

let frequencies = ["f1", "f2", "f3", "f4", "f5"]
print("Frequencies needed: \(Set(assignment.values).count)")
for (transmitter, freqIndex) in assignment {
    print("\(transmitter.id): \(frequencies[freqIndex])")
}
```

### Sudoku Solving

Sudoku as a graph coloring problem:

```swift
struct Cell: Hashable {
    let row, col: Int
}

// Build sudoku constraint graph
var edges: [GraphEdge<Cell, Empty>] = []
for r1 in 0..<9 {
    for c1 in 0..<9 {
        let cell1 = Cell(row: r1, col: c1)
        for r2 in 0..<9 {
            for c2 in 0..<9 where (r1, c1) != (r2, c2) {
                let cell2 = Cell(row: r2, col: c2)
                // Same row, column, or 3x3 box
                if r1 == r2 || c1 == c2 || (r1/3 == r2/3 && c1/3 == c2/3) {
                    edges.append(GraphEdge(source: cell1, destination: cell2))
                }
            }
        }
    }
}

let sudokuGraph = ConnectedGraph(edges: edges).undirected()

// Pre-color given cells
var precolored: [Cell: Int] = [:]
for (cell, value) in givenCells {
    precolored[cell] = value - 1  // 0-indexed colors
}

// Color remaining cells (this is simplified - actual sudoku solving is more complex)
let solution = sudokuGraph.colorNodes(using: .dsatur(), precolored: precolored)
```

### Exam Scheduling

Schedule exams avoiding student conflicts:

```swift
struct Exam: Hashable {
    let course: String
}

struct Student {
    let courses: Set<String>
}

// Build conflict graph
let students = loadStudents()
var conflicts: Set<(Exam, Exam)> = []

for student in students {
    let exams = student.courses.map { Exam(course: $0) }
    for i in 0..<exams.count {
        for j in i+1..<exams.count {
            conflicts.insert((exams[i], exams[j]))
        }
    }
}

var edges: [GraphEdge<Exam, Empty>] = []
for (e1, e2) in conflicts {
    edges.append(GraphEdge(source: e1, destination: e2))
}

let examGraph = ConnectedGraph(edges: edges).undirected()
let schedule = examGraph.colorNodes(using: .dsatur())

print("Minimum exam periods needed: \(Set(schedule.values).count)")

var periods: [Int: [Exam]] = [:]
for (exam, period) in schedule {
    periods[period, default: []].append(exam)
}

for (period, exams) in periods.sorted(by: { $0.key < $1.key }) {
    print("Period \(period + 1): \(exams.map(\.course).joined(separator: ", "))")
}
```

## Theoretical Bounds

### Chromatic Number Bounds

**Lower bound**: χ(G) ≥ ω(G) where ω = clique number
**Upper bound**: χ(G) ≤ Δ + 1 where Δ = maximum degree

```swift
func chromaticNumberBounds<G: Graph>(graph: G) -> (lower: Int, upper: Int) 
where G.Node: Hashable {
    // Lower bound: size of maximum clique
    let cliques = graph.findCliques()
    let lower = cliques.max(by: { $0.count < $1.count })?.count ?? 1
    
    // Upper bound: max degree + 1
    let maxDegree = graph.allNodes.map { graph.edges(from: $0).count }.max() ?? 0
    let upper = maxDegree + 1
    
    return (lower, upper)
}
```

### Special Graph Classes

**Bipartite graphs**: χ = 2
```swift
let graph = loadGraph()
if graph.isBipartite() {
    print("Chromatic number: 2")
}
```

**Complete graphs**: χ = n
```swift
let complete = CompleteGraph(nodes: nodes)
print("Chromatic number: \(complete.allNodes.count)")
```

**Trees**: χ = 2
```swift
if graph.isTree() {
    print("Chromatic number: 2")
}
```

**Planar graphs**: χ ≤ 4 (Four Color Theorem)
```swift
if graph.isPlanar() {
    print("Chromatic number: at most 4")
}
```

## Advanced Coloring

### K-Coloring Problem

Determine if graph can be colored with k colors:

```swift
func canColor<G: Graph>(graph: G, withColors k: Int) -> Bool 
where G.Node: Hashable {
    let coloring = graph.colorNodes(using: .dsatur())
    let colorsUsed = Set(coloring.values).count
    return colorsUsed <= k
}

// Binary search for chromatic number
func findChromaticNumber<G: Graph>(graph: G) -> Int 
where G.Node: Hashable {
    var low = 1
    var high = graph.allNodes.count
    
    while low < high {
        let mid = (low + high) / 2
        if canColor(graph: graph, withColors: mid) {
            high = mid
        } else {
            low = mid + 1
        }
    }
    
    return low
}
```

### Edge Coloring

Color edges instead of vertices:

```swift
func edgeColoring<G: Graph>(graph: G) -> [GraphEdge<G.Node, G.Edge>: Int] 
where G.Node: Hashable {
    // Convert to line graph (edges become vertices)
    var lineGraphEdges: [GraphEdge<GraphEdge<G.Node, G.Edge>, Empty>] = []
    
    for e1 in graph.allEdges {
        for e2 in graph.allEdges where e1 != e2 {
            if e1.destination == e2.source || e1.source == e2.destination {
                lineGraphEdges.append(GraphEdge(source: e1, destination: e2))
            }
        }
    }
    
    let lineGraph = ConnectedGraph(edges: lineGraphEdges).undirected()
    let coloring = lineGraph.colorNodes(using: .dsatur())
    
    return coloring
}
```

### List Coloring

Each vertex has a list of allowed colors:

```swift
func listColoring<G: Graph>(
    graph: G,
    allowedColors: [G.Node: Set<Int>]
) -> [G.Node: Int]? where G.Node: Hashable {
    var colors: [G.Node: Int] = [:]
    
    for node in graph.allNodes {
        guard let allowed = allowedColors[node] else {
            return nil
        }
        
        // Find colors used by neighbors
        var usedColors: Set<Int> = []
        for edge in graph.edges(from: node) {
            if let color = colors[edge.destination] {
                usedColors.insert(color)
            }
        }
        
        // Try to assign color from allowed list
        let available = allowed.subtracting(usedColors)
        guard let color = available.min() else {
            return nil  // No valid coloring
        }
        
        colors[node] = color
    }
    
    return colors
}
```

## Performance Comparison

| Algorithm | Time | Quality | Best Use |
|-----------|------|---------|----------|
| Greedy | O(V + E) | Δ + 1 | Fast, simple |
| DSatur | O(V²) | Better | Quality matters |
| Welsh-Powell | O(V log V + E) | Medium | Balanced |

## Validation

Verify a coloring is valid:

```swift
func isValidColoring<G: Graph>(
    graph: G,
    coloring: [G.Node: Int]
) -> Bool where G.Node: Hashable {
    for node in graph.allNodes {
        let color = coloring[node]
        for edge in graph.edges(from: node) {
            if coloring[edge.destination] == color {
                return false  // Adjacent vertices have same color
            }
        }
    }
    return true
}

let coloring = graph.colorNodes(using: .dsatur())
assert(isValidColoring(graph: graph, coloring: coloring))
```

## See Also

- <doc:GraphProperties>
- <doc:FlowAndMatching>
- ``GraphColoringAlgorithm``
- ``GreedyColoringAlgorithm``
- ``DSaturAlgorithm``
- ``WelshPowellAlgorithm``
