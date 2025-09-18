import Foundation

extension Yen.Visitor: Composable {
    func combined(with other: Self) -> Self {
        .init(
            onPathFound: { path in
                self.onPathFound(path)
                other.onPathFound(path)
            },
            onCandidateAdded: { path, cost in
                self.onCandidateAdded(path, cost)
                other.onCandidateAdded(path, cost)
            },
            onPathSelected: { path, cost in
                self.onPathSelected(path, cost)
                other.onPathSelected(path, cost)
            }
        )
    }
}
