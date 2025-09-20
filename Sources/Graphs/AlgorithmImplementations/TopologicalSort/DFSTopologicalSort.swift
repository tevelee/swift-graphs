import Collections

/// DFS-based algorithm for topological sorting.
/// 
/// This algorithm uses depth-first search and processes vertices in reverse finish time order.
/// If a back edge is detected during DFS, the graph contains a cycle.
struct DFSTopologicalSort<Graph: IncidenceGraph & VertexListGraph>: TopologicalSortAlgorithm where Graph.VertexDescriptor: Hashable {
    typealias Vertex = Graph.VertexDescriptor
    typealias Edge = Graph.EdgeDescriptor
    
    struct Visitor {
        var discoverVertex: ((Vertex) -> Void)?
        var examineEdge: ((Edge) -> Void)?
        var treeEdge: ((Edge) -> Void)?
        var backEdge: ((Edge) -> Void)?
        var forwardEdge: ((Edge) -> Void)?
        var crossEdge: ((Edge) -> Void)?
        var finishVertex: ((Vertex) -> Void)?
        var detectCycle: (([Vertex]) -> Void)?
    }
    
    private enum Color {
        case white // Undiscovered
        case gray  // Discovered but not fully processed
        case black // Fully processed
    }
    
    private enum ColorProperty: VertexProperty {
        static var defaultValue: Color { .white }
    }
    
    private let makeStack: () -> any StackProtocol<Vertex>
    
    init(makeStack: @escaping () -> any StackProtocol<Vertex> = { Array() }) {
        self.makeStack = makeStack
    }
    
    func topologicalSort(
        in graph: Graph,
        visitor: Visitor?
    ) -> TopologicalSortResult<Graph.VertexDescriptor> {
        var sortedVertices: [Vertex] = []
        var hasCycle = false
        var cycleVertices: [Vertex] = []
        var propertyMap: any MutablePropertyMap<Vertex, VertexPropertyValues> = graph.makeVertexPropertyMap()
        let colorProperty: any VertexProperty<Color>.Type = ColorProperty.self
        
        // Process all vertices to handle disconnected components
        for vertex in graph.vertices() {
            let color = propertyMap[vertex][colorProperty]
            if color == .white {
                let (cycle, cycleNodes) = dfsVisit(
                    from: vertex,
                    in: graph,
                    propertyMap: &propertyMap,
                    colorProperty: colorProperty,
                    sortedVertices: &sortedVertices,
                    visitor: visitor
                )
                if cycle {
                    hasCycle = true
                    cycleVertices.append(contentsOf: cycleNodes)
                }
            }
        }
        
        if hasCycle {
            visitor?.detectCycle?(cycleVertices)
        }
        
        return TopologicalSortResult(
            sortedVertices: sortedVertices,
            hasCycle: hasCycle,
            cycleVertices: cycleVertices
        )
    }
    
    private func dfsVisit(
        from vertex: Vertex,
        in graph: Graph,
        propertyMap: inout any MutablePropertyMap<Vertex, VertexPropertyValues>,
        colorProperty: any VertexProperty<Color>.Type,
        sortedVertices: inout [Vertex],
        visitor: Visitor?
    ) -> (hasCycle: Bool, cycleVertices: [Vertex]) {
        var hasCycle = false
        var cycleVertices: [Vertex] = []
        var stack = makeStack()
        
        stack.push(vertex)
        
        while !stack.isEmpty {
            guard let current = stack.pop() else { break }
            let color = propertyMap[current][colorProperty]
            
            switch color {
            case .white:
                // Mark as discovered
                propertyMap[current][colorProperty] = .gray
                visitor?.discoverVertex?(current)
                
                // Push back for processing after neighbors
                stack.push(current)
                
                // Process all outgoing edges
                for edge in graph.outgoingEdges(of: current) {
                    visitor?.examineEdge?(edge)
                    guard let destination = graph.destination(of: edge) else { continue }
                    
                    let destColor = propertyMap[destination][colorProperty]
                    switch destColor {
                    case .white:
                        visitor?.treeEdge?(edge)
                        stack.push(destination)
                    case .gray:
                        // Back edge detected - cycle found
                        visitor?.backEdge?(edge)
                        hasCycle = true
                        cycleVertices.append(destination)
                    case .black:
                        visitor?.forwardEdge?(edge)
                    }
                }
                
            case .gray:
                // Mark as finished and add to sorted list
                propertyMap[current][colorProperty] = .black
                visitor?.finishVertex?(current)
                sortedVertices.insert(current, at: 0) // Insert at beginning for reverse finish time
                
            case .black:
                // Already processed
                break
            }
        }
        
        return (hasCycle, cycleVertices)
    }
}

extension DFSTopologicalSort: VisitorSupporting {}
