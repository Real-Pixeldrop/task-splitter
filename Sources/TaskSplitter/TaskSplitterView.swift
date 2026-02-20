import SwiftUI

struct TaskSplitterView: View {
    @ObservedObject var taskManager: TaskManager
    @State private var newTask = ""
    @State private var showSettings = false

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
                // Provider badge
                Text(taskManager.aiProvider.currentConfig.selectedProvider.rawValue)
                    .font(.caption2)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.accentColor.opacity(0.15))
                    .cornerRadius(4)
                Button(action: { showSettings.toggle() }) {
                    Image(systemName: "gear")
                        .font(.title3)
                }
                .buttonStyle(.plain)
            }
            .padding()

            Divider()

            if showSettings {
                SettingsView(aiProvider: taskManager.aiProvider, showSettings: $showSettings)
            } else {
                // Input
                HStack {
                    TextField("Écris une tâche...", text: $newTask)
                        .textFieldStyle(.roundedBorder)
                        .onSubmit { addTask() }
                    Button("Split") { addTask() }
                        .disabled(newTask.isEmpty || !taskManager.aiProvider.isConfigured)
                }
                .padding(.horizontal)
                .padding(.vertical, 8)

                if !taskManager.aiProvider.isConfigured {
                    HStack {
                        Image(systemName: "exclamationmark.triangle")
                            .foregroundColor(.orange)
                        Text("Configure ton IA — clique ⚙️")
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

    @ViewBuilder
    func taskRow(_ task: TaskItem) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            singleTaskRow(task)

            if !task.subtasks.isEmpty {
                ForEach(task.subtasks) { subtask in
                    VStack(alignment: .leading, spacing: 2) {
                        singleTaskRow(subtask)
                            .padding(.leading, 16)

                        if !subtask.subtasks.isEmpty {
                            ForEach(subtask.subtasks) { sub2 in
                                singleTaskRow(sub2)
                                    .padding(.leading, 32)
                            }
                        }
                    }
                }
            }
        }
    }

    @ViewBuilder
    func singleTaskRow(_ task: TaskItem) -> some View {
        HStack(spacing: 6) {
            if task.depth > 0 {
                Rectangle()
                    .fill(Color.accentColor.opacity(0.3))
                    .frame(width: 2)
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
                .disabled(!taskManager.aiProvider.isConfigured)
            }

            Button(action: { taskManager.removeTask(task.id) }) {
                Image(systemName: "xmark")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .buttonStyle(.plain)
        }
    }

    func addTask() {
        guard !newTask.isEmpty else { return }
        taskManager.addTask(newTask)
        if taskManager.aiProvider.isConfigured {
            if let firstTask = taskManager.tasks.first {
                taskManager.splitTask(firstTask.id)
            }
        }
        newTask = ""
    }
}

// MARK: - Settings View

struct SettingsView: View {
    let aiProvider: AIProvider
    @Binding var showSettings: Bool

    @State private var selectedProvider: AIProviderType
    @State private var anthropicKey: String
    @State private var openaiKey: String
    @State private var ollamaModel: String
    @State private var ollamaURL: String

    init(aiProvider: AIProvider, showSettings: Binding<Bool>) {
        self.aiProvider = aiProvider
        self._showSettings = showSettings
        let config = aiProvider.currentConfig
        self._selectedProvider = State(initialValue: config.selectedProvider)
        self._anthropicKey = State(initialValue: config.anthropicKey)
        self._openaiKey = State(initialValue: config.openaiKey)
        self._ollamaModel = State(initialValue: config.ollamaModel)
        self._ollamaURL = State(initialValue: config.ollamaURL)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Choisis ton IA")
                    .font(.headline)

                // Provider cards
                ForEach(AIProviderType.allCases, id: \.self) { provider in
                    providerCard(provider)
                }

                // Config for selected provider
                switch selectedProvider {
                case .anthropic:
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Clé API Anthropic")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        SecureField("sk-ant-...", text: $anthropicKey)
                            .textFieldStyle(.roundedBorder)
                        Link("Obtenir une clé →", destination: URL(string: "https://console.anthropic.com")!)
                            .font(.caption)
                    }

                case .openai:
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Clé API OpenAI")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        SecureField("sk-...", text: $openaiKey)
                            .textFieldStyle(.roundedBorder)
                        Link("Obtenir une clé →", destination: URL(string: "https://platform.openai.com/api-keys")!)
                            .font(.caption)
                    }

                case .ollama:
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Modèle")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        TextField("llama3.2", text: $ollamaModel)
                            .textFieldStyle(.roundedBorder)
                        Text("URL Ollama")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        TextField("http://localhost:11434", text: $ollamaURL)
                            .textFieldStyle(.roundedBorder)
                        Link("Installer Ollama →", destination: URL(string: "https://ollama.com")!)
                            .font(.caption)
                    }
                }

                // Buttons
                HStack {
                    Button("Annuler") { showSettings = false }
                    Spacer()
                    Button("Sauvegarder") {
                        var config = AIProviderConfig()
                        config.selectedProvider = selectedProvider
                        config.anthropicKey = anthropicKey
                        config.openaiKey = openaiKey
                        config.ollamaModel = ollamaModel
                        config.ollamaURL = ollamaURL
                        aiProvider.currentConfig = config
                        showSettings = false
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
            .padding()
        }
    }

    func providerCard(_ provider: AIProviderType) -> some View {
        Button(action: { selectedProvider = provider }) {
            HStack {
                Image(systemName: provider.icon)
                    .font(.title3)
                    .frame(width: 28)
                VStack(alignment: .leading) {
                    Text(provider.rawValue)
                        .font(.system(size: 13, weight: .medium))
                    Text(provider.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
                if selectedProvider == provider {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.accentColor)
                }
            }
            .padding(10)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(selectedProvider == provider ? Color.accentColor.opacity(0.1) : Color.clear)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(selectedProvider == provider ? Color.accentColor : Color.gray.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}
