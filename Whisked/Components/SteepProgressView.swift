import SwiftUI

/// Displays progress toward the next free drink as a ring of filled/unfilled dots.
/// 9 dots total — each represents one steep. Filled dots use the accent color.
struct SteepProgressView: View {
    let progress: Int   // steeps earned toward the current threshold (0...8)
    let total: Int      // steeps per reward (always 9)

    var body: some View {
        GeometryReader { geo in
            let size   = min(geo.size.width, geo.size.height)
            let center = CGPoint(x: size / 2, y: size / 2)
            let radius = size / 2 - 20

            ZStack {
                // Background ring
                Circle()
                    .stroke(Color(.systemFill), lineWidth: 3)
                    .padding(10)

                // Dots
                ForEach(0..<total, id: \.self) { index in
                    let angle  = angle(for: index)
                    let x      = center.x + radius * cos(angle)
                    let y      = center.y + radius * sin(angle)
                    let filled = index < progress

                    Circle()
                        .fill(filled ? Color.whisked.amber : Color.whisked.beige)
                        .frame(width: dotSize(size: size), height: dotSize(size: size))
                        .overlay {
                            if filled {
                                Circle()
                                    .stroke(Color.whisked.amber.opacity(0.3), lineWidth: 1)
                            }
                        }
                        .position(x: x, y: y)
                        .animation(.spring(response: 0.4, dampingFraction: 0.7).delay(Double(index) * 0.04), value: progress)
                }

                // Center bell mark
                Image(systemName: "bell.fill")
                    .font(.title2)
                    .foregroundStyle(progress > 0 ? Color.whisked.amber : Color.whisked.beige)
            }
            .frame(width: size, height: size)
        }
    }

    private func angle(for index: Int) -> CGFloat {
        // Start at top (−π/2) and go clockwise
        let step = (2 * CGFloat.pi) / CGFloat(total)
        return step * CGFloat(index) - .pi / 2
    }

    private func dotSize(size: CGFloat) -> CGFloat {
        max(12, size / 10)
    }
}

#Preview {
    VStack(spacing: 32) {
        SteepProgressView(progress: 0, total: 9)
            .frame(width: 200, height: 200)
        SteepProgressView(progress: 5, total: 9)
            .frame(width: 200, height: 200)
        SteepProgressView(progress: 9, total: 9)
            .frame(width: 200, height: 200)
    }
    .padding()
}
