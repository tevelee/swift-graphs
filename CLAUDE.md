# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build & Test Commands

```bash
swift build                    # Build the library
swift test                     # Run all tests
swift test --filter GraphsTests.DijkstraTests   # Run a specific test suite
swift test --filter "GraphsTests.DijkstraTests/findsShortestPath"  # Run a single test
```

Tests use Swift Testing framework (`@Test` macro, `#expect()` assertions), not XCTest.

Two Package.swift variants exist: `Package.swift` (Swift 5.9+) and `Package@swift-6.0.swift` (Swift 6 with strict concurrency via `.swiftLanguageMode(.v6)`).

## Code Formatting

Configured via `.swift-format`. Key rules: 4-space indentation, 160 char line length, all public declarations require doc comments (`///`), no access level on extension declarations, use early exits.

## Architecture

This is a protocol-oriented graph algorithms library. The architecture has four layers:

### 1. Graph Protocol Hierarchy (`Sources/Graphs/GraphDefinitions/`)

Composable protocols that graph types conform to — each adds a capability:

- **`Graph`** — base protocol with `VertexDescriptor` and `EdgeDescriptor` associated types
- **`IncidenceGraph`** — outgoing edges from a vertex (`edges(from:)`)
- **`BidirectionalGraph`** — adds incoming edges
- **`VertexListGraph`** / **`EdgeListGraph`** — enumerate all vertices/edges
- **`AdjacencyGraph`** — direct neighbor access
- **`PropertyGraph`** — vertex and edge properties via subscript (`graph[vertex]`, `graph[edge]`)
- **`MutableGraph`** / **`MutablePropertyGraph`** — mutation capabilities
- **`EdgeLookupGraph`** — O(1) edge existence check
- **`BinaryIncidenceGraph`** — tree structures (left/right children)
- **`BipartiteGraph`** — two-partitioned vertex sets

### 2. Graph Implementations (`Sources/Graphs/GraphImplementations/`)

Concrete types conforming to the protocol hierarchy:

- **`AdjacencyList`** — primary sparse graph implementation, generic over storage backends
- **`AdjacencyMatrix`** — dense graph with O(1) edge lookup
- **`GridGraph`** — 2D coordinate-based graph for pathfinding
- **`InlineGraph`** — data embedded directly in vertex/edge types
- **`LazyGraph`** — edges computed on-demand

Storage backends in `Storage/` (CSR, COO, ordered, binary, cached bidirectional edges) are pluggable via generic parameters on `AdjacencyList`.

### 3. Algorithm Definitions (`Sources/Graphs/AlgorithmDefinitions/`)

Each algorithm category defines a protocol (e.g., `ShortestPathAlgorithm`, `TraversalAlgorithm`) with associated types for the graph, result, and visitor. Algorithms constrain on specific graph protocols (e.g., shortest path requires `IncidenceGraph`). The library is inspired by the Boost Graph Library (BGL) and translates BGL's C++ concepts into Swift protocols.

Algorithm protocol families: `ShortestPathAlgorithm`, `TraversalAlgorithm`, `SearchAlgorithm`, `ColoringAlgorithm`, `ConnectedComponentsAlgorithm`, `MinimumSpanningTreeAlgorithm`, `MaxFlowAlgorithm`, `CentralityAlgorithm`, `HamiltonianPathAlgorithm`, `EulerianPathAlgorithm`, `StronglyConnectedComponentsAlgorithm`, `MatchingAlgorithm`, `TopologicalSortAlgorithm`, `CliqueDetectionAlgorithm`, `CommunityDetectionAlgorithm`, `IsomorphismAlgorithm`, `RandomGraphAlgorithm`.

### 4. Algorithm Implementations (`Sources/Graphs/AlgorithmImplementations/`)

Each subdirectory contains one or more implementations of an algorithm protocol. Algorithms are **external to graphs** (strategy pattern) — they are separate types selected at the call site, not methods baked into graph types.

#### Adding a new algorithm (4 steps):

1. **Define the algorithm struct** conforming to the appropriate protocol:
   ```swift
   struct MyAlgorithm<G: IncidenceGraph, W: Numeric & Comparable>: ShortestPathAlgorithm {
       typealias Graph = G
       typealias Weight = W
       typealias Visitor = DijkstraVisitor<G>
       let weight: CostDefinition<G, W>
   }
   ```

2. **Implement required methods** — the algorithm's core logic, calling `visitor` hooks at appropriate points.

3. **Add a static factory method** on the protocol using a constrained extension:
   ```swift
   extension ShortestPathAlgorithm where Self == MyAlgorithm<some IncidenceGraph, some Numeric & Comparable> {
       static func myAlgorithm<G, W>(weight: CostDefinition<G, W>) -> MyAlgorithm<G, W> { ... }
   }
   ```

4. **Use it** — it works automatically with all compatible graphs:
   ```swift
   graph.shortestPath(from: a, to: b, using: .myAlgorithm(weight: .property(\.weight)))
   ```

#### Algorithm parameterization:

- **`CostDefinition<Graph, Cost>`** — extracts edge weights. Built-in factories: `.property(\.weight)`, `.uniform(1.0)`, or a custom closure.
- **`Heuristic<Graph, Cost>`** — estimates distance for A*/best-first. Built-ins: `.euclidean`, `.manhattanDistance`, `.chebyshevDistance`.

#### Visitor pattern:

Every algorithm protocol includes an optional `Visitor` associated type. Visitors observe execution without modifying the algorithm — hooks include events like `discoverVertex`, `examineEdge`, `edgeRelaxed`, `treeEdge`, `backEdge`, `finishVertex`, etc. Visitors are:

- **Struct-based** with optional closure properties (e.g., `DFSVisitor<Graph>`, `DijkstraVisitor<Graph>`).
- **Composable** — chain multiple visitors via `.withVisitor()` on an algorithm; all receive events.
- **Zero-cost when absent** — passing `nil` (the default) incurs no overhead.

Key difference between `TraversalAlgorithm` and `SearchAlgorithm`: traversal returns a complete `TraversalResult`, while search returns a lazy `Sequence` that supports early termination via `break`.

### Key Patterns

- **Performance annotations**: `@inlinable` and `@usableFromInline` are used extensively on hot paths.
- **Property maps**: `PropertyMap<Key, Value>` and `MutablePropertyMap` abstract property access across different graph types. Custom properties are defined as types conforming to `VertexProperty`/`EdgeProperty` with a `defaultValue`, then exposed as computed properties on `VertexPropertyValues`/`EdgePropertyValues`.
- **Graph views** (`GraphDefinitions/Views/`): Lazy transformations like filtered, reversed, mapped, and undirected wrappers over existing graphs — they don't copy data.
- **Pluggable storage**: `AdjacencyList` is generic over `VertexStore`, `EdgeStore`, `VertexPropertyMap`, and `EdgePropertyMap`. Storage types compose via wrappers (e.g., `OrderedEdgeStorage().cacheInOutEdges()` adds incoming edge tracking).
- **Serialization** (`Sources/Graphs/Serialization/`): DOT, GraphML, and JSON format support.

## Test Structure

Tests are in `Tests/GraphsTests/` organized by category: `Core/`, `DataStructures/`, `Algorithms/`, `Properties/`, `Serialization/`. Test suites are structs with `@Test`-annotated methods. Test names follow `GraphsTests.<SuiteName>/<methodName>()`.
