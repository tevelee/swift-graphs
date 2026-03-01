#if !GRAPHS_USES_TRAITS || GRAPHS_OPTIMIZATION
/// Prim's algorithm for finding minimum spanning trees.
///
/// This algorithm finds the MST by starting from a vertex and greedily adding
/// the minimum weight edge that connects a vertex in the MST to a vertex not in the MST.
///
/// - Complexity: O(E log V) where E is the number of edges and V is the number of vertices
public struct Prim<
    Graph: IncidenceGraph & VertexListGraph,
    Weight: AdditiveArithmetic & Comparable
> where
    Graph.VertexDescriptor: Hashable,
    Graph.EdgeDescriptor: Equatable
{
    /// The vertex type of the graph.
    public typealias Vertex = Graph.VertexDescriptor
    /// The edge type of the graph.
    public typealias Edge = Graph.EdgeDescriptor
    
    /// A visitor that can be used to observe Prim's algorithm progress.
    public struct Visitor {
        /// Called when examining a vertex.
        public var examineVertex: ((Vertex) -> Void)?
        /// Called when examining an edge.
        public var examineEdge: ((Edge) -> Void)?
        /// Called when adding an edge to the MST.
        public var addEdge: ((Edge, Weight) -> Void)?
        /// Called when skipping an edge.
        public var skipEdge: ((Edge, String) -> Void)?
        
        /// Creates a new visitor.
        @inlinable
        public init(
            examineVertex: ((Vertex) -> Void)? = nil,
            examineEdge: ((Edge) -> Void)? = nil,
            addEdge: ((Edge, Weight) -> Void)? = nil,
            skipEdge: ((Edge, String) -> Void)? = nil
        ) {
            self.examineVertex = examineVertex
            self.examineEdge = examineEdge
            self.addEdge = addEdge
            self.skipEdge = skipEdge
        }
    }
    
    /// The result of Prim's algorithm.
    @usableFromInline
    struct Result {
        @usableFromInline
        let edges: [Edge]
        @usableFromInline
        let totalWeight: Weight
        @usableFromInline
        let vertices: Set<Vertex>
        
        @usableFromInline
        init(edges: [Edge], totalWeight: Weight, vertices: Set<Vertex>) {
            self.edges = edges
            self.totalWeight = totalWeight
            self.vertices = vertices
        }
    }
    
    /// A priority queue item for Prim's algorithm.
    @usableFromInline
    struct PriorityItem {
        @usableFromInline
        let weight: Weight
        @usableFromInline
        let edge: Edge
        @usableFromInline
        let source: Vertex
        @usableFromInline
        let destination: Vertex
        
        @usableFromInline
        init(weight: Weight, edge: Edge, source: Vertex, destination: Vertex) {
            self.weight = weight
            self.edge = edge
            self.source = source
            self.destination = destination
        }
    }
    
    /// The edge weight definition.
    @usableFromInline
    let edgeWeight: CostDefinition<Graph, Weight>
    /// The starting vertex for the algorithm.
    @usableFromInline
    let startVertex: Vertex?
    
    /// Creates a new Prim's algorithm.
    ///
    /// - Parameters:
    ///   - edgeWeight: The cost definition for edge weights
    ///   - startVertex: The starting vertex (optional, will use first vertex if nil)
    @inlinable
    public init(
        edgeWeight: CostDefinition<Graph, Weight>,
        startVertex: Vertex? = nil
    ) {
        self.edgeWeight = edgeWeight
        self.startVertex = startVertex
    }
    
    /// Computes the minimum spanning tree using Prim's algorithm.
    ///
    /// - Parameters:
    ///   - graph: The graph to find the MST for
    ///   - visitor: An optional visitor to observe the algorithm progress
    /// - Returns: The minimum spanning tree result
    @inlinable
    public func minimumSpanningTree(on graph: Graph, visitor: Visitor? = nil) -> MinimumSpanningTree<Vertex, Edge, Weight> {
        var priorityQueue = PriorityQueue<PriorityItem>()
        var inMST: Set<Vertex> = []
        var mstEdges: [Edge] = []
        var totalWeight = Weight.zero
        
        guard let startVertex = startVertex ?? Array(graph.vertices()).first else {
            // Return empty result for empty graph
            return MinimumSpanningTree(edges: [], totalWeight: Weight.zero, vertices: [])
        }
        inMST.insert(startVertex)
        visitor?.examineVertex?(startVertex)
        
        for edge in graph.outgoingEdges(of: startVertex) {
            if let destination = graph.destination(of: edge) {
                visitor?.examineEdge?(edge)
                let currentEdgeWeight = edgeWeight.costToExplore(edge, graph)
                priorityQueue.enqueue(PriorityItem(
                    weight: currentEdgeWeight,
                    edge: edge,
                    source: startVertex,
                    destination: destination
                ))
            }
        }
        
        while !priorityQueue.isEmpty && inMST.count < graph.vertexCount {
            guard let currentItem = priorityQueue.dequeue() else { break }
            
            visitor?.examineEdge?(currentItem.edge)
            
            if inMST.contains(currentItem.destination) {
                visitor?.skipEdge?(currentItem.edge, "Destination already in MST")
                continue
            }
            
            // Early termination: if we have n-1 edges, we can stop
            if mstEdges.count == graph.vertexCount - 1 {
                break
            }
            
            mstEdges.append(currentItem.edge)
            totalWeight = totalWeight + currentItem.weight
            inMST.insert(currentItem.destination)
            visitor?.addEdge?(currentItem.edge, currentItem.weight)
            visitor?.examineVertex?(currentItem.destination)
            
            for newEdge in graph.outgoingEdges(of: currentItem.destination) {
                if let newDestination = graph.destination(of: newEdge),
                   !inMST.contains(newDestination) {
                    visitor?.examineEdge?(newEdge)
                    let newEdgeWeight = edgeWeight.costToExplore(newEdge, graph)
                    priorityQueue.enqueue(PriorityItem(
                        weight: newEdgeWeight,
                        edge: newEdge,
                        source: currentItem.destination,
                        destination: newDestination
                    ))
                }
            }
        }
        
        for vertex in graph.vertices() {
            inMST.insert(vertex)
        }
        
        return MinimumSpanningTree(
            edges: mstEdges,
            totalWeight: totalWeight,
            vertices: inMST
        )
    }
}

extension Prim: VisitorSupporting {}

extension Prim.PriorityItem: Comparable {
    @usableFromInline
    static func < (lhs: Self, rhs: Self) -> Bool {
        lhs.weight < rhs.weight
    }
    
    @usableFromInline
    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.weight == rhs.weight && lhs.edge == rhs.edge
    }
}
#endif
