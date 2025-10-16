# Traversal Algorithms

Comprehensive guide to graph traversal strategies and their applications.

## Overview

Graph traversal is the foundation of many graph algorithms. The library provides a flexible, strategy-based traversal system that supports multiple traversal orders and can be composed with visitors for enhanced functionality.

## Traversal Architecture

The library separates traversal **strategy** (how to visit nodes) from **visiting logic** (what to do when visiting):

```swift
extension GraphComponent {
    func traverse<Visit>(
        from node: Node, 
        strategy: some GraphTraversalStrategy<Node, Edge, Visit>
    ) -> [Visit]
}
```

This design allows:
- Pluggable traversal strategies (BFS, DFS, etc.)
- Composable visitors (path tracking, cycle detection)
- Lazy or eager evaluation
- Custom traversal logic

## Core Traversal Strategies

### Breadth-First Search (BFS)

Explores nodes level by level, visiting all neighbors before going deeper.

```swift
let graph = ConnectedGraph(edges: [
    "A": ["B", "C"],
    "B": ["D", "E"],
    "C": ["F"],
    "D": []
])

let bfsOrder = graph.traverse(from: "A", strategy: .bfs())
// ["A", "B", "C", "D", "E", "F"]
```

**Characteristics:**
- Uses a queue (FIFO)
- Visits nodes in order of distance from start
- Finds shortest paths in unweighted graphs
- Complete and optimal for unweighted graphs

**Use Cases:**
- Finding shortest paths (unweighted)
- Level-order traversal
- Finding connected components
- Web crawling

**Implementation:**
```swift
struct BreadthFirstSearch<Node, Edge>: GraphTraversalStrategy {
    struct Storage {
        var queue: [Node]
        var visited: Set<Node>  // if Node: Hashable
    }
    
    func next(from storage: inout Storage, 
             graph: some GraphComponent<Node, Edge>) -> Node? {
        guard let current = storage.queue.removeFirst() else {
            return nil
        }
        
        for edge in graph.edges(from: current) {
            if storage.visited.insert(edge.destination).inserted {
                storage.queue.append(edge.destination)
            }
        }
        
        return current
    }
}
```

### Depth-First Search (DFS)

Explores as far as possible along each branch before backtracking.

```swift
let graph = ConnectedGraph(edges: [
    "A": ["B", "C"],
    "B": ["D", "E"],
    "C": ["F"],
    "D": []
])

let dfsOrder = graph.traverse(from: "A", strategy: .dfs())
// ["A", "B", "D", "E", "C", "F"] (one possible order)
```

**Characteristics:**
- Uses a stack (LIFO)
- Explores deeply before broadly
- Natural for recursive algorithms
- Memory efficient for deep graphs

**Use Cases:**
- Topological sorting
- Cycle detection
- Path finding
- Maze solving
- Strongly connected components

### DFS Ordering Variants

The library supports specialized DFS orderings for binary graphs:

#### Preorder DFS

Visit node **before** its children:

```swift
let tree = ConnectedBinaryGraph(edges: [
    "F": (lhs: "B", rhs: "G"),
    "B": (lhs: "A", rhs: "D"),
    "D": (lhs: "C", rhs: "E"),
    "G": (lhs: nil, rhs: "I"),
    "I": (lhs: "H", rhs: nil)
])

let preorder = tree.traverse(from: "F", strategy: .dfs(order: .preorder()))
// ["F", "B", "A", "D", "C", "E", "G", "I", "H"]
```

**Use Cases:**
- Copying trees
- Prefix expression evaluation
- Creating tree copies

#### Inorder DFS (Binary Trees Only)

Visit left child, then node, then right child:

```swift
let inorder = tree.traverse(from: "F", strategy: .dfs(order: .inorder()))
// ["A", "B", "C", "D", "E", "F", "G", "H", "I"]
```

**Use Cases:**
- Binary search tree traversal (gives sorted order)
- Expression tree evaluation

#### Postorder DFS

Visit node **after** its children:

```swift
let postorder = tree.traverse(from: "F", strategy: .dfs(order: .postorder()))
// ["A", "C", "E", "D", "B", "H", "I", "G", "F"]
```

**Use Cases:**
- Deleting trees (delete children first)
- Postfix expression evaluation
- Dependency resolution

## Advanced Traversal Strategies

### Priority-Based Traversal

Visit nodes based on priority (like Dijkstra without weights):

```swift
let graph = ConnectedGraph(edges: [
    "A": ["B", "C"],
    "B": ["D"],
    "C": ["D"]
])

let priorityOrder = graph.traverse(
    from: "A",
    strategy: .priority { node in
        // Lower priority visited first
        node.count
    }
)
```

**Use Cases:**
- Best-first search
- Heuristic-guided exploration
- A* without weights

### Unique Traversal

Ensures each node is visited only once:

```swift
let cyclicGraph = ConnectedGraph(edges: [
    "A": ["B"],
    "B": ["C"],
    "C": ["A"]  // Cycle!
])

// Without unique: might loop forever
// With unique: visits each node once
let visited = cyclicGraph.traverse(
    from: "A",
    strategy: .bfs().visitEachNodeOnce()
)
// ["A", "B", "C"]
```

**Use Cases:**
- Cyclic graphs
- Preventing infinite loops
- Finding unique paths

### Limited Depth Traversal

Stop traversal at a maximum depth:

```swift
let graph = ConnectedGraph(edges: [
    "A": ["B", "C"],
    "B": ["D", "E"],
    "D": ["F", "G"]
])

let limited = graph.traverse(
    from: "A",
    strategy: .bfs().limited(depth: 2)
)
// ["A", "B", "C", "D", "E"] - stops before F and G
```

**Use Cases:**
- Limited exploration
- Local neighborhoods
- Performance optimization

### Iteratively Deepening DFS

Combines benefits of BFS and DFS:

```swift
let path = graph.traverse(
    from: "A",
    strategy: .iterativelyDeepeningDFS()
)
```

**Characteristics:**
- DFS space efficiency
- BFS optimality
- Finds shortest path with DFS memory usage

**Use Cases:**
- When memory is limited
- Finding shortest paths in large graphs
- Game AI (minimax with depth limits)

## Visitor Pattern

Visitors allow tracking additional information during traversal:

### Path Tracking

Track the path to each visited node:

```swift
let pathVisitor = graph.traverse(
    from: "A",
    strategy: .bfs().trackPath()
)

for visit in pathVisitor {
    print("\(visit.node): path = \(visit.path)")
}
// A: path = ["A"]
// B: path = ["A", "B"]
// C: path = ["A", "C"]
// ...
```

**Use Cases:**
- Finding paths
- Backtracking
- Path reconstruction

### Distance Tracking

Track distance from start:

```swift
let distanceVisitor = graph.traverse(
    from: "A",
    strategy: .bfs().trackDistance()
)

for visit in distanceVisitor {
    print("\(visit.node) is \(visit.distance) steps away")
}
```

**Use Cases:**
- Shortest path (unweighted)
- Level-order processing
- Distance calculations

### Cost Tracking (Weighted Graphs)

Track cumulative cost:

```swift
let weightedGraph = ConnectedGraph(edges: [
    "A": ["B": 5, "C": 3],
    "B": ["D": 2],
    "C": ["D": 6]
])

let costVisitor = weightedGraph.traverse(
    from: "A",
    strategy: .priority { $0.cost }.trackCost()
)

for visit in costVisitor {
    print("\(visit.node): cost = \(visit.cost)")
}
// A: cost = 0
// C: cost = 3
// B: cost = 5
// D: cost = 7
```

**Use Cases:**
- Weighted shortest paths
- Cost optimization
- Resource planning

### Node Tracking

Track all visited nodes:

```swift
let nodeTracker = graph.traverse(
    from: "A",
    strategy: .dfs().trackNodes()
)

for visit in nodeTracker {
    print("Visited so far: \(visit.visitedNodes)")
}
```

**Use Cases:**
- Cycle detection
- Visited set maintenance
- Graph coloring

## Composing Strategies and Visitors

Strategies and visitors can be composed:

```swift
let composed = graph.traverse(
    from: "A",
    strategy: .bfs()                // BFS strategy
        .visitEachNodeOnce()        // No revisits
        .trackPath()                // Track paths
        .limited(depth: 3)          // Max depth 3
)
```

## Custom Traversal Strategies

Implement ``GraphTraversalStrategy`` for custom logic:

```swift
struct RandomWalkStrategy<Node, Edge>: GraphTraversalStrategy {
    typealias Visit = Node
    
    struct Storage {
        var current: Node
        var steps: Int
        let maxSteps: Int
    }
    
    func initializeStorage(startNode: Node) -> Storage {
        Storage(current: startNode, steps: 0, maxSteps: 100)
    }
    
    func next(from storage: inout Storage, 
             graph: some GraphComponent<Node, Edge>) -> Node? {
        guard storage.steps < storage.maxSteps else { return nil }
        
        let edges = graph.edges(from: storage.current)
        guard !edges.isEmpty else { return nil }
        
        let randomEdge = edges.randomElement()!
        storage.current = randomEdge.destination
        storage.steps += 1
        
        return storage.current
    }
}

// Use custom strategy
let randomWalk = graph.traverse(from: "A", strategy: RandomWalkStrategy())
```

## Practical Examples

### Finding Shortest Path (Unweighted)

```swift
func shortestPathBFS<G: GraphComponent>(
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

let path = shortestPathBFS(in: graph, from: "A", to: "D")
// ["A", "B", "D"]
```

### Detecting Cycles

```swift
func hasCycle<G: GraphComponent>(
    in graph: G,
    from start: G.Node
) -> Bool where G.Node: Hashable {
    var visited: Set<G.Node> = []
    var recursionStack: Set<G.Node> = []
    
    func dfs(_ node: G.Node) -> Bool {
        visited.insert(node)
        recursionStack.insert(node)
        
        for edge in graph.edges(from: node) {
            if !visited.contains(edge.destination) {
                if dfs(edge.destination) { return true }
            } else if recursionStack.contains(edge.destination) {
                return true  // Back edge found
            }
        }
        
        recursionStack.remove(node)
        return false
    }
    
    return dfs(start)
}
```

### Level-Order Processing

```swift
func processLevelOrder<G: GraphComponent>(
    graph: G,
    from start: G.Node,
    process: (G.Node, Int) -> Void
) where G.Node: Hashable {
    for visit in graph.traversal(from: start, strategy: .bfs().trackDistance()) {
        process(visit.node, visit.distance)
    }
}

processLevelOrder(graph: tree, from: "root") { node, level in
    print("Level \(level): \(node)")
}
```

### Topological Sort

```swift
func topologicalSort<G: Graph>(graph: G) -> [G.Node]? where G.Node: Hashable {
    guard !graph.isCyclic() else { return nil }
    
    var result: [G.Node] = []
    var visited: Set<G.Node> = []
    
    func dfs(_ node: G.Node) {
        visited.insert(node)
        for edge in graph.edges(from: node) {
            if !visited.contains(edge.destination) {
                dfs(edge.destination)
            }
        }
        result.insert(node, at: 0)  // Prepend
    }
    
    for node in graph.allNodes {
        if !visited.contains(node) {
            dfs(node)
        }
    }
    
    return result
}
```

## Performance Characteristics

| Strategy | Time Complexity | Space Complexity | Use Case |
|----------|----------------|------------------|----------|
| BFS | O(V + E) | O(V) | Shortest path (unweighted) |
| DFS | O(V + E) | O(h) where h=height | Deep exploration |
| Priority | O((V + E) log V) | O(V) | Heuristic search |
| Iteratively Deepening | O(V + E) | O(h) | Memory-constrained BFS |

## See Also

- <doc:ShortestPathAlgorithms>
- <doc:GraphProperties>
- ``GraphTraversalStrategy``
- ``BreadthFirstSearch``
- ``DepthFirstSearch``
