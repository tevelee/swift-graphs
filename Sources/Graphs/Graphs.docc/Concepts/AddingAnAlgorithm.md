# Adding an Algorithm

Define a new graph algorithm that composes with every graph type in the library.

## Overview

Algorithms in Swift Graphs live **outside** graph types (strategy pattern): a graph instance does not know which shortest-path algorithm it can run, and an algorithm does not care which concrete graph type it operates on. The two meet through a protocol like ``ShortestPathAlgorithm`` whose `associatedtype Graph` constrains the graph capabilities the algorithm needs.

This indirection is what lets a single ``Dijkstra`` implementation work on ``AdjacencyList``, ``AdjacencyMatrix``, ``GridGraph``, lazy graphs, filtered views, and any user-defined graph that conforms to ``IncidenceGraph``.

Adding a new algorithm is a four-step recipe.

## Step 1 — Define the algorithm struct

Pick the right algorithm-family protocol (``ShortestPathAlgorithm``, ``TraversalAlgorithm``, ``MaxFlowAlgorithm``, ``MinimumSpanningTreeAlgorithm``, etc.) and constrain ``Graph`` on the protocols you actually need (``IncidenceGraph``, ``VertexListGraph``, ``EdgeListGraph``, ``PropertyGraph``, …):

```swift
public struct MyShortestPath<
    Graph: IncidenceGraph,
    Weight: Numeric & Comparable
>: ShortestPathAlgorithm where
    Graph.VertexDescriptor: Hashable,
    Weight.Magnitude == Weight
{
    public typealias Visitor = Self.Visitor

    @usableFromInline let weight: CostDefinition<Graph, Weight>

    @inlinable
    public init(weight: CostDefinition<Graph, Weight>) {
        self.weight = weight
    }
}
```

Use ``CostDefinition`` for edge weights instead of taking a raw `KeyPath` or closure — that gives callers `.property(\.weight)`, `.uniform(1)`, or a fully custom closure for free.

## Step 2 — Implement the algorithm's logic

Provide the protocol's required method(s), calling visitor hooks at the points an observer would care about:

```swift
extension MyShortestPath {
    public struct Visitor {
        public var examineVertex: ((Graph.VertexDescriptor) -> Void)?
        public var edgeRelaxed: ((Graph.EdgeDescriptor) -> Void)?
        @inlinable public init(
            examineVertex: ((Graph.VertexDescriptor) -> Void)? = nil,
            edgeRelaxed: ((Graph.EdgeDescriptor) -> Void)? = nil
        ) {
            self.examineVertex = examineVertex
            self.edgeRelaxed = edgeRelaxed
        }
    }

    public func shortestPath(
        from source: Graph.VertexDescriptor,
        to destination: Graph.VertexDescriptor,
        in graph: Graph,
        visitor: Visitor?
    ) -> Path<Graph.VertexDescriptor, Graph.EdgeDescriptor>? {
        // …relaxation loop here…
    }
}
```

If your result reuses standard sentinels (a per-vertex distance, a predecessor edge per vertex), prefer the shared ``DistanceProperty`` and ``PredecessorEdgeProperty`` rather than declaring private property enums per algorithm.

If your result conforms to the same query surface as the other shortest-path Result types, add a one-line conformance so users can swap algorithms without touching call sites:

```swift
extension MyShortestPath.Result: ShortestPathResult {}
```

## Step 3 — Add a static factory on the algorithm protocol

This is what makes the call site read naturally. Add a constrained extension on the algorithm protocol so the algorithm shows up as a `.myShortestPath(...)` member:

```swift
extension ShortestPathAlgorithm
where Self == MyShortestPath<some IncidenceGraph, some Numeric & Comparable> {
    public static func myShortestPath<G, W>(
        weight: CostDefinition<G, W>
    ) -> MyShortestPath<G, W> {
        MyShortestPath(weight: weight)
    }
}
```

## Step 4 — Use it

The algorithm now works with every graph type that satisfies its constraints:

```swift
let path = graph.shortestPath(
    from: a,
    to: b,
    using: .myShortestPath(weight: .property(\.weight))
)
```

Add tests under `Tests/GraphsTests/Algorithms/` using Swift Testing (`@Test` / `#expect`), and your algorithm is done.

## Topics

### Related

- <doc:AlgorithmInterfaces>
- <doc:VisitorPattern>
- <doc:PluggableArchitecture>
- <doc:PropertiesAndPropertyMaps>
