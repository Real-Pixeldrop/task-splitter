import SwiftUI

struct TaskSplitterView: View {
    @ObservedObject var taskManager: TaskManager
    @State private var newTask = ""
    @State private var showSettings = false
    @State private var apiKeyInput = ""

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Image(systemName: "scissors")
                    .font(.title2)
                Text("Task Splitter")
                    .font(.title2)
                    .fontWeight(.bold)
                Spacer()
                Button(action: { showSettings.toggle() }) {
                    Image(systemName: "gear")
                        .font(.title3)
                }
                .buttonStyle(.plain)
            }
            .padding()

            Divider()

            if showSettings {
                settingsView
            } else {
                // Input
                HStack {
                    TextField("Écris une tâche...", text: $newTask)
                        .textFieldStyle(.roundedBorder)
                        .onSubmit { addTask() }
                    Button("Split") { addTask() }
                        .disabled(newTask.isEmpty)
                }
                .padding(.horizontal)
                .padding(.vertical, 8)

                if !taskManager.hasApiKey {
                    HStack {
                        Image(systemName: "exclamationmark.triangle")
                            .foregroundColor(.orange)
                        Text("Clé API manquante — clique ⚙️")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal)
                }

                Divider()

                // Task list
                if taskManager.tasks.isEmpty {
                    Spacer()
                    VStack(spacing: 8) {
                        Image(systemName: "text.badge.plus")
                            .font(.largeTitle)
                            .foregroundColor(.secondary)
                        Text("Ajoute une tâche à découper")
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                } else {
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 4) {
                            ForEach(taskManager.tasks) { task in
                                taskRow(task)
                            }
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 8)
                    }
                }

                Divider()

                // Footer
                HStack {
                    Button("Vider terminées") { taskManager.clearCompleted() }
                        .font(.caption)
                        .buttonStyle(.plain)
                        .foregroundColor(.secondary)
                    Spacer()
                    Button("Tout effacer") {
                        taskManager.tasks.removeAll()
                        taskManager.saveTasks()
                    }
                    .font(.caption)
                    .buttonStyle(.plain)
                    .foregroundColor(.red)
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
            }
        }
        .frame(width: 420, height: 520)
    }

    var settingsView: some View {
        VStack(spacing: 12) {
            Text("Clé API Anthropic")
                .font(.headline)
            Text("Nécessaire pour découper les tâches avec l'IA")
                .font(.caption)
                .foregroundColor(.secondary)
            SecureField("sk-ant-...", text: $apiKeyInput)
                .textFieldStyle(.roundedBorder)
            HStack {
                Button("Annuler") { showSettings = false }
                Button("Sauvegarder") {
                    taskManager.setApiKey(apiKeyInput)
                    showSettings = false
                }
                .disabled(apiKeyInput.isEmpty)
            }
            Spacer()
        }
        .padding()
    }

    @ViewBuilder
    func taskRow(_ task: TaskItem) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 6) {
                // Indent based on depth
                if task.depth > 0 {
                    Rectangle()
                        .fill(Color.accentColor.opacity(0.3))
                        .frame(width: 2)
                        .padding(.leading, CGFloat(task.depth - 1) * 16)
                }

                Button(action: { taskManager.toggleComplete(task.id) }) {
                    Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                        .foregroundColor(task.isCompleted ? .green : .secondary)
                }
                .buttonStyle(.plain)

                Text(task.text)
                    .strikethrough(task.isCompleted)
                    .foregroundColor(task.isCompleted ? .secondary : .primary)
                    .font(.system(size: max(13 - CGFloat(task.depth), 11)))
                    .lineLimit(2)

                Spacer()

                if taskManager.isLoading && taskManager.loadingTaskId == task.id {
                    ProgressView()
                        .scaleEffect(0.6)
                } else if !task.isCompleted {
                    Button(action: { taskManager.splitTask(task.id) }) {
                        HStack(spacing: 2) {
                            Image(systemName: "scissors")
                            Text("Split")
                        }
                        .font(.caption2)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.accentColor.opacity(0.15))
                        .cornerRadius(4)
                    }
                    .buttonStyle(.plain)
                    .disabled(!taskManager.hasApiKey)
                }

                Button(action: { taskManager.removeTask(task.id) }) {
                    Image(systemName: "xmark")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }

            // Subtasks rendered inline to avoid recursive opaque type
            if !task.subtasks.isEmpty {
                ForEach(task.subtasks) { subtask in
                    subtaskRow(subtask)
                        .padding(.leading, 16)
                }
            }
        }
    }

    @ViewBuilder
    func subtaskRow(_ task: TaskItem) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 6) {
                Rectangle()
                    .fill(Color.accentColor.opacity(0.3))
                    .frame(width: 2)
                    .padding(.leading, CGFloat(max(task.depth - 1, 0)) * 16)

                Button(action: { taskManager.toggleComplete(task.id) }) {
                    Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                        .foregroundColor(task.isCompleted ? .green : .secondary)
                }
                .buttonStyle(.plain)

                Text(task.text)
                    .strikethrough(task.isCompleted)
                    .foregroundColor(task.isCompleted ? .secondary : .primary)
                    .font(.system(size: max(13 - CGFloat(task.depth), 11)))
                    .lineLimit(2)

                Spacer()

                if taskManager.isLoading && taskManager.loadingTaskId == task.id {
                    ProgressView()
                        .scaleEffect(0.6)
                } else if !task.isCompleted {
                    Button(action: { taskManager.splitTask(task.id) }) {
                        HStack(spacing: 2) {
                            Image(systemName: "scissors")
                            Text("Split")
                        }
                        .font(.caption2)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.accentColor.opacity(0.15))
                        .cornerRadius(4)
                    }
                    .buttonStyle(.plain)
                    .disabled(!taskManager.hasApiKey)
                }

                Button(action: { taskManager.removeTask(task.id) }) {
                    Image(systemName: "xmark")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }

            // Level 2 subtasks (max depth display)
            if !task.subtasks.isEmpty {
                ForEach(task.subtasks) { sub in
                    HStack(spacing: 6) {
                        Rectangle()
                            .fill(Color.accentColor.opacity(0.2))
                            .frame(width: 2)
                            .padding(.leading, CGFloat(max(sub.depth - 1, 0)) * 16)

                        Button(action: { taskManager.toggleComplete(sub.id) }) {
                            Image(systemName: sub.isCompleted ? "checkmark.circle.fill" : "circle")
                                .foregroundColor(sub.isCompleted ? .green : .secondary)
                        }
                        .buttonStyle(.plain)

                        Text(sub.text)
                            .strikethrough(sub.isCompleted)
                            .foregroundColor(sub.isCompleted ? .secondary : .primary)
                            .font(.system(size: 11))
                            .lineLimit(2)

                        Spacer()

                        if taskManager.isLoading && taskManager.loadingTaskId == sub.id {
                            ProgressView()
                                .scaleEffect(0.6)
                        } else if !sub.isCompleted {
                            Button(action: { taskManager.splitTask(sub.id) }) {
                                HStack(spacing: 2) {
                                    Image(systemName: "scissors")
                                    Text("Split")
                                }
                                .font(.caption2)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.accentColor.opacity(0.15))
                                .cornerRadius(4)
                            }
                            .buttonStyle(.plain)
                            .disabled(!taskManager.hasApiKey)
                        }
                    }
                    .padding(.leading, 16)
                }
            }
        }
    }

    func addTask() {
        guard !newTask.isEmpty else { return }
        taskManager.addTask(newTask)
        if taskManager.hasApiKey {
            // Auto-split the first time
            if let firstTask = taskManager.tasks.first {
                taskManager.splitTask(firstTask.id)
            }
        }
        newTask = ""
    }
}
