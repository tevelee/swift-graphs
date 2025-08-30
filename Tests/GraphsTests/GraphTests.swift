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
// graph.isIsomorphic(to: graph2, using: .vf2()) // or .weisfeilerLehman()
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
    func successors(of vertex: VertexDescriptor) -> some Sequence<VertexDescriptor> {
        outEdges(of: vertex).lazy.compactMap(destination)
    }
}

protocol BidirectionalGraph: IncidenceGraph {
    associatedtype InEdges: Sequence<EdgeDescriptor>

    func inEdges(of vertex: VertexDescriptor) -> InEdges
    func inDegree(of vertex: VertexDescriptor) -> Int
    func degree(of vertex: VertexDescriptor) -> Int
}

extension BidirectionalGraph {
    func predecessors(of vertex: VertexDescriptor) -> some Sequence<VertexDescriptor> {
        inEdges(of: vertex).lazy.compactMap(source)
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
    var numberOfVertices: Int { get }
}

protocol EdgeListGraph: Graph {
    associatedtype Edges: Sequence<EdgeDescriptor>

    func edges() -> Edges
    var numberOfEdges: Int { get }
}

protocol AdjacencyMatrix: Graph {
    func edge(from source: VertexDescriptor, to destination: VertexDescriptor) -> EdgeDescriptor?
}

protocol MutableGraph: Graph {
    @discardableResult
    mutating func addEdge(from source: VertexDescriptor, to destination: VertexDescriptor) -> EdgeDescriptor?
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

protocol VertexStorage {
    associatedtype Vertex: Hashable
    associatedtype Vertices: Sequence<Vertex>

    mutating func addVertex() -> Vertex
    mutating func remove(vertex: Vertex)
    func contains(_ vertex: Vertex) -> Bool
    func vertices() -> Vertices
    var numberOfVertices: Int { get }
}

protocol EdgeStorage {
    associatedtype Vertex: Hashable
    associatedtype Edge: Hashable
    associatedtype Edges: Sequence<Edge>

    mutating func addEdge(from source: Vertex, to destination: Vertex) -> Edge
    mutating func remove(edge: Edge)
    func endpoints(of edge: Edge) -> (source: Vertex, destination: Vertex)?
    func edges() -> Edges
    var numberOfEdges: Int { get }

    // Incidence operations
    func outEdges(of vertex: Vertex) -> Edges
    func outDegree(of vertex: Vertex) -> Int
    func inEdges(of vertex: Vertex) -> Edges
    func inDegree(of vertex: Vertex) -> Int
}

extension EdgeStorage {
    static func ordered<Vertex>() -> OrderedEdgeStorage<Vertex> where Self == OrderedEdgeStorage<Vertex> {
        OrderedEdgeStorage()
    }
}

extension VertexStorage {
    static func ordered() -> OrderedVertexStorage where Self == OrderedVertexStorage {
        OrderedVertexStorage()
    }
}

struct OrderedVertexStorage: VertexStorage {
    struct Vertex: Identifiable, Hashable {
        private let _id: UUID

        var id: some Hashable { _id }

        fileprivate init() {
            _id = UUID()
        }
    }

    private var _vertices: OrderedSet<Vertex> = []

    var numberOfVertices: Int {
        _vertices.count
    }

    func vertices() -> OrderedSet<Vertex> {
        _vertices
    }

    func contains(_ vertex: Vertex) -> Bool {
        _vertices.contains(vertex)
    }

    mutating func addVertex() -> Vertex {
        let vertex = Vertex()
        _vertices.updateOrAppend(vertex)
        return vertex
    }

    mutating func remove(vertex: Vertex) {
        _vertices.remove(vertex)
    }
}

struct OrderedEdgeStorage<Vertex: Hashable>: EdgeStorage {
    struct Edge: Identifiable, Hashable {
        private let _id: UUID

        var id: some Hashable { _id }

        fileprivate init() {
            _id = UUID()
        }
    }

    private var _edges: OrderedDictionary<Edge, (source: Vertex, destination: Vertex)> = [:]

    var numberOfEdges: Int {
        _edges.count
    }

    func edges() -> OrderedSet<Edge> {
        _edges.keys
    }

    func endpoints(of edge: Edge) -> (source: Vertex, destination: Vertex)? {
        _edges[edge]
    }

    func outEdges(of vertex: Vertex) -> OrderedSet<Edge> {
        _edges.filter { $0.value.source == vertex }.keys
    }

    func outDegree(of vertex: Vertex) -> Int {
        outEdges(of: vertex).count
    }

    func inEdges(of vertex: Vertex) -> OrderedSet<Edge> {
        _edges.filter { $0.value.destination == vertex }.keys
    }

    func inDegree(of vertex: Vertex) -> Int {
        inEdges(of: vertex).count
    }

    mutating func addEdge(from source: Vertex, to destination: Vertex) -> Edge {
        let edge = Edge()
        _edges[edge] = (source, destination)
        return edge
    }
    
    mutating func remove(edge: Edge) {
        _edges[edge] = nil
    }
}

extension EdgeStorage where Edges == OrderedSet<Edge> {
    func cacheInOutEdges() -> CacheInOutEdges<Self> {
        CacheInOutEdges(base: self)
    }
}

struct CacheInOutEdges<Base: EdgeStorage>: EdgeStorage where Base.Edges == OrderedSet<Base.Edge> {
    typealias Vertex = Base.Vertex
    typealias Edge = Base.Edge

    var base: Base

    init(base: Base) {
        self.base = base
    }

    private var _outEdges: OrderedDictionary<Vertex, OrderedSet<Edge>> = [:]
    private var _inEdges: OrderedDictionary<Vertex, OrderedSet<Edge>> = [:]

    func outEdges(of vertex: Vertex) -> OrderedSet<Edge> {
        _outEdges[vertex] ?? []
    }

    func outDegree(of vertex: Vertex) -> Int {
        outEdges(of: vertex).count
    }

    func inEdges(of vertex: Vertex) -> OrderedSet<Edge> {
        _inEdges[vertex] ?? []
    }

    func inDegree(of vertex: Vertex) -> Int {
        inEdges(of: vertex).count
    }

    mutating func addEdge(from source: Vertex, to destination: Vertex) -> Edge {
        let edge = base.addEdge(from: source, to: destination)
        _outEdges[source, default: []].updateOrAppend(edge)
        _inEdges[destination, default: []].updateOrAppend(edge)
        return edge
    }

    mutating func remove(edge: Edge) {
        if let (source, destination) = endpoints(of: edge) {
            _outEdges[source]?.remove(edge)
            _inEdges[destination]?.remove(edge)
        }
        base.remove(edge: edge)
    }

    func endpoints(of edge: Edge) -> (source: Vertex, destination: Vertex)? {
        base.endpoints(of: edge)
    }

    func edges() -> Base.Edges {
        base.edges()
    }

    var numberOfEdges: Int {
        base.numberOfEdges
    }
}

struct AdjacencyList<VertexStore: VertexStorage, EdgeStore: EdgeStorage> where EdgeStore.Vertex == VertexStore.Vertex {
    private var vertexStorage: VertexStore
    private var edgeStorage: EdgeStore

    init(
        vertexStorage: VertexStore = OrderedVertexStorage(),
        edgeStorage: EdgeStore = OrderedEdgeStorage<OrderedVertexStorage.Vertex>().cacheInOutEdges()
    ) {
        self.vertexStorage = vertexStorage
        self.edgeStorage = edgeStorage
    }
}

extension AdjacencyList: Graph {
    typealias VertexDescriptor = VertexStore.Vertex
    typealias EdgeDescriptor = EdgeStore.Edge
}

extension AdjacencyList: IncidenceGraph {
    func outEdges(of vertex: VertexDescriptor) -> EdgeStore.Edges {
        edgeStorage.outEdges(of: vertex)
    }

    func source(of edge: EdgeDescriptor) -> VertexDescriptor? {
        edgeStorage.endpoints(of: edge)?.source
    }
    
    func destination(of edge: EdgeDescriptor) -> VertexDescriptor? {
        edgeStorage.endpoints(of: edge)?.destination
    }
    
    func outDegree(of vertex: VertexDescriptor) -> Int {
        edgeStorage.outDegree(of: vertex)
    }
}

extension AdjacencyList: BidirectionalGraph {
    func inEdges(of vertex: VertexDescriptor) -> EdgeStore.Edges {
        edgeStorage.inEdges(of: vertex)
    }

    func inDegree(of vertex: VertexDescriptor) -> Int {
        edgeStorage.inDegree(of: vertex)
    }
}

extension AdjacencyList: VertexListGraph {
    func vertices() -> VertexStore.Vertices {
        vertexStorage.vertices()
    }

    var numberOfVertices: Int {
        vertexStorage.numberOfVertices
    }
}

extension AdjacencyList: EdgeListGraph {
    func edges() -> EdgeStore.Edges {
        edgeStorage.edges()
    }

    var numberOfEdges: Int {
        edgeStorage.numberOfEdges
    }
}

extension AdjacencyList: AdjacencyGraph {}

extension AdjacencyList: MutableGraph {
    @discardableResult
    mutating func addEdge(from source: VertexDescriptor, to destination: VertexDescriptor) -> EdgeDescriptor? {
        guard vertexStorage.contains(source), vertexStorage.contains(destination) else { return nil }
        return edgeStorage.addEdge(from: source, to: destination)
    }

    mutating func remove(edge: consuming EdgeDescriptor) {
        edgeStorage.remove(edge: edge)
    }

    mutating func addVertex() -> VertexDescriptor {
        vertexStorage.addVertex()
    }

    mutating func remove(vertex: consuming VertexDescriptor) {
        for edge in outEdges(of: vertex) {
            remove(edge: edge)
        }
        for edge in inEdges(of: vertex) {
            remove(edge: edge)
        }
        vertexStorage.remove(vertex: vertex)
    }
}
