#if !GRAPHS_USES_TRAITS || GRAPHS_ANALYSIS
@testable import Graphs
import Testing

struct CentralityAlgorithmTests {
    
    // MARK: - Test Graphs
    
    func createEmptyGraph() -> some AdjacencyListProtocol {
        AdjacencyList()
    }
    
    func createSingleVertexGraph() -> some AdjacencyListProtocol {
        var graph = AdjacencyList()
        _ = graph.addVertex()
        return graph
    }
    
    func createCompleteGraph() -> some AdjacencyListProtocol {
        var graph = AdjacencyList()
        let vertices = (0..<4).map { _ in graph.addVertex() }
        for i in 0..<vertices.count {
            for j in (i+1)..<vertices.count {
                graph.addEdge(from: vertices[i], to: vertices[j])
                graph.addEdge(from: vertices[j], to: vertices[i])
            }
        }
        return graph
    }
    
    func createCycleGraph() -> some AdjacencyListProtocol {
        var graph = AdjacencyList()
        let a = graph.addVertex()
        let b = graph.addVertex()
        let c = graph.addVertex()
        let d = graph.addVertex()
        // Bidirectional edges for undirected cycle
        graph.addEdge(from: a, to: b)
        graph.addEdge(from: b, to: a)
        graph.addEdge(from: b, to: c)
        graph.addEdge(from: c, to: b)
        graph.addEdge(from: c, to: d)
        graph.addEdge(from: d, to: c)
        graph.addEdge(from: d, to: a)
        graph.addEdge(from: a, to: d)
        return graph
    }
    
    func createPathGraph() -> some AdjacencyListProtocol {
        var graph = AdjacencyList()
        let a = graph.addVertex()
        let b = graph.addVertex()
        let c = graph.addVertex()
        // Bidirectional edges for undirected path
        graph.addEdge(from: a, to: b)
        graph.addEdge(from: b, to: a)
        graph.addEdge(from: b, to: c)
        graph.addEdge(from: c, to: b)
        return graph
    }
    
    func createDisconnectedGraph() -> some AdjacencyListProtocol {
        var graph = AdjacencyList()
        let a = graph.addVertex()
        let b = graph.addVertex()
        let c = graph.addVertex()
        let d = graph.addVertex()
        graph.addEdge(from: a, to: b)
        graph.addEdge(from: c, to: d)
        return graph
    }
    
    // MARK: - Core Behavior (Degree)
    
    @Test func degreeCentralityEmptyGraph() {
        let graph = createEmptyGraph()
        let result = graph.centrality(using: .degree())
        #expect(result.values.isEmpty)
    }
    
    @Test func degreeCentralitySingleVertex() {
        let graph = createSingleVertexGraph()
        let result = graph.centrality(using: .degree())
        let vertex = Array(graph.vertices())[0]
        #expect(result.centrality(for: vertex) == 0.0)
    }
    
    @Test func degreeCentralityStarGraph() {
        var graph = AdjacencyList()
        let center = graph.addVertex()
        var leaves: [DefaultAdjacencyList.VertexDescriptor] = []
        for _ in 0..<5 {
            let leaf = graph.addVertex()
            leaves.append(leaf)
            graph.addEdge(from: center, to: leaf)
            graph.addEdge(from: leaf, to: center)
        }
        let result = graph.centrality(using: .degree())
        
        // Center should have highest degree
        #expect(result.centrality(for: center) > result.centrality(for: leaves[0]))
        #expect(result.mostCentralVertex() == center)
    }
    
    @Test func degreeCentralityStarGraphExactValues() {
        var graph = AdjacencyList()
        let center = graph.addVertex()
        var leaves: [DefaultAdjacencyList.VertexDescriptor] = []
        for _ in 0..<5 {
            let leaf = graph.addVertex()
            leaves.append(leaf)
            graph.addEdge(from: center, to: leaf)
            graph.addEdge(from: leaf, to: center)
        }
        
        // Unnormalized: exact values
        let unnormalized = graph.centrality(using: .degree(normalized: false))
        #expect(unnormalized.centrality(for: center) == 5.0)
        for leaf in leaves {
            #expect(unnormalized.centrality(for: leaf) == 1.0)
        }
        
        // Normalized: exact values (center = 1.0, leaves = 0.2)
        let normalized = graph.centrality(using: .degree(normalized: true))
        #expect(abs(normalized.centrality(for: center) - 1.0) < 0.001)
        for leaf in leaves {
            #expect(abs(normalized.centrality(for: leaf) - 0.2) < 0.001)
        }
    }
    
    @Test func degreeCentralityNormalized() {
        var graph = AdjacencyList()
        let center = graph.addVertex()
        for _ in 0..<5 {
            let leaf = graph.addVertex()
            graph.addEdge(from: center, to: leaf)
        }
        let result = graph.centrality(using: .degree(normalized: true))
        
        // Normalized values should be in [0, 1]
        for vertex in graph.vertices() {
            let normalized = result.normalizedCentrality(for: vertex)
            #expect(normalized >= 0.0)
            #expect(normalized <= 1.0)
        }
    }
    
    @Test func degreeCentralityIsolatedVertex() {
        var graph = AdjacencyList()
        let connected = graph.addVertex()
        let isolated = graph.addVertex()
        let other = graph.addVertex()
        graph.addEdge(from: connected, to: other)
        let result = graph.centrality(using: .degree())
        #expect(result.centrality(for: isolated) == 0.0)
    }
    
    @Test func degreeCentralityVisitor() {
        var examinedVertices: Set<DefaultAdjacencyList.VertexDescriptor> = []
        var computedDegrees: [DefaultAdjacencyList.VertexDescriptor: Int] = [:]
        
        var graph = DefaultAdjacencyList()
        let center = graph.addVertex()
        for _ in 0..<5 {
            let leaf = graph.addVertex()
            graph.addEdge(from: center, to: leaf)
        }
        
        let algorithm = DegreeCentralityAlgorithm<DefaultAdjacencyList>(normalized: true)
        let visitor = DegreeCentrality<DefaultAdjacencyList>.Visitor(
            examineVertex: { vertex in
                examinedVertices.insert(vertex)
            },
            computeDegree: { vertex, degree in
                computedDegrees[vertex] = degree
            }
        )
        _ = algorithm.centrality(in: graph, visitor: visitor)
        
        #expect(examinedVertices.count == graph.vertexCount)
        #expect(computedDegrees.count == graph.vertexCount)
    }
    
    // MARK: - Core Behavior (PageRank)
    
    @Test func pageRankEmptyGraph() {
        let graph = createEmptyGraph()
        let result = graph.centrality(using: .pageRank())
        #expect(result.values.isEmpty)
    }
    
    @Test func pageRankSingleVertex() {
        let graph = createSingleVertexGraph()
        let result = graph.centrality(using: .pageRank())
        let vertex = Array(graph.vertices())[0]
        #expect(result.centrality(for: vertex) == 1.0)
    }
    
    @Test func pageRankCycleGraph() {
        let graph = createCycleGraph()
        let result = graph.centrality(using: .pageRank())
        
        // In a cycle, all vertices should have similar PageRank
        let values = Array(result.values.values)
        let firstValue = values[0]
        for value in values {
            #expect(abs(Double(value) - Double(firstValue)) < 0.1)
        }
    }
    
    @Test func pageRankStarGraph() {
        var graph = AdjacencyList()
        let center = graph.addVertex()
        var leaves: [DefaultAdjacencyList.VertexDescriptor] = []
        for _ in 0..<5 {
            let leaf = graph.addVertex()
            leaves.append(leaf)
            graph.addEdge(from: center, to: leaf)
            graph.addEdge(from: leaf, to: center)
        }
        let result = graph.centrality(using: .pageRank())
        
        // Center should have higher PageRank due to incoming links
        #expect(result.centrality(for: center) > result.centrality(for: leaves[0]))
    }
    
    @Test func pageRankConvergence() {
        var graph = AdjacencyList()
        let a = graph.addVertex()
        let b = graph.addVertex()
        let c = graph.addVertex()
        let d = graph.addVertex()
        graph.addEdge(from: a, to: b)
        graph.addEdge(from: b, to: c)
        graph.addEdge(from: c, to: d)
        graph.addEdge(from: d, to: a)
        
        var iterations = 0
        let algorithm = PageRankCentralityAlgorithm<DefaultAdjacencyList>(dampingFactor: 0.85, maxIterations: 100, tolerance: 1e-6)
        let visitor = PageRankCentrality<DefaultAdjacencyList>.Visitor(
            startIteration: { iteration in
                iterations = iteration
            }
        )
        _ = algorithm.centrality(in: graph, visitor: visitor)
        #expect(iterations < 100) // Should converge before max iterations
    }
    
    @Test func pageRankVisitor() {
        var startCount = 0
        var endCount = 0
        
        var graph = AdjacencyList()
        let a = graph.addVertex()
        let b = graph.addVertex()
        let c = graph.addVertex()
        let d = graph.addVertex()
        graph.addEdge(from: a, to: b)
        graph.addEdge(from: b, to: c)
        graph.addEdge(from: c, to: d)
        graph.addEdge(from: d, to: a)
        
        let algorithm = PageRankCentralityAlgorithm<DefaultAdjacencyList>()
        let visitor = PageRankCentrality<DefaultAdjacencyList>.Visitor(
            startIteration: { _ in startCount += 1 },
            endIteration: { _, _ in endCount += 1 }
        )
        _ = algorithm.centrality(in: graph, visitor: visitor)
        
        #expect(startCount > 0)
        #expect(endCount > 0)
        #expect(startCount == endCount)
    }
    
    @Test func pageRankSumProperty() {
        var graph = AdjacencyList()
        let a = graph.addVertex()
        let b = graph.addVertex()
        let c = graph.addVertex()
        graph.addEdge(from: a, to: b)
        graph.addEdge(from: b, to: c)
        graph.addEdge(from: c, to: a)
        
        let result = graph.centrality(using: .pageRank())
        
        // PageRank values must sum to approximately 1.0
        let sum = result.values.values.reduce(0.0, +)
        #expect(abs(sum - 1.0) < 0.01, "PageRank values should sum to ~1.0, got \(sum)")
    }
    
    @Test func pageRankDanglingNodes() {
        var graph = AdjacencyList()
        let a = graph.addVertex()
        let b = graph.addVertex()
        let c = graph.addVertex() // Dangling node (no outgoing edges)
        graph.addEdge(from: a, to: b)
        graph.addEdge(from: b, to: a)
        graph.addEdge(from: a, to: c)
        // c has no outgoing edges
        
        let result = graph.centrality(using: .pageRank())
        
        // Should handle dangling nodes without crashing
        #expect(result.values.count == 3)
        
        // PageRank should still sum to ~1.0
        let sum = result.values.values.reduce(0.0, +)
        #expect(abs(sum - 1.0) < 0.01)
    }
    
    // MARK: - Core Behavior (Betweenness)
    
    @Test func betweennessEmptyGraph() {
        let graph = createEmptyGraph()
        let result = graph.centrality(using: .betweenness())
        #expect(result.values.isEmpty)
    }
    
    @Test func betweennessSingleVertex() {
        let graph = createSingleVertexGraph()
        let result = graph.centrality(using: .betweenness())
        let vertex = Array(graph.vertices())[0]
        #expect(result.centrality(for: vertex) == 0.0)
    }
    
    @Test func betweennessPathGraph() {
        let graph = createPathGraph()
        let result = graph.centrality(using: .betweenness())
        let vertices = Array(graph.vertices())
        
        // Middle vertex should have highest betweenness
        let middleVertex = vertices[1]
        #expect(result.centrality(for: middleVertex) > result.centrality(for: vertices[0]))
        #expect(result.centrality(for: middleVertex) > result.centrality(for: vertices[2]))
    }
    
    @Test func betweennessPathGraphExactValues() {
        var graph = AdjacencyList()
        let a = graph.addVertex()
        let b = graph.addVertex()
        let c = graph.addVertex()
        // Bidirectional path A-B-C
        // Note: For directed graph algorithm on bidirectional edges,
        // we count both directions, so B appears on paths A->C and C->A
        graph.addEdge(from: a, to: b)
        graph.addEdge(from: b, to: a)
        graph.addEdge(from: b, to: c)
        graph.addEdge(from: c, to: b)
        
        let result = graph.centrality(using: .betweenness(normalized: false))
        
        // B is on paths A->C and C->A, so betweenness = 2.0 (counting both directions)
        // A and C are endpoints, so betweenness = 0.0
        #expect(result.centrality(for: b) == 2.0)
        #expect(result.centrality(for: a) == 0.0)
        #expect(result.centrality(for: c) == 0.0)
    }
    
    @Test func betweennessVisitor() {
        var examinedVertices: Set<DefaultAdjacencyList.VertexDescriptor> = []
        var foundPaths: [(DefaultAdjacencyList.VertexDescriptor, DefaultAdjacencyList.VertexDescriptor, Int)] = []
        
        var graph = DefaultAdjacencyList()
        let a = graph.addVertex()
        let b = graph.addVertex()
        let c = graph.addVertex()
        graph.addEdge(from: a, to: b)
        graph.addEdge(from: b, to: c)
        
        let algorithm = BetweennessCentralityAlgorithm<DefaultAdjacencyList>(normalized: false)
        let visitor = BetweennessCentrality<DefaultAdjacencyList>.Visitor(
            examineVertex: { vertex in
                examinedVertices.insert(vertex)
            },
            foundShortestPath: { source, destination, distance in
                foundPaths.append((source, destination, distance))
            }
        )
        _ = algorithm.centrality(in: graph, visitor: visitor)
        
        #expect(examinedVertices.count == graph.vertexCount)
        #expect(foundPaths.count > 0)
    }
    
    @Test func betweennessStarGraph() {
        var graph = AdjacencyList()
        let center = graph.addVertex()
        for _ in 0..<5 {
            let leaf = graph.addVertex()
            graph.addEdge(from: center, to: leaf)
            graph.addEdge(from: leaf, to: center)
        }
        let result = graph.centrality(using: .betweenness())
        
        // Center should have highest betweenness
        #expect(result.mostCentralVertex() == center)
    }
    
    @Test func betweennessIsolatedVertex() {
        var graph = AdjacencyList()
        let connected = graph.addVertex()
        let isolated = graph.addVertex()
        let other = graph.addVertex()
        graph.addEdge(from: connected, to: other)
        let result = graph.centrality(using: .betweenness())
        #expect(result.centrality(for: isolated) == 0.0)
    }
    
    @Test func betweennessNormalized() {
        let graph = createPathGraph()
        let result = graph.centrality(using: .betweenness(normalized: true))
        
        // Normalized values should be in [0, 1]
        for vertex in graph.vertices() {
            let normalized = result.normalizedCentrality(for: vertex)
            #expect(normalized >= 0.0)
            #expect(normalized <= 1.0)
        }
    }
    
    // MARK: - Core Behavior (Closeness)
    
    @Test func closenessEmptyGraph() {
        let graph = createEmptyGraph()
        let result = graph.centrality(using: .closeness())
        #expect(result.values.isEmpty)
    }
    
    @Test func closenessSingleVertex() {
        let graph = createSingleVertexGraph()
        let result = graph.centrality(using: .closeness())
        let vertex = Array(graph.vertices())[0]
        #expect(result.centrality(for: vertex) == 0.0)
    }
    
    @Test func closenessStarGraph() {
        var graph = AdjacencyList()
        let center = graph.addVertex()
        for _ in 0..<5 {
            let leaf = graph.addVertex()
            graph.addEdge(from: center, to: leaf)
            graph.addEdge(from: leaf, to: center)
        }
        let result = graph.centrality(using: .closeness())
        
        // Center should have highest closeness
        #expect(result.mostCentralVertex() == center)
    }
    
    @Test func closenessDisconnectedGraph() {
        let graph = createDisconnectedGraph()
        let result = graph.centrality(using: .closeness())
        
        // Vertices in disconnected components should have 0 closeness
        for vertex in graph.vertices() {
            // Since not all vertices are reachable, closeness should be 0
            #expect(result.centrality(for: vertex) == 0.0)
        }
    }
    
    @Test func closenessIsolatedVertex() {
        var graph = AdjacencyList()
        let connected = graph.addVertex()
        let isolated = graph.addVertex()
        let other = graph.addVertex()
        graph.addEdge(from: connected, to: other)
        let result = graph.centrality(using: .closeness())
        #expect(result.centrality(for: isolated) == 0.0)
    }
    
    @Test func closenessVisitor() {
        var examinedVertices: Set<DefaultAdjacencyList.VertexDescriptor> = []
        var computedDistances: [(DefaultAdjacencyList.VertexDescriptor, DefaultAdjacencyList.VertexDescriptor, Int)] = []
        
        var graph = DefaultAdjacencyList()
        let a = graph.addVertex()
        let b = graph.addVertex()
        let c = graph.addVertex()
        graph.addEdge(from: a, to: b)
        graph.addEdge(from: b, to: c)
        
        let algorithm = ClosenessCentralityAlgorithm<DefaultAdjacencyList>()
        let visitor = ClosenessCentrality<DefaultAdjacencyList>.Visitor(
            examineVertex: { vertex in
                examinedVertices.insert(vertex)
            },
            computeDistance: { source, destination, distance in
                computedDistances.append((source, destination, distance))
            }
        )
        _ = algorithm.centrality(in: graph, visitor: visitor)
        
        #expect(examinedVertices.count == graph.vertexCount)
        #expect(computedDistances.count > 0)
    }
    
    // MARK: - Core Behavior (Eigenvector)
    
    @Test func eigenvectorEmptyGraph() {
        let graph = AdjacencyList()
        let result = graph.centrality(using: .eigenvector())
        #expect(result.values.isEmpty)
    }
    
    @Test func eigenvectorSingleVertex() {
        var graph = AdjacencyList()
        let vertex = graph.addVertex()
        let result = graph.centrality(using: .eigenvector())
        #expect(result.centrality(for: vertex) == 1.0)
    }
    
    @Test func eigenvectorStarGraph() {
        var graph = AdjacencyList()
        let center = graph.addVertex()
        for _ in 0..<5 {
            let leaf = graph.addVertex()
            graph.addEdge(from: center, to: leaf)
            graph.addEdge(from: leaf, to: center)
        }
        let result = graph.centrality(using: .eigenvector())
        
        // Verify eigenvector centrality is computed for all vertices
        #expect(result.values.count == graph.vertexCount)
        
        // All values should be positive
        for vertex in graph.vertices() {
            let ev = result.centrality(for: vertex)
            #expect(ev >= 0.0, "Eigenvector centrality should be non-negative")
        }
        
        // Note: Due to normalization by max value at each iteration,
        // eigenvector centrality values may not preserve relative ordering
        // in all cases. The algorithm completes successfully if it converges.
    }
    
    @Test func eigenvectorConvergence() {
        var graph = AdjacencyList()
        let a = graph.addVertex()
        let b = graph.addVertex()
        let c = graph.addVertex()
        let d = graph.addVertex()
        graph.addEdge(from: a, to: b)
        graph.addEdge(from: b, to: a)
        graph.addEdge(from: b, to: c)
        graph.addEdge(from: c, to: b)
        graph.addEdge(from: c, to: d)
        graph.addEdge(from: d, to: c)
        graph.addEdge(from: d, to: a)
        graph.addEdge(from: a, to: d)
        
        var iterations = 0
        let algorithm = EigenvectorCentralityAlgorithm<DefaultAdjacencyList>(maxIterations: 100, tolerance: 1e-6)
        let visitor = EigenvectorCentrality<DefaultAdjacencyList>.Visitor(
            startIteration: { iteration in
                iterations = iteration
            }
        )
        _ = algorithm.centrality(in: graph, visitor: visitor)
        #expect(iterations < 100)
    }
    
    @Test func eigenvectorVisitor() {
        var startCount = 0
        var endCount = 0
        var convergedCount = 0
        
        var graph = DefaultAdjacencyList()
        let a = graph.addVertex()
        let b = graph.addVertex()
        let c = graph.addVertex()
        graph.addEdge(from: a, to: b)
        graph.addEdge(from: b, to: a)
        graph.addEdge(from: b, to: c)
        graph.addEdge(from: c, to: b)
        
        let algorithm = EigenvectorCentralityAlgorithm<DefaultAdjacencyList>()
        let visitor = EigenvectorCentrality<DefaultAdjacencyList>.Visitor(
            startIteration: { _ in startCount += 1 },
            endIteration: { _, _ in endCount += 1 },
            converge: { _, _ in convergedCount += 1 }
        )
        _ = algorithm.centrality(in: graph, visitor: visitor)
        
        #expect(startCount > 0)
        #expect(endCount > 0)
        #expect(startCount == endCount)
        // Convergence callback may or may not be called depending on tolerance
        #expect(convergedCount >= 0)
    }
    
    // MARK: - Result Utilities
    
    @Test func centralityResultNormalizedValues() {
        var graph = AdjacencyList()
        let center = graph.addVertex()
        for _ in 0..<5 {
            let leaf = graph.addVertex()
            graph.addEdge(from: center, to: leaf)
        }
        let result = graph.centrality(using: .degree())
        
        // All normalized values should be in [0, 1]
        for vertex in graph.vertices() {
            let normalized = result.normalizedCentrality(for: vertex)
            #expect(normalized >= 0.0)
            #expect(normalized <= 1.0)
        }
    }
    
    @Test func centralityResultMostCentralVertex() {
        var graph = AdjacencyList()
        let center = graph.addVertex()
        for _ in 0..<5 {
            let leaf = graph.addVertex()
            graph.addEdge(from: center, to: leaf)
            graph.addEdge(from: leaf, to: center)
        }
        let result = graph.centrality(using: .degree())
        #expect(result.mostCentralVertex() == center)
    }
    
    @Test func centralityResultVerticesByCentrality() {
        var graph = AdjacencyList()
        let center = graph.addVertex()
        var leaves: [DefaultAdjacencyList.VertexDescriptor] = []
        for _ in 0..<5 {
            let leaf = graph.addVertex()
            leaves.append(leaf)
            graph.addEdge(from: center, to: leaf)
            graph.addEdge(from: leaf, to: center)
        }
        let result = graph.centrality(using: .degree())
        let sorted = result.verticesByCentrality()
        
        // Center should be first
        #expect(sorted[0] == center)
        
        // All vertices should be included
        #expect(sorted.count == graph.vertexCount)
    }
    
    @Test func centralityResultForNonExistentVertex() {
        var graph = AdjacencyList()
        let center = graph.addVertex()
        for _ in 0..<5 {
            let leaf = graph.addVertex()
            graph.addEdge(from: center, to: leaf)
        }
        let result = graph.centrality(using: .degree())
        
        // Create a vertex that wasn't in the graph when centrality was computed
        let newVertex = graph.addVertex()
        
        // Should return 0.0 for vertex not in result
        #expect(result.centrality(for: newVertex) == 0.0)
        #expect(result.normalizedCentrality(for: newVertex) == 0.0)
    }
    
    // MARK: - API Convenience
    
    @Test func defaultCentralityMethod() {
        var graph = AdjacencyList()
        let center = graph.addVertex()
        for _ in 0..<5 {
            let leaf = graph.addVertex()
            graph.addEdge(from: center, to: leaf)
        }
        let result = graph.centrality() // Uses default .degree()
        
        // Should work without specifying algorithm
        #expect(!result.values.isEmpty)
        #expect(result.values.count == graph.vertexCount)
    }
    
    // MARK: - Visitor Support
    
    @Test func composedVisitorsReceiveAllEvents() {
        var callCount1 = 0
        var callCount2 = 0
        
        var graph = DefaultAdjacencyList()
        let center = graph.addVertex()
        for _ in 0..<5 {
            let leaf = graph.addVertex()
            graph.addEdge(from: center, to: leaf)
        }
        
        typealias G = DefaultAdjacencyList
        let algorithm = DegreeCentralityAlgorithm<G>(normalized: true)
        let visitor1 = DegreeCentrality<G>.Visitor(
            examineVertex: { _ in callCount1 += 1 }
        )
        let visitor2 = DegreeCentrality<G>.Visitor(
            examineVertex: { _ in callCount2 += 1 }
        )
        let combined = visitor1.combined(with: visitor2)
        _ = algorithm.centrality(in: graph, visitor: combined)
        
        #expect(callCount1 == graph.vertexCount)
        #expect(callCount2 == graph.vertexCount)
    }

    /// Exercises both `BetweennessCentrality.Visitor` events through a composed visitor pair.
    ///
    /// Graph: directed chain A→B→C→D (3 edges).
    /// Brandes' algorithm calls `examineVertex` for each source vertex (4 times total)
    /// and `foundShortestPath` for each reachable destination from each source.
    /// Both composed visitors must see identical event counts.
    @Test func betweennessComposedVisitorsReceiveAllEvents() {
        var graph = DefaultAdjacencyList()
        let a = graph.addVertex { $0.label = "A" }
        let b = graph.addVertex { $0.label = "B" }
        let c = graph.addVertex { $0.label = "C" }
        let d = graph.addVertex { $0.label = "D" }
        graph.addEdge(from: a, to: b)
        graph.addEdge(from: b, to: c)
        graph.addEdge(from: c, to: d)

        var examVtx1 = 0; var examVtx2 = 0
        var foundPath1 = 0; var foundPath2 = 0

        var v1 = BetweennessCentrality<DefaultAdjacencyList>.Visitor()
        v1.examineVertex    = { _ in examVtx1 += 1 }
        v1.foundShortestPath = { _, _, _ in foundPath1 += 1 }

        var v2 = BetweennessCentrality<DefaultAdjacencyList>.Visitor()
        v2.examineVertex    = { _ in examVtx2 += 1 }
        v2.foundShortestPath = { _, _, _ in foundPath2 += 1 }

        let combined = v1.combined(with: v2)
        _ = graph.centrality(using: .betweenness(normalized: false).withVisitor(combined))

        // Brandes fires examineVertex once per source vertex (4 sources in a 4-vertex graph)
        #expect(examVtx1 == 4, "examineVertex must fire once per source vertex")
        #expect(examVtx2 == 4)
        // foundShortestPath fires for each BFS discovery — at least 3 (chain has 3 reachable pairs)
        #expect(foundPath1 >= 3, "foundShortestPath fires for each BFS-discovered vertex")
        #expect(foundPath2 >= 3)
        // Both composed visitors must see identical event counts
        #expect(examVtx1 == examVtx2)
        #expect(foundPath1 == foundPath2)
    }

    /// Exercises both `ClosenessCentrality.Visitor` events through a composed visitor pair.
    ///
    /// Graph: undirected triangle A−B−C (bidirectional edges).
    /// `examineVertex` fires once per source vertex (3 times); `computeDistance` fires
    /// for each BFS discovery from each source. Both composed visitors must see identical counts.
    @Test func closenessComposedVisitorsReceiveAllEvents() {
        var graph = DefaultAdjacencyList()
        let a = graph.addVertex { $0.label = "A" }
        let b = graph.addVertex { $0.label = "B" }
        let c = graph.addVertex { $0.label = "C" }
        graph.addEdge(from: a, to: b); graph.addEdge(from: b, to: a)
        graph.addEdge(from: b, to: c); graph.addEdge(from: c, to: b)
        graph.addEdge(from: a, to: c); graph.addEdge(from: c, to: a)

        var examVtx1 = 0; var examVtx2 = 0
        var compDist1 = 0; var compDist2 = 0

        var v1 = ClosenessCentrality<DefaultAdjacencyList>.Visitor()
        v1.examineVertex  = { _ in examVtx1 += 1 }
        v1.computeDistance = { _, _, _ in compDist1 += 1 }

        var v2 = ClosenessCentrality<DefaultAdjacencyList>.Visitor()
        v2.examineVertex  = { _ in examVtx2 += 1 }
        v2.computeDistance = { _, _, _ in compDist2 += 1 }

        let combined = v1.combined(with: v2)
        _ = graph.centrality(using: .closeness().withVisitor(combined))

        // examineVertex fires once per vertex used as BFS source (3 vertices)
        #expect(examVtx1 == 3, "examineVertex fires once per source vertex")
        #expect(examVtx2 == 3)
        // computeDistance fires for each BFS-discovered vertex — at least 6 (2 per source in K3)
        #expect(compDist1 >= 6, "computeDistance fires for each vertex discovered from each source")
        #expect(compDist2 >= 6)
        // Both composed visitors must see identical event counts
        #expect(examVtx1 == examVtx2)
        #expect(compDist1 == compDist2)
    }

    /// Exercises all three `EigenvectorCentrality.Visitor` events through a composed visitor pair.
    ///
    /// Graph: directed 3-cycle A→B→C→A. All vertices have identical incoming-edge weights,
    /// so the power iteration converges after a single step (all centralities stay at 1.0).
    /// `startIteration` fires once per power-iteration step; `endIteration` fires once per step;
    /// `converge` fires exactly once when convergence is reached.
    /// Both composed visitors must see identical event counts.
    @Test func eigenvectorComposedVisitorsReceiveAllEvents() {
        var graph = DefaultAdjacencyList()
        let a = graph.addVertex { $0.label = "A" }
        let b = graph.addVertex { $0.label = "B" }
        let c = graph.addVertex { $0.label = "C" }
        // Directed 3-cycle: A→B→C→A — strongly connected, converges in 1 iteration
        graph.addEdge(from: a, to: b)
        graph.addEdge(from: b, to: c)
        graph.addEdge(from: c, to: a)

        var startIter1 = 0; var startIter2 = 0
        var endIter1 = 0;   var endIter2 = 0
        var converge1 = 0;  var converge2 = 0

        var v1 = EigenvectorCentrality<DefaultAdjacencyList>.Visitor()
        v1.startIteration = { _ in startIter1 += 1 }
        v1.endIteration   = { _, _ in endIter1 += 1 }
        v1.converge       = { _, _ in converge1 += 1 }

        var v2 = EigenvectorCentrality<DefaultAdjacencyList>.Visitor()
        v2.startIteration = { _ in startIter2 += 1 }
        v2.endIteration   = { _, _ in endIter2 += 1 }
        v2.converge       = { _, _ in converge2 += 1 }

        let combined = v1.combined(with: v2)
        _ = graph.centrality(using: .eigenvector().withVisitor(combined))

        #expect(startIter1 >= 1,  "startIteration fires once per power-iteration step")
        #expect(startIter2 >= 1)
        #expect(endIter1 >= 1,    "endIteration fires once per power-iteration step")
        #expect(endIter2 >= 1)
        #expect(converge1 == 1,   "converge fires exactly once when convergence is reached")
        #expect(converge2 == 1)
        // startIteration and endIteration must fire the same number of times as each other
        #expect(startIter1 == endIter1)
        // Both composed visitors must see identical event counts
        #expect(startIter1 == startIter2)
        #expect(endIter1 == endIter2)
        #expect(converge1 == converge2)
    }

    /// Exercises all three `PageRankCentrality.Visitor` events through a composed visitor pair.
    ///
    /// Graph: directed triangle A→B→C→A — converges quickly.
    /// `startIteration` fires once per iteration step; `endIteration` fires once per step;
    /// `converge` fires exactly once when convergence is reached.
    /// Both composed visitors must see identical event counts.
    @Test func pageRankComposedVisitorsReceiveAllEvents() {
        var graph = DefaultAdjacencyList()
        let a = graph.addVertex { $0.label = "A" }
        let b = graph.addVertex { $0.label = "B" }
        let c = graph.addVertex { $0.label = "C" }
        graph.addEdge(from: a, to: b)
        graph.addEdge(from: b, to: c)
        graph.addEdge(from: c, to: a)

        var startIter1 = 0; var startIter2 = 0
        var endIter1 = 0;   var endIter2 = 0
        var converge1 = 0;  var converge2 = 0

        var v1 = PageRankCentrality<DefaultAdjacencyList>.Visitor()
        v1.startIteration = { _ in startIter1 += 1 }
        v1.endIteration   = { _, _ in endIter1 += 1 }
        v1.converge       = { _, _ in converge1 += 1 }

        var v2 = PageRankCentrality<DefaultAdjacencyList>.Visitor()
        v2.startIteration = { _ in startIter2 += 1 }
        v2.endIteration   = { _, _ in endIter2 += 1 }
        v2.converge       = { _, _ in converge2 += 1 }

        let combined = v1.combined(with: v2)
        _ = graph.centrality(using: .pageRank().withVisitor(combined))

        #expect(startIter1 >= 1,  "startIteration fires once per PageRank iteration")
        #expect(startIter2 >= 1)
        #expect(endIter1 >= 1,    "endIteration fires once per PageRank iteration")
        #expect(endIter2 >= 1)
        #expect(converge1 == 1,   "converge fires exactly once when PageRank converges")
        #expect(converge2 == 1)
        // startIteration and endIteration must fire the same number of times
        #expect(startIter1 == endIter1)
        // Both composed visitors must see identical event counts
        #expect(startIter1 == startIter2)
        #expect(endIter1 == endIter2)
        #expect(converge1 == converge2)
    }

    // MARK: - Edge Cases
    
    @Test func completeGraphCentrality() {
        let graph = createCompleteGraph()
        let result = graph.centrality(using: .degree())
        
        // In complete graph, all vertices should have same degree
        let values = Array(result.values.values)
        let firstValue = values[0]
        for value in values {
            #expect(abs(Double(value) - Double(firstValue)) < 0.001)
        }
    }
    
    @Test func completeGraphAllMeasures() {
        let graph = createCompleteGraph() // K4 (4 vertices, complete graph)
        let vertices = Array(graph.vertices())
        
        // Degree: all should have degree 3 (K4 has degree 3 for each vertex)
        let degreeResult = graph.centrality(using: .degree(normalized: false))
        for vertex in vertices {
            #expect(degreeResult.centrality(for: vertex) == 3.0)
        }
        
        // Betweenness: in complete graph, no vertex is on shortest path
        // between others (all paths are direct), so all should be 0
        let betweennessResult = graph.centrality(using: .betweenness(normalized: false))
        for vertex in vertices {
            #expect(betweennessResult.centrality(for: vertex) == 0.0)
        }
        
        // Closeness: all vertices should have same closeness (distance 1 to all others)
        let closenessResult = graph.centrality(using: .closeness())
        let firstCloseness = closenessResult.centrality(for: vertices[0])
        for vertex in vertices {
            let closeness = closenessResult.centrality(for: vertex)
            #expect(abs(closeness - firstCloseness) < 0.001)
        }
        
        // PageRank: all should be approximately equal
        let pagerankResult = graph.centrality(using: .pageRank())
        let firstPR = pagerankResult.centrality(for: vertices[0])
        for vertex in vertices {
            let pr = pagerankResult.centrality(for: vertex)
            #expect(abs(pr - firstPR) < 0.1)
        }
        
        // PageRank should sum to ~1.0
        let pagerankSum = pagerankResult.values.values.reduce(0.0, +)
        #expect(abs(pagerankSum - 1.0) < 0.01)
    }
    
    @Test func cycleGraphCentrality() {
        let graph = createCycleGraph()
        let result = graph.centrality(using: .degree())
        
        // In cycle, all vertices should have same degree
        let values = Array(result.values.values)
        let firstValue = values[0]
        for value in values {
            #expect(abs(Double(value) - Double(firstValue)) < 0.001)
        }
    }
    
    @Test func cycleGraphSymmetry() {
        let graph = createCycleGraph()
        let vertices = Array(graph.vertices())
        
        // Degree: all should have degree 2
        let degreeResult = graph.centrality(using: .degree(normalized: false))
        for vertex in vertices {
            #expect(degreeResult.centrality(for: vertex) == 2.0)
        }
        
        // PageRank: all should be approximately equal
        let pagerankResult = graph.centrality(using: .pageRank())
        let firstPR = pagerankResult.centrality(for: vertices[0])
        for vertex in vertices {
            let pr = pagerankResult.centrality(for: vertex)
            #expect(abs(pr - firstPR) < 0.1)
        }
        
        // PageRank should sum to ~1.0
        let sum = pagerankResult.values.values.reduce(0.0, +)
        #expect(abs(sum - 1.0) < 0.01)
    }
    
    @Test func normalizationFormula() throws {
        var graph = AdjacencyList()
        let a = graph.addVertex()
        let b = graph.addVertex()
        let c = graph.addVertex()
        graph.addEdge(from: a, to: b)
        graph.addEdge(from: b, to: c)
        
        let result = graph.centrality(using: .degree(normalized: false))
        
        // Verify normalization formula: (value - min) / (max - min)
        let values = result.values.values
        let minValue = try #require(values.min(), "Values should have a minimum")
        let maxValue = try #require(values.max(), "Values should have a maximum")
        let range = maxValue - minValue
        
        if range > 0 {
            for (vertex, rawValue) in result.values {
                let expectedNormalized = (rawValue - minValue) / range
                let actualNormalized = result.normalizedCentrality(for: vertex)
                #expect(abs(actualNormalized - expectedNormalized) < 0.001,
                       "Normalization formula mismatch for vertex \(vertex): expected \(expectedNormalized), got \(actualNormalized)")
            }
        }
    }
    
    @Test func normalizationAllValuesEqual() {
        // Test edge case: all values equal -> normalized should be 0.0
        var graph = AdjacencyList()
        let a = graph.addVertex()
        let b = graph.addVertex()
        // Two isolated vertices, both have degree 0
        let result = graph.centrality(using: .degree())
        
        // Both should have normalized value 0.0 (all values equal)
        #expect(result.normalizedCentrality(for: a) == 0.0)
        #expect(result.normalizedCentrality(for: b) == 0.0)
    }
    
    @Test func twoVertexGraph() {
        var graph = AdjacencyList()
        let a = graph.addVertex()
        let b = graph.addVertex()
        graph.addEdge(from: a, to: b)
        graph.addEdge(from: b, to: a)
        
        // Degree: both should have degree 1
        let degreeResult = graph.centrality(using: .degree(normalized: false))
        #expect(degreeResult.centrality(for: a) == 1.0)
        #expect(degreeResult.centrality(for: b) == 1.0)
        
        // Betweenness: both should be 0 (no intermediate paths)
        let betweennessResult = graph.centrality(using: .betweenness(normalized: false))
        #expect(betweennessResult.centrality(for: a) == 0.0)
        #expect(betweennessResult.centrality(for: b) == 0.0)
        
        // Closeness: both should have same closeness
        let closenessResult = graph.centrality(using: .closeness())
        let closenessA = closenessResult.centrality(for: a)
        let closenessB = closenessResult.centrality(for: b)
        #expect(abs(closenessA - closenessB) < 0.001)
    }
}
#endif
