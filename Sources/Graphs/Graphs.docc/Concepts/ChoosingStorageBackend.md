# Choosing a Storage Backend

Pick the right vertex and edge storage for the graph's shape and access pattern.

## Overview

``AdjacencyList`` is generic over its storage:

```swift
public struct AdjacencyList<
    VertexStore: VertexStorage,
    EdgeStore: EdgeStorage,
    VertexPropertyMap: MutablePropertyMap,
    EdgePropertyMap: MutablePropertyMap
>
```

The default — `AdjacencyList<OrderedVertexStorage, CacheInOutEdges<OrderedEdgeStorage<…>>, …>` — is a safe baseline for general use: insertion-ordered iteration, cached incoming-edge sets so ``BidirectionalGraph`` queries are O(1), and dictionary-backed property maps.

Use a different backend when the graph's shape or access pattern makes that default a poor fit.

## Vertex storage

### OrderedVertexStorage *(default)*

Insertion-ordered, hash-indexed vertex set. Use unless you have a specific reason not to.

## Edge storage

The library ships four edge backends, each optimized for a different workload.

### OrderedEdgeStorage *(default)*

General-purpose `OrderedSet`-based storage. Good for mixed read/write workloads on graphs that grow and shrink over time. Insertion-ordered edge iteration.

### CSREdgeStorage

Compressed Sparse Row: edges grouped by source vertex in flat arrays with row offsets. Excellent cache locality for outgoing-edge iteration — the dominant access pattern for shortest-path, traversal, and centrality algorithms.

**Use when:**
- The graph is mostly read after construction (analytics, batch algorithms).
- You run many traversals over a static or rarely-mutated topology.
- Edge count is large and you want compact memory.

**Avoid when:** the graph mutates heavily after construction. CSR's flat layout is not append-friendly compared with the ordered backend.

### COOEdgeStorage

Coordinate format: parallel `(source, destination)` arrays with tombstones for deletes. The simplest backend; serves well as an interchange format and for builders that ingest edge lists.

**Use when:** you are bulk-loading from an edge list, exporting to a tabular format, or you want the absolute minimum per-edge overhead and don't need ordered incoming-edge lookups.

### BinaryEdgeStore

Per-vertex `(left, right)` child slots. Conforms to ``BinaryIncidenceGraph``, unlocking tree-shaped algorithms (in-/pre-/post-order traversals).

**Use when:** modelling binary trees or any structure where every vertex has at most two outgoing edges with positional meaning.

## Adding incoming-edge caching

``BidirectionalGraph`` (queries like `incomingEdges(of:)`) is not free for every backend — `OrderedEdgeStorage` and `CSREdgeStorage` only track outgoing edges natively. Wrap any compatible edge store with ``CacheInOutEdges`` to add O(1) reverse lookups, paid for by extra memory and write cost:

```swift
let graph = AdjacencyList(
    edgeStore: OrderedEdgeStorage().cacheInOutEdges()
)
```

This is what the default initializer does. Drop the wrapper if you never run an algorithm that needs incoming edges (Kosaraju, Tarjan SCC, reverse-BFS, edge betweenness, etc.).

## Property maps

By default, properties are stored in `DictionaryPropertyMap<Key, Values>`. The same pluggability applies — provide a custom ``MutablePropertyMap`` to back properties by an array (when descriptors are dense integer ids), a database, or any other store. See <doc:PropertiesAndPropertyMaps>.

## Quick decision table

| Workload                                  | Recommended edge store                            |
|-------------------------------------------|---------------------------------------------------|
| General-purpose, mixed read/write         | `OrderedEdgeStorage().cacheInOutEdges()` (default)|
| Static graph, heavy traversal workload    | `CSREdgeStorage` (+ `cacheInOutEdges` if needed)  |
| Bulk loading from edge list / interchange | `COOEdgeStorage`                                  |
| Binary trees                              | `BinaryEdgeStore`                                 |

## Topics

### Related

- <doc:PluggableArchitecture>
- <doc:ChoosingGraphType>
- <doc:PropertiesAndPropertyMaps>
