import SwiftUI
import Foundation

struct ContentView: View {
    @Environment(\.openURL) private var openURL
    @State private var phoneNumber = ""
    @State private var feedbackCount = 0
    @State private var showsCallError = false

    var body: some View {
        ZStack {
            WoodBackground()

            VStack(spacing: 12) {
                DialedNumberDisplay(
                    phoneNumber: phoneNumber,
                    onDelete: deleteLastDigit,
                    onClear: clearNumber
                )

                VintageTelephone(phoneNumber: phoneNumber) { digit in
                    phoneNumber.append(digit)
                    feedbackCount += 1
                }
                .frame(maxWidth: 430)
                .aspectRatio(0.78, contentMode: .fit)

                CallButton(isEnabled: !phoneNumber.isEmpty, action: callNumber)
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 12)
        }
        .sensoryFeedback(.success, trigger: feedbackCount)
        .alert("Unable to Start Call", isPresented: $showsCallError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Calling is unavailable on this device. Try again on an iPhone with the Phone app configured.")
        }
    }

    private func deleteLastDigit() {
        guard !phoneNumber.isEmpty else { return }
        phoneNumber.removeLast()
    }

    private func clearNumber() {
        phoneNumber = ""
    }

    private func callNumber() {
        guard let url = URL(string: "tel:\(phoneNumber)") else {
            showsCallError = true
            return
        }

        openURL(url) { accepted in
            if !accepted {
                showsCallError = true
            }
        }
    }
}

private struct WoodBackground: View {
    var body: some View {
        LinearGradient(
            colors: [
                Color(red: 0.65, green: 0.40, blue: 0.18),
                Color(red: 0.82, green: 0.58, blue: 0.29),
                Color(red: 0.58, green: 0.34, blue: 0.15)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .overlay {
            Canvas { context, size in
                for index in 0..<14 {
                    let y = CGFloat(index) * size.height / 13
                    var path = Path()
                    path.move(to: CGPoint(x: 0, y: y))
                    path.addCurve(
                        to: CGPoint(x: size.width, y: y + 12),
                        control1: CGPoint(x: size.width * 0.3, y: y - 10),
                        control2: CGPoint(x: size.width * 0.7, y: y + 22)
                    )
                    context.stroke(path, with: .color(.black.opacity(0.05)), lineWidth: 1)
                }
            }
        }
        .ignoresSafeArea()
    }
}

private struct DialedNumberDisplay: View {
    let phoneNumber: String
    let onDelete: () -> Void
    let onClear: () -> Void

    var body: some View {
        HStack(spacing: 14) {
            Button("Clear", action: onClear)
                .disabled(phoneNumber.isEmpty)

            Text(phoneNumber.isEmpty ? "Dial a number" : phoneNumber)
                .font(.system(.title2, design: .monospaced, weight: .medium))
                .foregroundStyle(phoneNumber.isEmpty ? Color.secondary : Color.black)
                .lineLimit(1)
                .minimumScaleFactor(0.55)
                .frame(maxWidth: .infinity)

            Button(action: onDelete) {
                Label("Delete", systemImage: "delete.left")
                    .labelStyle(.iconOnly)
                    .font(.title3)
            }
            .disabled(phoneNumber.isEmpty)
        }
        .buttonStyle(.plain)
        .foregroundStyle(.brown)
        .padding(.horizontal, 16)
        .frame(height: 54)
        .background(Color(red: 0.91, green: 0.86, blue: 0.73), in: RoundedRectangle(cornerRadius: 14))
        .overlay {
            RoundedRectangle(cornerRadius: 14)
                .stroke(.black.opacity(0.2), lineWidth: 1)
        }
        .shadow(color: .black.opacity(0.25), radius: 5, y: 3)
        .accessibilityElement(children: .contain)
    }
}

private struct CallButton: View {
    let isEnabled: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Label("Call", systemImage: "phone.fill")
                .font(.title3.weight(.semibold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 13)
        }
        .buttonStyle(.borderedProminent)
        .tint(Color(red: 0.16, green: 0.46, blue: 0.25))
        .clipShape(Capsule())
        .disabled(!isEnabled)
    }
}

private struct VintageTelephone: View {
    let phoneNumber: String
    let onDigit: (String) -> Void

    var body: some View {
        GeometryReader { proxy in
            let width = proxy.size.width
            let height = proxy.size.height
            let dialSide = min(width * 0.89, height * 0.72)

            ZStack(alignment: .top) {
                TelephoneBase()

                RotaryDial(phoneNumber: phoneNumber, onDigit: onDigit)
                    .frame(width: dialSide, height: dialSide)
                    .offset(y: height * 0.245)

                Handset()
                    .frame(width: width * 1.02, height: height * 0.26)
                    .offset(y: height * 0.005)
            }
            .frame(width: width, height: height)
        }
    }
}

private struct TelephoneBase: View {
    var body: some View {
        UnevenRoundedRectangle(
            topLeadingRadius: 62,
            bottomLeadingRadius: 28,
            bottomTrailingRadius: 28,
            topTrailingRadius: 62
        )
        .fill(
            LinearGradient(
                colors: [
                    Color(red: 0.91, green: 0.87, blue: 0.75),
                    Color(red: 0.72, green: 0.67, blue: 0.55)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .overlay {
            UnevenRoundedRectangle(
                topLeadingRadius: 62,
                bottomLeadingRadius: 28,
                bottomTrailingRadius: 28,
                topTrailingRadius: 62
            )
            .stroke(.black.opacity(0.22), lineWidth: 2)
        }
        .padding(.horizontal, 14)
        .padding(.top, 42)
        .shadow(color: .black.opacity(0.38), radius: 14, y: 10)
    }
}

private struct Handset: View {
    var body: some View {
        ZStack {
            Capsule()
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.94, green: 0.90, blue: 0.80),
                            Color(red: 0.70, green: 0.65, blue: 0.54)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .padding(.horizontal, 34)
                .padding(.vertical, 22)

            HStack {
                RoundedRectangle(cornerRadius: 34)
                    .frame(width: 92)
                Spacer()
                RoundedRectangle(cornerRadius: 34)
                    .frame(width: 92)
            }
            .foregroundStyle(Color(red: 0.86, green: 0.81, blue: 0.70))
        }
        .overlay {
            Capsule()
                .stroke(.black.opacity(0.2), lineWidth: 2)
                .padding(.horizontal, 34)
                .padding(.vertical, 22)
        }
        .shadow(color: .black.opacity(0.4), radius: 8, y: 6)
        .accessibilityHidden(true)
    }
}

private struct RotaryDial: View {
    private static let markings = [
        DialMarking(digit: "1", letters: ""),
        DialMarking(digit: "2", letters: "ABC"),
        DialMarking(digit: "3", letters: "DEF"),
        DialMarking(digit: "4", letters: "GHI"),
        DialMarking(digit: "5", letters: "JKL"),
        DialMarking(digit: "6", letters: "MNO"),
        DialMarking(digit: "7", letters: "PRS"),
        DialMarking(digit: "8", letters: "TUV"),
        DialMarking(digit: "9", letters: "WXY"),
        DialMarking(digit: "0", letters: "OPERATOR")
    ]
    private static let numberStep = 27.0
    private static let firstNumberAngle = -55.0
    private static let minimumTravel = 30.0

    let phoneNumber: String
    let onDigit: (String) -> Void

    @State private var rotation = 0.0
    @State private var selectedIndex: Int?
    @State private var lastTouchAngle: Double?
    @State private var reachedStop = false
    @State private var clickCount = 0

    var body: some View {
        GeometryReader { proxy in
            let side = min(proxy.size.width, proxy.size.height)
            let center = CGPoint(x: proxy.size.width / 2, y: proxy.size.height / 2)

            ZStack {
                Circle()
                    .fill(Color(red: 0.88, green: 0.84, blue: 0.72))
                    .overlay {
                        Circle().stroke(.black.opacity(0.28), lineWidth: 2)
                    }

                StationaryNumberRing(
                    markings: Self.markings,
                    side: side,
                    firstNumberAngle: Self.firstNumberAngle,
                    numberStep: Self.numberStep
                )

                ClearFingerWheel(
                    count: Self.markings.count,
                    rotation: rotation,
                    side: side,
                    firstNumberAngle: Self.firstNumberAngle,
                    numberStep: Self.numberStep
                )

                NumberCard(phoneNumber: phoneNumber, side: side)
                FingerStop(side: side)
            }
            .frame(width: side, height: side)
            .position(center)
            .contentShape(Circle())
            .gesture(dialGesture(side: side, center: center))
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Rotary telephone dial")
            .accessibilityValue(phoneNumber.isEmpty ? "No digits entered" : phoneNumber)
            .accessibilityHint("Choose a digit from the accessibility actions, or drag a numbered hole clockwise to the stop.")
            .accessibilityActions {
                ForEach(Self.markings, id: \.digit) { marking in
                    Button("Dial \(marking.digit)") {
                        onDigit(marking.digit)
                    }
                }
            }
        }
        .sensoryFeedback(.selection, trigger: clickCount)
    }

    private func dialGesture(side: CGFloat, center: CGPoint) -> some Gesture {
        DragGesture(minimumDistance: 0, coordinateSpace: .local)
            .onChanged { value in
                let touchAngle = angle(from: center, to: value.location)

                if selectedIndex == nil {
                    guard let index = holeIndex(at: value.startLocation, center: center, side: side) else {
                        return
                    }
                    selectedIndex = index
                    lastTouchAngle = touchAngle
                    reachedStop = false
                }

                guard let index = selectedIndex, let previousAngle = lastTouchAngle else {
                    return
                }

                let delta = normalizedDelta(from: previousAngle, to: touchAngle)
                let oldStep = Int(rotation / 9)
                let maximumRotation = Self.minimumTravel + (Double(index) * Self.numberStep)
                rotation = min(max(rotation + delta, 0), maximumRotation)
                lastTouchAngle = touchAngle

                if Int(rotation / 9) > oldStep {
                    clickCount += 1
                }
                reachedStop = rotation >= maximumRotation - 2
            }
            .onEnded { _ in
                guard let index = selectedIndex else { return }
                let digit = Self.markings[index].digit
                let shouldEnterDigit = reachedStop

                selectedIndex = nil
                lastTouchAngle = nil
                reachedStop = false

                withAnimation(.spring(duration: 0.6, bounce: 0.15)) {
                    rotation = 0
                }

                if shouldEnterDigit {
                    onDigit(digit)
                }
            }
    }

    private func holeIndex(at location: CGPoint, center: CGPoint, side: CGFloat) -> Int? {
        let ringRadius = side * 0.315
        let hitRadius = side * 0.065

        return Self.markings.indices.first { index in
            let position = point(
                center: center,
                radius: ringRadius,
                angle: Self.firstNumberAngle - (Double(index) * Self.numberStep)
            )
            return hypot(location.x - position.x, location.y - position.y) <= hitRadius
        }
    }

    private func point(center: CGPoint, radius: CGFloat, angle: Double) -> CGPoint {
        let radians = angle * .pi / 180
        return CGPoint(
            x: center.x + (radius * cos(radians)),
            y: center.y + (radius * sin(radians))
        )
    }

    private func angle(from center: CGPoint, to point: CGPoint) -> Double {
        atan2(point.y - center.y, point.x - center.x) * 180 / .pi
    }

    private func normalizedDelta(from oldAngle: Double, to newAngle: Double) -> Double {
        var delta = newAngle - oldAngle
        if delta > 180 {
            delta -= 360
        } else if delta < -180 {
            delta += 360
        }
        return delta
    }
}

private struct DialMarking: Hashable {
    let digit: String
    let letters: String
}

private struct StationaryNumberRing: View {
    let markings: [DialMarking]
    let side: CGFloat
    let firstNumberAngle: Double
    let numberStep: Double

    var body: some View {
        ZStack {
            ForEach(Array(markings.enumerated()), id: \.offset) { index, marking in
                UprightDialLabel(
                    marking: marking,
                    side: side,
                    angle: firstNumberAngle - (Double(index) * numberStep)
                )
            }
        }
    }
}

private struct UprightDialLabel: View {
    let marking: DialMarking
    let side: CGFloat
    let angle: Double

    var body: some View {
        let radians = angle * .pi / 180
        let digitRadius = side * 0.395
        let letterRadius = side * 0.465
        let letterSize = marking.digit == "0" ? side * 0.021 : side * 0.031

        ZStack {
            Text(marking.digit)
                .font(.system(size: side * 0.064, weight: .black, design: .rounded))
                .offset(
                    x: digitRadius * cos(radians),
                    y: digitRadius * sin(radians)
                )

            Text(marking.letters)
                .font(.system(size: letterSize, weight: .black, design: .rounded))
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .frame(width: side * 0.20)
                .offset(
                    x: letterRadius * cos(radians),
                    y: letterRadius * sin(radians)
                )
        }
        .foregroundStyle(.black)
        .accessibilityHidden(true)
    }
}

private struct ClearFingerWheel: View {
    let count: Int
    let rotation: Double
    let side: CGFloat
    let firstNumberAngle: Double
    let numberStep: Double

    var body: some View {
        ZStack {
            Circle()
                .fill(.white.opacity(0.20))
                .frame(width: side * 0.73, height: side * 0.73)
                .overlay {
                    Circle().stroke(.white.opacity(0.75), lineWidth: side * 0.014)
                }

            Circle()
                .stroke(.black.opacity(0.24), lineWidth: side * 0.025)
                .frame(width: side * 0.47, height: side * 0.47)

            ForEach(0..<count, id: \.self) { index in
                FingerHole(
                    side: side,
                    angle: firstNumberAngle - (Double(index) * numberStep)
                )
            }
        }
        .rotationEffect(.degrees(rotation))
        .shadow(color: .black.opacity(0.25), radius: 4, y: 3)
    }
}

private struct FingerHole: View {
    let side: CGFloat
    let angle: Double

    var body: some View {
        let radians = angle * .pi / 180
        let radius = side * 0.315

        Circle()
            .fill(Color(red: 0.82, green: 0.77, blue: 0.65))
            .overlay {
                Circle()
                    .stroke(
                        LinearGradient(
                            colors: [.white.opacity(0.9), .black.opacity(0.45)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: side * 0.014
                    )
            }
            .frame(width: side * 0.125, height: side * 0.125)
            .offset(
                x: radius * cos(radians),
                y: radius * sin(radians)
            )
    }
}

private struct NumberCard: View {
    let phoneNumber: String
    let side: CGFloat

    var body: some View {
        Circle()
            .fill(Color(red: 0.94, green: 0.91, blue: 0.81))
            .frame(width: side * 0.40, height: side * 0.40)
            .overlay {
                Circle().stroke(.black.opacity(0.35), lineWidth: 2)
            }
            .overlay {
                VStack(spacing: side * 0.012) {
                    Text("AREA CODE")
                        .font(.system(size: side * 0.033, weight: .bold, design: .rounded))
                    Text("555")
                        .font(.system(size: side * 0.055, weight: .bold, design: .monospaced))
                    Divider()
                        .frame(width: side * 0.24)
                    Text(phoneNumber.isEmpty ? "• • • • • • •" : phoneNumber)
                        .font(.system(size: side * 0.038, weight: .medium, design: .monospaced))
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                        .frame(width: side * 0.31)
                }
                .foregroundStyle(.black.opacity(0.78))
            }
            .shadow(color: .black.opacity(0.25), radius: 3, y: 2)
    }
}

private struct FingerStop: View {
    let side: CGFloat

    var body: some View {
        Capsule()
            .fill(
                LinearGradient(
                    colors: [
                        Color(red: 0.35, green: 0.35, blue: 0.33),
                        Color(red: 0.86, green: 0.86, blue: 0.80),
                        Color(red: 0.28, green: 0.28, blue: 0.27)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .frame(width: side * 0.055, height: side * 0.20)
            .overlay {
                Capsule().stroke(.black.opacity(0.7), lineWidth: 1.5)
            }
            .rotationEffect(.degrees(-56))
            .offset(x: side * 0.36, y: side * 0.13)
            .shadow(color: .black.opacity(0.5), radius: 3, y: 2)
            .accessibilityHidden(true)
    }
}

#Preview {
    ContentView()
}
