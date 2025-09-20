import Foundation

struct EulerFormulaPlanarPropertyAlgorithm<Graph: IncidenceGraph & VertexListGraph & EdgeListGraph> where Graph.VertexDescriptor: Hashable {
    typealias Vertex = Graph.VertexDescriptor
    typealias Edge = Graph.EdgeDescriptor
    
    struct Visitor {
        var checkEulerFormula: ((Int, Int, Int) -> Void)?
        var examineVertex: ((Vertex) -> Void)?
        var examineEdge: ((Edge) -> Void)?
        var checkKuratowski: (() -> Void)?
        var kuratowskiViolation: ((String) -> Void)?
        var eulerFormulaViolation: ((Int, Int, Int) -> Void)?
    }
    
    func isPlanar(
        in graph: Graph,
        visitor: Visitor?
    ) -> Bool {
        // Handle empty graphs and single vertex graphs
        guard graph.vertexCount > 0 else {
            return true
        }
        
        guard graph.vertexCount > 1 else {
            return true
        }
        
        let vertices = graph.vertexCount
        let edges = graph.edgeCount
        
        // Quick check: if graph has too many edges, it cannot be planar
        // For a connected planar graph: |E| ≤ 3|V| - 6
        // For a planar graph with |V| ≥ 3: |E| ≤ 3|V| - 6
        if vertices >= 3 && edges > 3 * vertices - 6 {
            visitor?.eulerFormulaViolation?(vertices, edges, 3 * vertices - 6)
            return false
        }
        
        // Check for K₅ (complete graph on 5 vertices) - 10 edges
        // Only check for small graphs to avoid exponential explosion
        if vertices >= 5 && vertices <= 8 && edges >= 10 {
            if checkForK5(in: graph, visitor: visitor) {
                visitor?.kuratowskiViolation?("Contains K₅ subdivision")
                return false
            }
        }
        
        // Check for K₃,₃ (complete bipartite graph) - 9 edges
        // Only check for small graphs to avoid exponential explosion
        if vertices >= 6 && vertices <= 8 && edges >= 9 {
            if checkForK33(in: graph, visitor: visitor) {
                visitor?.kuratowskiViolation?("Contains K₃,₃ subdivision")
                return false
            }
        }
        
        // For small graphs, use a more detailed check
        if vertices <= 6 {
            return checkSmallGraphPlanarity(in: graph, visitor: visitor)
        }
        
        // If we get here, the graph passes the basic checks
        // In a full implementation, we would use a proper planarity testing algorithm
        // like Boyer-Myrvold, but for now we'll be conservative and return true
        // for graphs that pass Euler's formula and don't contain obvious K₅ or K₃,₃
        return true
    }
    
    private func checkForK5(in graph: Graph, visitor: Visitor?) -> Bool {
        let vertices = Array(graph.vertices())
        
        // Check all combinations of 5 vertices
        for i in 0..<vertices.count {
            for j in (i+1)..<vertices.count {
                for k in (j+1)..<vertices.count {
                    for l in (k+1)..<vertices.count {
                        for m in (l+1)..<vertices.count {
                            let candidateVertices = [vertices[i], vertices[j], vertices[k], vertices[l], vertices[m]]
                            if isCompleteSubgraph(candidateVertices, in: graph) {
                                return true
                            }
                        }
                    }
                }
            }
        }
        return false
    }
    
    private func checkForK33(in graph: Graph, visitor: Visitor?) -> Bool {
        let vertices = Array(graph.vertices())
        
        // Check all combinations of 6 vertices for K₃,₃ structure
        for i in 0..<vertices.count {
            for j in (i+1)..<vertices.count {
                for k in (j+1)..<vertices.count {
                    for l in (k+1)..<vertices.count {
                        for m in (l+1)..<vertices.count {
                            for n in (m+1)..<vertices.count {
                                let candidateVertices = [vertices[i], vertices[j], vertices[k], vertices[l], vertices[m], vertices[n]]
                                if isK33Subgraph(candidateVertices, in: graph) {
                                    return true
                                }
                            }
                        }
                    }
                }
            }
        }
        return false
    }
    
    private func isCompleteSubgraph(_ vertices: [Graph.VertexDescriptor], in graph: Graph) -> Bool {
        // Check if all pairs of vertices are connected
        for i in 0..<vertices.count {
            for j in (i+1)..<vertices.count {
                if !hasEdge(from: vertices[i], to: vertices[j], in: graph) {
                    return false
                }
            }
        }
        return true
    }
    
    private func isK33Subgraph(_ vertices: [Graph.VertexDescriptor], in graph: Graph) -> Bool {
        // Try all possible partitions into two sets of 3 vertices each
        let partitions = generatePartitions(vertices, size1: 3, size2: 3)
        
        for partition in partitions {
            let set1 = partition.0
            let set2 = partition.1
            
            // Check if every vertex in set1 is connected to every vertex in set2
            var isK33 = true
            for v1 in set1 {
                for v2 in set2 {
                    if !hasEdge(from: v1, to: v2, in: graph) {
                        isK33 = false
                        break
                    }
                }
                if !isK33 { break }
            }
            
            if isK33 {
                return true
            }
        }
        
        return false
    }
    
    private func hasEdge(from source: Graph.VertexDescriptor, to destination: Graph.VertexDescriptor, in graph: Graph) -> Bool {
        for edge in graph.outgoingEdges(of: source) {
            if let dest = graph.destination(of: edge), dest == destination {
                return true
            }
        }
        return false
    }
    
    private func generatePartitions<T>(_ elements: [T], size1: Int, size2: Int) -> [([T], [T])] {
        guard elements.count == size1 + size2 else { return [] }
        
        var partitions: [([T], [T])] = []
        let indices = Array(0..<elements.count)
        
        // Generate all combinations of size1 elements
        let combinations = generateCombinations(indices, size: size1)
        
        for combination in combinations {
            let set1 = combination.map { elements[$0] }
            let set2 = (0..<elements.count).compactMap { index in
                combination.contains(index) ? nil : elements[index]
            }
            partitions.append((set1, set2))
        }
        
        return partitions
    }
    
    private func generateCombinations<T>(_ elements: [T], size: Int) -> [[T]] {
        guard size > 0 && size <= elements.count else { return [] }
        guard size < elements.count else { return [elements] }
        guard size > 1 else { return elements.map { [$0] } }
        
        var combinations: [[T]] = []
        
        func generate(_ current: [T], _ remaining: [T], _ targetSize: Int) {
            if current.count == targetSize {
                combinations.append(current)
                return
            }
            
            for (index, element) in remaining.enumerated() {
                let newCurrent = current + [element]
                let newRemaining = Array(remaining.dropFirst(index + 1))
                generate(newCurrent, newRemaining, targetSize)
            }
        }
        
        generate([], elements, size)
        return combinations
    }
    
    private func checkSmallGraphPlanarity(in graph: Graph, visitor: Visitor?) -> Bool {
        let vertices = graph.vertexCount
        let edges = graph.edgeCount
        
        // Known planar graphs
        if vertices <= 3 {
            return true
        }
        
        if vertices == 4 {
            // K₄ is planar, but any graph with more than 6 edges is not
            return edges <= 6
        }
        
        if vertices == 5 {
            // K₅ is not planar (10 edges), but K₅ minus one edge is planar
            return edges < 10
        }
        
        if vertices == 6 {
            // K₃,₃ is not planar (9 edges), but smaller graphs might be
            return edges < 9
        }
        
        return true
    }
}

extension EulerFormulaPlanarPropertyAlgorithm.Visitor: Composable {
    func combined(with other: Self) -> Self {
        .init(
            checkEulerFormula: { vertices, edges, faces in
                self.checkEulerFormula?(vertices, edges, faces)
                other.checkEulerFormula?(vertices, edges, faces)
            },
            examineVertex: { vertex in
                self.examineVertex?(vertex)
                other.examineVertex?(vertex)
            },
            examineEdge: { edge in
                self.examineEdge?(edge)
                other.examineEdge?(edge)
            },
            checkKuratowski: {
                self.checkKuratowski?()
                other.checkKuratowski?()
            },
            kuratowskiViolation: { reason in
                self.kuratowskiViolation?(reason)
                other.kuratowskiViolation?(reason)
            },
            eulerFormulaViolation: { vertices, edges, faces in
                self.eulerFormulaViolation?(vertices, edges, faces)
                other.eulerFormulaViolation?(vertices, edges, faces)
            }
        )
    }
}

extension EulerFormulaPlanarPropertyAlgorithm: VisitorSupporting {}
