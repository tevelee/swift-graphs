/// Event vocabulary for Ore's Hamiltonicity condition.
public struct OreProperty<Graph: IncidenceGraph & VertexListGraph & BidirectionalGraph> where Graph.VertexDescriptor: Hashable {
    /// An event emitted while checking Ore's condition.
    public enum Event {
        /// The graph has too few vertices for the theorem.
        case insufficientVertexCount(Int)
        /// The graph's vertex count is about to be used.
        case vertexCountChecked(Int)
        /// A vertex pair was checked for adjacency.
        case vertexPairChecked(Graph.VertexDescriptor, Graph.VertexDescriptor, adjacent: Bool)
        /// A non-adjacent pair's degree sum was checked.
        case degreeSumChecked(Graph.VertexDescriptor, Graph.VertexDescriptor, sum: Int, required: Int)
        /// A non-adjacent pair failed the degree-sum condition.
        case degreeSumTooLow(Graph.VertexDescriptor, Graph.VertexDescriptor, sum: Int, required: Int)
    }

    /// Typed selectors for Ore-condition events.
    public enum EventCases {
        /// Selects insufficient vertex counts.
        public static var insufficientVertexCount: AlgorithmEventCase<Event, Int> {
            .init {
                guard case .insufficientVertexCount(let count) = $0 else { return nil }
                return count
            }
        }

        /// Selects vertex-count checks.
        public static var vertexCountChecked: AlgorithmEventCase<Event, Int> {
            .init {
                guard case .vertexCountChecked(let count) = $0 else { return nil }
                return count
            }
        }

        /// Selects adjacency checks.
        public static var vertexPairChecked: AlgorithmEventCase<Event, (Graph.VertexDescriptor, Graph.VertexDescriptor, adjacent: Bool)> {
            .init {
                guard case .vertexPairChecked(let first, let second, let adjacent) = $0 else { return nil }
                return (first, second, adjacent)
            }
        }

        /// Selects degree-sum checks.
        public static var degreeSumChecked: AlgorithmEventCase<Event, (Graph.VertexDescriptor, Graph.VertexDescriptor, sum: Int, required: Int)> {
            .init {
                guard case .degreeSumChecked(let first, let second, let sum, let required) = $0 else { return nil }
                return (first, second, sum, required)
            }
        }

        /// Selects failed degree-sum checks.
        public static var degreeSumTooLow: AlgorithmEventCase<Event, (Graph.VertexDescriptor, Graph.VertexDescriptor, sum: Int, required: Int)> {
            .init {
                guard case .degreeSumTooLow(let first, let second, let sum, let required) = $0 else { return nil }
                return (first, second, sum, required)
            }
        }
    }
}
