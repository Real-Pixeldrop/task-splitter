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
    let aiProvider = AIProvider()

    private let storageFile: URL

    init() {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let appDir = appSupport.appendingPathComponent("TaskSplitter")
        try? FileManager.default.createDirectory(at: appDir, withIntermediateDirectories: true)
        storageFile = appDir.appendingPathComponent("tasks.json")
        loadTasks()
    }

    func addTask(_ text: String) {
        let task = TaskItem(text: text, depth: 0)
        tasks.insert(task, at: 0)
        saveTasks()
    }

    func removeTask(_ id: UUID) {
        removeTaskIn(list: &tasks, id: id)
        saveTasks()
    }

    private func removeTaskIn(list: inout [TaskItem], id: UUID) {
        list.removeAll { $0.id == id }
        for i in list.indices {
            removeTaskIn(list: &list[i].subtasks, id: id)
        }
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
        guard aiProvider.isConfigured else { return }
        isLoading = true
        loadingTaskId = id

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

        aiProvider.splitTask(prompt: prompt) { [weak self] result in
            DispatchQueue.main.async {
                if let text = result {
                    let newDepth = depth + 1
                    let items = text
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
}
