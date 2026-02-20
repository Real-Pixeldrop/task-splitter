import Foundation

struct TaskItem: Identifiable, Codable {
    let id: UUID
    var text: String
    var subtasks: [TaskItem]
    var isCompleted: Bool
    var depth: Int

    init(text: String, depth: Int = 0) {
        self.id = UUID()
        self.text = text
        self.subtasks = []
        self.isCompleted = false
        self.depth = depth
    }
}

class TaskManager: ObservableObject {
    @Published var tasks: [TaskItem] = []
    @Published var isLoading = false
    @Published var loadingTaskId: UUID?
    private var apiKey: String = ""

    private let storageFile: URL

    init() {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let appDir = appSupport.appendingPathComponent("TaskSplitter")
        try? FileManager.default.createDirectory(at: appDir, withIntermediateDirectories: true)
        storageFile = appDir.appendingPathComponent("tasks.json")

        // Load API key from file or env
        let keyFile = appDir.appendingPathComponent("api_key")
        if let key = try? String(contentsOf: keyFile, encoding: .utf8) {
            apiKey = key.trimmingCharacters(in: .whitespacesAndNewlines)
        } else if let key = ProcessInfo.processInfo.environment["ANTHROPIC_API_KEY"] {
            apiKey = key
        }

        loadTasks()
    }

    func addTask(_ text: String) {
        let task = TaskItem(text: text, depth: 0)
        tasks.insert(task, at: 0)
        saveTasks()
    }

    func removeTask(_ id: UUID) {
        tasks.removeAll { $0.id == id }
        saveTasks()
    }

    func toggleComplete(_ id: UUID) {
        toggleCompleteIn(list: &tasks, id: id)
        saveTasks()
    }

    private func toggleCompleteIn(list: inout [TaskItem], id: UUID) {
        for i in list.indices {
            if list[i].id == id {
                list[i].isCompleted.toggle()
                return
            }
            toggleCompleteIn(list: &list[i].subtasks, id: id)
        }
    }

    func splitTask(_ id: UUID) {
        guard !apiKey.isEmpty else { return }
        isLoading = true
        loadingTaskId = id

        // Find the task text and depth
        guard let (text, depth) = findTask(in: tasks, id: id) else {
            isLoading = false
            loadingTaskId = nil
            return
        }

        let prompt = """
        Decompose cette tache en 3 a 5 sous-taches actionnables et concretes de 15 minutes max chacune.
        La tache : "\(text)"
        Reponds UNIQUEMENT avec les sous-taches, une par ligne, sans numerotation, sans tiret, sans explication.
        Chaque sous-tache doit commencer par un verbe d'action.
        """

        callClaude(prompt: prompt) { [weak self] result in
            DispatchQueue.main.async {
                if let subtasks = result {
                    let newDepth = depth + 1
                    let items = subtasks
                        .components(separatedBy: "\n")
                        .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                        .filter { !$0.isEmpty }
                        .map { TaskItem(text: $0, depth: newDepth) }

                    self?.insertSubtasks(items, for: id)
                }
                self?.isLoading = false
                self?.loadingTaskId = nil
            }
        }
    }

    private func findTask(in list: [TaskItem], id: UUID) -> (String, Int)? {
        for item in list {
            if item.id == id { return (item.text, item.depth) }
            if let found = findTask(in: item.subtasks, id: id) { return found }
        }
        return nil
    }

    private func insertSubtasks(_ subtasks: [TaskItem], for id: UUID) {
        insertSubtasksIn(list: &tasks, subtasks: subtasks, for: id)
        saveTasks()
    }

    private func insertSubtasksIn(list: inout [TaskItem], subtasks: [TaskItem], for id: UUID) {
        for i in list.indices {
            if list[i].id == id {
                list[i].subtasks = subtasks
                return
            }
            insertSubtasksIn(list: &list[i].subtasks, subtasks: subtasks, for: id)
        }
    }

    private func callClaude(prompt: String, completion: @escaping (String?) -> Void) {
        guard let url = URL(string: "https://api.anthropic.com/v1/messages") else {
            completion(nil)
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "content-type")
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")

        let body: [String: Any] = [
            "model": "claude-sonnet-4-20250514",
            "max_tokens": 500,
            "messages": [
                ["role": "user", "content": prompt]
            ]
        ]

        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        URLSession.shared.dataTask(with: request) { data, _, error in
            guard let data = data, error == nil,
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let content = json["content"] as? [[String: Any]],
                  let first = content.first,
                  let text = first["text"] as? String else {
                completion(nil)
                return
            }
            completion(text.isEmpty ? nil : text)
        }.resume()
    }

    func saveTasks() {
        if let data = try? JSONEncoder().encode(tasks) {
            try? data.write(to: storageFile)
        }
    }

    func loadTasks() {
        guard let data = try? Data(contentsOf: storageFile),
              let saved = try? JSONDecoder().decode([TaskItem].self, from: data) else { return }
        tasks = saved
    }

    func clearCompleted() {
        clearCompletedIn(list: &tasks)
        saveTasks()
    }

    private func clearCompletedIn(list: inout [TaskItem]) {
        list.removeAll { $0.isCompleted }
        for i in list.indices {
            clearCompletedIn(list: &list[i].subtasks)
        }
    }

    var hasApiKey: Bool { !apiKey.isEmpty }

    func setApiKey(_ key: String) {
        apiKey = key
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let keyFile = appSupport.appendingPathComponent("TaskSplitter/api_key")
        try? key.write(to: keyFile, atomically: true, encoding: .utf8)
    }
}
