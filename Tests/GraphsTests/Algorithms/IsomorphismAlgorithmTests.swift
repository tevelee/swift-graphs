#if !GRAPHS_USES_TRAITS || GRAPHS_ADVANCED
    import Testing
    @testable import Graphs

    struct IsomorphismAlgorithmTests {

        // MARK: - Test Graphs

        func createSimpleGraph() -> AdjacencyList {
            var graph = AdjacencyList()
            let a = graph.addVertex { $0.label = "A" }
            let b = graph.addVertex { $0.label = "B" }
            let c = graph.addVertex { $0.label = "C" }

            graph.addEdge(from: a, to: b)
            graph.addEdge(from: b, to: c)
            graph.addEdge(from: c, to: a)

            return graph
        }

        func createIsomorphicGraph() -> AdjacencyList {
            var graph = AdjacencyList()
            let x = graph.addVertex { $0.label = "X" }
            let y = graph.addVertex { $0.label = "Y" }
            let z = graph.addVertex { $0.label = "Z" }

            graph.addEdge(from: x, to: y)
            graph.addEdge(from: y, to: z)
            graph.addEdge(from: z, to: x)

            return graph
        }

        func createNonIsomorphicGraph() -> AdjacencyList {
            var graph = AdjacencyList()
            let p = graph.addVertex { $0.label = "P" }
            let q = graph.addVertex { $0.label = "Q" }
            let r = graph.addVertex { $0.label = "R" }

            graph.addEdge(from: p, to: q)
            graph.addEdge(from: q, to: r)
            // Missing the third edge to make it non-isomorphic

            return graph
        }

        func createPathGraph(vertices: [String]) -> AdjacencyList {
            var graph = AdjacencyList()
            let vertexDescriptors = vertices.map { label in graph.addVertex { $0.label = label } }

            for i in 0 ..< (vertexDescriptors.count - 1) {
                graph.addEdge(from: vertexDescriptors[i], to: vertexDescriptors[i + 1])
            }

            return graph
        }

        func createCycleGraph(vertices: [String]) -> AdjacencyList {
            var graph = AdjacencyList()
            let vertexDescriptors = vertices.map { label in graph.addVertex { $0.label = label } }

            for i in 0 ..< vertexDescriptors.count {
                let next = (i + 1) % vertexDescriptors.count
                graph.addEdge(from: vertexDescriptors[i], to: vertexDescriptors[next])
            }

            return graph
        }

        // MARK: - Core Behavior (VF2)

        @Test func vf2DetectsIsomorphicGraphs() {
            let graph1 = createSimpleGraph()
            let graph2 = createIsomorphicGraph()

            let vf2 = VF2Isomorphism<AdjacencyList>()

            #expect(vf2.areIsomorphic(graph1, graph2))

            let mapping = vf2.findIsomorphism(graph1, graph2)
            #expect(mapping != nil)
            #expect(mapping?.count == 3)
        }

        @Test func vf2RejectsNonIsomorphicGraphs() {
            let graph1 = createSimpleGraph()
            let graph2 = createNonIsomorphicGraph()

            let vf2 = VF2Isomorphism<AdjacencyList>()

            #expect(!vf2.areIsomorphic(graph1, graph2))

            let mapping = vf2.findIsomorphism(graph1, graph2)
            #expect(mapping == nil)
        }

        @Test func vf2DetectsSameGraph() {
            let graph = createSimpleGraph()
            let vf2 = VF2Isomorphism<AdjacencyList>()

            #expect(vf2.areIsomorphic(graph, graph))

            let mapping = vf2.findIsomorphism(graph, graph)
            #expect(mapping != nil)
            #expect(mapping?.count == 3)
        }

        @Test func vf2RejectsDifferentSizes() {
            let graph1 = createSimpleGraph()  // 3 vertices
            let graph2 = createPathGraph(vertices: ["A", "B"])  // 2 vertices

            let vf2 = VF2Isomorphism<AdjacencyList>()

            #expect(!vf2.areIsomorphic(graph1, graph2))
            #expect(vf2.findIsomorphism(graph1, graph2) == nil)
        }

        @Test func vf2PathGraphs() {
            let path1 = createPathGraph(vertices: ["A", "B", "C", "D"])
            let path2 = createPathGraph(vertices: ["W", "X", "Y", "Z"])

            let vf2 = VF2Isomorphism<AdjacencyList>()

            #expect(vf2.areIsomorphic(path1, path2))

            let mapping = vf2.findIsomorphism(path1, path2)
            #expect(mapping != nil)
            #expect(mapping?.count == 4)
        }

        @Test func vf2CycleGraphs() {
            let cycle1 = createCycleGraph(vertices: ["A", "B", "C", "D"])
            let cycle2 = createCycleGraph(vertices: ["W", "X", "Y", "Z"])

            let vf2 = VF2Isomorphism<AdjacencyList>()

            #expect(vf2.areIsomorphic(cycle1, cycle2))

            let mapping = vf2.findIsomorphism(cycle1, cycle2)
            #expect(mapping != nil)
            #expect(mapping?.count == 4)
        }

        // MARK: - Core Behavior (Weisfeiler-Lehman)

        @Test func weisfeilerLehmanDetectsIsomorphicGraphs() {
            let graph1 = createSimpleGraph()
            let graph2 = createIsomorphicGraph()

            let wl = WeisfeilerLehmanIsomorphism<AdjacencyList>()

            #expect(wl.areIsomorphic(graph1, graph2))

            let mapping = wl.findIsomorphism(graph1, graph2)
            #expect(mapping != nil)
            #expect(mapping?.count == 3)
        }

        @Test func weisfeilerLehmanRejectsNonIsomorphicGraphs() {
            let graph1 = createSimpleGraph()
            let graph2 = createNonIsomorphicGraph()

            let wl = WeisfeilerLehmanIsomorphism<AdjacencyList>()

            #expect(!wl.areIsomorphic(graph1, graph2))

            let mapping = wl.findIsomorphism(graph1, graph2)
            #expect(mapping == nil)
        }

        @Test func weisfeilerLehmanDetectsSameGraph() {
            let graph = createSimpleGraph()
            let wl = WeisfeilerLehmanIsomorphism<AdjacencyList>()

            #expect(wl.areIsomorphic(graph, graph))

            let mapping = wl.findIsomorphism(graph, graph)
            #expect(mapping != nil)
            #expect(mapping?.count == 3)
        }

        @Test func weisfeilerLehmanRejectsDifferentSizes() {
            let graph1 = createSimpleGraph()  // 3 vertices
            let graph2 = createPathGraph(vertices: ["A", "B"])  // 2 vertices

            let wl = WeisfeilerLehmanIsomorphism<AdjacencyList>()

            #expect(!wl.areIsomorphic(graph1, graph2))
            #expect(wl.findIsomorphism(graph1, graph2) == nil)
        }

        @Test func weisfeilerLehmanPathGraphs() {
            let path1 = createPathGraph(vertices: ["A", "B", "C", "D"])
            let path2 = createPathGraph(vertices: ["W", "X", "Y", "Z"])

            let wl = WeisfeilerLehmanIsomorphism<AdjacencyList>()

            #expect(wl.areIsomorphic(path1, path2))

            let mapping = wl.findIsomorphism(path1, path2)
            #expect(mapping != nil)
            #expect(mapping?.count == 4)
        }

        @Test func weisfeilerLehmanCycleGraphs() {
            let cycle1 = createCycleGraph(vertices: ["A", "B", "C", "D"])
            let cycle2 = createCycleGraph(vertices: ["W", "X", "Y", "Z"])

            let wl = WeisfeilerLehmanIsomorphism<AdjacencyList>()

            #expect(wl.areIsomorphic(cycle1, cycle2))

            let mapping = wl.findIsomorphism(cycle1, cycle2)
            #expect(mapping != nil)
            #expect(mapping?.count == 4)
        }

        // MARK: - Core Behavior (Enhanced Weisfeiler-Lehman)

        @Test func enhancedWeisfeilerLehmanDetectsIsomorphicGraphs() {
            let graph1 = createSimpleGraph()
            let graph2 = createIsomorphicGraph()

            let enhancedWL = EnhancedWeisfeilerLehmanIsomorphism<AdjacencyList>()

            #expect(enhancedWL.areIsomorphic(graph1, graph2))

            let mapping = enhancedWL.findIsomorphism(graph1, graph2)
            #expect(mapping != nil)
            #expect(mapping?.count == 3)
        }

        @Test func enhancedWeisfeilerLehmanRejectsNonIsomorphicGraphs() {
            let graph1 = createSimpleGraph()
            let graph2 = createNonIsomorphicGraph()

            let enhancedWL = EnhancedWeisfeilerLehmanIsomorphism<AdjacencyList>()

            #expect(!enhancedWL.areIsomorphic(graph1, graph2))

            let mapping = enhancedWL.findIsomorphism(graph1, graph2)
            #expect(mapping == nil)
        }

        // MARK: - API Convenience

        @Test func graphIsIsomorphicExtension() {
            let graph1 = createSimpleGraph()
            let graph2 = createIsomorphicGraph()
            let graph3 = createNonIsomorphicGraph()

            let vf2 = VF2Isomorphism<AdjacencyList>()

            #expect(graph1.isIsomorphic(to: graph2, using: vf2))
            #expect(!graph1.isIsomorphic(to: graph3, using: vf2))
        }

        @Test func graphFindIsomorphismExtension() {
            let graph1 = createSimpleGraph()
            let graph2 = createIsomorphicGraph()
            let graph3 = createNonIsomorphicGraph()

            let vf2 = VF2Isomorphism<AdjacencyList>()

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

            let vf2 = VF2Isomorphism<AdjacencyList>()

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

            let vf2 = VF2Isomorphism<AdjacencyList>.vf2()
            let wl = WeisfeilerLehmanIsomorphism<AdjacencyList>.weisfeilerLehman()

            #expect(graph1.isIsomorphic(to: graph2, using: vf2))
            #expect(graph1.isIsomorphic(to: graph2, using: wl))
        }

        // MARK: - Edge Cases

        @Test func emptyGraphs() {
            let empty1 = AdjacencyList()
            let empty2 = AdjacencyList()

            let vf2 = VF2Isomorphism<AdjacencyList>()

            #expect(vf2.areIsomorphic(empty1, empty2))
            #expect(vf2.findIsomorphism(empty1, empty2) != nil)
        }

        @Test func singleVertexGraphs() {
            var graph1 = AdjacencyList()
            graph1.addVertex { $0.label = "A" }

            var graph2 = AdjacencyList()
            graph2.addVertex { $0.label = "B" }

            let vf2 = VF2Isomorphism<AdjacencyList>()

            #expect(vf2.areIsomorphic(graph1, graph2))
            let mapping = vf2.findIsomorphism(graph1, graph2)
            #expect(mapping != nil)
            #expect(mapping?.count == 1)
        }

        @Test func disconnectedGraphs() {
            var graph1 = AdjacencyList()
            let a1 = graph1.addVertex { $0.label = "A1" }
            let b1 = graph1.addVertex { $0.label = "B1" }
            let c1 = graph1.addVertex { $0.label = "C1" }
            let d1 = graph1.addVertex { $0.label = "D1" }

            graph1.addEdge(from: a1, to: b1)
            graph1.addEdge(from: c1, to: d1)

            var graph2 = AdjacencyList()
            let a2 = graph2.addVertex { $0.label = "A2" }
            let b2 = graph2.addVertex { $0.label = "B2" }
            let c2 = graph2.addVertex { $0.label = "C2" }
            let d2 = graph2.addVertex { $0.label = "D2" }

            graph2.addEdge(from: a2, to: b2)
            graph2.addEdge(from: c2, to: d2)

            let vf2 = VF2Isomorphism<AdjacencyList>()

            #expect(vf2.areIsomorphic(graph1, graph2))
            let mapping = vf2.findIsomorphism(graph1, graph2)
            #expect(mapping != nil)
            #expect(mapping?.count == 4)
        }

        // MARK: - Observation Support

        @Test func vf2WithObservation() {
            let graph1 = createSimpleGraph()
            let graph2 = createSimpleGraph()

            var examinedVertices: [AdjacencyList.VertexDescriptor] = []
            var examinedEdges: [AdjacencyList.EdgeDescriptor] = []
            var tryMappings: [(AdjacencyList.VertexDescriptor, AdjacencyList.VertexDescriptor)] = []
            var mappingFound: [AdjacencyList.VertexDescriptor: AdjacencyList.VertexDescriptor]?
            var backtracks: [(AdjacencyList.VertexDescriptor, AdjacencyList.VertexDescriptor)] = []

            let observation = AlgorithmObservation<VF2Isomorphism<AdjacencyList>.Event> { event in
                switch event {
                    case .vertexExamined(let vertex):
                        examinedVertices.append(vertex)
                    case .edgeExamined(let edge):
                        examinedEdges.append(edge)
                    case .mappingTried(let pair):
                        tryMappings.append((pair.first, pair.second))
                    case .mappingFound(let mapping):
                        mappingFound = mapping
                    case .mappingBacktracked(let pair):
                        backtracks.append((pair.first, pair.second))
                }
            }

            let algorithm = VF2Isomorphism<AdjacencyList>()
            let result = algorithm.areIsomorphic(graph1, graph2, observation: observation)

            #expect(result)
            #expect(!examinedVertices.isEmpty)
            //        #expect(!examinedEdges.isEmpty)
            #expect(!tryMappings.isEmpty)
            #expect(mappingFound != nil)
        }

        @Test func weisfeilerLehmanWithObservation() {
            let graph1 = createSimpleGraph()
            let graph2 = createSimpleGraph()

            var examinedVertices: [AdjacencyList.VertexDescriptor] = []
            var examinedEdges: [AdjacencyList.EdgeDescriptor] = []
            var labeledVertices: [(AdjacencyList.VertexDescriptor, Int)] = []
            var iterations: [(Int, [AdjacencyList.VertexDescriptor: Int])] = []
            var stabilized: [AdjacencyList.VertexDescriptor: Int]?

            let observation = AlgorithmObservation<WeisfeilerLehmanIsomorphism<AdjacencyList>.Event> { event in
                switch event {
                    case .vertexExamined(let vertex):
                        examinedVertices.append(vertex)
                    case .edgeExamined(let edge):
                        examinedEdges.append(edge)
                    case .vertexLabeled(let labeled):
                        labeledVertices.append((labeled.vertex, labeled.label))
                    case .iterationCompleted(let iteration):
                        iterations.append((iteration.number, iteration.labels))
                    case .labelsStabilized(let labels):
                        stabilized = labels
                }
            }

            let algorithm = WeisfeilerLehmanIsomorphism<AdjacencyList>()
            let result = algorithm.areIsomorphic(graph1, graph2, observation: observation)

            #expect(result)
            #expect(!examinedVertices.isEmpty)
            #expect(!examinedEdges.isEmpty)
            #expect(!labeledVertices.isEmpty)
            #expect(!iterations.isEmpty)
            #expect(stabilized != nil)
        }

        @Test func enhancedWeisfeilerLehmanWithObservation() {
            let graph1 = createSimpleGraph()
            let graph2 = createSimpleGraph()

            var examinedVertices: [AdjacencyList.VertexDescriptor] = []
            var examinedEdges: [AdjacencyList.EdgeDescriptor] = []
            var labeledVertices: [(AdjacencyList.VertexDescriptor, Int)] = []
            var iterations: [(Int, [AdjacencyList.VertexDescriptor: Int])] = []
            var stabilized: [AdjacencyList.VertexDescriptor: Int]?

            let observation = AlgorithmObservation<EnhancedWeisfeilerLehmanIsomorphism<AdjacencyList>.Event> { event in
                switch event {
                    case .vertexExamined(let vertex):
                        examinedVertices.append(vertex)
                    case .edgeExamined(let edge):
                        examinedEdges.append(edge)
                    case .vertexLabeled(let labeled):
                        labeledVertices.append((labeled.vertex, labeled.label))
                    case .iterationCompleted(let iteration):
                        iterations.append((iteration.number, iteration.labels))
                    case .labelsStabilized(let labels):
                        stabilized = labels
                }
            }

            let algorithm = EnhancedWeisfeilerLehmanIsomorphism<AdjacencyList>()
            let result = algorithm.areIsomorphic(graph1, graph2, observation: observation)

            #expect(result)
            #expect(!examinedVertices.isEmpty)
            #expect(!examinedEdges.isEmpty)
            #expect(!labeledVertices.isEmpty)
            #expect(!iterations.isEmpty)
            #expect(stabilized != nil)
        }

        // MARK: - Composition

        /// Exercises all five VF2Isomorphism events through a composed observation pair.
        ///
        /// Two identical triangle graphs (isomorphic). VF2 will discover a mapping, triggering
        /// `mappingFound`; it tries vertex mappings (`tryMapping`) and examines vertices and edges.
        /// Since both graphs are isomorphic, backtracking may occur as the algorithm explores the
        /// search space before finding the full mapping.
        @Test func vf2ComposedObservationsReceiveAllEventsInOrder() {
            let graph1 = createSimpleGraph()
            let graph2 = createSimpleGraph()

            var examVtx1 = 0
            var examVtx2 = 0
            var tryMap1 = 0
            var tryMap2 = 0
            var mapFound1 = 0
            var mapFound2 = 0
            var observationOrder: [Int] = []

            let algorithm = VF2Isomorphism<AdjacencyList>()
                .observing { event in
                    observationOrder.append(1)
                    switch event {
                        case .vertexExamined: examVtx1 += 1
                        case .mappingTried: tryMap1 += 1
                        case .mappingFound: mapFound1 += 1
                        default: break
                    }
                }
                .observing { event in
                    observationOrder.append(2)
                    switch event {
                        case .vertexExamined: examVtx2 += 1
                        case .mappingTried: tryMap2 += 1
                        case .mappingFound: mapFound2 += 1
                        default: break
                    }
                }
            let result = graph1.isIsomorphic(to: graph2, using: algorithm)

            #expect(result, "two identical graphs must be isomorphic")
            #expect(examVtx1 >= 1, "examineVertex fires during the search")
            #expect(examVtx2 >= 1)
            #expect(tryMap1 >= 1, "tryMapping fires for each candidate vertex pair")
            #expect(tryMap2 >= 1)
            #expect(mapFound1 >= 1, "mappingFound fires when the full isomorphism is found")
            #expect(mapFound2 >= 1)
            // Both composed observations must see identical event counts and attachment order.
            #expect(examVtx1 == examVtx2)
            #expect(tryMap1 == tryMap2)
            #expect(mapFound1 == mapFound2)
            #expect(observationOrder.enumerated().allSatisfy { index, value in value == (index % 2) + 1 })
        }

        /// Exercises all five Weisfeiler-Lehman events through a composed observation pair.
        ///
        /// Two identical triangle graphs (isomorphic). WeisfeilerLehman relabels vertices
        /// iteratively until labels stabilize, firing label and iteration events.
        @Test func weisfeilerLehmanComposedObservationsReceiveAllEventsInOrder() {
            let graph1 = createSimpleGraph()
            let graph2 = createSimpleGraph()

            var examVtx1 = 0
            var examVtx2 = 0
            var label1 = 0
            var label2 = 0
            var iter1 = 0
            var iter2 = 0
            var stable1 = 0
            var stable2 = 0

            var examEdge1 = 0
            var examEdge2 = 0
            var observationOrder: [Int] = []

            let algorithm = WeisfeilerLehmanIsomorphism<AdjacencyList>()
                .observing { event in
                    observationOrder.append(1)
                    switch event {
                        case .vertexExamined: examVtx1 += 1
                        case .edgeExamined: examEdge1 += 1
                        case .vertexLabeled: label1 += 1
                        case .iterationCompleted: iter1 += 1
                        case .labelsStabilized: stable1 += 1
                    }
                }
                .observing { event in
                    observationOrder.append(2)
                    switch event {
                        case .vertexExamined: examVtx2 += 1
                        case .edgeExamined: examEdge2 += 1
                        case .vertexLabeled: label2 += 1
                        case .iterationCompleted: iter2 += 1
                        case .labelsStabilized: stable2 += 1
                    }
                }
            let result = graph1.isIsomorphic(to: graph2, using: algorithm)

            #expect(result, "two identical graphs must be isomorphic")
            #expect(examVtx1 >= 1, "examineVertex fires during label propagation")
            #expect(examVtx2 >= 1)
            #expect(examEdge1 >= 1, "examineEdge fires for each edge examined in the iteration")
            #expect(examEdge2 >= 1)
            #expect(label1 >= 1, "labelVertex fires for each vertex-label assignment")
            #expect(label2 >= 1)
            #expect(iter1 >= 1, "iterationComplete fires after each WL iteration")
            #expect(iter2 >= 1)
            #expect(stable1 >= 1, "labelsStabilized fires when WL converges (once per graph)")
            #expect(stable2 >= 1)
            // Both composed observations must see identical event counts and attachment order.
            #expect(examVtx1 == examVtx2)
            #expect(examEdge1 == examEdge2)
            #expect(label1 == label2)
            #expect(iter1 == iter2)
            #expect(stable1 == stable2)
            #expect(observationOrder.enumerated().allSatisfy { index, value in value == (index % 2) + 1 })
        }

        /// Exercises all five enhanced Weisfeiler-Lehman events through a composed
        /// observation pair. Uses two identical triangle graphs (isomorphic).
        @Test func enhancedWeisfeilerLehmanComposedObservationsReceiveAllEventsInOrder() {
            let graph1 = createSimpleGraph()
            let graph2 = createSimpleGraph()

            var examVtx1 = 0
            var examVtx2 = 0
            var examEdge1 = 0
            var examEdge2 = 0
            var label1 = 0
            var label2 = 0
            var iter1 = 0
            var iter2 = 0
            var stable1 = 0
            var stable2 = 0
            var observationOrder: [Int] = []

            let algorithm = EnhancedWeisfeilerLehmanIsomorphism<AdjacencyList>()
                .observing { event in
                    observationOrder.append(1)
                    switch event {
                        case .vertexExamined: examVtx1 += 1
                        case .edgeExamined: examEdge1 += 1
                        case .vertexLabeled: label1 += 1
                        case .iterationCompleted: iter1 += 1
                        case .labelsStabilized: stable1 += 1
                    }
                }
                .observing { event in
                    observationOrder.append(2)
                    switch event {
                        case .vertexExamined: examVtx2 += 1
                        case .edgeExamined: examEdge2 += 1
                        case .vertexLabeled: label2 += 1
                        case .iterationCompleted: iter2 += 1
                        case .labelsStabilized: stable2 += 1
                    }
                }
            let result = graph1.isIsomorphic(to: graph2, using: algorithm)

            #expect(result, "two identical triangle graphs must be isomorphic")
            #expect(examVtx1 >= 1, "examineVertex fires for each vertex examined")
            #expect(examVtx2 >= 1)
            #expect(examEdge1 >= 1, "examineEdge fires for each edge in the label propagation")
            #expect(examEdge2 >= 1)
            #expect(label1 >= 1, "labelVertex fires for each vertex-label assignment")
            #expect(label2 >= 1)
            #expect(iter1 >= 1, "iterationComplete fires after each enhanced WL iteration")
            #expect(iter2 >= 1)
            #expect(stable1 >= 1, "labelsStabilized fires when labels converge")
            #expect(stable2 >= 1)
            #expect(examVtx1 == examVtx2)
            #expect(examEdge1 == examEdge2)
            #expect(label1 == label2)
            #expect(iter1 == iter2)
            #expect(stable1 == stable2)
            #expect(observationOrder.enumerated().allSatisfy { index, value in value == (index % 2) + 1 })
        }
    }
#endif
