import SwiftUI
import Charts

private let reportPalette: [Color] = [
    Color(red: 0.36, green: 0.55, blue: 0.94),
    Color(red: 0.49, green: 0.42, blue: 0.94),
    Color(red: 0.17, green: 0.73, blue: 0.68),
    Color(red: 0.91, green: 0.66, blue: 0.22),
    Color(red: 0.88, green: 0.35, blue: 0.35),
    Color(red: 0.30, green: 0.69, blue: 0.48),
    Color(red: 0.26, green: 0.65, blue: 0.96),
    Color(red: 0.67, green: 0.28, blue: 0.74),
    Color(red: 1.00, green: 0.44, blue: 0.26),
    Color(red: 0.15, green: 0.65, blue: 0.60),
]

struct ReportView: View {
    @StateObject private var reportVM = ReportViewModel()
    @ObservedObject private var currencyStore = CurrencyStore.shared

    var body: some View {
        VStack(spacing: 0) {
            OfflineBanner()
            ScrollView {
                VStack(spacing: 0) {
                    Picker("Timeframe", selection: $reportVM.timeframe) {
                        ForEach(ReportViewModel.Timeframe.allCases, id: \.self) { timeframe in
                            Text(timeframe.rawValue).tag(timeframe)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal, 8)
                    .padding(.top, 8)
                    .onChange(of: reportVM.timeframe) { _, _ in
                        Task { await reportVM.loadData() }
                    }

                    HStack {
                        Button {
                            reportVM.shiftPeriod(by: -1)
                            Task { await reportVM.loadData() }
                        } label: {
                            Image(systemName: "chevron.left")
                                .font(.body.weight(.semibold))
                                .foregroundColor(Color(red: 0.54, green: 0.40, blue: 0.98))
                                .frame(width: 40, height: 40)
                                .background(Circle().fill(Color(red: 0.54, green: 0.40, blue: 0.98).opacity(0.12)))
                        }
                        VStack(spacing: 4) {
                            Text(reportVM.periodLabel)
                                .font(.title2.weight(.bold))
                                .foregroundColor(Color(red: 0.38, green: 0.19, blue: 0.98))
                                .multilineTextAlignment(.center)
                            Text("Based on your saved transactions")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        Button {
                            reportVM.shiftPeriod(by: 1)
                            Task { await reportVM.loadData() }
                        } label: {
                            Image(systemName: "chevron.right")
                                .font(.body.weight(.semibold))
                                .foregroundColor(Color(red: 0.54, green: 0.40, blue: 0.98))
                                .frame(width: 40, height: 40)
                                .background(Circle().fill(Color(red: 0.54, green: 0.40, blue: 0.98).opacity(0.12)))
                        }
                    }
                    .padding(.vertical, 14)
                    .padding(.horizontal, 10)
                    .background(Color(.systemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .padding(.horizontal, 8)
                    .padding(.top, 8)

                    HStack(spacing: 8) {
                        SummaryCard(title: "Income", amount: reportVM.totalIncome, color: .green, icon: "arrow.up")
                        SummaryCard(title: "Expense", amount: reportVM.totalExpenses, color: .red, icon: "arrow.down")
                        SummaryCard(
                            title: "Net",
                            amount: reportVM.netBalance,
                            color: reportVM.netBalance >= 0 ? .green : .red,
                            icon: "plusminus"
                        )
                    }
                    .padding(.horizontal, 8)
                    .padding(.top, 8)

                    if reportVM.totalIncome == 0 && reportVM.totalExpenses == 0 {
                        Text("Nothing to show for this period.")
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color(.systemGray6))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .padding(.horizontal, 8)
                            .padding(.top, 8)
                    }

                    categoryCard(title: "Income by category", data: reportVM.incomeByCategory)
                    categoryCard(title: "Expense by category", data: reportVM.expensesByCategory)

                    if reportVM.timeframe == .year {
                        monthlyTrendCard
                    }
                }
                .padding(.bottom, 28)
                .id(currencyStore.code)
            }
        }
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
        .navigationTitle("Reports")
        .task { await reportVM.loadData() }
        .refreshable { await reportVM.loadData() }
    }

    private var monthlyTrendCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Monthly income vs expense")
                .font(.headline)
            HStack(spacing: 16) {
                legendDot(color: .green, title: "Income")
                legendDot(color: .red, title: "Expense")
            }
            Chart {
                ForEach(reportVM.monthlyData.sorted(by: { $0.key < $1.key }), id: \.key) { month, data in
                    BarMark(
                        x: .value("Month", month),
                        y: .value("Income", data.income)
                    )
                    .foregroundStyle(.green)
                    .position(by: .value("Type", "Income"))
                    BarMark(
                        x: .value("Month", month),
                        y: .value("Expenses", data.expenses)
                    )
                    .foregroundStyle(.red)
                    .position(by: .value("Type", "Expense"))
                }
            }
            .chartLegend(.hidden)
            .frame(height: 200)
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .padding(.horizontal, 8)
        .padding(.top, 8)
    }

    private func categoryCard(title: String, data: [String: Double]) -> some View {
        let slices = data.sorted(by: { $0.value > $1.value })
        let total = slices.reduce(0) { $0 + $1.value }
        return VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
            if slices.isEmpty {
                Text("Nothing to show for this period.")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
            } else {
                Chart(slices, id: \.key) { item in
                    SectorMark(
                        angle: .value("Amount", item.value),
                        innerRadius: .ratio(0.62),
                        angularInset: 1.6
                    )
                    .foregroundStyle(color(for: item.key, in: slices))
                    .cornerRadius(3)
                }
                .chartLegend(.hidden)
                .frame(height: 200)

                Text("Total \(formattedAmount(total))")
                    .font(.subheadline.weight(.bold))
                    .frame(maxWidth: .infinity)

                ForEach(Array(slices.enumerated()), id: \.element.key) { index, item in
                    HStack(spacing: 10) {
                        Circle()
                            .fill(reportPalette[index % reportPalette.count])
                            .frame(width: 10, height: 10)
                        Text(item.key)
                            .lineLimit(1)
                        Spacer()
                        Text(sharePercent(item.value, of: total))
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(formattedAmount(item.value))
                            .font(.subheadline.weight(.semibold))
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .padding(.horizontal, 8)
        .padding(.top, 8)
    }

    private func sharePercent(_ value: Double, of total: Double) -> String {
        guard value > 0, total > 0 else { return "0%" }
        let percent = (value / total) * 100
        if percent < 0.1 { return "<0.1%" }
        if percent < 1 { return String(format: "%.1f%%", percent) }
        return "\(Int(percent.rounded()))%"
    }

    private func color(for key: String, in slices: [(key: String, value: Double)]) -> Color {
        let index = slices.firstIndex(where: { $0.key == key }) ?? 0
        return reportPalette[index % reportPalette.count]
    }

    private func legendDot(color: Color, title: String) -> some View {
        HStack(spacing: 6) {
            Circle().fill(color).frame(width: 10, height: 10)
            Text(title).font(.caption)
        }
    }
}

struct SummaryCard: View {
    let title: String
    let amount: Double
    let color: Color
    var icon: String = "circle.fill"
    var iconSize: CGFloat = 16

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: iconSize, weight: .bold))
                .foregroundColor(color)
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            Text(formattedAmount(amount))
                .font(.subheadline.weight(.bold))
                .foregroundColor(color)
                .minimumScaleFactor(0.7)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .padding(.horizontal, 6)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

struct ReportView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            ReportView()
        }
    }
}
