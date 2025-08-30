// requirements
// - flexible graph representations with a small core API and make it extensible for various wide range of algorithms, representations
//   - adjacency list
//   - adjacency matrix
//   - compressed sparse row (CSR)
//   - support for a "lazy" graph so you don't have to predefine the whole structure but compute edges on demand (via closure?)
//   - support for grid graph (optimized traversals)
//   - support for undirected graphs (reversed/bidirectional edges)
// - inspired by boost graph library, graphs independent of concrete storage (vector/array) so algorithms have different characteristics
// - structure is independent from algorithms. They can be extensions
// - vertext/edge descriptors can help with performance optimizations so if nodes are heavy, they don't have to be stored in memory multiple times
// - strong reliance on strongly typed structures and algorithms via compile time generics, imposing constraints
//   - certain algorithms are only available on appropriate graphs (e.g. infix dfs only for binary graph, shortest path only for weighted graphs, dijkstra only for non-negative edges)
// - common operations represented as wrappers/views (e.g. transposing, filtering, complement graph, partitioning, subpath)
// - extensive test coverage
//   - ability to produce deterministic, repeatable results (e.g. if stoage is heap, lets inject sort)
// - since possibly algorithms will reuse each other, it would be nice to have a single generic Dijkstra implementation and multiple API surfaces reusing the same underlying one
// - extensions Graph for algotihms
//  - separate the definition and the implementation of each specific algo
//  - group by use-cases e.g. shortest path algotihms, traversals, minimum spanning tree and specify specific algo as parameter (with a good default)
//
// Example
//
// Callsite graph.shortestPath(from: "Root", to: "Z", using: .dijkstra()) // or .aStar() or .bellmanFord()
//
// extension GraphComponent where Edge: Weighted {
//     @inlinable public func shortestPath(
//         from source: Node,
//         until condition: (Node) -> Bool,
//         using algorithm: some ShortestPathUntilAlgorithm<Node, Edge>
//     ) -> Path<Node, Edge>? {
//         algorithm.shortestPath(from: source, until: condition, in: self)
//     }
// }
//
// public protocol ShortestPathUntilAlgorithm<Node, Edge> {
//     associatedtype Node
//     associatedtype Edge
//
//     @inlinable func shortestPath(
//         from source: Node,
//         until condition: (Node) -> Bool,
//         in graph: some GraphComponent<Node, Edge>
//     ) -> Path<Node, Edge>?
// }
//
// extension ShortestPathUntilAlgorithm {
//     @inlinable public static func dijkstra<Node, Edge>() -> Self where Self == DijkstraAlgorithm<Node, Edge> {
//         .init()
//     }
// }
//
// extension DijkstraAlgorithm: ShortestPathUntilAlgorithm {
//     @inlinable public func shortestPath(
//         from source: Node,
//         until condition: (Node) -> Bool,
//         in graph: some GraphComponent<Node, Edge>
//     ) -> Path<Node, Edge>? {
//         ...
//     }
// }
//
// extension ShortestPathAlgorithm where Self: ShortestPathUntilAlgorithm, Node: Equatable {
//     @inlinable public func shortestPath(
//         from source: Node,
//         to destination: Node,
//         in graph: some GraphComponent<Node, Edge>
//     ) -> Path<Node, Edge>? {
//         shortestPath(from: source, until: { $0 == destination }, in: graph)
//     }
// }
//
// Similarly, capabilities would be nice to look like this behind a unified API surface with extensible/plugin architecture
// Note: this is not the exact API surface I precisely want, the graph repsentations might require something different. I expect a lot of changes needed around traversal strategies
//
// graph.traverse(from: "Root", strategy: .bfs())
// graph.traverse(from: "Root", strategy: .dfs())
// graph.traverse(from: "Root", strategy: .bfs(.trackPath()))
// graph.traverse(from: "Root", strategy: .dfs(order: .postorder()))
// graph.traverse(from: "Root", strategy: .dfs().visitEachNodeOnce())
// binaryGraph.traverse(from: "Root", strategy: .dfs(order: .inorder()))
// graph.shortestPath(from: "Root", to: "Z", using: .dijkstra()) // or .aStar() or .bellmanFord()
// graph.shortestPaths(from: "Root", using: .dijkstra()) // or .bellmanFord()
// graph.shortestPathsForAllPairs(using: .floydWarshall()) // or .johnson()
// graph.minimumSpanningTree(using: .kruskal()) // or .prim() or .boruvka()
// graph.maximumFlow(using: .fordFulkerson()) // or .edmondsKarp() or .dinic()
// graph.stronglyConnectedComponents(using: .kosaraju()) // or .tarjan()
// graph.colorNodes(using: .greedy()) // or .dsatur() or .welshPowell()
// graph.isIsomorphoc(to: graph2, using: .vf2()) // or .weisfeilerLehman()
// ConnectedGraph.random(using: .erdosRenyi()) // or .barabasiAlbert() or .wattsStrogatz()
// bipartite.maximumMatching(using: .hopcroftKarp())
// graph.isCyclic()
// graph.isTree()
// graph.isConnected()
// graph.isPlanar()
// graph.isBipartite()
// graph.topologicalSort()
// gridGraph.shortestPath(from: GridPosition(x: 0, y: 0), to: GridPosition(x: 4, y: 4), using: .aStar(heuristic: .euclideanDistance(of: \.coordinates)))
// gridGraph.shortestPaths(from: GridPosition(x: 0, y: 0))
// gridGraph.shortestPathsForAllPairs()
// gridGraph.eulerianCycle()
// gridGraph.eulerianPath()
// gridGraph.hamiltonianCycle()
// gridGraph.hamiltonianPath()
// gridGraph.hamiltonianPath(from: GridPosition(x: 0, y: 0))
// gridGraph.hamiltonianPath(from: GridPosition(x: 0, y: 0), to: GridPosition(x: 4, y: 4))
//
// TODOs
// [ ] basic graph representations
//   [x] basic protocols for vertices, edges
//   [ ] multiple representations
//     [ ] adjacency list
//       [ ] variable storage, e.g. array/dictionary/vector
//     [ ] matrix
//   [ ] special graphs
//     [ ] binary (lhs/rhs edge)
//     [ ] grid
//     [ ] lazy
//     [ ] bipartite
// [ ] conditional conformances on equatable, hashable
// [ ] property maps like BGL to store weights, capacities etc for algos
// [ ] extensions on graph to support various algos
//   [ ] shortest paths from source until end condition
//     [ ] Dijkstra
//     [ ] A*
//       [ ] Injectable heuristic (e.g. distance like manhattan/hamiltonian
//   [ ] shortest paths from source to all vertices
//     [ ] Dijkstra
//     [ ] A*
//   [ ] shortest paths for all pairs
//     [ ] FloydWarshall
//     [ ] Johnson
//   [ ] shortest paths when EdgeListGraph
//     [ ] BellmannFord
//     [ ] Bidirectional Dijkstra
//   [ ] K shortest paths
//     [ ] Yen
//   [ ] traversals
//     [ ] ability to track predecessor path, depth etc. in visits
//     [ ] ability to skip already visited (acyclic)
//     [ ] limited depth support
//     [ ] BFS
//     [ ] DFS
//       [ ] prefix order
//       [ ] postfix order
//       [ ] represent binary graph edges with a dedicated type/marker and support infix order
//       [ ] iteratively deepening
//     [ ] Best-first search
//     [ ] Instead of a BGL like API, let's expose the traversal as an iterable Sequence. And search becomes just a filter on the sequence.
//   [ ] topological sort
//   [ ] computing graph properties
//     [ ] is cyclic
//     [ ] is connected
//     [ ] is tree
//     [ ] has eulerian path
//     [ ] has eulerian cycle
//     [ ] satisfied dirac / ore
//     [ ] is planar
//   [ ] minimum spanning tree
//     [ ] Prim
//     [ ] Kruskal
//     [ ] Boruvka
//   [ ] max flow / min cut
//     [ ] EdmondsKarp
//     [ ] FordFulkerson
//     [ ] Dinic
//   [ ] matching
//     [ ] HopcroftKarp
//   [ ] isomprphism
//     [ ] VF2
//     [ ] WeisfeilerLehman
//   [ ] eulerian path
//     [ ] Hierholzer
//     [ ] backtracking based
//   [ ] hamiltonian path
//     [ ] heuristic based
//     [ ] backtracking based
//   [ ] coloring
//     [ ] DSatur
//     [ ] greedy
//     [ ] WelshPowell
//   [ ] strongly connected components
//     [ ] Tarjan
//     [ ] Kosaraju
//   [ ] creating random graphs
//     [ ] BarabasiAlbert
//     [ ] ErdosRenyi
//     [ ] WattsStrogatz

#if canImport(Testing)
    import Graphs
    import Testing

    struct GraphTests {
        @Test func initial() {
            var graph = AdjacencyList()

            let root = graph.addVertex()
            let a = graph.addVertex()
            let b = graph.addVertex()
            let c = graph.addVertex()
            let d = graph.addVertex()
            let x = graph.addVertex()

            graph.addEdge(from: root, to: a)
            graph.addEdge(from: a, to: b)
            graph.addEdge(from: a, to: c)
            graph.addEdge(from: a, to: d)
            graph.addEdge(from: root, to: x)
            
            #expect(graph.vertices().count == 6)
            #expect(graph.edges().count == 5)
            #expect(graph.adjacentVertices(of: a) == [b, c, d, root])
            #expect(graph.outEdges(of: a).map(graph.destination) == [b, c, d])
            #expect(graph.inEdges(of: a).map(graph.source) == [root])
            #expect(graph.inEdges(of: root).isEmpty)
        }
    }
#endif

// Graph definitions/Graph.swift

protocol Graph {
    associatedtype VertexDescriptor
    associatedtype EdgeDescriptor
}

protocol IncidenceGraph: Graph {
    associatedtype OutEdges: Sequence<EdgeDescriptor>

    func outEdges(of vertex: VertexDescriptor) -> OutEdges
    func source(of edge: EdgeDescriptor) -> VertexDescriptor?
    func destination(of edge: EdgeDescriptor) -> VertexDescriptor?
    func outDegree(of vertex: VertexDescriptor) -> Int
}

extension IncidenceGraph {
    func reachableVertices(from vertex: VertexDescriptor) -> some Sequence<VertexDescriptor> {
        outEdges(of: vertex).compactMap(destination)
    }
}

protocol BidirectionalGraph: IncidenceGraph {
    associatedtype InEdges: Sequence<EdgeDescriptor>

    func inEdges(of vertex: VertexDescriptor) -> InEdges
    func inDegree(of vertex: VertexDescriptor) -> Int
    func degree(of vertex: VertexDescriptor) -> Int
}

extension BidirectionalGraph {
    func orignatingVertices(to vertex: VertexDescriptor) -> some Sequence<VertexDescriptor> {
        inEdges(of: vertex).compactMap(source)
    }

    func degree(of vertex: VertexDescriptor) -> Int {
        inDegree(of: vertex) + outDegree(of: vertex)
    }
}

protocol AdjacencyGraph: Graph {
    associatedtype AdjacentVertices: Sequence<VertexDescriptor>

    func adjacentVertices(of vertex: VertexDescriptor) -> AdjacentVertices
}

extension AdjacencyGraph where Self: BidirectionalGraph, VertexDescriptor: Hashable {
    func adjacentVertices(of vertex: VertexDescriptor) -> OrderedSet<VertexDescriptor> {
        var result: OrderedSet<VertexDescriptor> = []
        result.append(contentsOf: outEdges(of: vertex).compactMap(destination))
        result.append(contentsOf: inEdges(of: vertex).compactMap(source))
        return result
    }
}

protocol VertexListGraph: Graph {
    associatedtype Vertices: Sequence<VertexDescriptor>

    func vertices() -> Vertices
    func numberOfVertices() -> Int
}

protocol EdgeListGraph: Graph {
    associatedtype Edges: Sequence<EdgeDescriptor>

    func edges() -> Edges
    func numberOfEdges() -> Int
}

protocol AdjacencyMatrix: Graph {
    func edge(from source: VertexDescriptor, to destination: VertexDescriptor) -> EdgeDescriptor?
}

protocol MutableGraph: Graph {
    @discardableResult
    mutating func addEdge(from source: VertexDescriptor, to destination: VertexDescriptor) -> EdgeDescriptor
    mutating func remove(edge: consuming EdgeDescriptor)

    mutating func addVertex() -> VertexDescriptor
    mutating func remove(vertex: consuming VertexDescriptor)
}

protocol BinaryIncidenceGraph: Graph {
    func leftEdge(of v: VertexDescriptor) -> EdgeDescriptor?
    func rightEdge(of v: VertexDescriptor) -> EdgeDescriptor?

    func leftChild(of v: VertexDescriptor) -> VertexDescriptor?
    func rightChild(of v: VertexDescriptor) -> VertexDescriptor?
}

struct Empty: Sendable, Hashable, Codable {
    init() {}
}

// Concrete Graph Implementations/AdjacencyList.swift

import Foundation
import Collections

struct AdjacencyList {
    private var _vertices: OrderedSet<VertexDescriptor> = []

    private var _edges: OrderedSet<EdgeDescriptor> = []
    private var _outEdges: [VertexDescriptor: OrderedSet<EdgeDescriptor>] = [:]
    private var _inEdges: [VertexDescriptor: OrderedSet<EdgeDescriptor>] = [:]

    private var _verticesOfEdges: [EdgeDescriptor: (source: VertexDescriptor, destination: VertexDescriptor)] = [:]
}

extension AdjacencyList: Graph {
    struct VertexDescriptor: Identifiable, Hashable {
        private let _id: UUID

        var id: some Hashable { _id }

        fileprivate init() {
            _id = UUID()
        }
    }

    struct EdgeDescriptor: Identifiable, Hashable {
        private let _id: UUID

        var id: some Hashable { _id }

        fileprivate init() {
            _id = UUID()
        }
    }
}

extension AdjacencyList: IncidenceGraph {
    func outEdges(of vertex: VertexDescriptor) -> OrderedSet<EdgeDescriptor> {
        guard _vertices.contains(vertex), let edges = _outEdges[vertex] else { return [] }
        return edges
    }

    func source(of edge: EdgeDescriptor) -> VertexDescriptor? {
        guard _edges.contains(edge), let edge = _verticesOfEdges[edge] else { return nil }
        return edge.source
    }
    
    func destination(of edge: EdgeDescriptor) -> VertexDescriptor? {
        guard _edges.contains(edge), let edge = _verticesOfEdges[edge] else { return nil }
        return edge.destination
    }
    
    func outDegree(of vertex: VertexDescriptor) -> Int {
        guard _vertices.contains(vertex), let edges = _outEdges[vertex] else { return 0 }
        return edges.count
    }
}

extension AdjacencyList: BidirectionalGraph {
    func inEdges(of vertex: VertexDescriptor) -> OrderedSet<EdgeDescriptor> {
        guard _vertices.contains(vertex), let edges = _inEdges[vertex] else { return [] }
        return edges
    }

    func inDegree(of vertex: VertexDescriptor) -> Int {
        guard _vertices.contains(vertex), let edges = _inEdges[vertex] else { return 0 }
        return edges.count
    }
}

extension AdjacencyList: VertexListGraph {
    func vertices() -> OrderedSet<VertexDescriptor> {
        _vertices
    }

    func numberOfVertices() -> Int {
        _vertices.count
    }
}

extension AdjacencyList: EdgeListGraph {
    func edges() -> OrderedSet<EdgeDescriptor> {
        _edges
    }

    func numberOfEdges() -> Int {
        _edges.count
    }
}

extension AdjacencyList: AdjacencyGraph {}

extension AdjacencyList: MutableGraph {
    @discardableResult
    mutating func addEdge(from source: VertexDescriptor, to destination: VertexDescriptor) -> EdgeDescriptor {
        let edge = EdgeDescriptor()
        addVertex(source)
        addVertex(destination)
        _edges.updateOrAppend(edge)
        _verticesOfEdges[edge] = (source, destination)
        _outEdges[source, default: []].updateOrAppend(edge)
        _inEdges[destination, default: []].updateOrAppend(edge)
        return edge
    }

    mutating func remove(edge: consuming EdgeDescriptor) {
        if let vertex = source(of: edge) {
            _outEdges[vertex]?.remove(edge)
        }
        if let vertex = destination(of: edge) {
            _inEdges[vertex]?.remove(edge)
        }
        _edges.remove(edge)
        _verticesOfEdges[edge] = nil
    }

    mutating func addVertex() -> VertexDescriptor {
        let vertex = VertexDescriptor()
        addVertex(vertex)
        return vertex
    }

    mutating func remove(vertex: consuming VertexDescriptor) {
        for edge in outEdges(of: vertex) {
            remove(edge: edge)
        }
        for edge in inEdges(of: vertex) {
            remove(edge: edge)
        }
        _vertices.remove(vertex)
    }

    private mutating func addVertex(_ vertex: VertexDescriptor) {
        _vertices.updateOrAppend(vertex)
    }
}
