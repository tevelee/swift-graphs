#if !GRAPHS_USES_TRAITS || GRAPHS_PATHFINDING

    extension ContractionHierarchy {

        // MARK: - CH Edge (augmented graph edge representation)

        /// An edge in the augmented graph: either an original edge or a virtual shortcut.
        enum CHEdge {
            case original(Edge)
            case shortcut(from: Vertex, Shortcut)
        }

        // MARK: - Priority Queue Item

        struct CHQueryItem: Comparable {
            let cost: W
            let vertex: Vertex
            let isForward: Bool
            static func < (lhs: Self, rhs: Self) -> Bool { lhs.cost < rhs.cost }
            static func == (lhs: Self, rhs: Self) -> Bool {
                lhs.cost == rhs.cost && lhs.vertex == rhs.vertex && lhs.isForward == rhs.isForward
            }
        }

        // MARK: - Query

        /// Finds the shortest path from `source` to `destination` using the contraction hierarchy.
        ///
        /// Runs upward-restricted bidirectional Dijkstra on the augmented graph, then unpacks
        /// any shortcut edges into original graph edges before returning.
        ///
        /// - Complexity: Much faster than vanilla Dijkstra on large sparse graphs.
        ///   Typical query time is O(k log k) where k is a small fraction of the graph.
        /// - Returns: The shortest path in terms of original graph edges, or `nil` if unreachable.
        public func shortestPath(from source: Vertex, to destination: Vertex) -> Path<Vertex, Edge>? {
            guard source != destination else {
                return Path(source: source, destination: destination, vertices: [source], edges: [])
            }

            var fwdDist: [Vertex: W] = [source: W.zero]
            var bwdDist: [Vertex: W] = [destination: W.zero]
            var fwdPred: [Vertex: CHEdge] = [:]  // edge arriving at key vertex (forward)
            var bwdPred: [Vertex: CHEdge] = [:]  // edge departing key vertex toward destination (backward)
            var fwdSettled: Set<Vertex> = []
            var bwdSettled: Set<Vertex> = []

            var queue = PriorityQueue<CHQueryItem>()
            queue.enqueue(CHQueryItem(cost: W.zero, vertex: source, isForward: true))
            queue.enqueue(CHQueryItem(cost: W.zero, vertex: destination, isForward: false))

            var bestCost: W?
            var meetingVertex: Vertex?

            while let item = queue.dequeue() {
                let v = item.vertex
                let d = item.cost

                // Terminate if remaining items can't improve bestCost
                if let best = bestCost, d >= best { break }

                if item.isForward {
                    guard !fwdSettled.contains(v) else { continue }
                    guard fwdDist[v] == d else { continue }
                    fwdSettled.insert(v)

                    // Update meeting if backward has settled this vertex
                    if let bwdD = bwdDist[v], bwdSettled.contains(v) {
                        let total = d + bwdD
                        if bestCost == nil || total < bestCost! {
                            bestCost = total
                            meetingVertex = v
                        }
                    }

                    expandForward(from: v, cost: d, fwdDist: &fwdDist, fwdPred: &fwdPred, queue: &queue)

                } else {
                    // Backward search
                    guard !bwdSettled.contains(v) else { continue }
                    guard bwdDist[v] == d else { continue }
                    bwdSettled.insert(v)

                    if let fwdD = fwdDist[v], fwdSettled.contains(v) {
                        let total = fwdD + d
                        if bestCost == nil || total < bestCost! {
                            bestCost = total
                            meetingVertex = v
                        }
                    }

                    expandBackward(from: v, cost: d, bwdDist: &bwdDist, bwdPred: &bwdPred, queue: &queue)
                }
            }

            guard let mv = meetingVertex else { return nil }

            return buildPath(
                from: source,
                to: destination,
                meetingVertex: mv,
                fwdPred: fwdPred,
                bwdPred: bwdPred
            )
        }

        /// Returns the cost of the shortest path from `source` to `destination`, without constructing the path.
        ///
        /// Faster than `shortestPath(from:to:)` when only the distance is needed: skips predecessor
        /// map allocation and shortcut unpacking.
        ///
        /// - Returns: The minimum cost, or `nil` if `destination` is unreachable from `source`.
        public func shortestDistance(from source: Vertex, to destination: Vertex) -> W? {
            guard source != destination else { return W.zero }

            var fwdDist: [Vertex: W] = [source: W.zero]
            var bwdDist: [Vertex: W] = [destination: W.zero]
            var fwdSettled: Set<Vertex> = []
            var bwdSettled: Set<Vertex> = []

            var queue = PriorityQueue<CHQueryItem>()
            queue.enqueue(CHQueryItem(cost: W.zero, vertex: source, isForward: true))
            queue.enqueue(CHQueryItem(cost: W.zero, vertex: destination, isForward: false))

            var bestCost: W?

            while let item = queue.dequeue() {
                let v = item.vertex
                let d = item.cost

                if let best = bestCost, d >= best { break }

                if item.isForward {
                    guard !fwdSettled.contains(v) else { continue }
                    guard fwdDist[v] == d else { continue }
                    fwdSettled.insert(v)

                    if let bwdD = bwdDist[v], bwdSettled.contains(v) {
                        let total = d + bwdD
                        if bestCost == nil || total < bestCost! { bestCost = total }
                    }

                    expandForward(from: v, cost: d, fwdDist: &fwdDist, queue: &queue)

                } else {
                    guard !bwdSettled.contains(v) else { continue }
                    guard bwdDist[v] == d else { continue }
                    bwdSettled.insert(v)

                    if let fwdD = fwdDist[v], fwdSettled.contains(v) {
                        let total = fwdD + d
                        if bestCost == nil || total < bestCost! { bestCost = total }
                    }

                    expandBackward(from: v, cost: d, bwdDist: &bwdDist, queue: &queue)
                }
            }

            return bestCost
        }

        // MARK: - Edge Expansion Helpers

        private func expandForward(
            from v: Vertex,
            cost d: W,
            fwdDist: inout [Vertex: W],
            fwdPred: inout [Vertex: CHEdge],
            queue: inout PriorityQueue<CHQueryItem>
        ) {
            let vLevel = vertexLevel[v, default: -1]
            for e in graph.outgoingEdges(of: v) {
                guard let nb = graph.destination(of: e), vertexLevel[nb, default: -1] > vLevel else { continue }
                let nc = d + weight.costToExplore(e, graph)
                if fwdDist[nb].map({ nc < $0 }) ?? true {
                    fwdDist[nb] = nc
                    fwdPred[nb] = .original(e)
                    queue.enqueue(CHQueryItem(cost: nc, vertex: nb, isForward: true))
                }
            }
            for sc in shortcuts[v, default: []] {
                guard vertexLevel[sc.target, default: -1] > vLevel else { continue }
                let nc = d + sc.weight
                if fwdDist[sc.target].map({ nc < $0 }) ?? true {
                    fwdDist[sc.target] = nc
                    fwdPred[sc.target] = .shortcut(from: v, sc)
                    queue.enqueue(CHQueryItem(cost: nc, vertex: sc.target, isForward: true))
                }
            }
        }

        private func expandBackward(
            from v: Vertex,
            cost d: W,
            bwdDist: inout [Vertex: W],
            bwdPred: inout [Vertex: CHEdge],
            queue: inout PriorityQueue<CHQueryItem>
        ) {
            let vLevel = vertexLevel[v, default: -1]
            for e in graph.incomingEdges(of: v) {
                guard let nb = graph.source(of: e), vertexLevel[nb, default: -1] > vLevel else { continue }
                let nc = d + weight.costToExplore(e, graph)
                if bwdDist[nb].map({ nc < $0 }) ?? true {
                    bwdDist[nb] = nc
                    bwdPred[nb] = .original(e)
                    queue.enqueue(CHQueryItem(cost: nc, vertex: nb, isForward: false))
                }
            }
            for sc in shortcutsByTarget[v, default: []] {
                guard vertexLevel[sc.source, default: -1] > vLevel else { continue }
                let nc = d + sc.weight
                if bwdDist[sc.source].map({ nc < $0 }) ?? true {
                    bwdDist[sc.source] = nc
                    bwdPred[sc.source] = .shortcut(from: sc.source, Shortcut(target: v, weight: sc.weight, via: sc.via))
                    queue.enqueue(CHQueryItem(cost: nc, vertex: sc.source, isForward: false))
                }
            }
        }

        private func expandForward(
            from v: Vertex,
            cost d: W,
            fwdDist: inout [Vertex: W],
            queue: inout PriorityQueue<CHQueryItem>
        ) {
            let vLevel = vertexLevel[v, default: -1]
            for e in graph.outgoingEdges(of: v) {
                guard let nb = graph.destination(of: e), vertexLevel[nb, default: -1] > vLevel else { continue }
                let nc = d + weight.costToExplore(e, graph)
                if fwdDist[nb].map({ nc < $0 }) ?? true {
                    fwdDist[nb] = nc
                    queue.enqueue(CHQueryItem(cost: nc, vertex: nb, isForward: true))
                }
            }
            for sc in shortcuts[v, default: []] {
                guard vertexLevel[sc.target, default: -1] > vLevel else { continue }
                let nc = d + sc.weight
                if fwdDist[sc.target].map({ nc < $0 }) ?? true {
                    fwdDist[sc.target] = nc
                    queue.enqueue(CHQueryItem(cost: nc, vertex: sc.target, isForward: true))
                }
            }
        }

        private func expandBackward(
            from v: Vertex,
            cost d: W,
            bwdDist: inout [Vertex: W],
            queue: inout PriorityQueue<CHQueryItem>
        ) {
            let vLevel = vertexLevel[v, default: -1]
            for e in graph.incomingEdges(of: v) {
                guard let nb = graph.source(of: e), vertexLevel[nb, default: -1] > vLevel else { continue }
                let nc = d + weight.costToExplore(e, graph)
                if bwdDist[nb].map({ nc < $0 }) ?? true {
                    bwdDist[nb] = nc
                    queue.enqueue(CHQueryItem(cost: nc, vertex: nb, isForward: false))
                }
            }
            for sc in shortcutsByTarget[v, default: []] {
                guard vertexLevel[sc.source, default: -1] > vLevel else { continue }
                let nc = d + sc.weight
                if bwdDist[sc.source].map({ nc < $0 }) ?? true {
                    bwdDist[sc.source] = nc
                    queue.enqueue(CHQueryItem(cost: nc, vertex: sc.source, isForward: false))
                }
            }
        }
    }

#endif
