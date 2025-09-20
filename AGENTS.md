# Project high level requirements
- flexible graph representations with a small core API and make it extensible for various wide range of algorithms, representations
  - adjacency list
  - adjacency matrix
  - compressed sparse row (CSR)
  - support for a "lazy" graph so you don't have to predefine the whole structure but compute edges on demand (via closure?)
  - support for grid graph (optimized traversals)
  - support for undirected graphs (reversed/bidirectional edges)
- inspired by boost graph library, graphs independent of concrete storage (vector/array) so algorithms have different characteristics
- structure is independent from algorithms. They can be extensions
- vertext/edge descriptors can help with performance optimizations so if nodes are heavy, they don't have to be stored in memory multiple times
- strong reliance on strongly typed structures and algorithms via compile time generics, imposing constraints
  - certain algorithms are only available on appropriate graphs (e.g. infix dfs only for binary graph, shortest path only for weighted graphs, dijkstra only for non-negative edges)
- common operations represented as wrappers/views (e.g. transposing, filtering, complement graph, partitioning, subpath)
- extensive test coverage
  - ability to produce deterministic, repeatable results (e.g. if stoage is heap, lets inject sort)
- since possibly algorithms will reuse each other, it would be nice to have a single generic Dijkstra implementation and multiple API surfaces reusing the same underlying one
- extensions Graph for algotihms
  - separate the definition and the implementation of each specific algo
  - group by use-cases e.g. shortest path algotihms, traversals, minimum spanning tree and specify specific algo as parameter (with a good default)


## Code organization example

Callsite graph.shortestPath(from: "Root", to: "Z", using: .dijkstra()) // or .aStar() or .bellmanFord()
extension GraphComponent where Edge: Weighted {
    @inlinable public func shortestPath(
        from source: Node,
        until condition: (Node) -> Bool,
        using algorithm: some ShortestPathUntilAlgorithm<Node, Edge>
    ) -> Path<Node, Edge>? {
        algorithm.shortestPath(from: source, until: condition, in: self)
    }
}
public protocol ShortestPathUntilAlgorithm<Node, Edge> {
    associatedtype Node
    associatedtype Edge
    @inlinable func shortestPath(
        from source: Node,
        until condition: (Node) -> Bool,
        in graph: some GraphComponent<Node, Edge>
    ) -> Path<Node, Edge>?
}
extension ShortestPathUntilAlgorithm {
    @inlinable public static func dijkstra<Node, Edge>() -> Self where Self == Dijkstra<Node, Edge> {
        .init()
    }
}
extension Dijkstra: ShortestPathUntilAlgorithm {
    @inlinable public func shortestPath(
        from source: Node,
        until condition: (Node) -> Bool,
        in graph: some GraphComponent<Node, Edge>
    ) -> Path<Node, Edge>? {
        ...
    }
}

extension ShortestPathAlgorithm where Self: ShortestPathUntilAlgorithm, Node: Equatable {
    @inlinable public func shortestPath(
       from source: Node,
       to destination: Node,
       in graph: some GraphComponent<Node, Edge>
   ) -> Path<Node, Edge>? {
       shortestPath(from: source, until: { $0 == destination }, in: graph)
    }
}

Similarly, capabilities would be nice to look like this behind a unified API surface with extensible/plugin architecture

## Callsite examples

Note: this is not the exact API surface I precisely want, the graph repsentations might require something different. I expect a lot of changes needed around traversal strategies
graph.traverse(from: "Root", strategy: .bfs())
graph.traverse(from: "Root", strategy: .dfs())
graph.traverse(from: "Root", strategy: .bfs(.trackPath()))
graph.traverse(from: "Root", strategy: .dfs(order: .postorder()))
graph.traverse(from: "Root", strategy: .dfs().visitEachNodeOnce())
binaryGraph.traverse(from: "Root", strategy: .dfs(order: .inorder()))
graph.shortestPath(from: "Root", to: "Z", using: .dijkstra()) // or .aStar() or .bellmanFord()
graph.shortestPaths(from: "Root", using: .dijkstra()) // or .bellmanFord()
graph.shortestPathsForAllPairs(using: .floydWarshall()) // or .johnson()
graph.minimumSpanningTree(using: .kruskal()) // or .prim() or .boruvka()
graph.maximumFlow(using: .fordFulkerson()) // or .edmondsKarp() or .dinic()
graph.stronglyConnectedComponents(using: .kosaraju()) // or .tarjan()
graph.colorNodes(using: .greedy()) // or .dsatur() or .welshPowell()
graph.isIsomorphic(to: graph2, using: .vf2()) // or .weisfeilerLehman()
ConnectedGraph.random(using: .erdosRenyi()) // or .barabasiAlbert() or .wattsStrogatz()
bipartite.maximumMatching(using: .hopcroftKarp())
graph.isCyclic()
graph.isTree()
graph.isConnected()
graph.isPlanar()
graph.isBipartite()
graph.topologicalSort()
gridGraph.shortestPath(from: GridPosition(x: 0, y: 0), to: GridPosition(x: 4, y: 4), using: .aStar(heuristic: .euclideanDistance(of: \.coordinates)))
gridGraph.shortestPaths(from: GridPosition(x: 0, y: 0))
gridGraph.shortestPathsForAllPairs()
gridGraph.eulerianCycle()
gridGraph.eulerianPath()
gridGraph.hamiltonianCycle()
gridGraph.hamiltonianPath()
gridGraph.hamiltonianPath(from: GridPosition(x: 0, y: 0))
gridGraph.hamiltonianPath(from: GridPosition(x: 0, y: 0), to: GridPosition(x: 4, y: 4))

# TODOs
[ ] basic graph representations
  [x] basic protocols for vertices, edges
  [ ] multiple representations
    [x] adjacency list
      [x] variable storage, e.g. array/dictionary/vector
    [x] matrix
  [x] special graphs
    [x] binary (lhs/rhs edge)
    [ ] grid
    [ ] lazy
    [ ] bipartite
[ ] conditional conformances on equatable, hashable
[x] property maps like BGL to store weights, capacities etc for algos
[ ] extensions on graph to support various algos
  [ ] shortest paths from source until end condition
    [x] Dijkstra
    [x] A*
      [x] Injectable heuristic (e.g. distance like manhattan/hamiltonian)
    [ ] Iteratively deepening A*
  [ ] shortest paths from source to all vertices
    [ ] Dijkstra
    [ ] A*
  [ ] shortest paths for all pairs
    [ ] FloydWarshall
    [ ] Johnson
  [ ] shortest paths when EdgeListGraph
    [ ] BellmannFord
    [ ] Bidirectional Dijkstra
  [ ] K shortest paths
    [ ] Yen
  [x] traversals
    [x] ability to track predecessor path, depth etc. in visits
    [x] ability to skip already visited (acyclic)
    [x] limited depth support
    [x] BFS
    [x] DFS
      [x] prefix order
      [x] postfix order
      [x] represent binary graph edges with a dedicated type/marker and support infix order
      [x] iteratively deepening
    [x] Best-first search
    [x] Instead of a BGL like API, let's expose the traversal as an iterable Sequence. And search becomes just a filter on the sequence.
  [ ] topological sort
  [ ] computing graph properties
    [x] is cyclic
    [x] is connected
    [x] is tree
    [x] has eulerian path
    [x] has eulerian cycle
    [ ] satisfies dirac / ore
    [x] is planar
  [ ] minimum spanning tree
    [ ] Prim
    [ ] Kruskal
    [ ] Boruvka
  [ ] max flow / min cut
    [ ] EdmondsKarp
    [ ] FordFulkerson
    [ ] Dinic
  [ ] matching
    [ ] HopcroftKarp
  [ ] isomprphism
    [ ] VF2
    [ ] WeisfeilerLehman
  [ ] eulerian path
    [ ] Hierholzer
    [ ] backtracking based
  [ ] hamiltonian path
    [ ] heuristic based
    [ ] backtracking based
  [ ] coloring
    [ ] DSatur
    [ ] greedy
    [ ] WelshPowell
  [ ] strongly connected components
    [ ] Tarjan
    [ ] Kosaraju
  [ ] creating random graphs
    [ ] BarabasiAlbert
    [ ] ErdosRenyi
    [ ] WattsStrogatz
