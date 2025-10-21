/// Weisfeiler-Lehman algorithm for graph isomorphism.
/// This algorithm uses iterative vertex labeling based on neighborhood structure
/// to determine if two graphs are isomorphic. It's a fast heuristic that works
/// well for many graph types but is not complete (may give false negatives).
///
/// - Complexity: O(V * E * I) where V is the number of vertices, E is the number of edges, and I is the number of iterations
public struct WeisfeilerLehmanIsomorphism<Graph: IncidenceGraph & VertexListGraph & EdgeListGraph> where Graph.VertexDescriptor: Hashable {
    /// The vertex type of the graph.
    public typealias Vertex = Graph.VertexDescriptor
    /// The edge type of the graph.
    public typealias Edge = Graph.EdgeDescriptor
    
    /// A visitor that can be used to observe the Weisfeiler-Lehman algorithm progress.
    public struct Visitor {
        /// Called when examining a vertex.
        public var examineVertex: ((Vertex) -> Void)?
        /// Called when examining an edge.
        public var examineEdge: ((Edge) -> Void)?
        /// Called when labeling a vertex.
        public var labelVertex: ((Vertex, Int) -> Void)?
        /// Called when an iteration is complete.
        public var iterationComplete: ((Int, [Vertex: Int]) -> Void)?
        /// Called when labels have stabilized.
        public var labelsStabilized: (([Vertex: Int]) -> Void)?
        
        /// Creates a new visitor.
        @inlinable
        public init(
            examineVertex: ((Vertex) -> Void)? = nil,
            examineEdge: ((Edge) -> Void)? = nil,
            labelVertex: ((Vertex, Int) -> Void)? = nil,
            iterationComplete: ((Int, [Vertex: Int]) -> Void)? = nil,
            labelsStabilized: (([Vertex: Int]) -> Void)? = nil
        ) {
            self.examineVertex = examineVertex
            self.examineEdge = examineEdge
            self.labelVertex = labelVertex
            self.iterationComplete = iterationComplete
            self.labelsStabilized = labelsStabilized
        }
    }
    
    @usableFromInline
    let maxIterations: Int
    
    @inlinable
    public init(maxIterations: Int = 10) {
        self.maxIterations = maxIterations
    }
    
    @inlinable
    public func areIsomorphic(_ graph1: Graph, _ graph2: Graph, visitor: Visitor? = nil) -> Bool {
        return findIsomorphism(graph1, graph2, visitor: visitor) != nil
    }
    
    @inlinable
    public func findIsomorphism(_ graph1: Graph, _ graph2: Graph, visitor: Visitor? = nil) -> [Vertex: Vertex]? {
        // Quick checks for basic isomorphism requirements
        guard graph1.vertexCount == graph2.vertexCount else { return nil }
        guard graph1.edgeCount == graph2.edgeCount else { return nil }
        
        // Run Weisfeiler-Lehman test
        let labels1 = computeWLLabels(graph: graph1, visitor: visitor)
        let labels2 = computeWLLabels(graph: graph2, visitor: visitor)
        
        // Check if the label multisets are equal
        guard areLabelMultisetsEqual(labels1, labels2) else { return nil }
        
        // If WL test passes, try to find a mapping using VF2 as a fallback
        // This is because WL is not complete and may give false positives
        let vf2 = VF2Isomorphism<Graph>()
        return vf2.findIsomorphism(graph1, graph2)
    }
    
    @usableFromInline
    func computeWLLabels(graph: Graph, visitor: Visitor?) -> [Vertex: Int] {
        var labels: [Vertex: Int] = [:]
        
        // Initialize with degree-based labels
        for vertex in graph.vertices() {
            let degree = graph.outDegree(of: vertex)
            labels[vertex] = degree
            visitor?.labelVertex?(vertex, degree)
        }
        
        // Iteratively refine labels
        for iteration in 0..<maxIterations {
            var newLabels: [Vertex: Int] = [:]
            var labelMap: [String: Int] = [:]
            var nextNewLabel = 0
            
            for vertex in graph.vertices() {
                visitor?.examineVertex?(vertex)
                
                // Create a signature based on current label and neighbor labels
                let currentLabel = labels[vertex]!
                var neighborLabels: [Int] = []
                
                for edge in graph.outgoingEdges(of: vertex) {
                    visitor?.examineEdge?(edge)
                    guard let neighbor = graph.destination(of: edge) else { continue }
                    neighborLabels.append(labels[neighbor]!)
                }
                
                // Sort neighbor labels for consistency
                neighborLabels.sort()
                
                // Create a string signature
                let signature = "\(currentLabel):\(neighborLabels.map(String.init).joined(separator: ","))"
                
                // Assign a new label based on the signature
                if let existingLabel = labelMap[signature] {
                    newLabels[vertex] = existingLabel
                } else {
                    let newLabel = nextNewLabel
                    labelMap[signature] = newLabel
                    newLabels[vertex] = newLabel
                    nextNewLabel += 1
                }
                
                visitor?.labelVertex?(vertex, newLabels[vertex]!)
            }
            
            visitor?.iterationComplete?(iteration + 1, newLabels)
            
            // Check if labels have stabilized
            if labels == newLabels {
                visitor?.labelsStabilized?(newLabels)
                break
            }
            
            labels = newLabels
        }
        
        return labels
    }
    
    @usableFromInline
    func areLabelMultisetsEqual(_ labels1: [Vertex: Int], _ labels2: [Vertex: Int]) -> Bool {
        // Count occurrences of each label in both graphs
        var count1: [Int: Int] = [:]
        var count2: [Int: Int] = [:]
        
        for label in labels1.values {
            count1[label, default: 0] += 1
        }
        
        for label in labels2.values {
            count2[label, default: 0] += 1
        }
        
        // Check if the multisets are equal
        return count1 == count2
    }
}

// MARK: - Enhanced Weisfeiler-Lehman with Edge Labels

/// Enhanced Weisfeiler-Lehman algorithm that considers edge labels/weights
public struct EnhancedWeisfeilerLehmanIsomorphism<Graph: IncidenceGraph & VertexListGraph & EdgeListGraph> where Graph.VertexDescriptor: Hashable {
    public typealias Vertex = Graph.VertexDescriptor
    public typealias Edge = Graph.EdgeDescriptor
    
    /// A visitor that can be used to observe the enhanced Weisfeiler-Lehman algorithm progress.
    public struct Visitor {
        /// Called when examining a vertex.
        public var examineVertex: ((Vertex) -> Void)?
        /// Called when examining an edge.
        public var examineEdge: ((Edge) -> Void)?
        /// Called when labeling a vertex.
        public var labelVertex: ((Vertex, Int) -> Void)?
        /// Called when an iteration is complete.
        public var iterationComplete: ((Int, [Vertex: Int]) -> Void)?
        /// Called when labels have stabilized.
        public var labelsStabilized: (([Vertex: Int]) -> Void)?
        
        /// Creates a new visitor.
        @inlinable
        public init(
            examineVertex: ((Vertex) -> Void)? = nil,
            examineEdge: ((Edge) -> Void)? = nil,
            labelVertex: ((Vertex, Int) -> Void)? = nil,
            iterationComplete: ((Int, [Vertex: Int]) -> Void)? = nil,
            labelsStabilized: (([Vertex: Int]) -> Void)? = nil
        ) {
            self.examineVertex = examineVertex
            self.examineEdge = examineEdge
            self.labelVertex = labelVertex
            self.iterationComplete = iterationComplete
            self.labelsStabilized = labelsStabilized
        }
    }
    
    @usableFromInline
    let maxIterations: Int
    
    @inlinable
    public init(maxIterations: Int = 10) {
        self.maxIterations = maxIterations
    }
    
    @inlinable
    public func areIsomorphic(_ graph1: Graph, _ graph2: Graph, visitor: Visitor? = nil) -> Bool {
        return findIsomorphism(graph1, graph2, visitor: visitor) != nil
    }
    
    @inlinable
    public func findIsomorphism(_ graph1: Graph, _ graph2: Graph, visitor: Visitor? = nil) -> [Vertex: Vertex]? {
        // Quick checks for basic isomorphism requirements
        guard graph1.vertexCount == graph2.vertexCount else { return nil }
        guard graph1.edgeCount == graph2.edgeCount else { return nil }
        
        // Run enhanced Weisfeiler-Lehman test
        let labels1 = computeEnhancedWLLabels(graph: graph1, visitor: visitor)
        let labels2 = computeEnhancedWLLabels(graph: graph2, visitor: visitor)
        
        // Check if the label multisets are equal
        guard areLabelMultisetsEqual(labels1, labels2) else { return nil }
        
        // If WL test passes, try to find a mapping using VF2 as a fallback
        let vf2 = VF2Isomorphism<Graph>()
        return vf2.findIsomorphism(graph1, graph2)
    }
    
    @usableFromInline
    func computeEnhancedWLLabels(graph: Graph, visitor: Visitor?) -> [Vertex: Int] {
        var labels: [Vertex: Int] = [:]
        
        // Initialize with degree-based labels
        for vertex in graph.vertices() {
            let degree = graph.outDegree(of: vertex)
            labels[vertex] = degree
            visitor?.labelVertex?(vertex, degree)
        }
        
        // Iteratively refine labels
        for iteration in 0..<maxIterations {
            var newLabels: [Vertex: Int] = [:]
            var labelMap: [String: Int] = [:]
            var nextNewLabel = 0
            
            for vertex in graph.vertices() {
                visitor?.examineVertex?(vertex)
                
                // Create a signature based on current label and neighbor labels with edge information
                let currentLabel = labels[vertex]!
                var neighborInfo: [(Int, String)] = []
                
                for edge in graph.outgoingEdges(of: vertex) {
                    visitor?.examineEdge?(edge)
                    guard let neighbor = graph.destination(of: edge) else { continue }
                    let neighborLabel = labels[neighbor]!
                    // Use edge descriptor as string representation for edge labels
                    let edgeInfo = String(describing: edge)
                    neighborInfo.append((neighborLabel, edgeInfo))
                }
                
                // Sort by neighbor label, then by edge info for consistency
                neighborInfo.sort { $0.0 < $1.0 || ($0.0 == $1.0 && $0.1 < $1.1) }
                
                // Create a string signature including edge information
                let neighborString = neighborInfo.map { "\($0.0):\($0.1)" }.joined(separator: ",")
                let signature = "\(currentLabel):[\(neighborString)]"
                
                // Assign a new label based on the signature
                if let existingLabel = labelMap[signature] {
                    newLabels[vertex] = existingLabel
                } else {
                    let newLabel = nextNewLabel
                    labelMap[signature] = newLabel
                    newLabels[vertex] = newLabel
                    nextNewLabel += 1
                }
                
                visitor?.labelVertex?(vertex, newLabels[vertex]!)
            }
            
            visitor?.iterationComplete?(iteration + 1, newLabels)
            
            // Check if labels have stabilized
            if labels == newLabels {
                visitor?.labelsStabilized?(newLabels)
                break
            }
            
            labels = newLabels
        }
        
        return labels
    }
    
    @usableFromInline
    func areLabelMultisetsEqual(_ labels1: [Vertex: Int], _ labels2: [Vertex: Int]) -> Bool {
        // Count occurrences of each label in both graphs
        var count1: [Int: Int] = [:]
        var count2: [Int: Int] = [:]
        
        for label in labels1.values {
            count1[label, default: 0] += 1
        }
        
        for label in labels2.values {
            count2[label, default: 0] += 1
        }
        
        // Check if the multisets are equal
        return count1 == count2
    }
}

extension WeisfeilerLehmanIsomorphism: VisitorSupporting {}
extension EnhancedWeisfeilerLehmanIsomorphism: VisitorSupporting {}
