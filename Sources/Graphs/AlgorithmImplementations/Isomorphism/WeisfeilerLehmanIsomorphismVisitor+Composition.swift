import Foundation

extension WeisfeilerLehmanIsomorphism.Visitor: Composable {
    func combined(with other: Self) -> Self {
        .init(
            examineVertex: { vertex in
                self.examineVertex?(vertex)
                other.examineVertex?(vertex)
            },
            examineEdge: { edge in
                self.examineEdge?(edge)
                other.examineEdge?(edge)
            },
            labelVertex: { vertex, label in
                self.labelVertex?(vertex, label)
                other.labelVertex?(vertex, label)
            },
            iterationComplete: { iteration, labels in
                self.iterationComplete?(iteration, labels)
                other.iterationComplete?(iteration, labels)
            },
            labelsStabilized: { labels in
                self.labelsStabilized?(labels)
                other.labelsStabilized?(labels)
            }
        )
    }
}

extension EnhancedWeisfeilerLehmanIsomorphism.Visitor: Composable {
    func combined(with other: Self) -> Self {
        .init(
            examineVertex: { vertex in
                self.examineVertex?(vertex)
                other.examineVertex?(vertex)
            },
            examineEdge: { edge in
                self.examineEdge?(edge)
                other.examineEdge?(edge)
            },
            labelVertex: { vertex, label in
                self.labelVertex?(vertex, label)
                other.labelVertex?(vertex, label)
            },
            iterationComplete: { iteration, labels in
                self.iterationComplete?(iteration, labels)
                other.iterationComplete?(iteration, labels)
            },
            labelsStabilized: { labels in
                self.labelsStabilized?(labels)
                other.labelsStabilized?(labels)
            }
        )
    }
}
