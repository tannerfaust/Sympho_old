//
//  SidebarTodayPlanCard.swift
//  Sympho
//

#if os(macOS)
import SwiftUI
import SwiftData

struct SidebarTodayPlanCard: View {
    let onOpenPlanner: () -> Void
    let onOpenReading: () -> Void
    let onOpenNode: (Node) -> Void

    @Query(sort: [SortDescriptor(\PlannerWeeklyBlock.weekday), SortDescriptor(\PlannerWeeklyBlock.sortIndex)])
    private var weeklyBlocks: [PlannerWeeklyBlock]

    @Query(
        filter: #Predicate<Domain> { !$0.isArchived && !$0.isDeletedLocally },
        sort: [SortDescriptor(\Domain.sortIndex), SortDescriptor(\Domain.title)]
    )
    private var domains: [Domain]

    @Query(filter: #Predicate<Project> { !$0.isDeletedLocally }, sort: \Project.title)
    private var projects: [Project]

    @Query(filter: #Predicate<ReadingListItem> { !$0.isDeletedLocally }, sort: \ReadingListItem.title)
    private var readingItems: [ReadingListItem]

    @Query(filter: #Predicate<Resource> { !$0.isDeletedLocally }, sort: \Resource.title)
    private var resources: [Resource]

    @Query(
        filter: #Predicate<Node> { $0.statusValue == "active" && !$0.isDeletedLocally },
        sort: \Node.updatedAt,
        order: .reverse
    )
    private var activeNodes: [Node]

    private var todayPlan: PlannerDayPlan {
        PlannerLogic.todayPlan(
            weeklyBlocks: weeklyBlocks,
            domains: domains,
            projects: projects,
            readingItems: readingItems,
            resources: resources
        )
    }

    private var totalMinutes: Int {
        todayPlan.entries.reduce(0) { $0 + $1.durationMinutes }
    }

    private var activeReading: [ReadingListItem] {
        readingItems.filter { $0.status == .reading }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Button(action: onOpenPlanner) {
                HStack(alignment: .firstTextBaseline) {
                    Text("Today")
                        .font(.system(size: 12, weight: .semibold))
                    Spacer(minLength: 0)
                    if !todayPlan.entries.isEmpty {
                        Text(PlannerLogic.formatDuration(minutes: totalMinutes))
                            .font(.system(size: 10, weight: .medium, design: .monospaced))
                            .foregroundStyle(SymphoTheme.secondaryText)
                    }
                }
                .foregroundStyle(SymphoTheme.primaryText)
            }
            .buttonStyle(.plain)

            if let node = activeNodes.first {
                SidebarTodayActionRow(
                    icon: "play.fill",
                    title: "Continue studying",
                    detail: node.title,
                    accent: SymphoTheme.primaryText,
                    action: { onOpenNode(node) }
                )
            }

            ForEach(todayPlan.entries.prefix(2)) { entry in
                SidebarTodayActionRow(
                    icon: entry.iconName,
                    title: entry.title,
                    detail: PlannerLogic.formatDuration(minutes: entry.durationMinutes),
                    action: onOpenPlanner
                )
            }

            if let book = activeReading.first {
                SidebarTodayActionRow(
                    icon: "book.closed",
                    title: book.title,
                    detail: activeReading.count > 1 ? "\(activeReading.count) reading" : "Reading",
                    action: onOpenReading
                )
            }
        }
        .padding(.horizontal, 11)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(SymphoTheme.elevatedCanvas.opacity(0.72))
        }
        .overlay {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(SymphoTheme.dividerColor.opacity(0.78), lineWidth: 1)
        }
    }
}

private struct SidebarTodayActionRow: View {
    let icon: String
    let title: String
    let detail: String
    var accent: Color = SymphoTheme.secondaryText
    let action: () -> Void

    @State private var isHovering = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(accent)
                    .frame(width: 14)
                Text(title)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(SymphoTheme.primaryText)
                    .lineLimit(1)
                Spacer(minLength: 0)
                Text(detail)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(SymphoTheme.tertiaryText)
                    .lineLimit(1)
            }
            .padding(.horizontal, 7)
            .padding(.vertical, 5)
            .background {
                RoundedRectangle(cornerRadius: SymphoTheme.controlRadius, style: .continuous)
                    .fill(isHovering ? SymphoTheme.primaryText.opacity(0.055) : .clear)
            }
        }
        .buttonStyle(.plain)
        .onHover { isHovering = $0 }
    }
}
#endif
