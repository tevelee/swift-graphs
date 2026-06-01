#if !GRAPHS_USES_TRAITS || GRAPHS_PATHFINDING

    extension ContractionHierarchy {

        // MARK: - Path Building

        /// Builds the final unpacked path through the meeting vertex using forward and backward predecessor maps.
        func buildPath(
            from source: Vertex,
            to destination: Vertex,
            meetingVertex: Vertex,
            fwdPred: [Vertex: CHEdge],
            bwdPred: [Vertex: CHEdge]
        ) -> Path<Vertex, Edge>? {
            var edges: [Edge] = []

            // Forward half: source → meetingVertex
            buildForwardEdges(to: meetingVertex, from: source, pred: fwdPred, into: &edges)

            // Backward half: meetingVertex → destination
            buildBackwardEdges(from: meetingVertex, to: destination, pred: bwdPred, into: &edges)

            // Reconstruct vertex list from edge list
            var vertices: [Vertex] = [source]
            for e in edges {
                if let dst = graph.destination(of: e) {
                    vertices.append(dst)
                }
            }

            return Path(source: source, destination: destination, vertices: vertices, edges: edges)
        }

        // MARK: - Forward Half

        /// Walks forward predecessor map from `current` back to `source`, collecting unpacked original edges.
        private func buildForwardEdges(
            to current: Vertex,
            from source: Vertex,
            pred: [Vertex: CHEdge],
            into result: inout [Edge]
        ) {
            // Collect the forward chain by walking back from meetingVertex to source
            var chain: [CHEdge] = []
            var v = current
            while v != source {
                guard let chEdge = pred[v] else { break }
                chain.append(chEdge)
                switch chEdge {
                    case .original(let e):
                        guard let prev = graph.source(of: e) else { return }
                        v = prev
                    case .shortcut(let from, _):
                        v = from
                }
            }
            // Reverse chain to get source→meetingVertex order, then unpack each
            for chEdge in chain.reversed() {
                switch chEdge {
                    case .original(let e):
                        result.append(e)
                    case .shortcut(let from, let sc):
                        unpackShortcutEdge(from: from, to: sc.target, via: sc.via, into: &result)
                }
            }
        }

        // MARK: - Backward Half

        /// Walks backward predecessor map forward from `current` to `destination`, collecting unpacked edges.
        private func buildBackwardEdges(
            from current: Vertex,
            to destination: Vertex,
            pred: [Vertex: CHEdge],
            into result: inout [Edge]
        ) {
            var v = current
            while v != destination {
                guard let chEdge = pred[v] else { break }
                switch chEdge {
                    case .original(let e):
                        result.append(e)
                        guard let next = graph.destination(of: e) else { return }
                        v = next
                    case .shortcut(_, let sc):
                        // sc.target is the next vertex in the path toward destination
                        unpackShortcutEdge(from: v, to: sc.target, via: sc.via, into: &result)
                        v = sc.target
                }
            }
        }

        // MARK: - Shortcut Unpacking

        /// Recursively unpacks a single shortcut edge (u → w via contracted vertex `via`)
        /// into a sequence of original graph edges.
        private func unpackShortcutEdge(from u: Vertex, to w: Vertex, via: Vertex, into result: inout [Edge]) {
            // Unpack left half: u → via
            unpackHalf(from: u, to: via, into: &result)
            // Unpack right half: via → w
            unpackHalf(from: via, to: w, into: &result)
        }

        /// Expands a single directed segment (u → v) — either an original edge or a shortcut — into
        /// original graph edges, appended to `result`.
        private func unpackHalf(from u: Vertex, to v: Vertex, into result: inout [Edge]) {
            if let sc = shortcutLookup[Pair(u, v)] {
                // This is a shortcut — recurse
                unpackShortcutEdge(from: u, to: v, via: sc.via, into: &result)
            } else {
                // This is an original edge
                if let e = findOriginalEdge(from: u, to: v) {
                    result.append(e)
                }
            }
        }
    }

#endif
