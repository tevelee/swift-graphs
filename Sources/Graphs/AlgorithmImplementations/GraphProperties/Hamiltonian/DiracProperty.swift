/// Event vocabulary for Dirac's Hamiltonicity condition.
public struct DiracProperty<Graph: IncidenceGraph & VertexListGraph & BidirectionalGraph> where Graph.VertexDescriptor: Hashable {
    /// An event emitted while checking Dirac's condition.
    public enum Event {
        /// The graph has too few vertices for the theorem.
        case insufficientVertexCount(Int)
        /// The required minimum degree was computed.
        case minimumDegreeComputed(Int)
        /// A vertex degree is about to be checked.
        case vertexDegreeChecked(vertex: Graph.VertexDescriptor, degree: Int, minimum: Int)
        /// A vertex failed the minimum-degree condition.
        case vertexDegreeTooLow(vertex: Graph.VertexDescriptor, degree: Int, minimum: Int)
    }

    /// Typed selectors for Dirac-condition events.
    public enum EventCases {
        /// Selects insufficient vertex counts.
        public static var insufficientVertexCount: AlgorithmEventCase<Event, Int> {
            .init {
                guard case .insufficientVertexCount(let count) = $0 else { return nil }
                return count
            }
        }

        /// Selects computed minimum degrees.
        public static var minimumDegreeComputed: AlgorithmEventCase<Event, Int> {
            .init {
                guard case .minimumDegreeComputed(let degree) = $0 else { return nil }
                return degree
            }
        }

        /// Selects vertex-degree checks.
        public static var vertexDegreeChecked: AlgorithmEventCase<Event, (vertex: Graph.VertexDescriptor, degree: Int, minimum: Int)> {
            .init {
                guard case .vertexDegreeChecked(let vertex, let degree, let minimum) = $0 else { return nil }
                return (vertex, degree, minimum)
            }
        }

        /// Selects failed vertex-degree checks.
        public static var vertexDegreeTooLow: AlgorithmEventCase<Event, (vertex: Graph.VertexDescriptor, degree: Int, minimum: Int)> {
            .init {
                guard case .vertexDegreeTooLow(let vertex, let degree, let minimum) = $0 else { return nil }
                return (vertex, degree, minimum)
            }
        }
    }
}
