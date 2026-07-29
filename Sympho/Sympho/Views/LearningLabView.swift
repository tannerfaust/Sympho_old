//
//  LearningLabView.swift
//  Sympho
//

import SwiftUI
import SwiftData
import UniformTypeIdentifiers
#if os(iOS)
import PencilKit
#endif

struct LearningLabView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.openURL) private var openURL
    @Query(sort: \LabBoard.updatedAt, order: .reverse) private var boards: [LabBoard]

    @State private var selectedBoardID: UUID?
    @State private var selectedItemID: UUID?
    @State private var linkSourceID: UUID?
    @State private var zoom: Double = 0.82
    @State private var showingImporter = false
    @State private var showingVideoPrompt = false
    @State private var showingSketch = false
    @State private var videoURLText = ""
    @State private var inspectorVisible = true
    @State private var previewFile: LibraryPreviewFile?

    private let canvasSize = CGSize(width: 3400, height: 2400)

    private var selectedBoard: LabBoard? {
        let id = selectedBoardID ?? boards.first?.id
        return boards.first { $0.id == id }
    }

    private var selectedItem: LabItem? {
        guard let selectedItemID else { return nil }
        return selectedBoard?.items.first { $0.id == selectedItemID }
    }

    var body: some View {
        HStack(spacing: 0) {
            boardRail
            Divider()

            VStack(spacing: 0) {
                labHeader
                Divider()
                canvas
            }

            if inspectorVisible {
                Divider()
                inspector
                    .frame(width: 292)
                    .transition(.move(edge: .trailing).combined(with: .opacity))
            }
        }
        .background(Color(red: 0.965, green: 0.962, blue: 0.948))
        .task { createWelcomeBoardIfNeeded() }
        .fileImporter(
            isPresented: $showingImporter,
            allowedContentTypes: [.pdf, .image, .movie, .audio, .plainText, .data],
            allowsMultipleSelection: true,
            onCompletion: importFiles
        )
        .sheet(isPresented: $showingVideoPrompt) { videoPrompt }
        .sheet(isPresented: $showingSketch) {
            if let selectedItem, selectedItem.kind == .sketch {
                LabSketchEditor(item: selectedItem)
            }
        }
        .sheet(item: $previewFile) { file in
            LibraryFilePreviewSheet(file: file)
        }
        .animation(.snappy(duration: 0.2), value: inspectorVisible)
    }

    private var boardRail: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("LABS")
                    .font(.system(size: 10, weight: .bold))
                    .tracking(0.9)
                    .foregroundStyle(SymphoTheme.secondaryText)
                Spacer()
                Button(action: createBoard) {
                    Image(systemName: "plus")
                }
                .buttonStyle(.plain)
                .help("New learning lab")
            }

            ScrollView {
                VStack(spacing: 5) {
                    ForEach(boards) { board in
                        Button {
                            selectedBoardID = board.id
                            selectedItemID = nil
                            linkSourceID = nil
                        } label: {
                            VStack(alignment: .leading, spacing: 4) {
                                HStack(spacing: 7) {
                                    Image(systemName: "square.grid.3x3.square")
                                    Text(board.title)
                                        .lineLimit(1)
                                    Spacer(minLength: 0)
                                }
                                .font(.system(size: 12, weight: .semibold))

                                Text("\(board.items.count) objects · \(board.connections.count) links")
                                    .font(.system(size: 10))
                                    .foregroundStyle(SymphoTheme.secondaryText)
                            }
                            .foregroundStyle(SymphoTheme.primaryText)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(9)
                            .background {
                                RoundedRectangle(cornerRadius: 8, style: .continuous)
                                    .fill(selectedBoard?.id == board.id ? Color.white : .clear)
                            }
                            .overlay {
                                if selectedBoard?.id == board.id {
                                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                                        .stroke(SymphoTheme.dividerColor)
                                }
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            Spacer()

            Label("Local-first workspace", systemImage: "lock.shield")
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(SymphoTheme.secondaryText)
        }
        .padding(14)
        .frame(width: 190)
        .background(SymphoTheme.controlBackground.opacity(0.72))
    }

    private var labHeader: some View {
        HStack(spacing: 14) {
            VStack(alignment: .leading, spacing: 2) {
                Text(selectedBoard?.title ?? "Learning Lab")
                    .font(.system(size: 20, weight: .semibold))
                Text(selectedBoard?.focusQuestion.isEmpty == false
                     ? selectedBoard!.focusQuestion
                     : "Arrange sources, think in space, then test what you understand.")
                    .font(.system(size: 11))
                    .foregroundStyle(SymphoTheme.secondaryText)
                    .lineLimit(1)
            }

            Spacer()

            Menu {
                Button("Note", systemImage: LabItemKind.note.iconName) { addItem(.note) }
                Button("Concept", systemImage: LabItemKind.concept.iconName) { addItem(.concept) }
                Button("Question", systemImage: LabItemKind.question.iconName) { addItem(.question) }
                Button("Sketch", systemImage: LabItemKind.sketch.iconName) { addItem(.sketch) }
                Divider()
                Button("File or PDF…", systemImage: "doc.badge.plus") { showingImporter = true }
                Button("Video link…", systemImage: "play.rectangle") { showingVideoPrompt = true }
            } label: {
                Label("Add to lab", systemImage: "plus")
            }
            .buttonStyle(.borderedProminent)
            .tint(SymphoTheme.primaryAction)

            Button {
                if let selectedItemID {
                    if linkSourceID == nil {
                        linkSourceID = selectedItemID
                    } else if linkSourceID != selectedItemID {
                        connect(source: linkSourceID!, target: selectedItemID)
                    }
                }
            } label: {
                Label(linkSourceID == nil ? "Connect" : "Choose destination", systemImage: "point.topleft.down.curvedto.point.bottomright.up")
            }
            .buttonStyle(.bordered)
            .disabled(selectedItemID == nil)

            HStack(spacing: 5) {
                Image(systemName: "minus.magnifyingglass")
                Slider(value: $zoom, in: 0.42...1.3)
                    .frame(width: 92)
                Text("\(Int(zoom * 100))%")
                    .frame(width: 36, alignment: .trailing)
            }
            .font(.system(size: 10, weight: .medium))
            .foregroundStyle(SymphoTheme.secondaryText)

            Button {
                inspectorVisible.toggle()
            } label: {
                Image(systemName: "sidebar.right")
            }
            .buttonStyle(.bordered)
            .help("Toggle learning inspector")
        }
        .padding(.horizontal, 18)
        .frame(height: 72)
        .background(Color.white.opacity(0.92))
    }

    private var canvas: some View {
        ScrollView([.horizontal, .vertical]) {
            ZStack(alignment: .topLeading) {
                LabGrid(spacing: 28)

                if let board = selectedBoard {
                    LabConnectionsLayer(board: board)

                    ForEach(board.items) { item in
                        LabItemCard(
                            item: item,
                            isSelected: selectedItemID == item.id,
                            isLinkSource: linkSourceID == item.id,
                            onSelect: {
                                if let linkSourceID, linkSourceID != item.id {
                                    connect(source: linkSourceID, target: item.id)
                                } else {
                                    selectedItemID = item.id
                                }
                            },
                            onOpen: {
                                selectedItemID = item.id
                                open(item)
                            },
                            onMove: save
                        )
                        .frame(width: item.width, height: item.height)
                        .position(x: item.x, y: item.y)
                    }
                }
            }
            .frame(width: canvasSize.width, height: canvasSize.height)
            .scaleEffect(zoom, anchor: .topLeading)
            .frame(
                width: canvasSize.width * zoom,
                height: canvasSize.height * zoom,
                alignment: .topLeading
            )
        }
        .scrollIndicators(.visible)
        .background(Color(red: 0.965, green: 0.962, blue: 0.948))
        .onTapGesture {
            selectedItemID = nil
            linkSourceID = nil
        }
    }

    @ViewBuilder
    private var inspector: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Label("Learning guide", systemImage: "sparkles")
                    .font(.system(size: 13, weight: .semibold))
                Spacer()
                Circle()
                    .fill(Color.green)
                    .frame(width: 7, height: 7)
                Text("Grounded")
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundStyle(SymphoTheme.secondaryText)
            }
            .padding(14)

            Divider()

            if let item = selectedItem {
                ScrollView {
                    VStack(alignment: .leading, spacing: 14) {
                        Label(item.kind.displayName, systemImage: item.kind.iconName)
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(SymphoTheme.secondaryText)

                        TextField("Title", text: Binding(
                            get: { item.title },
                            set: { item.title = $0; item.updatedAt = Date(); save() }
                        ))
                        .font(.system(size: 16, weight: .semibold))
                        .textFieldStyle(.plain)

                        TextEditor(text: Binding(
                            get: { item.bodyText },
                            set: { item.bodyText = $0; item.updatedAt = Date(); save() }
                        ))
                        .font(SymphoNoteTypography.readingFont)
                        .scrollContentBackground(.hidden)
                        .frame(minHeight: 130)

                        if item.kind == .sketch {
                            Button("Open Pencil canvas", systemImage: "pencil.tip") {
                                showingSketch = true
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(SymphoTheme.primaryAction)
                        }

                        Divider()
                        learningActions(for: item)

                        Button("Remove from lab", systemImage: "trash", role: .destructive) {
                            delete(item)
                        }
                        .buttonStyle(.plain)
                        .font(.system(size: 11))
                    }
                    .padding(16)
                }
            } else {
                labGuide
            }
        }
        .background(Color.white.opacity(0.94))
    }

    private func learningActions(for item: LabItem) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("WORK WITH THIS")
                .font(.system(size: 9, weight: .bold))
                .tracking(0.8)
                .foregroundStyle(SymphoTheme.secondaryText)

            LabGuideAction(icon: "quote.bubble", title: "Explain in context", subtitle: "Use connected sources only")
            LabGuideAction(icon: "arrow.left.arrow.right", title: "Find tensions", subtitle: "Compare linked claims")
            LabGuideAction(icon: "brain.head.profile", title: "Test my understanding", subtitle: "Create a recall prompt") {
                addRecallPrompt(from: item)
            }
        }
    }

    private var labGuide: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Build understanding, not a prettier pile.")
                        .font(.system(size: 16, weight: .semibold))
                    Text("Connect claims to sources. Turn uncertainty into questions. Revisit the questions later from memory.")
                        .font(.system(size: 12))
                        .foregroundStyle(SymphoTheme.secondaryText)
                        .lineSpacing(3)
                }

                LabGuideStep(number: "1", title: "Collect", text: "Drop PDFs, files, links, and lectures.")
                LabGuideStep(number: "2", title: "Distill", text: "Pull out concepts, claims, and unresolved questions.")
                LabGuideStep(number: "3", title: "Connect", text: "Label why two ideas belong together.")
                LabGuideStep(number: "4", title: "Retrieve", text: "Close the source and explain it from memory.")

                Divider()

                Label("NotebookLM bridge", systemImage: "arrow.up.forward.app")
                    .font(.system(size: 12, weight: .semibold))
                Text("Export a source pack for NotebookLM today; a direct API can be added when Google exposes a supported notebook integration.")
                    .font(.system(size: 11))
                    .foregroundStyle(SymphoTheme.secondaryText)
            }
            .padding(16)
        }
    }

    private var videoPrompt: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Add a lecture or video")
                .font(.system(size: 20, weight: .semibold))
            Text("Paste a YouTube, Vimeo, or direct video URL. It remains connected to your notes on the canvas.")
                .font(.system(size: 12))
                .foregroundStyle(SymphoTheme.secondaryText)
            TextField("https://…", text: $videoURLText)
                .textFieldStyle(.roundedBorder)
            HStack {
                Spacer()
                Button("Cancel") { showingVideoPrompt = false }
                Button("Add video") {
                    addVideo()
                    showingVideoPrompt = false
                }
                .buttonStyle(.borderedProminent)
                .disabled(URL(string: videoURLText) == nil)
            }
        }
        .padding(24)
        .frame(width: 470)
    }

    private func createWelcomeBoardIfNeeded() {
        guard boards.isEmpty else {
            selectedBoardID = selectedBoardID ?? boards.first?.id
            return
        }

        let board = LabBoard(
            title: "Understanding workspace",
            focusQuestion: "What do I need to be able to explain without looking?"
        )
        modelContext.insert(board)

        let source = LabItem(
            kind: .source,
            title: "Drop your first source",
            bodyText: "PDFs, research papers, slides, images, audio, and other files stay anchored here.",
            x: 470, y: 420, width: 310, height: 230, colorHex: "#EAF1FF", board: board
        )
        let concept = LabItem(
            kind: .concept,
            title: "Core idea",
            bodyText: "Distill the source into a claim you can explain in your own words.",
            x: 930, y: 330, width: 280, height: 190, colorHex: "#FFF1C7", board: board
        )
        let question = LabItem(
            kind: .question,
            title: "What still does not make sense?",
            bodyText: "A good learning space makes uncertainty visible instead of hiding it in highlights.",
            x: 920, y: 650, width: 300, height: 205, colorHex: "#F4E9FF", board: board
        )
        modelContext.insert(source)
        modelContext.insert(concept)
        modelContext.insert(question)
        modelContext.insert(LabConnection(sourceItemID: source.id, targetItemID: concept.id, label: "supports", board: board))
        modelContext.insert(LabConnection(sourceItemID: concept.id, targetItemID: question.id, label: "raises", board: board))
        selectedBoardID = board.id
        save()
    }

    private func createBoard() {
        let board = LabBoard(title: "Untitled learning lab", focusQuestion: "What am I trying to understand?")
        modelContext.insert(board)
        selectedBoardID = board.id
        selectedItemID = nil
        save()
    }

    private func addItem(_ kind: LabItemKind) {
        guard let board = selectedBoard else { return }
        let index = Double(board.items.count)
        let item = LabItem(
            kind: kind,
            title: kind == .question ? "New question" : kind == .concept ? "New concept" : kind == .sketch ? "Pencil sketch" : "New note",
            bodyText: kind == .question ? "What would I need to know to answer this?" : "",
            x: 620 + (index.truncatingRemainder(dividingBy: 4) * 90),
            y: 430 + (index.truncatingRemainder(dividingBy: 5) * 75),
            width: kind == .sketch ? 380 : 280,
            height: kind == .sketch ? 260 : 190,
            colorHex: color(for: kind),
            board: board
        )
        modelContext.insert(item)
        board.updatedAt = Date()
        selectedItemID = item.id
        save()
        if kind == .sketch { showingSketch = true }
    }

    private func addVideo() {
        guard let board = selectedBoard else { return }
        let item = LabItem(
            kind: .video,
            title: "Video source",
            bodyText: "Add timestamped notes here while you watch.",
            urlString: videoURLText.trimmingCharacters(in: .whitespacesAndNewlines),
            x: 700, y: 520, width: 400, height: 300, colorHex: "#E9F5F0", board: board
        )
        modelContext.insert(item)
        selectedItemID = item.id
        videoURLText = ""
        save()
    }

    private func importFiles(_ result: Result<[URL], Error>) {
        guard let board = selectedBoard, case .success(let urls) = result else { return }

        for (offset, url) in urls.enumerated() {
            let resource = Resource(title: url.deletingPathExtension().lastPathComponent, resourceType: url.pathExtension.lowercased() == "pdf" ? .pdf : .note)
            modelContext.insert(resource)

            do {
                let imported = try LibraryStorage.importFile(from: url, entryID: resource.id, entryTitle: resource.title)
                let attachment = LibraryAttachment(imported: imported, resource: resource)
                modelContext.insert(attachment)
                resource.fileRelativePath = imported.storedPath
            } catch {
                resource.bodyText = "Import failed: \(error.localizedDescription)"
            }

            let item = LabItem(
                kind: .source,
                title: resource.title,
                bodyText: url.pathExtension.uppercased() + " source",
                x: 480 + Double(offset * 70),
                y: 430 + Double(offset * 70),
                width: 320,
                height: 230,
                colorHex: "#EAF1FF",
                board: board,
                resource: resource
            )
            modelContext.insert(item)
            selectedItemID = item.id
        }
        board.updatedAt = Date()
        save()
    }

    private func connect(source: UUID, target: UUID) {
        guard let board = selectedBoard, source != target else { return }
        let duplicate = board.connections.contains {
            $0.sourceItemID == source && $0.targetItemID == target
        }
        if !duplicate {
            modelContext.insert(LabConnection(sourceItemID: source, targetItemID: target, board: board))
        }
        selectedItemID = target
        linkSourceID = nil
        board.updatedAt = Date()
        save()
    }

    private func addRecallPrompt(from item: LabItem) {
        guard let board = selectedBoard else { return }
        let prompt = LabItem(
            kind: .question,
            title: "Explain “\(item.title)” from memory",
            bodyText: "Hide the source. Write or say everything you can recall, then check the gaps.",
            x: item.x + item.width + 130,
            y: item.y + 60,
            width: 300,
            height: 210,
            colorHex: "#F4E9FF",
            board: board
        )
        modelContext.insert(prompt)
        modelContext.insert(LabConnection(sourceItemID: item.id, targetItemID: prompt.id, label: "test with", board: board))
        selectedItemID = prompt.id
        save()
    }

    private func open(_ item: LabItem) {
        if item.kind == .sketch {
            showingSketch = true
            return
        }

        if item.kind == .video, let url = URL(string: item.urlString) {
            openURL(url)
            return
        }

        guard item.kind == .source,
              let attachment = item.resource?.attachments.first,
              let url = LibraryStorage.resolvedURL(for: attachment) else {
            return
        }

        previewFile = LibraryPreviewFile(
            id: attachment.id,
            title: attachment.displayName,
            contentType: attachment.contentType,
            url: url,
            byteSize: attachment.byteSize
        )
    }

    private func delete(_ item: LabItem) {
        if let board = selectedBoard {
            for connection in board.connections where connection.sourceItemID == item.id || connection.targetItemID == item.id {
                modelContext.delete(connection)
            }
        }
        modelContext.delete(item)
        selectedItemID = nil
        save()
    }

    private func color(for kind: LabItemKind) -> String {
        switch kind {
        case .note: return "#FFF7CF"
        case .question: return "#F4E9FF"
        case .concept: return "#FFF1C7"
        case .source: return "#EAF1FF"
        case .video: return "#E9F5F0"
        case .sketch: return "#FFFFFF"
        }
    }

    private func save() {
        try? modelContext.save()
    }
}

private struct LabGrid: View {
    let spacing: CGFloat

    var body: some View {
        Canvas { context, size in
            let color = Color.black.opacity(0.085)
            for x in stride(from: 0.0, through: size.width, by: spacing) {
                for y in stride(from: 0.0, through: size.height, by: spacing) {
                    context.fill(Path(ellipseIn: CGRect(x: x, y: y, width: 1.35, height: 1.35)), with: .color(color))
                }
            }
        }
    }
}

private struct LabConnectionsLayer: View {
    let board: LabBoard

    var body: some View {
        Canvas { context, _ in
            let items = Dictionary(uniqueKeysWithValues: board.items.map { ($0.id, $0) })
            for connection in board.connections {
                guard let source = items[connection.sourceItemID],
                      let target = items[connection.targetItemID] else { continue }

                let start = CGPoint(x: source.x + source.width / 2, y: source.y)
                let end = CGPoint(x: target.x - target.width / 2, y: target.y)
                let control = max(70, abs(end.x - start.x) * 0.42)
                var path = Path()
                path.move(to: start)
                path.addCurve(
                    to: end,
                    control1: CGPoint(x: start.x + control, y: start.y),
                    control2: CGPoint(x: end.x - control, y: end.y)
                )
                context.stroke(path, with: .color(Color.black.opacity(0.26)), style: StrokeStyle(lineWidth: 1.6, dash: [6, 5]))

                let midpoint = CGPoint(x: (start.x + end.x) / 2, y: (start.y + end.y) / 2 - 12)
                context.draw(
                    Text(connection.label)
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(Color.black.opacity(0.48)),
                    at: midpoint
                )
            }
        }
        .allowsHitTesting(false)
    }
}

private struct LabItemCard: View {
    @Bindable var item: LabItem
    let isSelected: Bool
    let isLinkSource: Bool
    let onSelect: () -> Void
    let onOpen: () -> Void
    let onMove: () -> Void

    @State private var dragStart: CGPoint?

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 7) {
                Image(systemName: item.kind.iconName)
                Text(item.kind.displayName.uppercased())
                    .tracking(0.65)
                Spacer()
                if isLinkSource {
                    Label("Linking", systemImage: "link")
                        .labelStyle(.iconOnly)
                }
                Image(systemName: "circle.grid.2x2.fill")
                    .foregroundStyle(Color.black.opacity(0.18))
            }
            .font(.system(size: 9, weight: .bold))
            .foregroundStyle(Color.black.opacity(0.48))
            .padding(.horizontal, 13)
            .frame(height: 34)

            Divider().opacity(0.45)

            cardContent
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
        .background(Color(hex: item.colorHex) ?? Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 13, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 13, style: .continuous)
                .stroke(isSelected || isLinkSource ? Color.black.opacity(0.78) : Color.black.opacity(0.12), lineWidth: isSelected || isLinkSource ? 2 : 1)
        }
        .shadow(color: .black.opacity(isSelected ? 0.14 : 0.075), radius: isSelected ? 18 : 10, y: 5)
        .contentShape(RoundedRectangle(cornerRadius: 13, style: .continuous))
        .onTapGesture(count: 2, perform: onOpen)
        .onTapGesture(perform: onSelect)
        .gesture(
            DragGesture(minimumDistance: 3)
                .onChanged { value in
                    if dragStart == nil {
                        dragStart = CGPoint(x: item.x, y: item.y)
                    }
                    guard let dragStart else { return }
                    item.x = dragStart.x + value.translation.width
                    item.y = dragStart.y + value.translation.height
                }
                .onEnded { _ in
                    dragStart = nil
                    item.updatedAt = Date()
                    onMove()
                }
        )
    }

    @ViewBuilder
    private var cardContent: some View {
        if item.kind == .video {
            VStack(alignment: .leading, spacing: 9) {
                ZStack {
                    RoundedRectangle(cornerRadius: 7)
                        .fill(Color.black.opacity(0.83))
                    Image(systemName: "play.fill")
                        .font(.system(size: 28))
                        .foregroundStyle(.white)
                }
                .frame(maxWidth: .infinity, minHeight: 112)
                Text(item.title)
                    .font(.system(size: 14, weight: .semibold))
                Text(item.bodyText)
                    .font(.system(size: 11))
                    .foregroundStyle(Color.black.opacity(0.56))
                    .lineLimit(2)
            }
            .padding(13)
        } else if item.kind == .source {
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 12) {
                    Image(systemName: item.resource?.resourceType == .pdf ? "doc.richtext.fill" : "doc.fill")
                        .font(.system(size: 34, weight: .light))
                        .foregroundStyle(Color.blue.opacity(0.72))
                    VStack(alignment: .leading, spacing: 3) {
                        Text(item.title)
                            .font(.system(size: 15, weight: .semibold))
                            .lineLimit(2)
                        Text(item.bodyText)
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(Color.black.opacity(0.48))
                    }
                }
                Spacer()
                Label("Double-click to read", systemImage: "arrow.up.right.square")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(Color.black.opacity(0.52))
            }
            .padding(14)
        } else if item.kind == .sketch {
            VStack(alignment: .leading, spacing: 10) {
                Spacer()
                Image(systemName: "pencil.and.outline")
                    .font(.system(size: 36, weight: .light))
                    .foregroundStyle(Color.black.opacity(0.28))
                    .frame(maxWidth: .infinity)
                Text(item.title)
                    .font(.system(size: 15, weight: .semibold))
                Text(item.drawingData == nil ? "Double-click to write or draw with Apple Pencil." : "Sketch saved. Double-click to continue.")
                    .font(.system(size: 11))
                    .foregroundStyle(Color.black.opacity(0.52))
                Spacer()
            }
            .padding(14)
        } else {
            VStack(alignment: .leading, spacing: 9) {
                Text(item.title)
                    .font(.system(size: item.kind == .concept ? 17 : 15, weight: .semibold, design: item.kind == .concept ? .rounded : .default))
                    .lineLimit(3)
                Text(item.bodyText.isEmpty ? "Select to start writing…" : item.bodyText)
                    .font(SymphoNoteTypography.previewFont)
                    .foregroundStyle(Color.black.opacity(item.bodyText.isEmpty ? 0.34 : 0.68))
                    .lineSpacing(3)
                    .lineLimit(7)
                Spacer()
            }
            .padding(14)
        }
    }
}

private struct LabGuideAction: View {
    let icon: String
    let title: String
    let subtitle: String
    var action: () -> Void = {}

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .frame(width: 25, height: 25)
                    .background(Color.black.opacity(0.055), in: RoundedRectangle(cornerRadius: 6))
                VStack(alignment: .leading, spacing: 2) {
                    Text(title).font(.system(size: 11, weight: .semibold))
                    Text(subtitle).font(.system(size: 9)).foregroundStyle(SymphoTheme.secondaryText)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundStyle(SymphoTheme.tertiaryText)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

private struct LabGuideStep: View {
    let number: String
    let title: String
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Text(number)
                .font(.system(size: 10, weight: .bold))
                .frame(width: 22, height: 22)
                .background(Color.black, in: Circle())
                .foregroundStyle(.white)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.system(size: 11, weight: .semibold))
                Text(text).font(.system(size: 10)).foregroundStyle(SymphoTheme.secondaryText)
            }
        }
    }
}

private struct LabSketchEditor: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Bindable var item: LabItem

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                VStack(alignment: .leading) {
                    Text(item.title)
                        .font(.system(size: 16, weight: .semibold))
                    Text("Think by hand. Your strokes remain attached to this lab.")
                        .font(.system(size: 10))
                        .foregroundStyle(SymphoTheme.secondaryText)
                }
                Spacer()
                Button("Done") {
                    try? modelContext.save()
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
            }
            .padding(16)
            Divider()

            #if os(iOS)
            PencilCanvas(drawingData: Binding(
                get: { item.drawingData },
                set: { item.drawingData = $0; item.updatedAt = Date() }
            ))
            #else
            VStack(spacing: 14) {
                Image(systemName: "ipad.and.arrow.forward")
                    .font(.system(size: 44, weight: .light))
                Text("Open this lab on iPad to draw with Apple Pencil.")
                    .font(.system(size: 15, weight: .semibold))
                Text("The sketch syncs as part of the board and remains visible on Mac.")
                    .font(.system(size: 12))
                    .foregroundStyle(SymphoTheme.secondaryText)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            #endif
        }
        .frame(minWidth: 720, minHeight: 560)
        .background(Color.white)
    }
}

#if os(iOS)
private struct PencilCanvas: UIViewRepresentable {
    @Binding var drawingData: Data?

    func makeCoordinator() -> Coordinator {
        Coordinator(drawingData: $drawingData)
    }

    func makeUIView(context: Context) -> PKCanvasView {
        let canvas = PKCanvasView()
        canvas.delegate = context.coordinator
        canvas.drawingPolicy = .anyInput
        canvas.backgroundColor = .white
        if let drawingData, let drawing = try? PKDrawing(data: drawingData) {
            canvas.drawing = drawing
        }

        let picker = PKToolPicker()
        picker.addObserver(canvas)
        picker.setVisible(true, forFirstResponder: canvas)
        canvas.becomeFirstResponder()
        context.coordinator.toolPicker = picker
        return canvas
    }

    func updateUIView(_ uiView: PKCanvasView, context: Context) {}

    final class Coordinator: NSObject, PKCanvasViewDelegate {
        var drawingData: Binding<Data?>
        var toolPicker: PKToolPicker?

        init(drawingData: Binding<Data?>) {
            self.drawingData = drawingData
        }

        func canvasViewDrawingDidChange(_ canvasView: PKCanvasView) {
            drawingData.wrappedValue = canvasView.drawing.dataRepresentation()
        }
    }
}
#endif
