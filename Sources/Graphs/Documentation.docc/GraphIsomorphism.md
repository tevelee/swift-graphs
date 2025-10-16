# Graph Isomorphism

Testing whether two graphs have the same structure.

## Overview

Graph isomorphism determines if two graphs are structurally identical - that is, whether they can be transformed into each other by relabeling vertices. This is a fundamental problem in graph theory with applications in chemistry, pattern recognition, and network analysis.

## The Isomorphism Problem

Two graphs G₁ and G₂ are **isomorphic** if there exists a bijection f: V₁ → V₂ such that:
- (u, v) is an edge in G₁ if and only if (f(u), f(v)) is an edge in G₂

**Complexity**: The graph isomorphism problem is in NP, but not known to be NP-complete or in P. It's one of the few problems with unclear computational complexity.

## Checking Isomorphism

```swift
let graph1 = ConnectedGraph(edges: [
    "A": ["B", "C"],
    "B": ["A", "C"],
    "C": ["A", "B"]
])

let graph2 = ConnectedGraph(edges: [
    "X": ["Y", "Z"],
    "Y": ["X", "Z"],
    "Z": ["X", "Y"]
])

let isomorphic = graph1.isIsomorphic(to: graph2, using: .vf2())
print(isomorphic)  // true (both are triangles)
```

## VF2 Algorithm

State-space search algorithm with efficient pruning.

```swift
let result = graph1.isIsomorphic(to: graph2, using: .vf2())
```

**Characteristics:**
- **Time Complexity**: O(N!N) worst case, much better in practice
- **Space Complexity**: O(N)
- **Method**: State-space search with feasibility rules
- **Accuracy**: Exact (not heuristic)

**How it works:**
1. Build partial mapping between vertices
2. Use feasibility rules to prune search space:
   - Syntactic rules (degree, neighbors)
   - Semantic rules (labels, attributes)
3. Backtrack when mapping fails
4. Success when complete mapping found

**Feasibility Rules:**
- **Look-ahead**: Check if partial mapping can be extended
- **Look-back**: Verify consistency with existing mapping
- **Degree consistency**: Vertices must have same degree
- **Neighborhood consistency**: Mapped neighbors must correspond

**Best For:**
- Small to medium graphs
- Exact isomorphism testing
- Subgraph isomorphism
- Pattern matching

**Implementation Details:**
```swift
struct VF2Algorithm<Node: Hashable>: GraphIsomorphismAlgorithm {
    func isIsomorphic<G1: Graph, G2: Graph>(
        _ graph1: G1,
        _ graph2: G2
    ) -> Bool where G1.Node == Node, G2.Node == Node {
        // Early termination checks
        guard graph1.allNodes.count == graph2.allNodes.count else {
            return false
        }
        guard graph1.allEdges.count == graph2.allEdges.count else {
            return false
        }
        
        // State-space search
        var mapping: [G1.Node: G2.Node] = [:]
        return vf2Match(graph1, graph2, &mapping)
    }
    
    private func vf2Match<G1: Graph, G2: Graph>(
        _ g1: G1,
        _ g2: G2,
        _ mapping: inout [G1.Node: G2.Node]
    ) -> Bool {
        // Base case: complete mapping
        if mapping.count == g1.allNodes.count {
            return true
        }
        
        // Find candidate pair
        for n1 in g1.allNodes where mapping[n1] == nil {
            for n2 in g2.allNodes where !mapping.values.contains(n2) {
                if isFeasible(n1, n2, mapping, g1, g2) {
                    mapping[n1] = n2
                    if vf2Match(g1, g2, &mapping) {
                        return true
                    }
                    mapping.removeValue(forKey: n1)
                }
            }
            return false  // No valid mapping for n1
        }
        
        return false
    }
    
    private func isFeasible<G1: Graph, G2: Graph>(
        _ n1: G1.Node,
        _ n2: G2.Node,
        _ mapping: [G1.Node: G2.Node],
        _ g1: G1,
        _ g2: G2
    ) -> Bool {
        // Degree check
        if g1.edges(from: n1).count != g2.edges(from: n2).count {
            return false
        }
        
        // Neighborhood consistency
        for edge1 in g1.edges(from: n1) {
            if let mapped = mapping[edge1.destination] {
                // Must have corresponding edge in g2
                if !g2.edges(from: n2).contains(where: { $0.destination == mapped }) {
                    return false
                }
            }
        }
        
        return true
    }
}
```

## Weisfeiler-Lehman Algorithm

Fast hash-based heuristic for isomorphism testing.

```swift
let result = graph1.isIsomorphic(to: graph2, using: .weisfeilerLehman())
```

**Characteristics:**
- **Time Complexity**: O(N log N) per iteration
- **Space Complexity**: O(N)
- **Method**: Iterative hash refinement
- **Accuracy**: Heuristic (may have false negatives)

**How it works:**
1. Initialize each vertex with its degree as hash
2. Iterate:
   - For each vertex, collect hashes of neighbors
   - Sort neighbor hashes
   - Create new hash from (old hash, sorted neighbor hashes)
   - Update vertex hash
3. Compare final hash multisets

**Hash Refinement:**
```swift
func weisfeilerLehmanHash<G: Graph>(
    graph: G,
    iterations: Int = 3
) -> [Int: Int] where G.Node: Hashable {
    var hashes: [G.Node: Int] = [:]
    
    // Initialize with degrees
    for node in graph.allNodes {
        hashes[node] = graph.edges(from: node).count
    }
    
    // Refine hashes
    for _ in 0..<iterations {
        var newHashes: [G.Node: Int] = [:]
        
        for node in graph.allNodes {
            var neighborHashes = graph.edges(from: node)
                .map { hashes[$0.destination]! }
                .sorted()
            
            // Combine current hash with neighbor hashes
            var combined = "\(hashes[node]!)"
            for h in neighborHashes {
                combined += ",\(h)"
            }
            
            newHashes[node] = combined.hashValue
        }
        
        hashes = newHashes
    }
    
    return hashes
}
```

**Best For:**
- Large graphs
- Quick filtering (eliminate non-isomorphic quickly)
- Pre-processing before exact algorithm
- Graph similarity (not just isomorphism)

**Limitations:**
- Not guaranteed to distinguish all non-isomorphic graphs
- May report non-isomorphic graphs as potentially isomorphic
- Works well in practice for most graphs

## Subgraph Isomorphism

Finding if one graph contains another as a subgraph.

```swift
extension Graph where Node: Hashable {
    func containsSubgraph<G: Graph>(_ pattern: G) -> Bool 
    where G.Node == Node {
        // Use VF2 with subgraph matching mode
        return subgraphIsomorphism(pattern: pattern, using: .vf2())
    }
    
    func findAllSubgraphs<G: Graph>(_ pattern: G) -> [Set<Node>]
    where G.Node == Node {
        var matches: [Set<Node>] = []
        
        // Try all possible starting vertices
        for start in allNodes {
            if let match = findSubgraphFrom(start, pattern: pattern) {
                matches.append(match)
            }
        }
        
        return matches
    }
}
```

**Applications:**
- Chemical substructure search
- Pattern recognition in networks
- Code clone detection
- Biological pathway analysis

## Practical Applications

### Molecular Structure Comparison

```swift
struct Atom: Hashable {
    let element: String
    let id: Int
}

struct Bond {
    let type: String  // single, double, triple
}

let molecule1 = ConnectedGraph(edges: [
    Atom(element: "C", id: 1): [
        Atom(element: "H", id: 2),
        Atom(element: "H", id: 3),
        Atom(element: "O", id: 4)
    ],
    // ... more bonds
])

let molecule2 = ConnectedGraph(edges: [
    Atom(element: "C", id: 10): [
        Atom(element: "H", id: 11),
        Atom(element: "H", id: 12),
        Atom(element: "O", id: 13)
    ],
    // ... more bonds
])

// Check if molecules are the same structure
if molecule1.isIsomorphic(to: molecule2, using: .vf2()) {
    print("Same molecular structure")
}

// Find if molecule1 contains a functional group
let functionalGroup = ConnectedGraph(edges: [/* OH group */])
if molecule1.containsSubgraph(functionalGroup) {
    print("Contains hydroxyl group")
}
```

### Circuit Equivalence

```swift
struct Gate: Hashable {
    let type: String  // AND, OR, NOT
    let id: Int
}

let circuit1 = ConnectedGraph<Gate, Empty>(edges: circuitConnections1)
let circuit2 = ConnectedGraph<Gate, Empty>(edges: circuitConnections2)

if circuit1.isIsomorphic(to: circuit2, using: .vf2()) {
    print("Circuits are logically equivalent")
}
```

### Network Pattern Detection

```swift
// Find triangle patterns (K3) in social network
let triangle = ConnectedGraph(edges: [
    "A": ["B", "C"],
    "B": ["A", "C"],
    "C": ["A", "B"]
])

let socialNetwork = loadSocialNetwork()
let triangles = socialNetwork.findAllSubgraphs(triangle)

print("Found \(triangles.count) triangular relationships")
```

### Code Clone Detection

```swift
struct ASTNode: Hashable {
    let type: String  // function, variable, operator, etc.
    let id: Int
}

// Build AST as graph
let ast1 = buildAST(from: sourceCode1)
let ast2 = buildAST(from: sourceCode2)

if ast1.isIsomorphic(to: ast2, using: .vf2()) {
    print("Code blocks are structurally identical")
}
```

## Automorphism

Finding isomorphisms from a graph to itself.

```swift
extension Graph where Node: Hashable {
    func automorphisms() -> [Node: Set<Node>] {
        var autos: [Node: Set<Node>] = [:]
        
        for node in allNodes {
            autos[node] = []
        }
        
        // Find all automorphic mappings
        for perm in allNodes.permutations() {
            let mapping = Dictionary(uniqueKeysWithValues: zip(allNodes, perm))
            
            if isAutomorphism(mapping) {
                for (node, mapped) in mapping {
                    autos[node]?.insert(mapped)
                }
            }
        }
        
        return autos
    }
    
    private func isAutomorphism(_ mapping: [Node: Node]) -> Bool {
        for edge in allEdges {
            let mappedEdge = GraphEdge(
                source: mapping[edge.source]!,
                destination: mapping[edge.destination]!
            )
            if !allEdges.contains(where: { $0 == mappedEdge }) {
                return false
            }
        }
        return true
    }
}

// Example: Find symmetries
let graph = ConnectedGraph(edges: regularGraphEdges)
let symmetries = graph.automorphisms()

print("Vertex symmetries:")
for (node, equivalents) in symmetries {
    print("\(node) is symmetric to: \(equivalents)")
}
```

## Graph Canonization

Creating a unique canonical form for isomorphic graphs.

```swift
extension Graph where Node: Hashable {
    func canonicalForm() -> Self {
        // Create canonical labeling using nauty algorithm
        let canonicalLabeling = computeCanonicalLabeling()
        
        // Relabel graph with canonical labels
        let canonicalEdges = allEdges.map { edge in
            GraphEdge(
                source: canonicalLabeling[edge.source]!,
                destination: canonicalLabeling[edge.destination]!,
                value: edge.value
            )
        }
        
        return Self(edges: canonicalEdges)
    }
}

// Use canonical forms for fast isomorphism testing
let canonical1 = graph1.canonicalForm()
let canonical2 = graph2.canonicalForm()

// If canonical forms are identical, graphs are isomorphic
let isomorphic = canonical1.allEdges == canonical2.allEdges
```

## Performance Optimization

### Early Termination

```swift
func quickIsomorphismCheck<G1: Graph, G2: Graph>(
    _ g1: G1,
    _ g2: G2
) -> Bool? where G1.Node: Hashable, G2.Node: Hashable {
    // Quick negative checks
    if g1.allNodes.count != g2.allNodes.count { return false }
    if g1.allEdges.count != g2.allEdges.count { return false }
    
    // Degree sequence check
    let deg1 = g1.allNodes.map { g1.edges(from: $0).count }.sorted()
    let deg2 = g2.allNodes.map { g2.edges(from: $0).count }.sorted()
    if deg1 != deg2 { return false }
    
    // Can't determine - need full algorithm
    return nil
}

// Use in practice
if let quick = quickIsomorphismCheck(graph1, graph2) {
    print("Quick result: \(quick)")
} else {
    let result = graph1.isIsomorphic(to: graph2, using: .vf2())
    print("Full result: \(result)")
}
```

### Hybrid Approach

```swift
func hybridIsomorphismTest<G1: Graph, G2: Graph>(
    _ g1: G1,
    _ g2: G2
) -> Bool where G1.Node: Hashable, G2.Node: Hashable {
    // 1. Quick structural checks
    guard quickIsomorphismCheck(g1, g2) == nil else {
        return false
    }
    
    // 2. Weisfeiler-Lehman filtering
    if !g1.isIsomorphic(to: g2, using: .weisfeilerLehman()) {
        return false
    }
    
    // 3. Exact VF2 algorithm
    return g1.isIsomorphic(to: g2, using: .vf2())
}
```

## Algorithm Comparison

| Algorithm | Time | Accuracy | Best For |
|-----------|------|----------|----------|
| VF2 | O(N!N) worst, O(N²) typical | Exact | Small-medium graphs |
| Weisfeiler-Lehman | O(N log N) | Heuristic | Large graphs, filtering |
| Nauty | O(N!) worst | Exact | Canonical forms |

## See Also

- <doc:GraphProperties>
- <doc:TraversalAlgorithms>
- ``GraphIsomorphismAlgorithm``
- ``VF2Algorithm``
- ``WeisfeilerLehmanAlgorithm``
