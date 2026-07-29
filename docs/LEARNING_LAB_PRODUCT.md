# Sympho Learning Lab

## Product thesis

The Lab is not a whiteboard with attachments. It is a place where a learner moves through a complete understanding loop:

1. **Collect** primary material without breaking focus.
2. **Read and watch** inside the workspace.
3. **Distill** passages into claims, concepts, and questions.
4. **Connect** each idea back to evidence and to related ideas.
5. **Explain** the emerging model in the learner's own words.
6. **Retrieve** it later without the source visible.
7. **Apply** it in a project or learning node.

This is the missing bridge between Sympho's reference Library and its structured Domains, Tracks, Modules, and Nodes.

## Design principles

- **Source truth over AI fluency.** Every generated statement should cite an exact source, page, timestamp, or note.
- **The canvas is a view, not the database.** Cards represent durable resources, excerpts, concepts, questions, and learning nodes. Moving a card does not trap the knowledge inside a proprietary board.
- **Spatial when useful, structured when needed.** Free arrangement helps sense-making; an outline, source list, graph, and review queue keep large labs navigable.
- **Ink is first-class data.** Pencil strokes should remain editable, searchable after handwriting recognition, and attachable to concepts or source regions.
- **Reading must produce action.** Highlights can become a note, question, claim, connection, or recall prompt in one gesture.
- **Local-first by default.** Original files, annotations, coordinates, and extracted text remain available offline. AI is an optional processing layer.
- **Progress means demonstrated understanding.** A full board is not progress. Explanations, answered questions, retrieval history, and applied outputs are.

## Core object model

| Object | Purpose | Durable provenance |
| --- | --- | --- |
| Lab | A focused inquiry or course workspace | Domain, Track, Module, Node, or Project |
| Source | PDF, web page, video, audio, image, EPUB, slide deck, or file | Original file/URL and content hash |
| Excerpt | A selected passage, region, image, or timestamp | Source ID plus page/coordinates/time range |
| Note | The learner's own writing or ink | Optional links to any objects |
| Concept | A canonical idea that can appear on many boards | Backlinks and aliases |
| Question | An uncertainty or retrieval prompt | Answer history, confidence, next review |
| Connection | A typed relationship | `supports`, `contradicts`, `explains`, `example of`, `depends on`, or custom |
| Synthesis | A learner- or AI-produced explanation | Exact citations and revision history |

## Interaction model

### Canvas

- Pan, pinch/scroll zoom, minimap, frame selection, alignment, grouping, and semantic zoom.
- At far zoom, cards collapse into recognizable source/concept clusters.
- At near zoom, PDFs, video, rich notes, and ink become directly interactive.
- Connections attach to objects and source anchors, not just screen coordinates.
- Focus mode temporarily turns a cluster into a split reader + notes layout.

### PDF and document reading

- PDFKit reader with thumbnails, outline, search, highlights, underline, ink, comments, and page history.
- Drag a selection onto the canvas to create an excerpt that preserves page and quadrilateral bounds.
- Clicking an excerpt returns to the exact page and selection.
- Place two excerpts side-by-side even when they come from different documents.
- OCR scanned PDFs and index recognized text locally.

### Video and audio

- Embedded player with transcript and chapters.
- A note created while playing automatically stores the current timestamp.
- Transcript selections become source excerpts.
- Ink and typed notes can be synchronized to playback time.

### Apple Pencil

- PencilKit canvas with the native tool picker, pressure-sensitive ink, lasso, erase, and ruler.
- Pencil double-tap/hover can switch tools or reveal source anchors.
- On-device handwriting recognition makes ink searchable without replacing the strokes.
- Scribble in card text fields and draw directly over PDF pages.

### Active learning

- “Explain without looking” hides connected source material and opens a response surface.
- A learner can rate confidence before revealing cited evidence.
- Questions enter Sympho's Planner using spaced retrieval rules.
- AI varies the framing of a prompt rather than repeating an identical flashcard.
- A concept is considered understood only after successful retrieval and/or application, never from reading time alone.

## Grounded AI

The assistant should operate on a selected scope: one object, a cluster, selected sources, or the entire Lab.

Useful actions:

- Explain this passage in the context of the current learning goal.
- Compare selected claims and identify assumptions or contradictions.
- Find missing prerequisites.
- Suggest connections, but require user confirmation before adding them.
- Generate questions at factual, conceptual, transfer, and critique levels.
- Critique the learner's explanation against cited evidence.
- Produce a source-backed briefing, glossary, timeline, mind map, or audio script.

The retrieval pipeline should retain chunk-level metadata for file hash, source ID, page, bounding region, timestamp, and extraction method. Answers without retrievable citations should be visibly marked as general model knowledge.

## NotebookLM bridge

NotebookLM is a useful companion, but Sympho should not depend on an undocumented integration.

Near-term:

- Export a Lab source pack containing original supported sources, a Markdown index, questions, and citation metadata.
- Copy a clean prompt describing the Lab's focus question and desired output.
- Accept NotebookLM-generated notes or exported artifacts back as attributed sources.

Later:

- Add a direct connector only if Google publishes a supported NotebookLM API or import contract.
- Keep Sympho's native grounded assistant so the spatial workflow, citations, and active-recall loop remain integrated.

## Delivery sequence

### Foundation

- Persistent labs, typed spatial cards, connections, file/PDF import, native preview, video links, inspector, and PencilKit sketches.
- This is the current implemented slice.

### Deep reading

- Full embedded PDF card/reader, durable annotations, exact excerpt anchors, thumbnails, OCR, and cross-document comparison.
- Embedded media playback with timestamped notes and transcripts.

### Understanding engine

- Local extraction and indexing, grounded chat, cited synthesis, concept suggestions, contradiction detection, and prerequisite mapping.
- Promote concepts and questions into existing Sympho learning nodes.

### Practice loop

- Recall sessions, confidence calibration, adaptive scheduling in Planner, explanation critique, and mastery evidence.
- Board health indicators: uncited claims, unanswered questions, stale sources, and due retrieval prompts.

### Scale and collaboration

- Minimap, semantic zoom, frames, saved views, keyboard/Pencil power tools, export, version history, CloudKit collaboration, presence, and comments.

## Inspiration and evidence

- [Apple PencilKit](https://developer.apple.com/documentation/pencilkit) for low-latency editable ink and on-device handwriting analysis.
- [Apple PDFKit](https://developer.apple.com/documentation/pdfkit) for native document display, selection, search, and annotation.
- [LiquidText](https://www.liquidtext.net/features) for pulling source-grounded excerpts into a parallel workspace.
- [Muse](https://museapp.com/) for a calm, mixed-media spatial desk.
- [NotebookLM](https://support.google.com/notebooklm/answer/16164461) for source-grounded answers and transformations such as study guides, mind maps, and audio overviews.
- [tldraw](https://github.com/tldraw/tldraw) for the interaction quality expected from a modern extensible infinite canvas.
- [Carpenter, Pan, and Butler (2022)](https://doi.org/10.1038/s44159-022-00089-1) for the role of spacing and retrieval practice in durable learning.

