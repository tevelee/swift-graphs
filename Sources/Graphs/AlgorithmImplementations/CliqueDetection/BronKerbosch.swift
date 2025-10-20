import Collections

/// Bron-Kerbosch algorithm for finding all maximal cliques.
///
/// This algorithm finds all maximal cliques using the Bron-Kerbosch algorithm
/// with pivoting for improved performance.
///
/// - Complexity: O(3^(n/3)) in worst case, but typically much faster in practice
public struct BronKerboschCliqueDetection<Graph: IncidenceGraph & VertexListGraph> 
    where Graph.VertexDescriptor: Hashable 
{
    /// The vertex type of the graph.
    public typealias Vertex = Graph.VertexDescriptor
    /// The edge type of the graph.
    public typealias Edge = Graph.EdgeDescriptor

    /// A visitor that can be used to observe the Bron-Kerbosch algorithm progress.
    public struct Visitor {
        /// Called when exploring a clique candidate.
        public var exploreClique: (([Vertex]) -> Void)?
        /// Called when a maximal clique is found.
        public var foundClique: (([Vertex]) -> Void)?
        /// Called when choosing a pivot vertex.
        public var choosePivot: ((Vertex) -> Void)?
        /// Called when backtracking.
        public var backtrack: (([Vertex]) -> Void)?
        
        /// Creates a new visitor.
        @inlinable
        public init(
            exploreClique: (([Vertex]) -> Void)? = nil,
            foundClique: (([Vertex]) -> Void)? = nil,
            choosePivot: ((Vertex) -> Void)? = nil,
            backtrack: (([Vertex]) -> Void)? = nil
        ) {
            self.exploreClique = exploreClique
            self.foundClique = foundClique
            self.choosePivot = choosePivot
            self.backtrack = backtrack
        }
    }

    /// The graph to find cliques in.
    @usableFromInline
    let graph: Graph

    /// Creates a new Bron-Kerbosch clique detection algorithm.
    ///
    /// - Parameter graph: The graph to find cliques in
    @inlinable
    public init(on graph: Graph) {
        self.graph = graph
    }

    /// Finds all maximal cliques using Bron-Kerbosch with pivoting.
    ///
    /// - Parameter visitor: An optional visitor to observe the algorithm progress
    /// - Returns: The clique detection result
    @inlinable
    public func findCliques(visitor: Visitor?) -> CliqueDetectionResult<Vertex> {
        var cliques: [[Vertex]] = []
        
        // Build adjacency map for quick neighbor lookup
        var neighbors: [Vertex: Set<Vertex>] = [:]
        for vertex in graph.vertices() {
            neighbors[vertex] = Set(graph.successors(of: vertex))
        }
        
        let allVertices = Set(graph.vertices())
        
        bronKerboschWithPivot(
            r: [],
            p: allVertices,
            x: [],
            neighbors: neighbors,
            cliques: &cliques,
            visitor: visitor
        )
        
        return CliqueDetectionResult(cliques: cliques)
    }
    
    @usableFromInline
    func bronKerboschWithPivot(
        r: Set<Vertex>,
        p: Set<Vertex>,
        x: Set<Vertex>,
        neighbors: [Vertex: Set<Vertex>],
        cliques: inout [[Vertex]],
        visitor: Visitor?
    ) {
        if p.isEmpty && x.isEmpty {
            // Found a maximal clique (but only if it's not empty)
            if !r.isEmpty {
                let clique = Array(r)
                visitor?.foundClique?(clique)
                cliques.append(clique)
            }
            return
        }
        
        visitor?.exploreClique?(Array(r))
        
        // Choose pivot from P ∪ X with maximum neighbors in P
        let pivot = choosePivot(from: p.union(x), in: p, neighbors: neighbors)
        visitor?.choosePivot?(pivot)
        
        let pivotNeighbors = neighbors[pivot] ?? []
        let candidates = p.subtracting(pivotNeighbors)
        
        var currentP = p
        var currentX = x
        
        for vertex in candidates {
            let vertexNeighbors = neighbors[vertex] ?? []
            
            bronKerboschWithPivot(
                r: r.union([vertex]),
                p: currentP.intersection(vertexNeighbors),
                x: currentX.intersection(vertexNeighbors),
                neighbors: neighbors,
                cliques: &cliques,
                visitor: visitor
            )
            
            currentP.remove(vertex)
            currentX.insert(vertex)
            visitor?.backtrack?(Array(r))
        }
    }
    
    @usableFromInline
    func choosePivot(
        from candidates: Set<Vertex>,
        in p: Set<Vertex>,
        neighbors: [Vertex: Set<Vertex>]
    ) -> Vertex {
        // Choose vertex with maximum degree in P
        candidates.max { v1, v2 in
            let count1 = (neighbors[v1] ?? []).intersection(p).count
            let count2 = (neighbors[v2] ?? []).intersection(p).count
            return count1 < count2
        } ?? candidates.first!
    }
}

extension BronKerboschCliqueDetection: CliqueDetectionAlgorithm {
    @inlinable
    public func findCliques(
        in graph: Graph,
        visitor: Visitor?
    ) -> CliqueDetectionResult<Graph.VertexDescriptor> {
        findCliques(visitor: visitor)
    }
}

extension BronKerboschCliqueDetection: VisitorSupporting {}
