#if !GRAPHS_USES_TRAITS || GRAPHS_ADVANCED
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

        public struct VertexLabel {
            public let vertex: Vertex
            public let label: Int

            @inlinable
            public init(vertex: Vertex, label: Int) {
                self.vertex = vertex
                self.label = label
            }
        }

        public struct Iteration {
            public let number: Int
            public let labels: [Vertex: Int]

            @inlinable
            public init(number: Int, labels: [Vertex: Int]) {
                self.number = number
                self.labels = labels
            }
        }

        public enum Event {
            case vertexExamined(Vertex)
            case edgeExamined(Edge)
            case vertexLabeled(VertexLabel)
            case iterationCompleted(Iteration)
            case labelsStabilized([Vertex: Int])
        }

        public enum EventCases {
            public static var vertexExamined: AlgorithmEventCase<Event, Vertex> {
                .init {
                    guard case .vertexExamined(let value) = $0 else { return nil }
                    return value
                }
            }
            public static var edgeExamined: AlgorithmEventCase<Event, Edge> {
                .init {
                    guard case .edgeExamined(let value) = $0 else { return nil }
                    return value
                }
            }
            public static var vertexLabeled: AlgorithmEventCase<Event, VertexLabel> {
                .init {
                    guard case .vertexLabeled(let value) = $0 else { return nil }
                    return value
                }
            }
            public static var iterationCompleted: AlgorithmEventCase<Event, Iteration> {
                .init {
                    guard case .iterationCompleted(let value) = $0 else { return nil }
                    return value
                }
            }
            public static var labelsStabilized: AlgorithmEventCase<Event, [Vertex: Int]> {
                .init {
                    guard case .labelsStabilized(let value) = $0 else { return nil }
                    return value
                }
            }
        }

        @usableFromInline
        let maxIterations: Int

        @inlinable
        public init(maxIterations: Int = 10) {
            self.maxIterations = maxIterations
        }

        @inlinable
        public func areIsomorphic(_ graph1: Graph, _ graph2: Graph, observation: AlgorithmObservation<Event>? = nil) -> Bool {
            return findIsomorphism(graph1, graph2, observation: observation) != nil
        }

        @inlinable
        public func findIsomorphism(_ graph1: Graph, _ graph2: Graph, observation: AlgorithmObservation<Event>? = nil) -> [Vertex: Vertex]? {
            // Quick checks for basic isomorphism requirements
            guard graph1.vertexCount == graph2.vertexCount else { return nil }
            guard graph1.edgeCount == graph2.edgeCount else { return nil }

            // Run Weisfeiler-Lehman test
            let labels1 = computeWLLabels(graph: graph1, observation: observation)
            let labels2 = computeWLLabels(graph: graph2, observation: observation)

            // Check if the label multisets are equal
            guard areLabelMultisetsEqual(labels1, labels2) else { return nil }

            // If WL test passes, try to find a mapping using VF2 as a fallback
            // This is because WL is not complete and may give false negatives
            let vf2 = VF2Isomorphism<Graph>()
            return vf2.findIsomorphism(graph1, graph2)
        }

        @usableFromInline
        func computeWLLabels(graph: Graph, observation: AlgorithmObservation<Event>?) -> [Vertex: Int] {
            var labels: [Vertex: Int] = [:]

            // Initialize with degree-based labels
            for vertex in graph.vertices() {
                let degree = graph.outDegree(of: vertex)
                labels[vertex] = degree
                observation?.receive(.vertexLabeled(.init(vertex: vertex, label: degree)))
            }

            // Iteratively refine labels
            for iteration in 0 ..< maxIterations {
                var newLabels: [Vertex: Int] = [:]
                var labelMap: [String: Int] = [:]
                var nextNewLabel = 0

                for vertex in graph.vertices() {
                    observation?.receive(.vertexExamined(vertex))

                    // Create a signature based on current label and neighbor labels
                    guard let currentLabel = labels[vertex] else { continue }
                    var neighborLabels: [Int] = []

                    for edge in graph.outgoingEdges(of: vertex) {
                        observation?.receive(.edgeExamined(edge))
                        guard let neighbor = graph.destination(of: edge),
                            let neighborLabel = labels[neighbor]
                        else { continue }
                        neighborLabels.append(neighborLabel)
                    }

                    // Sort neighbor labels for consistency
                    neighborLabels.sort()

                    // Create a string signature
                    let signature = "\(currentLabel):\(neighborLabels.map { "\($0)" }.joined(separator: ","))"

                    // Assign a new label based on the signature
                    if let existingLabel = labelMap[signature] {
                        newLabels[vertex] = existingLabel
                    } else {
                        let newLabel = nextNewLabel
                        labelMap[signature] = newLabel
                        newLabels[vertex] = newLabel
                        nextNewLabel += 1
                    }

                    if let newLabel = newLabels[vertex] {
                        observation?.receive(.vertexLabeled(.init(vertex: vertex, label: newLabel)))
                    }
                }

                observation?.receive(.iterationCompleted(.init(number: iteration + 1, labels: newLabels)))

                // Check if labels have stabilized
                if labels == newLabels {
                    observation?.receive(.labelsStabilized(newLabels))
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

        public struct VertexLabel {
            public let vertex: Vertex
            public let label: Int

            @inlinable
            public init(vertex: Vertex, label: Int) {
                self.vertex = vertex
                self.label = label
            }
        }

        public struct Iteration {
            public let number: Int
            public let labels: [Vertex: Int]

            @inlinable
            public init(number: Int, labels: [Vertex: Int]) {
                self.number = number
                self.labels = labels
            }
        }

        public enum Event {
            case vertexExamined(Vertex)
            case edgeExamined(Edge)
            case vertexLabeled(VertexLabel)
            case iterationCompleted(Iteration)
            case labelsStabilized([Vertex: Int])
        }

        public enum EventCases {
            public static var vertexExamined: AlgorithmEventCase<Event, Vertex> {
                .init {
                    guard case .vertexExamined(let value) = $0 else { return nil }
                    return value
                }
            }
            public static var edgeExamined: AlgorithmEventCase<Event, Edge> {
                .init {
                    guard case .edgeExamined(let value) = $0 else { return nil }
                    return value
                }
            }
            public static var vertexLabeled: AlgorithmEventCase<Event, VertexLabel> {
                .init {
                    guard case .vertexLabeled(let value) = $0 else { return nil }
                    return value
                }
            }
            public static var iterationCompleted: AlgorithmEventCase<Event, Iteration> {
                .init {
                    guard case .iterationCompleted(let value) = $0 else { return nil }
                    return value
                }
            }
            public static var labelsStabilized: AlgorithmEventCase<Event, [Vertex: Int]> {
                .init {
                    guard case .labelsStabilized(let value) = $0 else { return nil }
                    return value
                }
            }
        }

        @usableFromInline
        let maxIterations: Int

        @inlinable
        public init(maxIterations: Int = 10) {
            self.maxIterations = maxIterations
        }

        @inlinable
        public func areIsomorphic(_ graph1: Graph, _ graph2: Graph, observation: AlgorithmObservation<Event>? = nil) -> Bool {
            return findIsomorphism(graph1, graph2, observation: observation) != nil
        }

        @inlinable
        public func findIsomorphism(_ graph1: Graph, _ graph2: Graph, observation: AlgorithmObservation<Event>? = nil) -> [Vertex: Vertex]? {
            // Quick checks for basic isomorphism requirements
            guard graph1.vertexCount == graph2.vertexCount else { return nil }
            guard graph1.edgeCount == graph2.edgeCount else { return nil }

            // Run enhanced Weisfeiler-Lehman test
            let labels1 = computeEnhancedWLLabels(graph: graph1, observation: observation)
            let labels2 = computeEnhancedWLLabels(graph: graph2, observation: observation)

            // Check if the label multisets are equal
            guard areLabelMultisetsEqual(labels1, labels2) else { return nil }

            // If WL test passes, try to find a mapping using VF2 as a fallback
            let vf2 = VF2Isomorphism<Graph>()
            return vf2.findIsomorphism(graph1, graph2)
        }

        @usableFromInline
        func computeEnhancedWLLabels(graph: Graph, observation: AlgorithmObservation<Event>?) -> [Vertex: Int] {
            var labels: [Vertex: Int] = [:]

            // Initialize with degree-based labels
            for vertex in graph.vertices() {
                let degree = graph.outDegree(of: vertex)
                labels[vertex] = degree
                observation?.receive(.vertexLabeled(.init(vertex: vertex, label: degree)))
            }

            // Iteratively refine labels
            for iteration in 0 ..< maxIterations {
                var newLabels: [Vertex: Int] = [:]
                var labelMap: [String: Int] = [:]
                var nextNewLabel = 0

                for vertex in graph.vertices() {
                    observation?.receive(.vertexExamined(vertex))

                    // Create a signature based on current label and neighbor labels with edge information
                    guard let currentLabel = labels[vertex] else { continue }
                    var neighborInfo: [(Int, String)] = []

                    for edge in graph.outgoingEdges(of: vertex) {
                        observation?.receive(.edgeExamined(edge))
                        guard let neighbor = graph.destination(of: edge),
                            let neighborLabel = labels[neighbor]
                        else { continue }
                        // Use edge descriptor as string representation for edge labels
                        let edgeInfo = "\(edge)"
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

                    if let newLabel = newLabels[vertex] {
                        observation?.receive(.vertexLabeled(.init(vertex: vertex, label: newLabel)))
                    }
                }

                observation?.receive(.iterationCompleted(.init(number: iteration + 1, labels: newLabels)))

                // Check if labels have stabilized
                if labels == newLabels {
                    observation?.receive(.labelsStabilized(newLabels))
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

    extension WeisfeilerLehmanIsomorphism: AlgorithmObserving {}
    extension EnhancedWeisfeilerLehmanIsomorphism: AlgorithmObserving {}
#endif

#if !GRAPHS_USES_TRAITS || GRAPHS_ADVANCED
    extension WeisfeilerLehmanIsomorphism.Event: VertexExaminedEvent, EdgeExaminedEvent {
        @inlinable
        public static func examinedVertex(from event: Self) -> Graph.VertexDescriptor? {
            guard case .vertexExamined(let vertex) = event else { return nil }
            return vertex
        }

        @inlinable
        public static func examinedEdge(from event: Self) -> Graph.EdgeDescriptor? {
            guard case .edgeExamined(let edge) = event else { return nil }
            return edge
        }
    }

    extension EnhancedWeisfeilerLehmanIsomorphism.Event: VertexExaminedEvent, EdgeExaminedEvent {
        @inlinable
        public static func examinedVertex(from event: Self) -> Graph.VertexDescriptor? {
            guard case .vertexExamined(let vertex) = event else { return nil }
            return vertex
        }

        @inlinable
        public static func examinedEdge(from event: Self) -> Graph.EdgeDescriptor? {
            guard case .edgeExamined(let edge) = event else { return nil }
            return edge
        }
    }
#endif
