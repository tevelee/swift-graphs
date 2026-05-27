# Benchmarks

Comprehensive performance benchmarks for swift-graphs, built on
[ordo-one/package-benchmark](https://github.com/ordo-one/package-benchmark).

This is a **standalone Swift package** (`Benchmarks/Package.swift`) that
depends on the parent library via a local path. Keeping it separate means
the benchmark dependency and its macOS 13+ platform requirement never
leak into the library's published surface, and the benchmark package can
enable every algorithm trait without forcing the same on library
consumers.

## Prerequisites

`package-benchmark` uses [jemalloc](https://jemalloc.net) for allocation
counts and resident-memory metrics:

```sh
brew install jemalloc           # macOS
sudo apt install libjemalloc-dev # Debian/Ubuntu
```

If jemalloc is not installed (or the Homebrew keg is broken), build with
`BENCHMARK_DISABLE_JEMALLOC=1` — wall-clock and CPU time will still be
reported but malloc-count and resident-peak columns are unavailable.

## Running

> [!IMPORTANT]
> On the current Swift 6.2 toolchain you **must** pass
> `--benchmark-build-configuration debug`. Release mode hits multiple
> SIL-optimiser crashes (`SIL verification failed: result of
> struct_element_addr does not match type of field` in
> `BoundsCheckOpts`) when specialising stored closure-typed fields
> across several library types (`Dijkstra.makeIterator`,
> `BidirectionalDijkstra.makePriorityQueue`, `Kahn`, …). The library
> itself compiles in release; the bug is triggered by how the
> benchmark targets specialise on `AdjacencyList<…>`. Remove the
> `--benchmark-build-configuration debug` flag once a newer toolchain
> fixes this.

From the repo root:

```sh
swift package --package-path Benchmarks benchmark --benchmark-build-configuration debug
swift package --package-path Benchmarks benchmark --benchmark-build-configuration debug --filter Dijkstra
swift package --package-path Benchmarks benchmark --benchmark-build-configuration debug --filter "Storage/"
swift package --package-path Benchmarks benchmark --benchmark-build-configuration debug list
```

Or from inside this directory:

```sh
cd Benchmarks
swift package benchmark --benchmark-build-configuration debug
swift package benchmark --benchmark-build-configuration debug --filter "ShortestPath/Dijkstra/sparse-1k"
```

Debug-mode numbers are absolute-lower-bound (no optimisation), but
relative deltas between commits remain meaningful — which is the
primary use-case for the suite.

## What's covered

Benchmarks are grouped by algorithm family. Names follow
`<Family>/<Algorithm>/<shape>-<size>-<density>`.

| File                    | Family                              | Algorithms                              |
|-------------------------|-------------------------------------|-----------------------------------------|
| `ShortestPath.swift`    | Single-source / single-pair         | Dijkstra, BidirectionalDijkstra, BellmanFord, SPFA |
| `AllPairs.swift`        | All-pairs shortest paths            | FloydWarshall, Johnson                  |
| `Traversal.swift`       | BFS, DFS, visitor overhead          | BFS, DFS                                |
| `Connectivity.swift`    | (S)CC, articulation points          | DFS CC, Kosaraju, Tarjan, Tarjan AP     |
| `MST.swift`             | Minimum spanning tree               | Kruskal, Prim, Borůvka                  |
| `TopologicalSort.swift` | DAG ordering                        | Kahn, DFS                               |
| `Coloring.swift`        | Vertex coloring                     | Greedy, DSatur                          |
| `Centrality.swift`      | Centrality measures                 | Degree, PageRank, Betweenness           |
| `Storage.swift`         | Edge-storage backend comparison     | Dijkstra & BFS across Ordered / Ordered+CacheInOut / CSR; graph-build throughput |

Sizes are deliberately conservative on the O(V·E) and O(V³) algorithms
(BellmanFord, Betweenness, FloydWarshall) so the full suite runs in
single-digit minutes.

## Baselines and regression detection

`package-benchmark` is designed for tracking performance across commits.

```sh
# Save the current performance as a baseline named "main".
swift package --package-path Benchmarks benchmark baseline update main

# Switch branches, make changes, re-run. Compare against the saved baseline.
swift package --package-path Benchmarks benchmark baseline compare main

# Fail with a non-zero exit if any benchmark regressed beyond its threshold.
swift package --package-path Benchmarks benchmark baseline check main
```

See `swift package --package-path Benchmarks benchmark --help` for the
full surface (`list`, `read`, `thresholds`, etc.).

The default configuration (set in `Benchmarks.swift`) captures wall
clock, total CPU time, total malloc count, peak resident memory, and
throughput. Per-benchmark thresholds and metric overrides can be set
through the `Benchmark(configuration:)` initialiser — start with the
defaults and tighten as the project matures.

## CI integration

See the
[package-benchmark CI guide](https://swiftpackageindex.com/ordo-one/package-benchmark/documentation/benchmark/runningbenchmarks#GitHub-Actions)
for a GitHub Actions workflow that posts a PR comment with the
benchmark delta vs. `main`.

## Adding a benchmark

1. Pick (or create) a file in `GraphsBenchmarks/` named after the
   algorithm family.
2. Add a registration function `func registerFooBenchmarks() { … }` that
   calls `Benchmark("Family/Algorithm/shape") { benchmark in … }`.
3. Call it from `Benchmarks.swift`'s `let benchmarks = { … }` closure.
4. Always perform graph construction *before* `benchmark.startMeasurement()`
   so setup is not part of the timing.

## Notes

- Graph fixtures use SplitMix64 (see `Fixtures.swift`) so identical seeds
  yield identical graphs across machines of the same architecture.
  Cross-host comparisons therefore reflect real perf deltas, not RNG
  variance.
- `Storage/*` benchmarks deliberately re-implement the graph generator
  for each backend rather than parameterising it: the generic
  specialisation is itself part of what we want to measure.
- The `swift-collections` dependency is pinned to `<1.4.0`. Newer
  releases tightened `OrderedCollections` re-export visibility from the
  `Collections` umbrella and break swift-graphs' strict-`@inlinable`
  build under Swift 6 language mode. Loosen once the library imports
  `OrderedCollections` directly.
