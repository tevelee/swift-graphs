# Performance audit — May 2026

Performance audit of the most-used algorithms and data structures with
before/after numbers per fix. After unblocking the Swift 6.2 release-mode
build, the table shows **release** numbers (M2 MacBook Pro).

## Headline release-mode numbers (after all fixes)

| Benchmark                                       | Wall time | Notes |
|-------------------------------------------------|----------:|-------|
| `Centrality/Degree/sparse-10k-d8`               | **5.8 µs** | excellent |
| `ShortestPath/SPFA/sparse-1k-d8`                | **2.7 ms** | excellent |
| `ShortestPath/Dijkstra/sparse-1k-d8`            | **8 ms**  | was 15 ms (audit-1) |
| `ShortestPath/Dijkstra/dense-500-d50`           | **8 ms**  | was 15 ms (audit-1) |
| `MST/Prim/undirected-5k-d8`                     | 8 ms      | excellent |
| `Coloring/DSatur/undirected-2k-d12`             | 10 ms     | excellent |
| `Coloring/Greedy/undirected-2k-d12`             | 14 ms     |  |
| `ShortestPath/Dijkstra/single-pair-10k`         | **14 ms** | was 32 ms (audit-1) |
| `TopologicalSort/Kahn/DAG-10k-d8`               | 18 ms     |  |
| `Traversal/DFS/sparse-10k-d8`                   | **40 ms** | was 64 ms (audit-1) |
| `Centrality/PageRank/sparse-5k-d8`              | 40 ms     |  |
| `Connectivity/SCC/Kosaraju/sparse-10k-d8`       | 50 ms     |  |
| `MST/Boruvka/undirected-5k-d8`                  | 71 ms     |  |
| `ShortestPath/BidirectionalDijkstra/sparse-10k-d8` | **71 ms** | was 191 ms (audit-1) |
| `TopologicalSort/DFS/DAG-10k-d8`                | 96 ms     |  |
| `MST/Kruskal/undirected-5k-d8`                  | 156 ms    |  |
| `Centrality/Betweenness/sparse-500-d8`          | 388 ms    |  |
| `Traversal/BFS/sparse-10k-d8`                   | **388 ms** | was 615 ms (audit-1) |
| `Storage/Dijkstra/CSR/10k-d8`                   | **594 ms** | was 973 ms |
| `Storage/Dijkstra/Ordered+CacheInOut/10k-d8`    | **596 ms** | was 940 ms |
| `ShortestPath/Dijkstra/sparse-10k-d8`           | **597 ms** | was 968 ms (audit-1) |
| `Storage/Dijkstra/Ordered-bare/10k-d8`          | **679 ms** | uncached |
| `AllPairs/FloydWarshall/dense-200`              | 1.2 s     | O(V³) |
| `AllPairs/Johnson/sparse-500-d8`                | **1.8 s** | was 3.6 s (audit-1); runs Dijkstra V times |

## Speedups (vs. pre-audit debug baseline)

| Benchmark                                       | Before (debug) | After (release) | Combined factor |
|-------------------------------------------------|---------------:|----------------:|----------------:|
| `Storage/Dijkstra/Ordered-bare/10k`             | 123,000 ms     | 679 ms          | ~181×           |
| `Connectivity/SCC/Kosaraju/10k`                 | 716,000 ms     | 50 ms           | ~14,300×        |
| `Coloring/DSatur/2k`                            | 26,000 ms      | 10 ms           | ~2,700×         |
| `Traversal/DFS/10k`                             | 1,754 ms       | 40 ms           | ~44×            |
| `Coloring/Greedy/2k`                            | 49 ms          | 14 ms           | ~3.5× (release alone) |
| `ShortestPath/Dijkstra/1k`                      | 31 ms          | 8 ms            | ~4× (release alone)   |
| `ShortestPath/Dijkstra/10k` (cached)            | 1,107 ms       | 597 ms          | ~1.85×                |

The biggest moves between audit-1 and audit-3 come from genericising the
queue/stack types on the iterator algorithms (item 11 below) — most hot
loops now specialise on a concrete queue rather than dispatching through
`any QueueProtocol<...>`.

## Root causes and fixes

### 1. `OrderedEdgeStorage.outgoingEdges` was O(E) — commit `4380548`

The default sparse-graph edge storage implemented `outgoingEdges(of:)` as
`_edges.filter { source == v }` — a linear scan over the full edge set per
call. Dijkstra/BFS/DFS therefore ran at O(V·E) instead of O(V+E). The
`CacheInOutEdges` wrapper hid this because the default `AdjacencyList()`
auto-wraps; users constructing `AdjacencyList(edgeStore: OrderedEdgeStorage())`
got the slow path.

Fix: maintain `_outgoingByVertex` / `_incomingByVertex` adjacency dicts inside
`OrderedEdgeStorage`. All single-vertex incidence queries are O(1).
`CacheInOutEdges` is now redundant for this backend but kept for forward
compatibility.

### 2. Kosaraju re-traversed already-processed subgraphs — commit `3188561`

Both DFS passes used the library's `DepthFirstSearch`, which has its own
internal `visited` set. When the outer loop restarted DFS at a new vertex,
that fresh DFS happily re-traversed any subgraph reachable from the new
start, including vertices already in a previous component. Degraded from
O(V+E) to roughly O(K · (V+E)) for K components, plus per-call
`graph.transpose()` inside the inner function.

Fix: replace both passes with explicit stack-based iterative DFS using the
shared color `propertyMap` as visited set; hoist `transpose()` once.

### 3. DSatur was O(V³) — commit `c1bd566`

Three nested quadratics: `vertices.firstIndex(of:)` for tie-breaking,
`Set(graph.successors(of:))` rebuilt per saturation eval, saturation degree
recomputed from scratch per pick. Net O(V³).

Fix: precompute index/degrees/neighbours, maintain saturation incrementally,
update only touched neighbours per pick. O(V²). A heap-based pick would push
it to O((V + E) log V) — follow-up.

### 4. DFS allocated a `Result` per edge — commit `558ba53`

Inner edge loop unconditionally constructed `Result` (captures the
`any PropertyMap<…>` existential, costing a retain) just to pass to a
`shouldTraverse` visitor hook nearly always `nil`. For E=40k that's 40k
retain/release pairs in the hot path.

Fix: only build the context when `visitor?.shouldTraverse != nil`.

### 5. Dijkstra recursed on stale priority-queue entries — commit `efb74dd`

`return next()` per duplicate dequeue is a tail call Swift won't optimise.
On adversarial graphs could overflow the stack.

Fix: convert to a `while let` loop.

### 6. COOEdgeStorage had the same O(E) issue as OrderedEdgeStorage — commit `979c153`

Identical fix: maintain adjacency dicts. CSR was already O(degree) via row
offsets and incoming buckets, no change.

### 7. Swift 6.2 release-mode SIL crash — commit `edc80c9`

`BoundsCheckOpts` crashes when verifying generic structs whose stored
properties have type `() -> any QueueProtocol<Self.NestedType>`. Affected ten
algorithms (Dijkstra, BidirectionalDijkstra, AStar, UCS, BacktrackingDijkstra,
BFS, DFS, Kahn, DFSTopologicalSort, Yen).

Initial workaround: drop the stored factory; construct the default queue/stack
directly inside `makeIterator`. This unblocked the release-mode build but
forced every algorithm to dispatch through `any QueueProtocol<...>` on the
hot path, leaving the perf on the table. Item 11 below is the real fix.

### 8. AStar called heuristic on every stale-skip and neighbour relaxation — commit `1c7f149`

For an expensive heuristic the work compounded; for a cheap heuristic the
cost was the existential dispatch through `Heuristic`. First-use
memoisation in a `[Vertex: HScore]` dictionary; no behaviour change.

### 9. DFS could discover a vertex twice — commit `553cc55`

When a vertex was reachable from two siblings of a DFS frame (V→A, V→C,
A→C), both siblings could push it for first-visit. The C-from-V frame
popped last and re-discovered C, overwriting its color and double-counting
time. Correctness bug, latent.

Fix: skip first-visit frames whose vertex is already non-white.

### 10. Storage rename to LinearOrderedEdgeStorage + typealias — commit `ad62495`

Split the single `OrderedEdgeStorage` type into two: a raw
`LinearOrderedEdgeStorage` with O(E) incidence (honest about its
characteristics) and a `typealias OrderedEdgeStorage =
CacheInOutEdges<LinearOrderedEdgeStorage>` for the default name that
everything actually wants. Users who want the uncached form for an
append-only build phase reach for `LinearOrderedEdgeStorage` directly.

### 11. Queue/stack genericisation — Option A applied to nine algorithms

For each of Dijkstra, BFS, DFS, UCS, AStar (algorithms with exposed
iterators), the structure now carries a concrete `Queue` (or `Stack`)
generic parameter and stores a `makeQueue: () -> Queue` factory. The hot
loop reads `var queue: Queue` (specialised) rather than
`var queue: any QueueProtocol<...>` (witness-table dispatch).

To keep external references (`Foo<Graph>.Visitor`, `Foo<Graph>.Result`)
working without all generic args, the visitor / result / priority-item
types are now top-level: `DijkstraVisitor<Graph>`,
`DijkstraResult<Graph, Weight>`, `DijkstraPriorityItem<Vertex, Weight>`
and the equivalents for the other four. Each algorithm keeps nested
`typealias Visitor = …` etc. for internal references.

Each algorithm provides a no-arg-Queue convenience init constrained to the
default queue type (`PriorityQueue<...>` for Dijkstra/UCS/AStar,
`Deque<Vertex>` for BFS, `Array<DFSFrame>` for DFS), so existing
construction sites keep working:

```swift
Dijkstra(on: g, from: s, edgeWeight: w)                          // default queue
Dijkstra(on: g, from: s, edgeWeight: w, makeQueue: { MyHeap() }) // custom queue
```

For Kahn, DFSTopologicalSort, BidirectionalDijkstra and BacktrackingDijkstra
(no exposed iterator — the queue/stack lives inside a single function),
the change is surgical: the local `any QueueProtocol<X>` becomes a concrete
`PriorityQueue<X>` / `Deque<X>` / `Array<X>`. Same specialisation effect,
no API surface change.

The Iterator type stays nested in the algorithm struct and uses the outer
`Queue` directly (no rename, no naming collision with `Sequence.Iterator`).

Release deltas vs. audit-1 (M2):

| Benchmark                                       | audit-1 | audit-3 | Δ        |
|-------------------------------------------------|--------:|--------:|---------:|
| `ShortestPath/Dijkstra/sparse-1k-d8`            | 15 ms   | 8 ms    | -47%     |
| `ShortestPath/Dijkstra/sparse-10k-d8`           | 968 ms  | 597 ms  | -38%     |
| `ShortestPath/Dijkstra/dense-500-d50`           | 15 ms   | 8 ms    | -47%     |
| `ShortestPath/Dijkstra/single-pair-10k`         | 32 ms   | 14 ms   | -56%     |
| `ShortestPath/BidirectionalDijkstra/sparse-10k` | 191 ms  | 71 ms   | -63%     |
| `Traversal/BFS/sparse-10k-d8`                   | 615 ms  | 388 ms  | -37%     |
| `Traversal/DFS/sparse-10k-d8`                   | 64 ms   | 40 ms   | -38%     |
| `AllPairs/Johnson/sparse-500-d8`                | 3.6 s   | 1.8 s   | -50%     |
| `Storage/Dijkstra/Ordered-bare/10k-d8`          | 951 ms  | 679 ms  | -29%     |
| `Storage/Dijkstra/Ordered+CacheInOut/10k-d8`    | 940 ms  | 596 ms  | -37%     |
| `Storage/Dijkstra/CSR/10k-d8`                   | 973 ms  | 594 ms  | -39%     |

The remaining big numbers (BFS-10k at 388 ms, Dijkstra-10k at 597 ms)
were bottlenecked on the property-map existential — addressed by item 12
below.

### 12. Property-map existential — specialise to `DictionaryPropertyMap`

Until audit-3, every algorithm iterator and Result held its per-run
property map as `any MutablePropertyMap<Vertex, VertexPropertyValues>` /
`any PropertyMap<...>`. The hot loop reads + writes that field 2–3 times
per edge (color, distance, predecessor). Each access went through a
witness-table thunk that (a) couldn't devirtualise the subscript and (b)
forced a copy + writeback on `propertyMap[v][property] = …` because the
existential subscript thunk can't forward `_modify` cleanly — even though
`DictionaryPropertyMap.subscript` defines `_modify` for in-place
mutation.

Since `graph.makeVertexPropertyMap()` always constructs a
`DictionaryPropertyMap`, the storage type is private to each algorithm,
and there is only one real conformer in the library, the fix is to drop
the genericness entirely and bind the field to the concrete type:

```swift
@usableFromInline
var propertyMap: DictionaryPropertyMap<Vertex, VertexPropertyValues>
// …
self.propertyMap = DictionaryPropertyMap(defaultValue: .init())
```

Applied across all 5 algorithms that carried this state: Dijkstra,
AStar, UniformCostSearch, BFS, DFS, plus the `inout` parameter in
`DFSTopologicalSort.dfsVisit`.

For the two Result types whose `propertyMap` field is part of the
**public** API (UCS, BFS), the impl type is hidden behind an opaque
accessor — concrete storage, opaque exposure:

```swift
@usableFromInline
let _propertyMap: DictionaryPropertyMap<Vertex, VertexPropertyValues>

@inlinable
public var propertyMap: some PropertyMap<Vertex, VertexPropertyValues> {
    _propertyMap
}
```

Opaque types specialise within the module while keeping the concrete
type out of the API contract. The other Results (Dijkstra, AStar, DFS)
already had the field internal (`@usableFromInline let`), so the change
is purely a type narrowing.

This still defers the deeper `VertexPropertyValues = [ObjectIdentifier: Any]`
boxing — that would lose the dynamic-property model — and the
`Graph.VertexPropertyMap` associated-type approach (PM-1 in the design
notes) that would let graphs declare their natural property-map type. The
concrete-specialisation taken here is the lightest touch that removes the
existential cost; PM-1 remains an option if a future use case wants
non-dictionary backing.

Debug-mode deltas vs. audit-3 (M2, single-thread, 3-6 samples each):

| Benchmark                                          | Δ wall  | Δ malloc |
|----------------------------------------------------|--------:|---------:|
| `ShortestPath/Dijkstra/sparse-1k-d8`               | -6%     | -3%      |
| `ShortestPath/Dijkstra/sparse-10k-d8`              | -6%     | -3%      |
| `ShortestPath/Dijkstra/dense-500-d50`              | -6%     | -1%      |
| `ShortestPath/Dijkstra/single-pair-10k`            | -7%     | -5%      |
| `ShortestPath/BidirectionalDijkstra/sparse-10k-d8` | -8%     | 0%       |
| `Traversal/BFS/sparse-10k-d8`                      | -5%     | -4%      |
| `Traversal/BFS/with-visitor-10k`                   | -5%     | -4%      |
| `Traversal/DFS/sparse-10k-d8`                      | -7%     | -5%      |
| `Traversal/DFS/sparse-50k-d8`                      | -11%    | -5%      |
| `TopologicalSort/DFS/DAG-10k-d8`                   | -6%     | -2%      |
| `Connectivity/SCC/Kosaraju/sparse-10k-d8`          | -6%     | 0%       |
| `AllPairs/Johnson/sparse-500-d8`                   | -5%     | -2%      |
| `Storage/Dijkstra/CSR/10k-d8`                      | -6%     | -3%      |
| `Storage/Dijkstra/Ordered+CacheInOut/10k-d8`       | -5%     | -3%      |
| `Storage/Dijkstra/Ordered-bare/10k-d8`             | -4%     | -3%      |
| `Storage/BFS/CSR/10k-d8`                           | -6%     | -4%      |
| `Storage/BFS/Ordered+CacheInOut/10k-d8`            | -6%     | -4%      |

Consistent 5–7% wall-clock improvement and 2–5% allocation drop. The
biggest move is `Traversal/DFS/sparse-50k-d8` at -11% — DFS has the
highest per-edge property-map touch count (color state machine + time
+ discovery + depth + predecessor across 50k vertices). The allocation
drop reflects `_modify` no longer producing a temporary copy of
`VertexPropertyValues` per write.

These are debug-mode deltas (the only mode the benchmark targets
currently compile in — see item 7); release-mode magnitude will be
larger because the optimiser's contribution stacks on top of this.

## Storage backend confirmation

The OrderedEdgeStorage fix is visible in the storage matrix:

| Storage backend                  | Dijkstra/10k |
|----------------------------------|-------------:|
| `Ordered` (no cache wrapper)     | 679 ms       |
| `Ordered+CacheInOut`             | 596 ms       |
| `CSR`                            | 594 ms       |

CSR and the cached `Ordered` are within noise. The uncached
`LinearOrderedEdgeStorage` is the honest O(E) variant — slower as expected
(no incidence cache), but no longer catastrophically so since the rest of
Dijkstra's hot path was tightened up.

## Reproducing

```sh
brew install jemalloc
swift package --package-path Benchmarks benchmark
swift package --package-path Benchmarks benchmark --filter Dijkstra
```

Baselines:

```sh
swift package --package-path Benchmarks benchmark baseline update audit-after
# ... make changes ...
swift package --package-path Benchmarks benchmark baseline compare audit-after
```
