import Foundation

/// Weisfeiler-Lehman algorithm for graph isomorphism
/// This algorithm uses iterative vertex labeling based on neighborhood structure
/// to determine if two graphs are isomorphic. It's a fast heuristic that works
/// well for many graph types but is not complete (may give false negatives).
struct WeisfeilerLehmanIsomorphism<Graph: IncidenceGraph & VertexListGraph & EdgeListGraph> where Graph.VertexDescriptor: Hashable {
    typealias Vertex = Graph.VertexDescriptor
    typealias Edge = Graph.EdgeDescriptor
    
    struct Visitor {
        var examineVertex: ((Vertex) -> Void)?
        var examineEdge: ((Edge) -> Void)?
        var labelVertex: ((Vertex, Int) -> Void)?
        var iterationComplete: ((Int, [Vertex: Int]) -> Void)?
        var labelsStabilized: (([Vertex: Int]) -> Void)?
    }
    
    private let maxIterations: Int
    
    init(maxIterations: Int = 10) {
        self.maxIterations = maxIterations
    }
    
    func areIsomorphic(_ graph1: Graph, _ graph2: Graph, visitor: Visitor? = nil) -> Bool {
        return findIsomorphism(graph1, graph2, visitor: visitor) != nil
    }
    
    func findIsomorphism(_ graph1: Graph, _ graph2: Graph, visitor: Visitor? = nil) -> [Vertex: Vertex]? {
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
    
    private func computeWLLabels(graph: Graph, visitor: Visitor?) -> [Vertex: Int] {
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
    
    private func areLabelMultisetsEqual(_ labels1: [Vertex: Int], _ labels2: [Vertex: Int]) -> Bool {
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
struct EnhancedWeisfeilerLehmanIsomorphism<Graph: IncidenceGraph & VertexListGraph & EdgeListGraph> where Graph.VertexDescriptor: Hashable {
    typealias Vertex = Graph.VertexDescriptor
    typealias Edge = Graph.EdgeDescriptor
    
    struct Visitor {
        var examineVertex: ((Vertex) -> Void)?
        var examineEdge: ((Edge) -> Void)?
        var labelVertex: ((Vertex, Int) -> Void)?
        var iterationComplete: ((Int, [Vertex: Int]) -> Void)?
        var labelsStabilized: (([Vertex: Int]) -> Void)?
    }
    
    private let maxIterations: Int
    
    init(maxIterations: Int = 10) {
        self.maxIterations = maxIterations
    }
    
    func areIsomorphic(_ graph1: Graph, _ graph2: Graph, visitor: Visitor? = nil) -> Bool {
        return findIsomorphism(graph1, graph2, visitor: visitor) != nil
    }
    
    func findIsomorphism(_ graph1: Graph, _ graph2: Graph, visitor: Visitor? = nil) -> [Vertex: Vertex]? {
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
    
    private func computeEnhancedWLLabels(graph: Graph, visitor: Visitor?) -> [Vertex: Int] {
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
    
    private func areLabelMultisetsEqual(_ labels1: [Vertex: Int], _ labels2: [Vertex: Int]) -> Bool {
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
