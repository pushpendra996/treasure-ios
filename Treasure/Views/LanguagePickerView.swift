import SwiftUI

struct LanguagePickerView: View {
    var onboarding: Bool = false
    var onPicked: (() -> Void)? = nil

    @ObservedObject private var store = LanguageStore.shared
    @Environment(\.dismiss) private var dismiss

    private let indianColumns = [
        GridItem(.flexible(), spacing: 10),
        GridItem(.flexible(), spacing: 10),
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                header
                    .padding(.bottom, 24)

                sectionHeader(
                    title: L10n.string("hint_language_section_international"),
                    systemImage: "globe"
                )
                VStack(spacing: 8) {
                    ForEach(LanguageStore.internationalOptions) { option in
                        internationalRow(option)
                    }
                }
                .padding(.top, 10)

                sectionHeader(
                    title: L10n.string("hint_language_section_indian"),
                    systemImage: "flag"
                )
                .padding(.top, 20)

                LazyVGrid(columns: indianColumns, spacing: 10) {
                    ForEach(LanguageStore.indianOptions) { option in
                        indianCard(option)
                    }
                }
                .padding(.top, 10)

                footer
                    .padding(.top, 20)
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 28)
        }
        .background(TreasureTheme.languageBackground.ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
        .id(store.code)
    }

    private var header: some View {
        HStack(alignment: .center, spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(TreasureTheme.purple.opacity(0.12))
                    .frame(width: 48, height: 48)
                Image(systemName: "character.book.closed")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(TreasureTheme.purple)
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(L10n.string("hint_language_picker_title"))
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(TreasureTheme.title)
                Text(L10n.string("hint_language_picker_subtitle"))
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
    }

    private func sectionHeader(title: String, systemImage: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: systemImage)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(TreasureTheme.purple)
            Text(title)
                .font(.subheadline.weight(.bold))
                .foregroundColor(TreasureTheme.purple)
            Rectangle()
                .fill(TreasureTheme.languageDivider)
                .frame(height: 1)
        }
    }

    private func internationalRow(_ option: LanguageOption) -> some View {
        let selected = store.code == option.code
        return Button {
            pick(option)
        } label: {
            HStack(spacing: 12) {
                badge(option)
                VStack(alignment: .leading, spacing: 2) {
                    Text(option.nativeLabel)
                        .font(.body.weight(.semibold))
                        .foregroundColor(TreasureTheme.title)
                    if option.nativeLabel != option.englishLabel {
                        Text(option.englishLabel)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                Spacer()
                radio(selected)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(selected ? TreasureTheme.purple.opacity(0.10) : Color.white)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(selected ? TreasureTheme.purple : Color.clear, lineWidth: 1.5)
            )
        }
        .buttonStyle(.plain)
    }

    private func indianCard(_ option: LanguageOption) -> some View {
        let selected = store.code == option.code
        return Button {
            pick(option)
        } label: {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    badge(option)
                    Spacer()
                    radio(selected)
                }
                Text(option.nativeLabel)
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(TreasureTheme.title)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                Text(option.englishLabel)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(selected ? TreasureTheme.purple.opacity(0.10) : Color.white)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(selected ? TreasureTheme.purple : Color.clear, lineWidth: 1.5)
            )
        }
        .buttonStyle(.plain)
    }

    private func badge(_ option: LanguageOption) -> some View {
        Text(option.badgeText)
            .font(.caption.weight(.bold))
            .foregroundColor(.white)
            .frame(width: 32, height: 32)
            .background(Circle().fill(option.badgeColor))
    }

    private func radio(_ selected: Bool) -> some View {
        ZStack {
            Circle()
                .stroke(selected ? TreasureTheme.purple : Color.gray.opacity(0.4), lineWidth: 2)
                .frame(width: 20, height: 20)
            if selected {
                Circle()
                    .fill(TreasureTheme.purple)
                    .frame(width: 10, height: 10)
            }
        }
    }

    private var footer: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "checkmark.shield")
                .foregroundColor(TreasureTheme.purple)
            Text(L10n.string("hint_language_change_anytime"))
                .font(.footnote)
                .foregroundColor(TreasureTheme.purple)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(TreasureTheme.languageFooter)
        )
    }

    private func pick(_ option: LanguageOption) {
        store.save(option.code)
        onPicked?()
        if !onboarding {
            dismiss()
        }
    }
}
