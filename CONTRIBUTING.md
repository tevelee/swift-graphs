# Contributing to swift-graphs

Thank you for your interest in contributing! swift-graphs is a protocol-oriented graph algorithms library for Swift, inspired by the [Boost Graph Library](https://www.boost.org/doc/libs/1_89_0/libs/graph/doc/table_of_contents.html). Contributions of all kinds are welcome — new algorithms, bug fixes, documentation improvements, and performance work.

---

## Getting started

**Prerequisites:**
- Xcode 16+ or a Swift 6.2+ toolchain (download from [swift.org](https://swift.org/download/))
- `git clone https://github.com/tevelee/swift-graphs.git && cd swift-graphs`

**Build:**
```bash
swift build
```

**Run the full test suite** (required before submitting a PR):
```bash
# Default traits only (Pathfinding + Connectivity) — what most users get
swift test

# All traits — the full library including Serialization, GridGraph, MST, MaxFlow, etc.
# This must pass before submitting a PR.
swift test --enable-all-traits
```

> **Why two commands?** swift-graphs uses Swift Package Manager traits (in `Package@swift-6.2.swift`) to let users opt out of algorithm families they don't need. The default build compiles only the most common ones; `--enable-all-traits` compiles everything. CI checks both.

---

## Development workflow

1. **Fork** the repository and create a branch from `main`:
   ```bash
   git checkout -b feature/my-algorithm
   ```

2. **Write tests first** (TDD). New behaviour must have a failing test before any implementation. See the [Testing](#testing) section.

3. **Implement** the minimal code to make the test pass.

4. **Verify** locally:
   ```bash
   swift test --enable-all-traits
   swift-format lint --recursive Sources Tests   # advisory; see Code style
   ```

5. **Open a PR** against `main`. Fill in the PR template — especially the checklist. Add a label so the automated release notes pick it up correctly.

---

## Adding a new algorithm

The library follows a consistent four-step pattern for every algorithm:

**1. Define the algorithm struct** conforming to the appropriate protocol (in `Sources/Graphs/AlgorithmImplementations/<Category>/`):
```swift
#if !GRAPHS_USES_TRAITS || GRAPHS_PATHFINDING

public struct MyAlgorithm<G: IncidenceGraph, W: Numeric & Comparable>: ShortestPathAlgorithm
where G.VertexDescriptor: Hashable, W.Magnitude == W {
    public typealias Graph = G
    public typealias Weight = W
    public typealias Visitor = MyAlgorithmVisitor<G>
    let weight: CostDefinition<G, W>
}

#endif
```

**2. Implement** the required protocol methods — core algorithm logic.

**3. Add a static factory method** so call sites are ergonomic:
```swift
extension ShortestPathAlgorithm
where Self == MyAlgorithm<some IncidenceGraph, some Numeric & Comparable> {
    public static func myAlgorithm<G, W>(weight: CostDefinition<G, W>) -> MyAlgorithm<G, W> { ... }
}
```

**4. Use it** — it works automatically with all compatible graphs:
```swift
graph.shortestPath(from: a, to: b, using: .myAlgorithm(weight: .property(\.weight)))
```

**Trait guard requirement:** files in `AlgorithmImplementations/` and `GraphImplementations/` should be wrapped in `#if !GRAPHS_USES_TRAITS || GRAPHS_<CATEGORY>` so they can be opted out in `Package@swift-6.2.swift`. Choose the most appropriate existing trait or propose a new one.

---

## Testing

Tests live in `Tests/GraphsTests/`, organised by category (`Core/`, `Algorithms/`, `Serialization/`, etc.). The library uses **Swift Testing** (`@Test`, `#expect`).

**Rules:**
- Write the failing test *before* any implementation (TDD).
- Every new public function, algorithm, or graph type needs at least one test.
- Cover edge cases: empty graphs, single-vertex graphs, disconnected components.
- Trait-gated tests must be wrapped in the same `#if` guard as their source file.

**Running specific tests:**
```bash
swift test --filter GraphsTests.DijkstraTests
swift test --filter "GraphsTests.DijkstraTests/findsShortestPath"
```

---

## Code style

The project enforces style via `.swift-format`. Key rules:
- 4-space indentation, 160-character line limit
- All public declarations require `///` doc comments
- No access level on extension declarations
- Use early exits (guard statements)

**Format before submitting:**
```bash
swift-format format --in-place --recursive Sources Tests
swift-format lint --recursive Sources Tests  # check
```

If `swift-format` is not installed: `brew install swift-format`.

---

## Documentation

Every public declaration must have a `///` doc comment — this is enforced by `.swift-format`. Doc comments should describe *what* the type/function does and any important complexity or constraints.

When adding a new algorithm, also update the relevant DocC article in `Sources/Graphs/Graphs.docc/` if one exists for the algorithm family.

---

## Benchmarks

Performance-sensitive changes should include benchmark results. The benchmark suite lives in `Benchmarks/` as a separate Swift package using [ordo-one/benchmark](https://github.com/ordo-one/package-benchmark).

**Run all benchmarks (macOS only, requires jemalloc):**
```bash
brew install jemalloc
swift package --package-path Benchmarks benchmark
```

**Filter by name:**
```bash
swift package --package-path Benchmarks benchmark --filter Dijkstra
```

CI will automatically compare benchmark results between the PR head and the `main` branch and post a summary comment.

---

## Reporting bugs and requesting features

- **Bugs:** use the [Bug report](.github/ISSUE_TEMPLATE/bug_report.yml) template — include a minimal reproduction.
- **Features / algorithms:** use the [Feature request](.github/ISSUE_TEMPLATE/feature_request.yml) template — checking against the [BGL feature list](https://www.boost.org/doc/libs/1_89_0/libs/graph/doc/table_of_contents.html) first is helpful.
- **Questions:** use [GitHub Discussions](https://github.com/tevelee/swift-graphs/discussions) rather than issues.
- **Security vulnerabilities:** see [SECURITY.md](SECURITY.md) — do not open a public issue.

---

## Code of Conduct

This project follows the [Contributor Covenant Code of Conduct](CODE_OF_CONDUCT.md). By participating you agree to abide by its terms.
