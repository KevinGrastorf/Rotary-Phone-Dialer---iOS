import SwiftUI
import Foundation
import AVFAudio
import Contacts
import ContactsUI

private enum DialerTheme: String, CaseIterable, Identifiable {
    case classicWalnut
    case midnightTeal
    case cherryCream
    case sageBrass
    case slateBlue

    var id: String { rawValue }

    var name: String {
        switch self {
        case .classicWalnut: String(localized: "Classic Walnut")
        case .midnightTeal: String(localized: "Midnight Teal")
        case .cherryCream: String(localized: "Cherry Cream")
        case .sageBrass: String(localized: "Sage & Brass")
        case .slateBlue: String(localized: "Slate Blue")
        }
    }

    var backgroundColors: [Color] {
        switch self {
        case .classicWalnut:
            [Color(red: 0.65, green: 0.40, blue: 0.18), Color(red: 0.82, green: 0.58, blue: 0.29), Color(red: 0.58, green: 0.34, blue: 0.15)]
        case .midnightTeal:
            [Color(red: 0.04, green: 0.14, blue: 0.18), Color(red: 0.08, green: 0.34, blue: 0.36), Color(red: 0.03, green: 0.18, blue: 0.24)]
        case .cherryCream:
            [Color(red: 0.35, green: 0.06, blue: 0.10), Color(red: 0.68, green: 0.20, blue: 0.24), Color(red: 0.28, green: 0.04, blue: 0.08)]
        case .sageBrass:
            [Color(red: 0.20, green: 0.28, blue: 0.20), Color(red: 0.43, green: 0.52, blue: 0.37), Color(red: 0.16, green: 0.23, blue: 0.18)]
        case .slateBlue:
            [Color(red: 0.15, green: 0.22, blue: 0.32), Color(red: 0.34, green: 0.48, blue: 0.62), Color(red: 0.12, green: 0.18, blue: 0.28)]
        }
    }

    var displayColor: Color {
        switch self {
        case .classicWalnut: Color(red: 0.91, green: 0.86, blue: 0.73)
        case .midnightTeal: Color(red: 0.78, green: 0.91, blue: 0.87)
        case .cherryCream: Color(red: 0.98, green: 0.89, blue: 0.81)
        case .sageBrass: Color(red: 0.91, green: 0.87, blue: 0.68)
        case .slateBlue: Color(red: 0.86, green: 0.91, blue: 0.96)
        }
    }

    var accentColor: Color {
        switch self {
        case .classicWalnut: Color(red: 0.35, green: 0.18, blue: 0.08)
        case .midnightTeal: Color(red: 0.04, green: 0.35, blue: 0.34)
        case .cherryCream: Color(red: 0.52, green: 0.08, blue: 0.13)
        case .sageBrass: Color(red: 0.38, green: 0.35, blue: 0.12)
        case .slateBlue: Color(red: 0.16, green: 0.31, blue: 0.48)
        }
    }
}

private struct AutoDialRequest: Equatable {
    let id = UUID()
    let digits: String
}

private struct ContactPhoneOption: Identifiable {
    let id = UUID()
    let label: String
    let displayNumber: String
    let digits: String
}

struct ContentView: View {
    @Environment(\.openURL) private var openURL
    @AppStorage("localAreaCode") private var areaCode = "213"
    @AppStorage("dialerTheme") private var selectedThemeRawValue = DialerTheme.classicWalnut.rawValue
    @State private var phoneNumber = ""
    @State private var showsCallError = false
    @State private var showsAreaCodeEditor = false
    @State private var areaCodeDraft = ""
    @State private var showsPrivacyPolicy = false
    @State private var showsContactPicker = false
    @State private var showsPhoneNumberChoices = false
    @State private var selectedContactName = ""
    @State private var contactPhoneOptions: [ContactPhoneOption] = []
    @State private var autoDialRequest: AutoDialRequest?

    private var selectedTheme: DialerTheme {
        DialerTheme(rawValue: selectedThemeRawValue) ?? .classicWalnut
    }

    var body: some View {
        ZStack {
            WoodBackground(theme: selectedTheme)

            VStack(spacing: 12) {
                DialedNumberDisplay(
                    phoneNumber: phoneNumber,
                    theme: selectedTheme,
                    onDelete: deleteLastDigit,
                    onClear: clearNumber
                )

                VintageTelephone(
                    phoneNumber: phoneNumber,
                    areaCode: areaCode,
                    autoDialRequest: autoDialRequest,
                    onEditAreaCode: editAreaCode,
                    onDigit: { digit in
                        phoneNumber.append(digit)
                    },
                    onAutoDialComplete: callNumber
                )
                .frame(maxWidth: 560)
                .aspectRatio(1, contentMode: .fit)

                CallButton(
                    isEnabled: !phoneNumber.isEmpty,
                    tint: selectedTheme.accentColor,
                    action: callNumber
                )

                HStack(spacing: 12) {
                    ThemePicker(selection: $selectedThemeRawValue, selectedTheme: selectedTheme)

                    Button {
                        showsContactPicker = true
                    } label: {
                        Label("Choose Contact", systemImage: "person.crop.circle.badge.plus")
                            .labelStyle(.iconOnly)
                            .font(.title3.weight(.semibold))
                            .frame(width: 44, height: 44)
                    }
                    .buttonStyle(.bordered)
                    .tint(selectedTheme.displayColor)
                    .foregroundStyle(.white)
                    .accessibilityHint("Choose a contact to dial automatically")

                    Button {
                        showsPrivacyPolicy = true
                    } label: {
                        Label("Privacy Policy", systemImage: "hand.raised.fill")
                            .labelStyle(.iconOnly)
                            .font(.title3.weight(.semibold))
                            .frame(width: 44, height: 44)
                    }
                    .buttonStyle(.bordered)
                    .tint(selectedTheme.displayColor)
                    .foregroundStyle(.white)
                    .accessibilityHint("View the privacy policy")
                }
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 12)
        }
        .alert("Unable to Start Call", isPresented: $showsCallError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Calling is unavailable on this device. Try again on an iPhone with the Phone app configured.")
        }
        .alert("Set Your Area Code", isPresented: $showsAreaCodeEditor) {
            TextField("Area code", text: $areaCodeDraft)
                .keyboardType(.numberPad)
            Button("Cancel", role: .cancel) {}
            Button("Save", action: saveAreaCode)
                .disabled(areaCodeDraft.filter(\.isNumber).count != 3)
        } message: {
            Text("Enter the three-digit area code to print on the center card.")
        }
        .sheet(isPresented: $showsPrivacyPolicy) {
            PrivacyPolicyView()
        }
        .sheet(isPresented: $showsContactPicker) {
            ContactPicker(
                isPresented: $showsContactPicker,
                onSelect: handleContactSelection
            )
        }
        .confirmationDialog(
            "Choose a Number for \(selectedContactName)",
            isPresented: $showsPhoneNumberChoices,
            titleVisibility: .visible
        ) {
            ForEach(contactPhoneOptions) { option in
                Button("\(option.label): \(option.displayNumber)") {
                    startAutomaticDial(option.digits)
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("The rotary dial will enter the selected number and then open the Phone app.")
        }
    }

    private func deleteLastDigit() {
        guard !phoneNumber.isEmpty else { return }
        phoneNumber.removeLast()
    }

    private func clearNumber() {
        phoneNumber = ""
    }

    private func editAreaCode() {
        areaCodeDraft = areaCode
        showsAreaCodeEditor = true
    }

    private func saveAreaCode() {
        let digits = areaCodeDraft.filter(\.isNumber)
        guard digits.count == 3 else { return }
        areaCode = digits
    }

    private func handleContactSelection(
        name: String,
        phoneNumbers: [ContactPhoneOption]
    ) {
        selectedContactName = name
        contactPhoneOptions = phoneNumbers

        if let onlyNumber = phoneNumbers.first, phoneNumbers.count == 1 {
            startAutomaticDial(onlyNumber.digits)
        } else if !phoneNumbers.isEmpty {
            showsPhoneNumberChoices = true
        }
    }

    private func startAutomaticDial(_ digits: String) {
        guard !digits.isEmpty else { return }
        phoneNumber = ""
        autoDialRequest = AutoDialRequest(digits: digits)
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

private struct ContactPicker: UIViewControllerRepresentable {
    @Binding var isPresented: Bool
    let onSelect: (String, [ContactPhoneOption]) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    func makeUIViewController(context: Context) -> CNContactPickerViewController {
        let picker = CNContactPickerViewController()
        picker.delegate = context.coordinator
        picker.displayedPropertyKeys = [CNContactPhoneNumbersKey]
        picker.predicateForEnablingContact = NSPredicate(
            format: "phoneNumbers.@count > 0"
        )
        return picker
    }

    func updateUIViewController(
        _ uiViewController: CNContactPickerViewController,
        context: Context
    ) {}

    final class Coordinator: NSObject, CNContactPickerDelegate {
        private let parent: ContactPicker

        init(parent: ContactPicker) {
            self.parent = parent
        }

        func contactPicker(
            _ picker: CNContactPickerViewController,
            didSelect contact: CNContact
        ) {
            let name = CNContactFormatter.string(
                from: contact,
                style: .fullName
            ) ?? "Selected Contact"

            let phoneNumbers: [ContactPhoneOption] = contact.phoneNumbers.compactMap { labeledValue -> ContactPhoneOption? in
                let displayNumber = labeledValue.value.stringValue
                let digits = displayNumber.filter(\.isNumber)
                guard !digits.isEmpty else { return nil }

                let label = labeledValue.label.map {
                    CNLabeledValue<NSString>.localizedString(forLabel: $0)
                } ?? "Phone"

                return ContactPhoneOption(
                    label: label,
                    displayNumber: displayNumber,
                    digits: digits
                )
            }

            parent.isPresented = false
            parent.onSelect(name, phoneNumbers)
        }

        func contactPickerDidCancel(_ picker: CNContactPickerViewController) {
            parent.isPresented = false
        }
    }
}

private struct PrivacyPolicyView: View {
    @Environment(\.dismiss) private var dismiss
    private let onlinePolicyURL = URL(
        string: "https://kev-dev.com/rotary-phone-dialer-privacy-policy/"
    )

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Privacy Policy")
                    .font(.headline)

                Spacer()

                Button("Done") {
                    dismiss()
                }
                .font(.body.weight(.semibold))
            }
            .padding()

            Divider()

            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Privacy Policy")
                            .font(.largeTitle.weight(.bold))

                        Text("Effective date: Oct 25, 2026")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    Text("Retro Rotary Dialer does not collect, store, or share any personal information. This policy explains how the app works and applies to the app and to https://kev-dev.com/rotary-phone-dialer-privacy-policy/.")

                    Text("Retro Rotary Dialer is a rotary-style dialer made by Kevin Grastorf (\"we,\" \"us\"). You dial a number on the on-screen rotary dial, and the app hands that number to your device’s built-in Phone app to place the call.")

                    PrivacyPolicySection("Information we collect") {
                        Text("We collect no information. Specifically, the app does not:")

                        VStack(alignment: .leading, spacing: 8) {
                            Text("• Collect your name, email, phone number, location, or any other personal information")
                            Text("• Store the numbers you dial, your call history, or your contacts")
                            Text("• Use analytics, advertising, or tracking tools")
                            Text("• Use cookies or device identifiers")
                            Text("• Send any data to us or to any server")
                        }

                        Text("Numbers you dial exist only for the moment it takes to pass them to your Phone app. Nothing is saved on your device or anywhere else.")
                    }

                    PrivacyPolicySection("Permissions and calls") {
                        Text("The app requests no device permissions. It does not access your microphone, camera, location, photos, or storage, and it cannot read your contact list.")

                        Text("Contacts you select. If you choose to dial someone from your contacts, your device shows its own contact picker. The app receives only the contact you pick and uses that phone number to fill in the dial. It cannot see your other contacts, and it does not save the contact or send it anywhere.")

                        Text("Region setting. The app reads your device's region setting only to format phone numbers the way they are written where you live. This happens on your device, and the setting is not stored or sent anywhere.")

                        Text("When you finish dialing, the app opens your device's Phone app with the number filled in. The call itself is placed and handled entirely by your Phone app and your mobile carrier, under their own privacy policies. We never see or receive any information about your calls.")
                    }

                    PrivacyPolicySection("Third parties") {
                        Text("We do not share, sell, or rent any information, because we have none to share. The app store you downloaded the app from (such as the Apple App Store or Google Play) may collect information under its own privacy policy. We do not control or receive that data.")
                    }

                    PrivacyPolicySection("Children’s privacy") {
                        Text("The app collects no information from anyone, including children under 13.")
                    }

                    if let onlinePolicyURL {
                        Link(
                            "View Privacy Policy Online",
                            destination: onlinePolicyURL
                        )
                        .font(.body.weight(.semibold))
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(20)
            }
        }
    }
}

private struct PrivacyPolicySection<Content: View>: View {
    let title: LocalizedStringKey
    @ViewBuilder let content: Content

    init(_ title: LocalizedStringKey, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.title2.weight(.semibold))

            content
        }
    }
}

private struct WoodBackground: View {
    let theme: DialerTheme

    var body: some View {
        LinearGradient(
            colors: theme.backgroundColors,
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
    @Environment(\.locale) private var locale

    let phoneNumber: String
    let theme: DialerTheme
    let onDelete: () -> Void
    let onClear: () -> Void

    var body: some View {
        HStack(spacing: 14) {
            Button("Clear", action: onClear)
                .disabled(phoneNumber.isEmpty)

            Text(phoneNumber.isEmpty ? String(localized: "Dial a number") : formattedPhoneNumber)
                .font(.system(.title2, design: .monospaced))
                .fontWeight(.medium)
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
        .foregroundStyle(theme.accentColor)
        .padding(.horizontal, 16)
        .frame(height: 54)
        .background(theme.displayColor, in: RoundedRectangle(cornerRadius: 14))
        .overlay {
            RoundedRectangle(cornerRadius: 14)
                .stroke(.black.opacity(0.2), lineWidth: 1)
        }
        .shadow(color: .black.opacity(0.25), radius: 5, y: 3)
        .accessibilityElement(children: .contain)
    }

    private var formattedPhoneNumber: String {
        RegionalPhoneNumberFormatter.format(
            phoneNumber,
            regionCode: locale.regionCode
        )
    }
}

private enum RegionalPhoneNumberFormatter {
    static func format(_ phoneNumber: String, regionCode: String?) -> String {
        let digits = phoneNumber.filter(\.isNumber)
        guard !digits.isEmpty else { return phoneNumber }

        switch regionCode?.uppercased() {
        case "US", "CA", "AS", "AG", "AI", "BS", "BB", "BM", "VG", "KY",
             "DM", "DO", "GD", "GU", "JM", "MS", "MP", "PR", "KN", "LC",
             "VC", "SX", "TT", "TC", "VI":
            return northAmericanNumber(digits)

        case "GB":
            let national = nationalNumber(
                digits,
                callingCode: "44",
                nationalPrefix: "0",
                maximumLength: 11
            )
            if national.hasPrefix("02") {
                return grouped(national, sizes: [3, 4, 4], separator: " ")
            } else if national.hasPrefix("07") {
                return grouped(national, sizes: [5, 6], separator: " ")
            }
            return grouped(national, sizes: [4, 3, 4], separator: " ")

        case "FR":
            return grouped(
                nationalNumber(
                    digits,
                    callingCode: "33",
                    nationalPrefix: "0",
                    maximumLength: 10
                ),
                sizes: [2, 2, 2, 2, 2],
                separator: " "
            )

        case "AU":
            let national = nationalNumber(
                digits,
                callingCode: "61",
                nationalPrefix: "0",
                maximumLength: 10
            )
            return grouped(
                national,
                sizes: national.hasPrefix("04") ? [4, 3, 3] : [2, 4, 4],
                separator: " "
            )

        case "NZ":
            return grouped(
                nationalNumber(
                    digits,
                    callingCode: "64",
                    nationalPrefix: "0",
                    maximumLength: 10
                ),
                sizes: [3, 3, 4],
                separator: " "
            )

        case "BR":
            return parenthesizedNumber(
                nationalNumber(
                    digits,
                    callingCode: "55",
                    nationalPrefix: "",
                    maximumLength: 11
                ),
                areaCodeLength: 2,
                localGroups: [5, 4]
            )

        case "JP":
            return grouped(
                nationalNumber(
                    digits,
                    callingCode: "81",
                    nationalPrefix: "0",
                    maximumLength: 11
                ),
                sizes: [3, 4, 4],
                separator: "-"
            )

        case "KR":
            return grouped(
                nationalNumber(
                    digits,
                    callingCode: "82",
                    nationalPrefix: "0",
                    maximumLength: 11
                ),
                sizes: [3, 4, 4],
                separator: "-"
            )

        case "CN":
            return grouped(digits, sizes: [3, 4, 4], separator: " ")

        case "IN":
            return grouped(digits, sizes: [5, 5], separator: " ")

        case "DE", "AT", "NL", "IT", "ZA", "IL", "MY", "TH", "PH":
            return grouped(digits, sizes: [3, 3, 4], separator: " ")

        case "ES", "PT", "PL", "CZ", "SK":
            return grouped(digits, sizes: [3, 3, 3], separator: " ")

        case "DK", "NO":
            return grouped(digits, sizes: [2, 2, 2, 2], separator: " ")

        case "SE", "CH", "BE", "FI":
            return grouped(digits, sizes: [3, 3, 2, 2], separator: " ")

        case "SG", "HK":
            return grouped(digits, sizes: [4, 4], separator: " ")

        case "MX", "AR":
            return grouped(digits, sizes: [2, 4, 4], separator: " ")

        case "RU", "TR", "AE", "SA":
            return grouped(digits, sizes: [3, 3, 2, 2], separator: " ")

        default:
            return grouped(digits, sizes: [3, 3, 3, 3], separator: " ")
        }
    }

    private static func northAmericanNumber(_ digits: String) -> String {
        var national = digits
        var countryCode = ""

        if national.first == "1" {
            countryCode = "1 "
            national.removeFirst()
        }

        guard !national.isEmpty else {
            return countryCode.trimmingCharacters(in: .whitespaces)
        }

        return countryCode + parenthesizedNumber(
            national,
            areaCodeLength: 3,
            localGroups: [3, 4]
        )
    }

    private static func parenthesizedNumber(
        _ digits: String,
        areaCodeLength: Int,
        localGroups: [Int]
    ) -> String {
        guard digits.count > areaCodeLength else {
            let closingParenthesis = digits.count == areaCodeLength ? ")" : ""
            return "(\(digits)\(closingParenthesis)"
        }

        let areaCode = digits.prefix(areaCodeLength)
        let localNumber = String(digits.dropFirst(areaCodeLength))
        return "(\(areaCode)) "
            + grouped(localNumber, sizes: localGroups, separator: "-")
    }

    private static func nationalNumber(
        _ digits: String,
        callingCode: String,
        nationalPrefix: String,
        maximumLength: Int
    ) -> String {
        guard digits.count > maximumLength,
              digits.hasPrefix(callingCode) else {
            return digits
        }

        return nationalPrefix + digits.dropFirst(callingCode.count)
    }

    private static func grouped(
        _ digits: String,
        sizes: [Int],
        separator: String
    ) -> String {
        var groups: [String] = []
        var start = digits.startIndex

        for size in sizes where start < digits.endIndex {
            let end = digits.index(
                start,
                offsetBy: size,
                limitedBy: digits.endIndex
            ) ?? digits.endIndex
            groups.append(String(digits[start..<end]))
            start = end
        }

        if start < digits.endIndex {
            groups.append(String(digits[start...]))
        }

        return groups.joined(separator: separator)
    }
}

private struct CallButton: View {
    let isEnabled: Bool
    let tint: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Label("Call", systemImage: "phone.fill")
                .font(.title3.weight(.semibold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 13)
        }
        .buttonStyle(.borderedProminent)
        .tint(tint)
        .clipShape(Capsule())
        .disabled(!isEnabled)
    }
}

private struct ThemePicker: View {
    @Binding var selection: String
    let selectedTheme: DialerTheme

    var body: some View {
        Menu {
            Picker("Theme", selection: $selection) {
                ForEach(DialerTheme.allCases) { theme in
                    Text(theme.name)
                        .tag(theme.rawValue)
                }
            }
        } label: {
            Label("Theme", systemImage: "paintpalette.fill")
                .labelStyle(.iconOnly)
                .font(.title3.weight(.semibold))
                .frame(width: 44, height: 44)
        }
        .buttonStyle(.bordered)
        .tint(selectedTheme.displayColor)
        .foregroundStyle(.white)
        .accessibilityLabel("Theme")
        .accessibilityValue(selectedTheme.name)
        .accessibilityHint("Choose a background and number display color theme")
    }
}

private struct VintageTelephone: View {
    let phoneNumber: String
    let areaCode: String
    let autoDialRequest: AutoDialRequest?
    let onEditAreaCode: () -> Void
    let onDigit: (String) -> Void
    let onAutoDialComplete: () -> Void

    var body: some View {
        GeometryReader { proxy in
            let width = proxy.size.width
            let height = proxy.size.height
            let dialSide = min(width, height) * 0.98

            ZStack {
                RotaryDial(
                    phoneNumber: phoneNumber,
                    areaCode: areaCode,
                    autoDialRequest: autoDialRequest,
                    onEditAreaCode: onEditAreaCode,
                    onDigit: onDigit,
                    onAutoDialComplete: onAutoDialComplete
                )
                .frame(width: dialSide, height: dialSide)
                .position(x: width * 0.5, y: height * 0.5)
            }
            .frame(width: width, height: height)
        }
    }
}

private struct TelephoneBase: View {
    var body: some View {
        RoundedRectangle(cornerRadius: 40, style: .continuous)
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
            RoundedRectangle(cornerRadius: 40, style: .continuous)
            .stroke(.black.opacity(0.22), lineWidth: 2)
        }
        .padding(.horizontal, 14)
        .padding(.top, 42)
        .shadow(color: .black.opacity(0.38), radius: 14, y: 10)
    }
}

private struct Handset: View {
    var body: some View {
        GeometryReader { proxy in
            let width = proxy.size.width
            let height = proxy.size.height

            ZStack {
                HandsetBodyShape()
                    .fill(
                        LinearGradient(
                            stops: [
                                .init(color: Color(red: 0.97, green: 0.94, blue: 0.86), location: 0),
                                .init(color: Color(red: 0.88, green: 0.84, blue: 0.74), location: 0.48),
                                .init(color: Color(red: 0.69, green: 0.64, blue: 0.54), location: 1)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .overlay {
                        HandsetBodyShape()
                            .stroke(.black.opacity(0.28), lineWidth: 1.5)
                    }
                    .overlay {
                        HandsetBodyShape()
                            .stroke(.white.opacity(0.42), lineWidth: 1)
                            .offset(y: -1)
                            .mask {
                                LinearGradient(colors: [.white, .clear], startPoint: .top, endPoint: .center)
                            }
                    }
                    .overlay {
                        LinearGradient(
                            colors: [.white.opacity(0.20), .clear, .black.opacity(0.10)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                        .clipShape(HandsetBodyShape())
                    }

                HandsetGripRidgeShape()
                    .stroke(
                        LinearGradient(
                            colors: [.white.opacity(0.48), .black.opacity(0.16)],
                            startPoint: .top,
                            endPoint: .bottom
                        ),
                        style: StrokeStyle(lineWidth: 1.2, lineCap: .round)
                    )
                    .padding(.horizontal, width * 0.025)
                    .padding(.vertical, height * 0.02)

                HStack(spacing: 0) {
                    receiverEnd(isLeading: true, width: width, height: height)
                    Spacer(minLength: 0)
                    receiverEnd(isLeading: false, width: width, height: height)
                }
                .padding(.horizontal, width * 0.018)
                .padding(.top, height * 0.20)

                HStack {
                    seam(height: height)
                        .rotationEffect(.degrees(-5))
                    Spacer()
                    seam(height: height)
                        .rotationEffect(.degrees(5))
                }
                .padding(.horizontal, width * 0.272)
                .padding(.top, height * 0.23)
            }
            .shadow(color: .black.opacity(0.18), radius: 2, y: 2)
            .shadow(color: .black.opacity(0.42), radius: 8, y: 7)
        }
        .accessibilityHidden(true)
    }

    private func receiverEnd(isLeading: Bool, width: CGFloat, height: CGFloat) -> some View {
        HandsetEndShape(isLeading: isLeading)
        .fill(
            LinearGradient(
                stops: [
                    .init(color: Color.white.opacity(0.24), location: 0),
                    .init(color: Color(red: 0.84, green: 0.79, blue: 0.68).opacity(0.36), location: 0.5),
                    .init(color: Color(red: 0.58, green: 0.54, blue: 0.46).opacity(0.32), location: 1)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .overlay {
            HandsetEndShape(isLeading: isLeading)
                .stroke(
                    LinearGradient(
                        colors: [.white.opacity(0.34), .black.opacity(0.18)],
                        startPoint: .top,
                        endPoint: .bottom
                    ),
                    lineWidth: 1
                )
        }
        .frame(width: width * 0.275, height: height * 0.64)
    }

    private func seam(height: CGFloat) -> some View {
        Capsule()
            .fill(
                LinearGradient(
                    colors: [.black.opacity(0.16), .white.opacity(0.20)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .frame(width: 1.5, height: height * 0.37)
    }
}

private struct HandsetEndShape: Shape {
    let isLeading: Bool

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let outerX = isLeading ? rect.minX : rect.maxX
        let innerX = isLeading ? rect.maxX : rect.minX
        let direction: CGFloat = isLeading ? 1 : -1

        path.move(to: CGPoint(x: innerX, y: rect.minY + rect.height * 0.10))
        path.addCurve(
            to: CGPoint(x: outerX + direction * rect.width * 0.08, y: rect.minY + rect.height * 0.18),
            control1: CGPoint(x: innerX - direction * rect.width * 0.28, y: rect.minY),
            control2: CGPoint(x: outerX + direction * rect.width * 0.18, y: rect.minY)
        )
        path.addCurve(
            to: CGPoint(x: outerX, y: rect.minY + rect.height * 0.68),
            control1: CGPoint(x: outerX, y: rect.minY + rect.height * 0.30),
            control2: CGPoint(x: outerX, y: rect.minY + rect.height * 0.55)
        )
        path.addCurve(
            to: CGPoint(x: outerX + direction * rect.width * 0.28, y: rect.maxY),
            control1: CGPoint(x: outerX, y: rect.minY + rect.height * 0.88),
            control2: CGPoint(x: outerX + direction * rect.width * 0.12, y: rect.maxY)
        )
        path.addCurve(
            to: CGPoint(x: innerX, y: rect.minY + rect.height * 0.72),
            control1: CGPoint(x: innerX - direction * rect.width * 0.22, y: rect.maxY),
            control2: CGPoint(x: innerX - direction * rect.width * 0.04, y: rect.minY + rect.height * 0.88)
        )
        path.closeSubpath()
        return path
    }
}

private struct HandsetGripRidgeShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX + rect.width * 0.29, y: rect.minY + rect.height * 0.25))
        path.addCurve(
            to: CGPoint(x: rect.minX + rect.width * 0.71, y: rect.minY + rect.height * 0.25),
            control1: CGPoint(x: rect.minX + rect.width * 0.41, y: rect.minY + rect.height * 0.18),
            control2: CGPoint(x: rect.minX + rect.width * 0.59, y: rect.minY + rect.height * 0.18)
        )
        return path
    }
}

private struct HandsetBodyShape: Shape {
    func path(in rect: CGRect) -> Path {
        let x = rect.minX
        let y = rect.minY
        let width = rect.width
        let height = rect.height

        var path = Path()
        path.move(to: CGPoint(x: x + width * 0.08, y: y + height * 0.24))
        path.addCurve(
            to: CGPoint(x: x + width * 0.31, y: y + height * 0.14),
            control1: CGPoint(x: x + width * 0.14, y: y + height * 0.12),
            control2: CGPoint(x: x + width * 0.23, y: y + height * 0.13)
        )
        path.addCurve(
            to: CGPoint(x: x + width * 0.69, y: y + height * 0.14),
            control1: CGPoint(x: x + width * 0.41, y: y + height * 0.08),
            control2: CGPoint(x: x + width * 0.59, y: y + height * 0.08)
        )
        path.addCurve(
            to: CGPoint(x: x + width * 0.92, y: y + height * 0.24),
            control1: CGPoint(x: x + width * 0.77, y: y + height * 0.13),
            control2: CGPoint(x: x + width * 0.86, y: y + height * 0.12)
        )
        path.addCurve(
            to: CGPoint(x: x + width * 0.95, y: y + height * 0.68),
            control1: CGPoint(x: x + width, y: y + height * 0.35),
            control2: CGPoint(x: x + width, y: y + height * 0.58)
        )
        path.addCurve(
            to: CGPoint(x: x + width * 0.78, y: y + height * 0.88),
            control1: CGPoint(x: x + width * 0.91, y: y + height * 0.83),
            control2: CGPoint(x: x + width * 0.84, y: y + height * 0.90)
        )
        path.addCurve(
            to: CGPoint(x: x + width * 0.70, y: y + height * 0.58),
            control1: CGPoint(x: x + width * 0.73, y: y + height * 0.87),
            control2: CGPoint(x: x + width * 0.70, y: y + height * 0.72)
        )
        path.addCurve(
            to: CGPoint(x: x + width * 0.30, y: y + height * 0.58),
            control1: CGPoint(x: x + width * 0.58, y: y + height * 0.52),
            control2: CGPoint(x: x + width * 0.42, y: y + height * 0.52)
        )
        path.addCurve(
            to: CGPoint(x: x + width * 0.22, y: y + height * 0.88),
            control1: CGPoint(x: x + width * 0.30, y: y + height * 0.72),
            control2: CGPoint(x: x + width * 0.27, y: y + height * 0.87)
        )
        path.addCurve(
            to: CGPoint(x: x + width * 0.05, y: y + height * 0.68),
            control1: CGPoint(x: x + width * 0.16, y: y + height * 0.90),
            control2: CGPoint(x: x + width * 0.09, y: y + height * 0.83)
        )
        path.addCurve(
            to: CGPoint(x: x + width * 0.08, y: y + height * 0.24),
            control1: CGPoint(x: x, y: y + height * 0.58),
            control2: CGPoint(x: x, y: y + height * 0.35)
        )
        path.closeSubpath()
        return path
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
    let areaCode: String
    let autoDialRequest: AutoDialRequest?
    let onEditAreaCode: () -> Void
    let onDigit: (String) -> Void
    let onAutoDialComplete: () -> Void

    @State private var rotation = 0.0
    @State private var selectedIndex: Int?
    @State private var lastTouchAngle: Double?
    @State private var reachedStop = false
    @State private var clickCount = 0
    @State private var returnTask: Task<Void, Never>?
    @State private var hasPlayedWindingSound = false
    @State private var isAutoDialing = false
    private let feedbackPlayer = RotaryFeedbackPlayer.shared

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

                NumberCard(
                    phoneNumber: phoneNumber,
                    areaCode: areaCode,
                    side: side,
                    onEditAreaCode: onEditAreaCode
                )
                FingerStop(side: side)
            }
            .frame(width: side, height: side)
            .position(center)
            .contentShape(Circle())
            .gesture(dialGesture(side: side, center: center))
            .allowsHitTesting(!isAutoDialing)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Rotary telephone dial")
            .accessibilityValue(phoneNumber.isEmpty ? Text("No digits entered") : Text(phoneNumber))
            .accessibilityHint("Choose a digit from the accessibility actions, or drag a numbered hole clockwise to the stop.")
            .modifier(
                DialAccessibilityActions(markings: Self.markings) { index, marking in
                    feedbackPlayer.playReturn(for: index)
                    clickCount += 1
                    onDigit(marking.digit)
                }
            )
        }
        .modifier(SelectionFeedback(trigger: clickCount))
        .onChange(of: autoDialRequest) { request in
            guard let request else { return }
            startAutomaticDial(request.digits)
        }
    }

    private func dialGesture(side: CGFloat, center: CGPoint) -> some Gesture {
        DragGesture(minimumDistance: 0, coordinateSpace: .local)
            .onChanged { value in
                let touchAngle = angle(from: center, to: value.location)

                if selectedIndex == nil {
                    guard let index = holeIndex(at: value.startLocation, center: center, side: side) else {
                        return
                    }
                    returnTask?.cancel()
                    returnTask = nil
                    selectedIndex = index
                    lastTouchAngle = touchAngle
                    reachedStop = false
                    hasPlayedWindingSound = false
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
                    if !hasPlayedWindingSound {
                        feedbackPlayer.playWinding()
                        hasPlayedWindingSound = true
                    }
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
                hasPlayedWindingSound = false

                if shouldEnterDigit {
                    onDigit(digit)
                }

                startReturn(from: rotation, digitIndex: index)
            }
    }

    private func startAutomaticDial(_ digits: String) {
        returnTask?.cancel()
        isAutoDialing = true

        returnTask = Task { @MainActor in
            for digit in digits {
                guard !Task.isCancelled,
                      let index = Self.markings.firstIndex(
                        where: { $0.digit == String(digit) }
                      ) else {
                    isAutoDialing = false
                    return
                }

                let maximumRotation = Self.minimumTravel
                    + (Double(index) * Self.numberStep)
                let windingDuration = 0.22 + (Double(index) * 0.025)

                feedbackPlayer.playWinding()
                clickCount += 1

                withAnimation(.linear(duration: windingDuration)) {
                    rotation = maximumRotation
                }

                do {
                    try await Task.sleep(
                        nanoseconds: UInt64(windingDuration * 1_000_000_000)
                    )
                } catch {
                    isAutoDialing = false
                    return
                }

                onDigit(String(digit))

                let returnDuration = feedbackPlayer.returnDuration(for: index)
                feedbackPlayer.playReturn(for: index)
                clickCount += 1

                withAnimation(.linear(duration: returnDuration)) {
                    rotation = 0
                }

                do {
                    try await Task.sleep(
                        nanoseconds: UInt64((returnDuration + 0.12) * 1_000_000_000)
                    )
                } catch {
                    isAutoDialing = false
                    return
                }
            }

            isAutoDialing = false
            returnTask = nil
            onAutoDialComplete()
        }
    }

    private func startReturn(
        from startingRotation: Double,
        digitIndex: Int
    ) {
        returnTask?.cancel()

        let stepSize = 9.0
        let stepCount = max(Int(ceil(startingRotation / stepSize)), 1)
        let returnDuration = feedbackPlayer.returnDuration(for: digitIndex)
        let stepDuration = returnDuration / Double(stepCount)
        let stepMilliseconds = max(Int(stepDuration * 1_000), 1)

        feedbackPlayer.playReturn(for: digitIndex)

        returnTask = Task { @MainActor in
            for step in 0..<stepCount {
                guard !Task.isCancelled else { return }

                let remainingSteps = stepCount - step - 1
                clickCount += 1

                withAnimation(.linear(duration: stepDuration * 0.9)) {
                    rotation = max(0, Double(remainingSteps) * stepSize)
                }

                try? await Task.sleep(nanoseconds: UInt64(stepMilliseconds) * 1_000_000)
            }

            rotation = 0
            returnTask = nil
        }
    }

    private func holeIndex(at location: CGPoint, center: CGPoint, side: CGFloat) -> Int? {
        let ringRadius = side * 0.295
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

private struct DialAccessibilityActions: ViewModifier {
    let markings: [DialMarking]
    let dial: (Int, DialMarking) -> Void

    @ViewBuilder
    func body(content: Content) -> some View {
        if #available(iOS 16.0, *) {
            content.accessibilityActions {
                ForEach(Array(markings.enumerated()), id: \.element) { index, marking in
                    Button("Dial \(marking.digit)") {
                        dial(index, marking)
                    }
                }
            }
        } else {
            content
        }
    }
}

private struct SelectionFeedback: ViewModifier {
    let trigger: Int

    @ViewBuilder
    func body(content: Content) -> some View {
        if #available(iOS 17.0, *) {
            content.sensoryFeedback(.selection, trigger: trigger)
        } else {
            content
        }
    }
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
        let wheel = FingerWheelCutoutShape(
            count: count,
            firstNumberAngle: firstNumberAngle,
            numberStep: numberStep
        )

        ZStack {
            wheel
                .fill(.white.opacity(0.22), style: FillStyle(eoFill: true))

            wheel
                .stroke(
                    LinearGradient(
                        colors: [.white.opacity(0.9), .black.opacity(0.42)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: side * 0.009
                )
        }
        .rotationEffect(.degrees(rotation))
        .shadow(color: .black.opacity(0.25), radius: 4, y: 3)
    }
}

private struct FingerWheelCutoutShape: Shape {
    let count: Int
    let firstNumberAngle: Double
    let numberStep: Double

    func path(in rect: CGRect) -> Path {
        let side = min(rect.width, rect.height)
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let outerDiameter = side * 0.73
        let centerDiameter = side * 0.45
        let holeDiameter = side * 0.10
        let holeRadius = side * 0.295

        var path = Path()
        path.addEllipse(
            in: CGRect(
                x: center.x - outerDiameter / 2,
                y: center.y - outerDiameter / 2,
                width: outerDiameter,
                height: outerDiameter
            )
        )
        path.addEllipse(
            in: CGRect(
                x: center.x - centerDiameter / 2,
                y: center.y - centerDiameter / 2,
                width: centerDiameter,
                height: centerDiameter
            )
        )

        for index in 0..<count {
            let angle = firstNumberAngle - (Double(index) * numberStep)
            let radians = angle * .pi / 180
            let holeCenter = CGPoint(
                x: center.x + holeRadius * cos(radians),
                y: center.y + holeRadius * sin(radians)
            )
            path.addEllipse(
                in: CGRect(
                    x: holeCenter.x - holeDiameter / 2,
                    y: holeCenter.y - holeDiameter / 2,
                    width: holeDiameter,
                    height: holeDiameter
                )
            )
        }

        return path
    }
}

private struct NumberCard: View {
    let phoneNumber: String
    let areaCode: String
    let side: CGFloat
    let onEditAreaCode: () -> Void

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
                    Text("(123) 345-6789")
                        .font(.system(size: side * 0.038, weight: .medium, design: .monospaced))
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                        .frame(width: side * 0.31)
                }
                .foregroundStyle(.black.opacity(0.78))
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Area code 555, phone number 123 345 6789")
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

@MainActor
private final class RotaryFeedbackPlayer {
    static let shared = RotaryFeedbackPlayer()

    private static let fallbackDurations = [
        0.44, 0.47, 0.63, 0.70, 0.86,
        0.92, 1.00, 1.09, 1.20, 1.32
    ]

    private let engine = AVAudioEngine()
    private let windingNode = AVAudioPlayerNode()
    private let returnNode = AVAudioPlayerNode()
    private let windingFile: AVAudioFile?
    private let returnFiles: [AVAudioFile?]

    private init() {
        windingFile = Self.loadAudioFile(named: "rotary-winding")
        returnFiles = ["1", "2", "3", "4", "5", "6", "7", "8", "9", "0"]
            .map { Self.loadAudioFile(named: "rotary-return-\($0)") }

        let format = windingFile?.processingFormat
            ?? returnFiles.compactMap { $0?.processingFormat }.first
            ?? AVAudioFormat(
                standardFormatWithSampleRate: 48_000,
                channels: 1
            )!

        engine.attach(windingNode)
        engine.attach(returnNode)
        engine.connect(windingNode, to: engine.mainMixerNode, format: format)
        engine.connect(returnNode, to: engine.mainMixerNode, format: format)
        windingNode.volume = 0.8
        returnNode.volume = 1.0
        engine.prepare()

        Task.detached(priority: .userInitiated) { [engine] in
            #if os(iOS)
            let session = AVAudioSession.sharedInstance()
            try? session.setCategory(.ambient, options: [.mixWithOthers])
            try? session.setActive(true)
            #endif

            try? engine.start()
        }
    }

    func playWinding() {
        play(file: windingFile, using: windingNode)
    }

    func playReturn(for digitIndex: Int) {
        guard returnFiles.indices.contains(digitIndex) else { return }
        play(file: returnFiles[digitIndex], using: returnNode)
    }

    func returnDuration(for digitIndex: Int) -> Double {
        guard returnFiles.indices.contains(digitIndex),
              let file = returnFiles[digitIndex] else {
            return Self.fallbackDurations[
                min(max(digitIndex, 0), Self.fallbackDurations.count - 1)
            ]
        }

        return Double(file.length) / file.processingFormat.sampleRate
    }

    private func play(file: AVAudioFile?, using node: AVAudioPlayerNode) {
        guard engine.isRunning, let file else { return }
        node.stop()
        file.framePosition = 0
        node.scheduleFile(file, at: nil)
        node.play()
    }

    private static func loadAudioFile(named name: String) -> AVAudioFile? {
        let url = Bundle.main.url(
            forResource: name,
            withExtension: "caf",
            subdirectory: "Audio"
        ) ?? Bundle.main.url(
            forResource: name,
            withExtension: "caf"
        )

        guard let url else { return nil }
        return try? AVAudioFile(forReading: url)
    }
}
#Preview {
    ContentView()
}
