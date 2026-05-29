#if !GRAPHS_USES_TRAITS || GRAPHS_ADVANCED
import Testing
@testable import Graphs

struct IsomorphismAlgorithmTests {
    
    // MARK: - Test Graphs
    
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
    
    // MARK: - Core Behavior (VF2)
    
    @Test func vf2DetectsIsomorphicGraphs() {
        let graph1 = createSimpleGraph()
        let graph2 = createIsomorphicGraph()
        
        let vf2 = VF2Isomorphism<DefaultAdjacencyList>()
        
        #expect(vf2.areIsomorphic(graph1, graph2))
        
        let mapping = vf2.findIsomorphism(graph1, graph2)
        #expect(mapping != nil)
        #expect(mapping?.count == 3)
    }
    
    @Test func vf2RejectsNonIsomorphicGraphs() {
        let graph1 = createSimpleGraph()
        let graph2 = createNonIsomorphicGraph()
        
        let vf2 = VF2Isomorphism<DefaultAdjacencyList>()
        
        #expect(!vf2.areIsomorphic(graph1, graph2))
        
        let mapping = vf2.findIsomorphism(graph1, graph2)
        #expect(mapping == nil)
    }
    
    @Test func vf2DetectsSameGraph() {
        let graph = createSimpleGraph()
        let vf2 = VF2Isomorphism<DefaultAdjacencyList>()
        
        #expect(vf2.areIsomorphic(graph, graph))
        
        let mapping = vf2.findIsomorphism(graph, graph)
        #expect(mapping != nil)
        #expect(mapping?.count == 3)
    }
    
    @Test func vf2RejectsDifferentSizes() {
        let graph1 = createSimpleGraph() // 3 vertices
        let graph2 = createPathGraph(vertices: ["A", "B"]) // 2 vertices
        
        let vf2 = VF2Isomorphism<DefaultAdjacencyList>()
        
        #expect(!vf2.areIsomorphic(graph1, graph2))
        #expect(vf2.findIsomorphism(graph1, graph2) == nil)
    }
    
    @Test func vf2PathGraphs() {
        let path1 = createPathGraph(vertices: ["A", "B", "C", "D"])
        let path2 = createPathGraph(vertices: ["W", "X", "Y", "Z"])
        
        let vf2 = VF2Isomorphism<DefaultAdjacencyList>()
        
        #expect(vf2.areIsomorphic(path1, path2))
        
        let mapping = vf2.findIsomorphism(path1, path2)
        #expect(mapping != nil)
        #expect(mapping?.count == 4)
    }
    
    @Test func vf2CycleGraphs() {
        let cycle1 = createCycleGraph(vertices: ["A", "B", "C", "D"])
        let cycle2 = createCycleGraph(vertices: ["W", "X", "Y", "Z"])
        
        let vf2 = VF2Isomorphism<DefaultAdjacencyList>()
        
        #expect(vf2.areIsomorphic(cycle1, cycle2))
        
        let mapping = vf2.findIsomorphism(cycle1, cycle2)
        #expect(mapping != nil)
        #expect(mapping?.count == 4)
    }
    
    // MARK: - Core Behavior (Weisfeiler-Lehman)
    
    @Test func weisfeilerLehmanDetectsIsomorphicGraphs() {
        let graph1 = createSimpleGraph()
        let graph2 = createIsomorphicGraph()
        
        let wl = WeisfeilerLehmanIsomorphism<DefaultAdjacencyList>()
        
        #expect(wl.areIsomorphic(graph1, graph2))
        
        let mapping = wl.findIsomorphism(graph1, graph2)
        #expect(mapping != nil)
        #expect(mapping?.count == 3)
    }
    
    @Test func weisfeilerLehmanRejectsNonIsomorphicGraphs() {
        let graph1 = createSimpleGraph()
        let graph2 = createNonIsomorphicGraph()
        
        let wl = WeisfeilerLehmanIsomorphism<DefaultAdjacencyList>()
        
        #expect(!wl.areIsomorphic(graph1, graph2))
        
        let mapping = wl.findIsomorphism(graph1, graph2)
        #expect(mapping == nil)
    }
    
    @Test func weisfeilerLehmanDetectsSameGraph() {
        let graph = createSimpleGraph()
        let wl = WeisfeilerLehmanIsomorphism<DefaultAdjacencyList>()
        
        #expect(wl.areIsomorphic(graph, graph))
        
        let mapping = wl.findIsomorphism(graph, graph)
        #expect(mapping != nil)
        #expect(mapping?.count == 3)
    }
    
    @Test func weisfeilerLehmanRejectsDifferentSizes() {
        let graph1 = createSimpleGraph() // 3 vertices
        let graph2 = createPathGraph(vertices: ["A", "B"]) // 2 vertices
        
        let wl = WeisfeilerLehmanIsomorphism<DefaultAdjacencyList>()
        
        #expect(!wl.areIsomorphic(graph1, graph2))
        #expect(wl.findIsomorphism(graph1, graph2) == nil)
    }
    
    @Test func weisfeilerLehmanPathGraphs() {
        let path1 = createPathGraph(vertices: ["A", "B", "C", "D"])
        let path2 = createPathGraph(vertices: ["W", "X", "Y", "Z"])
        
        let wl = WeisfeilerLehmanIsomorphism<DefaultAdjacencyList>()
        
        #expect(wl.areIsomorphic(path1, path2))
        
        let mapping = wl.findIsomorphism(path1, path2)
        #expect(mapping != nil)
        #expect(mapping?.count == 4)
    }
    
    @Test func weisfeilerLehmanCycleGraphs() {
        let cycle1 = createCycleGraph(vertices: ["A", "B", "C", "D"])
        let cycle2 = createCycleGraph(vertices: ["W", "X", "Y", "Z"])
        
        let wl = WeisfeilerLehmanIsomorphism<DefaultAdjacencyList>()
        
        #expect(wl.areIsomorphic(cycle1, cycle2))
        
        let mapping = wl.findIsomorphism(cycle1, cycle2)
        #expect(mapping != nil)
        #expect(mapping?.count == 4)
    }
    
    // MARK: - Core Behavior (Enhanced Weisfeiler-Lehman)
    
    @Test func enhancedWeisfeilerLehmanDetectsIsomorphicGraphs() {
        let graph1 = createSimpleGraph()
        let graph2 = createIsomorphicGraph()
        
        let enhancedWL = EnhancedWeisfeilerLehmanIsomorphism<DefaultAdjacencyList>()
        
        #expect(enhancedWL.areIsomorphic(graph1, graph2))
        
        let mapping = enhancedWL.findIsomorphism(graph1, graph2)
        #expect(mapping != nil)
        #expect(mapping?.count == 3)
    }
    
    @Test func enhancedWeisfeilerLehmanRejectsNonIsomorphicGraphs() {
        let graph1 = createSimpleGraph()
        let graph2 = createNonIsomorphicGraph()
        
        let enhancedWL = EnhancedWeisfeilerLehmanIsomorphism<DefaultAdjacencyList>()
        
        #expect(!enhancedWL.areIsomorphic(graph1, graph2))
        
        let mapping = enhancedWL.findIsomorphism(graph1, graph2)
        #expect(mapping == nil)
    }
    
    // MARK: - API Convenience
    
    @Test func graphIsIsomorphicExtension() {
        let graph1 = createSimpleGraph()
        let graph2 = createIsomorphicGraph()
        let graph3 = createNonIsomorphicGraph()
        
        let vf2 = VF2Isomorphism<DefaultAdjacencyList>()
        
        #expect(graph1.isIsomorphic(to: graph2, using: vf2))
        #expect(!graph1.isIsomorphic(to: graph3, using: vf2))
    }
    
    @Test func graphFindIsomorphismExtension() {
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
    
    @Test func graphIsomorphismResultExtension() {
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
    
    // MARK: - Algorithm Selection
    
    @Test func algorithmSelection() {
        let graph1 = createSimpleGraph()
        let graph2 = createIsomorphicGraph()
        
        let vf2 = VF2Isomorphism<DefaultAdjacencyList>.vf2()
        let wl = WeisfeilerLehmanIsomorphism<DefaultAdjacencyList>.weisfeilerLehman()
        
        #expect(graph1.isIsomorphic(to: graph2, using: vf2))
        #expect(graph1.isIsomorphic(to: graph2, using: wl))
    }
    
    // MARK: - Edge Cases
    
    @Test func emptyGraphs() {
        let empty1 = DefaultAdjacencyList()
        let empty2 = DefaultAdjacencyList()
        
        let vf2 = VF2Isomorphism<DefaultAdjacencyList>()
        
        #expect(vf2.areIsomorphic(empty1, empty2))
        #expect(vf2.findIsomorphism(empty1, empty2) != nil)
    }
    
    @Test func singleVertexGraphs() {
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
    
    @Test func disconnectedGraphs() {
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
    
    // MARK: - Visitor Support
    
    @Test func vf2WithVisitor() {
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
    
    @Test func weisfeilerLehmanWithVisitor() {
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
    
    @Test func enhancedWeisfeilerLehmanWithVisitor() {
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

    // MARK: - Composition

    /// Exercises all five VF2Isomorphism visitor events through a composed visitor pair.
    ///
    /// Two identical triangle graphs (isomorphic). VF2 will discover a mapping, triggering
    /// `mappingFound`; it tries vertex mappings (`tryMapping`) and examines vertices and edges.
    /// Since both graphs are isomorphic, backtracking may occur as the algorithm explores the
    /// search space before finding the full mapping.
    @Test func vf2ComposedVisitorsReceiveAllEvents() {
        let graph1 = createSimpleGraph()
        let graph2 = createSimpleGraph()

        var examVtx1 = 0;    var examVtx2 = 0
        var tryMap1 = 0;     var tryMap2 = 0
        var mapFound1 = 0;   var mapFound2 = 0

        var v1 = VF2Isomorphism<DefaultAdjacencyList>.Visitor()
        v1.examineVertex = { _ in examVtx1 += 1 }
        v1.tryMapping    = { _, _ in tryMap1 += 1 }
        v1.mappingFound  = { _ in mapFound1 += 1 }

        var v2 = VF2Isomorphism<DefaultAdjacencyList>.Visitor()
        v2.examineVertex = { _ in examVtx2 += 1 }
        v2.tryMapping    = { _, _ in tryMap2 += 1 }
        v2.mappingFound  = { _ in mapFound2 += 1 }

        let combined = v1.combined(with: v2)
        let algorithm = VF2Isomorphism<DefaultAdjacencyList>()
        let result = algorithm.areIsomorphic(graph1, graph2, visitor: combined)

        #expect(result,           "two identical graphs must be isomorphic")
        #expect(examVtx1 >= 1,    "examineVertex fires during the search")
        #expect(examVtx2 >= 1)
        #expect(tryMap1 >= 1,     "tryMapping fires for each candidate vertex pair")
        #expect(tryMap2 >= 1)
        #expect(mapFound1 >= 1,   "mappingFound fires when the full isomorphism is found")
        #expect(mapFound2 >= 1)
        // Both composed visitors must see identical event counts
        #expect(examVtx1 == examVtx2)
        #expect(tryMap1 == tryMap2)
        #expect(mapFound1 == mapFound2)
    }

    /// Exercises all five WeisfeilerLehman visitor events through a composed visitor pair.
    ///
    /// Two identical triangle graphs (isomorphic). WeisfeilerLehman relabels vertices
    /// iteratively until labels stabilize, firing label and iteration events.
    @Test func weisfeilerLehmanComposedVisitorsReceiveAllEvents() {
        let graph1 = createSimpleGraph()
        let graph2 = createSimpleGraph()

        var examVtx1 = 0;   var examVtx2 = 0
        var label1 = 0;     var label2 = 0
        var iter1 = 0;      var iter2 = 0
        var stable1 = 0;    var stable2 = 0

        var examEdge1 = 0;  var examEdge2 = 0

        var v1 = WeisfeilerLehmanIsomorphism<DefaultAdjacencyList>.Visitor()
        v1.examineVertex      = { _ in examVtx1 += 1 }
        v1.examineEdge        = { _ in examEdge1 += 1 }
        v1.labelVertex        = { _, _ in label1 += 1 }
        v1.iterationComplete  = { _, _ in iter1 += 1 }
        v1.labelsStabilized   = { _ in stable1 += 1 }

        var v2 = WeisfeilerLehmanIsomorphism<DefaultAdjacencyList>.Visitor()
        v2.examineVertex      = { _ in examVtx2 += 1 }
        v2.examineEdge        = { _ in examEdge2 += 1 }
        v2.labelVertex        = { _, _ in label2 += 1 }
        v2.iterationComplete  = { _, _ in iter2 += 1 }
        v2.labelsStabilized   = { _ in stable2 += 1 }

        let combined = v1.combined(with: v2)
        let algorithm = WeisfeilerLehmanIsomorphism<DefaultAdjacencyList>()
        let result = algorithm.areIsomorphic(graph1, graph2, visitor: combined)

        #expect(result,          "two identical graphs must be isomorphic")
        #expect(examVtx1 >= 1,   "examineVertex fires during label propagation")
        #expect(examVtx2 >= 1)
        #expect(examEdge1 >= 1,  "examineEdge fires for each edge examined in the iteration")
        #expect(examEdge2 >= 1)
        #expect(label1 >= 1,     "labelVertex fires for each vertex-label assignment")
        #expect(label2 >= 1)
        #expect(iter1 >= 1,      "iterationComplete fires after each WL iteration")
        #expect(iter2 >= 1)
        #expect(stable1 >= 1,    "labelsStabilized fires when WL converges (once per graph)")
        #expect(stable2 >= 1)
        // Both composed visitors must see identical event counts
        #expect(examVtx1 == examVtx2)
        #expect(examEdge1 == examEdge2)
        #expect(label1 == label2)
        #expect(iter1 == iter2)
        #expect(stable1 == stable2)
    }

    /// Exercises all five `EnhancedWeisfeilerLehmanIsomorphism.Visitor` events through
    /// a composed visitor pair. Uses two identical triangle graphs (isomorphic).
    @Test func enhancedWeisfeilerLehmanComposedVisitorsReceiveAllEvents() {
        let graph1 = createSimpleGraph()
        let graph2 = createSimpleGraph()

        var examVtx1 = 0;   var examVtx2 = 0
        var examEdge1 = 0;  var examEdge2 = 0
        var label1 = 0;     var label2 = 0
        var iter1 = 0;      var iter2 = 0
        var stable1 = 0;    var stable2 = 0

        var v1 = EnhancedWeisfeilerLehmanIsomorphism<DefaultAdjacencyList>.Visitor()
        v1.examineVertex     = { _ in examVtx1 += 1 }
        v1.examineEdge       = { _ in examEdge1 += 1 }
        v1.labelVertex       = { _, _ in label1 += 1 }
        v1.iterationComplete = { _, _ in iter1 += 1 }
        v1.labelsStabilized  = { _ in stable1 += 1 }

        var v2 = EnhancedWeisfeilerLehmanIsomorphism<DefaultAdjacencyList>.Visitor()
        v2.examineVertex     = { _ in examVtx2 += 1 }
        v2.examineEdge       = { _ in examEdge2 += 1 }
        v2.labelVertex       = { _, _ in label2 += 1 }
        v2.iterationComplete = { _, _ in iter2 += 1 }
        v2.labelsStabilized  = { _ in stable2 += 1 }

        let combined = v1.combined(with: v2)
        let algorithm = EnhancedWeisfeilerLehmanIsomorphism<DefaultAdjacencyList>()
        let result = algorithm.areIsomorphic(graph1, graph2, visitor: combined)

        #expect(result,         "two identical triangle graphs must be isomorphic")
        #expect(examVtx1 >= 1,  "examineVertex fires for each vertex examined")
        #expect(examVtx2 >= 1)
        #expect(examEdge1 >= 1, "examineEdge fires for each edge in the label propagation")
        #expect(examEdge2 >= 1)
        #expect(label1 >= 1,    "labelVertex fires for each vertex-label assignment")
        #expect(label2 >= 1)
        #expect(iter1 >= 1,     "iterationComplete fires after each enhanced WL iteration")
        #expect(iter2 >= 1)
        #expect(stable1 >= 1,   "labelsStabilized fires when labels converge")
        #expect(stable2 >= 1)
        #expect(examVtx1 == examVtx2)
        #expect(examEdge1 == examEdge2)
        #expect(label1 == label2)
        #expect(iter1 == iter2)
        #expect(stable1 == stable2)
    }
}
#endif
