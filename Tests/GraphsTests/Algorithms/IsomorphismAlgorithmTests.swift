import Testing
@testable import Graphs

struct IsomorphismAlgorithmTests {
    
    // MARK: - Test Data
    
    func createSimpleGraph() -> DefaultAdjacencyList {
        var graph = DefaultAdjacencyList()
        let a = graph.addVertex { $0.label = "A" }
        let b = graph.addVertex { $0.label = "B" }
        let c = graph.addVertex { $0.label = "C" }
        
        graph.addEdge(from: a, to: b)
        graph.addEdge(from: b, to: c)
        graph.addEdge(from: c, to: a)
        
        return graph
    }
    
    func createIsomorphicGraph() -> DefaultAdjacencyList {
        var graph = DefaultAdjacencyList()
        let x = graph.addVertex { $0.label = "X" }
        let y = graph.addVertex { $0.label = "Y" }
        let z = graph.addVertex { $0.label = "Z" }
        
        graph.addEdge(from: x, to: y)
        graph.addEdge(from: y, to: z)
        graph.addEdge(from: z, to: x)
        
        return graph
    }
    
    func createNonIsomorphicGraph() -> DefaultAdjacencyList {
        var graph = DefaultAdjacencyList()
        let p = graph.addVertex { $0.label = "P" }
        let q = graph.addVertex { $0.label = "Q" }
        let r = graph.addVertex { $0.label = "R" }
        
        graph.addEdge(from: p, to: q)
        graph.addEdge(from: q, to: r)
        // Missing the third edge to make it non-isomorphic
        
        return graph
    }
    
    func createPathGraph(vertices: [String]) -> DefaultAdjacencyList {
        var graph = DefaultAdjacencyList()
        let vertexDescriptors = vertices.map { label in graph.addVertex { $0.label = label } }
        
        for i in 0..<(vertexDescriptors.count - 1) {
            graph.addEdge(from: vertexDescriptors[i], to: vertexDescriptors[i + 1])
        }
        
        return graph
    }
    
    func createCycleGraph(vertices: [String]) -> DefaultAdjacencyList {
        var graph = DefaultAdjacencyList()
        let vertexDescriptors = vertices.map { label in graph.addVertex { $0.label = label } }
        
        for i in 0..<vertexDescriptors.count {
            let next = (i + 1) % vertexDescriptors.count
            graph.addEdge(from: vertexDescriptors[i], to: vertexDescriptors[next])
        }
        
        return graph
    }
    
    // MARK: - VF2 Algorithm Tests
    
    @Test func testVF2IsomorphicGraphs() {
        let graph1 = createSimpleGraph()
        let graph2 = createIsomorphicGraph()
        
        let vf2 = VF2Isomorphism<DefaultAdjacencyList>()
        
        #expect(vf2.areIsomorphic(graph1, graph2))
        
        let mapping = vf2.findIsomorphism(graph1, graph2)
        #expect(mapping != nil)
        #expect(mapping?.count == 3)
    }
    
    @Test func testVF2NonIsomorphicGraphs() {
        let graph1 = createSimpleGraph()
        let graph2 = createNonIsomorphicGraph()
        
        let vf2 = VF2Isomorphism<DefaultAdjacencyList>()
        
        #expect(!vf2.areIsomorphic(graph1, graph2))
        
        let mapping = vf2.findIsomorphism(graph1, graph2)
        #expect(mapping == nil)
    }
    
    @Test func testVF2SameGraph() {
        let graph = createSimpleGraph()
        let vf2 = VF2Isomorphism<DefaultAdjacencyList>()
        
        #expect(vf2.areIsomorphic(graph, graph))
        
        let mapping = vf2.findIsomorphism(graph, graph)
        #expect(mapping != nil)
        #expect(mapping?.count == 3)
    }
    
    @Test func testVF2DifferentSizes() {
        let graph1 = createSimpleGraph() // 3 vertices
        let graph2 = createPathGraph(vertices: ["A", "B"]) // 2 vertices
        
        let vf2 = VF2Isomorphism<DefaultAdjacencyList>()
        
        #expect(!vf2.areIsomorphic(graph1, graph2))
        #expect(vf2.findIsomorphism(graph1, graph2) == nil)
    }
    
    @Test func testVF2PathGraphs() {
        let path1 = createPathGraph(vertices: ["A", "B", "C", "D"])
        let path2 = createPathGraph(vertices: ["W", "X", "Y", "Z"])
        
        let vf2 = VF2Isomorphism<DefaultAdjacencyList>()
        
        #expect(vf2.areIsomorphic(path1, path2))
        
        let mapping = vf2.findIsomorphism(path1, path2)
        #expect(mapping != nil)
        #expect(mapping?.count == 4)
    }
    
    @Test func testVF2CycleGraphs() {
        let cycle1 = createCycleGraph(vertices: ["A", "B", "C", "D"])
        let cycle2 = createCycleGraph(vertices: ["W", "X", "Y", "Z"])
        
        let vf2 = VF2Isomorphism<DefaultAdjacencyList>()
        
        #expect(vf2.areIsomorphic(cycle1, cycle2))
        
        let mapping = vf2.findIsomorphism(cycle1, cycle2)
        #expect(mapping != nil)
        #expect(mapping?.count == 4)
    }
    
    // MARK: - Weisfeiler-Lehman Algorithm Tests
    
    @Test func testWeisfeilerLehmanIsomorphicGraphs() {
        let graph1 = createSimpleGraph()
        let graph2 = createIsomorphicGraph()
        
        let wl = WeisfeilerLehmanIsomorphism<DefaultAdjacencyList>()
        
        #expect(wl.areIsomorphic(graph1, graph2))
        
        let mapping = wl.findIsomorphism(graph1, graph2)
        #expect(mapping != nil)
        #expect(mapping?.count == 3)
    }
    
    @Test func testWeisfeilerLehmanNonIsomorphicGraphs() {
        let graph1 = createSimpleGraph()
        let graph2 = createNonIsomorphicGraph()
        
        let wl = WeisfeilerLehmanIsomorphism<DefaultAdjacencyList>()
        
        #expect(!wl.areIsomorphic(graph1, graph2))
        
        let mapping = wl.findIsomorphism(graph1, graph2)
        #expect(mapping == nil)
    }
    
    @Test func testWeisfeilerLehmanSameGraph() {
        let graph = createSimpleGraph()
        let wl = WeisfeilerLehmanIsomorphism<DefaultAdjacencyList>()
        
        #expect(wl.areIsomorphic(graph, graph))
        
        let mapping = wl.findIsomorphism(graph, graph)
        #expect(mapping != nil)
        #expect(mapping?.count == 3)
    }
    
    @Test func testWeisfeilerLehmanDifferentSizes() {
        let graph1 = createSimpleGraph() // 3 vertices
        let graph2 = createPathGraph(vertices: ["A", "B"]) // 2 vertices
        
        let wl = WeisfeilerLehmanIsomorphism<DefaultAdjacencyList>()
        
        #expect(!wl.areIsomorphic(graph1, graph2))
        #expect(wl.findIsomorphism(graph1, graph2) == nil)
    }
    
    @Test func testWeisfeilerLehmanPathGraphs() {
        let path1 = createPathGraph(vertices: ["A", "B", "C", "D"])
        let path2 = createPathGraph(vertices: ["W", "X", "Y", "Z"])
        
        let wl = WeisfeilerLehmanIsomorphism<DefaultAdjacencyList>()
        
        #expect(wl.areIsomorphic(path1, path2))
        
        let mapping = wl.findIsomorphism(path1, path2)
        #expect(mapping != nil)
        #expect(mapping?.count == 4)
    }
    
    @Test func testWeisfeilerLehmanCycleGraphs() {
        let cycle1 = createCycleGraph(vertices: ["A", "B", "C", "D"])
        let cycle2 = createCycleGraph(vertices: ["W", "X", "Y", "Z"])
        
        let wl = WeisfeilerLehmanIsomorphism<DefaultAdjacencyList>()
        
        #expect(wl.areIsomorphic(cycle1, cycle2))
        
        let mapping = wl.findIsomorphism(cycle1, cycle2)
        #expect(mapping != nil)
        #expect(mapping?.count == 4)
    }
    
    // MARK: - Enhanced Weisfeiler-Lehman Algorithm Tests
    
    @Test func testEnhancedWeisfeilerLehmanIsomorphicGraphs() {
        let graph1 = createSimpleGraph()
        let graph2 = createIsomorphicGraph()
        
        let enhancedWL = EnhancedWeisfeilerLehmanIsomorphism<DefaultAdjacencyList>()
        
        #expect(enhancedWL.areIsomorphic(graph1, graph2))
        
        let mapping = enhancedWL.findIsomorphism(graph1, graph2)
        #expect(mapping != nil)
        #expect(mapping?.count == 3)
    }
    
    @Test func testEnhancedWeisfeilerLehmanNonIsomorphicGraphs() {
        let graph1 = createSimpleGraph()
        let graph2 = createNonIsomorphicGraph()
        
        let enhancedWL = EnhancedWeisfeilerLehmanIsomorphism<DefaultAdjacencyList>()
        
        #expect(!enhancedWL.areIsomorphic(graph1, graph2))
        
        let mapping = enhancedWL.findIsomorphism(graph1, graph2)
        #expect(mapping == nil)
    }
    
    // MARK: - Graph Extension Tests
    
    @Test func testGraphIsIsomorphicExtension() {
        let graph1 = createSimpleGraph()
        let graph2 = createIsomorphicGraph()
        let graph3 = createNonIsomorphicGraph()
        
        let vf2 = VF2Isomorphism<DefaultAdjacencyList>()
        
        #expect(graph1.isIsomorphic(to: graph2, using: vf2))
        #expect(!graph1.isIsomorphic(to: graph3, using: vf2))
    }
    
    @Test func testGraphFindIsomorphismExtension() {
        let graph1 = createSimpleGraph()
        let graph2 = createIsomorphicGraph()
        let graph3 = createNonIsomorphicGraph()
        
        let vf2 = VF2Isomorphism<DefaultAdjacencyList>()
        
        let mapping1 = graph1.findIsomorphism(to: graph2, using: vf2)
        #expect(mapping1 != nil)
        #expect(mapping1?.count == 3)
        
        let mapping2 = graph1.findIsomorphism(to: graph3, using: vf2)
        #expect(mapping2 == nil)
    }
    
    @Test func testGraphIsomorphismResultExtension() {
        let graph1 = createSimpleGraph()
        let graph2 = createIsomorphicGraph()
        let graph3 = createNonIsomorphicGraph()
        
        let vf2 = VF2Isomorphism<DefaultAdjacencyList>()
        
        let result1 = graph1.isomorphismResult(with: graph2, using: vf2)
        #expect(result1.isIsomorphic)
        #expect(result1.mapping != nil)
        #expect(result1.mapping?.count == 3)
        
        let result2 = graph1.isomorphismResult(with: graph3, using: vf2)
        #expect(!result2.isIsomorphic)
        #expect(result2.mapping == nil)
    }
    
    // MARK: - Algorithm Selection Tests
    
    @Test func testAlgorithmSelection() {
        let graph1 = createSimpleGraph()
        let graph2 = createIsomorphicGraph()
        
        let vf2 = VF2Isomorphism<DefaultAdjacencyList>.vf2()
        let wl = WeisfeilerLehmanIsomorphism<DefaultAdjacencyList>.weisfeilerLehman()
        
        #expect(graph1.isIsomorphic(to: graph2, using: vf2))
        #expect(graph1.isIsomorphic(to: graph2, using: wl))
    }
    
    // MARK: - Edge Cases
    
    @Test func testEmptyGraphs() {
        let empty1 = DefaultAdjacencyList()
        let empty2 = DefaultAdjacencyList()
        
        let vf2 = VF2Isomorphism<DefaultAdjacencyList>()
        
        #expect(vf2.areIsomorphic(empty1, empty2))
        #expect(vf2.findIsomorphism(empty1, empty2) != nil)
    }
    
    @Test func testSingleVertexGraphs() {
        var graph1 = DefaultAdjacencyList()
        graph1.addVertex { $0.label = "A" }
        
        var graph2 = DefaultAdjacencyList()
        graph2.addVertex { $0.label = "B" }
        
        let vf2 = VF2Isomorphism<DefaultAdjacencyList>()
        
        #expect(vf2.areIsomorphic(graph1, graph2))
        let mapping = vf2.findIsomorphism(graph1, graph2)
        #expect(mapping != nil)
        #expect(mapping?.count == 1)
    }
    
    @Test func testDisconnectedGraphs() {
        var graph1 = DefaultAdjacencyList()
        let a1 = graph1.addVertex { $0.label = "A1" }
        let b1 = graph1.addVertex { $0.label = "B1" }
        let c1 = graph1.addVertex { $0.label = "C1" }
        let d1 = graph1.addVertex { $0.label = "D1" }
        
        graph1.addEdge(from: a1, to: b1)
        graph1.addEdge(from: c1, to: d1)
        
        var graph2 = DefaultAdjacencyList()
        let a2 = graph2.addVertex { $0.label = "A2" }
        let b2 = graph2.addVertex { $0.label = "B2" }
        let c2 = graph2.addVertex { $0.label = "C2" }
        let d2 = graph2.addVertex { $0.label = "D2" }
        
        graph2.addEdge(from: a2, to: b2)
        graph2.addEdge(from: c2, to: d2)
        
        let vf2 = VF2Isomorphism<DefaultAdjacencyList>()
        
        #expect(vf2.areIsomorphic(graph1, graph2))
        let mapping = vf2.findIsomorphism(graph1, graph2)
        #expect(mapping != nil)
        #expect(mapping?.count == 4)
    }
    
    // MARK: - withVisitor Pattern Tests
    
    @Test func testVF2WithVisitor() {
        let graph1 = createSimpleGraph()
        let graph2 = createSimpleGraph()
        
        var examinedVertices: [DefaultAdjacencyList.VertexDescriptor] = []
        var examinedEdges: [DefaultAdjacencyList.EdgeDescriptor] = []
        var tryMappings: [(DefaultAdjacencyList.VertexDescriptor, DefaultAdjacencyList.VertexDescriptor)] = []
        var mappingFound: [DefaultAdjacencyList.VertexDescriptor: DefaultAdjacencyList.VertexDescriptor]? = nil
        var backtracks: [(DefaultAdjacencyList.VertexDescriptor, DefaultAdjacencyList.VertexDescriptor)] = []
        
        let visitor = VF2Isomorphism<DefaultAdjacencyList>.Visitor(
            examineVertex: { vertex in
                examinedVertices.append(vertex)
            },
            examineEdge: { edge in
                examinedEdges.append(edge)
            },
            tryMapping: { v1, v2 in
                tryMappings.append((v1, v2))
            },
            mappingFound: { mapping in
                mappingFound = mapping
            },
            backtrack: { v1, v2 in
                backtracks.append((v1, v2))
            }
        )
        
        let algorithm = VF2Isomorphism<DefaultAdjacencyList>()
        let wrapper = algorithm.withVisitor(visitor)
        let result = wrapper.base.areIsomorphic(graph1, graph2, visitor: wrapper.visitor)
        
        #expect(result)
        #expect(!examinedVertices.isEmpty)
//        #expect(!examinedEdges.isEmpty)
        #expect(!tryMappings.isEmpty)
        #expect(mappingFound != nil)
    }
    
    @Test func testWeisfeilerLehmanWithVisitor() {
        let graph1 = createSimpleGraph()
        let graph2 = createSimpleGraph()
        
        var examinedVertices: [DefaultAdjacencyList.VertexDescriptor] = []
        var examinedEdges: [DefaultAdjacencyList.EdgeDescriptor] = []
        var labeledVertices: [(DefaultAdjacencyList.VertexDescriptor, Int)] = []
        var iterations: [(Int, [DefaultAdjacencyList.VertexDescriptor: Int])] = []
        var stabilized: [DefaultAdjacencyList.VertexDescriptor: Int]? = nil
        
        let visitor = WeisfeilerLehmanIsomorphism<DefaultAdjacencyList>.Visitor(
            examineVertex: { vertex in
                examinedVertices.append(vertex)
            },
            examineEdge: { edge in
                examinedEdges.append(edge)
            },
            labelVertex: { vertex, label in
                labeledVertices.append((vertex, label))
            },
            iterationComplete: { iteration, labels in
                iterations.append((iteration, labels))
            },
            labelsStabilized: { labels in
                stabilized = labels
            }
        )
        
        let algorithm = WeisfeilerLehmanIsomorphism<DefaultAdjacencyList>()
        let result = algorithm.areIsomorphic(graph1, graph2, visitor: visitor)
        
        #expect(result)
        #expect(!examinedVertices.isEmpty)
        #expect(!examinedEdges.isEmpty)
        #expect(!labeledVertices.isEmpty)
        #expect(!iterations.isEmpty)
        #expect(stabilized != nil)
    }
    
    @Test func testEnhancedWeisfeilerLehmanWithVisitor() {
        let graph1 = createSimpleGraph()
        let graph2 = createSimpleGraph()
        
        var examinedVertices: [DefaultAdjacencyList.VertexDescriptor] = []
        var examinedEdges: [DefaultAdjacencyList.EdgeDescriptor] = []
        var labeledVertices: [(DefaultAdjacencyList.VertexDescriptor, Int)] = []
        var iterations: [(Int, [DefaultAdjacencyList.VertexDescriptor: Int])] = []
        var stabilized: [DefaultAdjacencyList.VertexDescriptor: Int]? = nil
        
        let visitor = EnhancedWeisfeilerLehmanIsomorphism<DefaultAdjacencyList>.Visitor(
            examineVertex: { vertex in
                examinedVertices.append(vertex)
            },
            examineEdge: { edge in
                examinedEdges.append(edge)
            },
            labelVertex: { vertex, label in
                labeledVertices.append((vertex, label))
            },
            iterationComplete: { iteration, labels in
                iterations.append((iteration, labels))
            },
            labelsStabilized: { labels in
                stabilized = labels
            }
        )
        
        let algorithm = EnhancedWeisfeilerLehmanIsomorphism<DefaultAdjacencyList>()
        let result = algorithm.areIsomorphic(graph1, graph2, visitor: visitor)
        
        #expect(result)
        #expect(!examinedVertices.isEmpty)
        #expect(!examinedEdges.isEmpty)
        #expect(!labeledVertices.isEmpty)
        #expect(!iterations.isEmpty)
        #expect(stabilized != nil)
    }
}
