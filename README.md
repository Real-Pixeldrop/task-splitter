# Task Splitter

Décomposition de tâches par IA. Colle n'importe quelle tâche, obtiens des sous-tâches actionnables. Menu bar macOS.

## Download

[Télécharger TaskSplitter.zip](https://github.com/Real-Pixeldrop/task-splitter/releases/latest/download/TaskSplitter.zip)

1. Télécharge le zip
2. Dézipe
3. Glisse dans Applications
4. Double-clic. C'est prêt.

## Comment ça marche

1. **Colle** une tâche complexe
2. **Splitte** en sous-tâches actionnables grâce à l'IA
3. **Décompose** récursivement si besoin
4. **Copie** le résultat et passe à l'action

## From source

```bash
git clone https://github.com/Real-Pixeldrop/task-splitter.git
cd task-splitter
swift build -c release
cp -r .build/release/TaskSplitter.app /Applications/ 2>/dev/null || \
  cp .build/release/TaskSplitter /Applications/
```

## One-liner install

```bash
curl -sL https://github.com/Real-Pixeldrop/task-splitter/releases/latest/download/TaskSplitter.zip -o /tmp/ts.zip && unzip -o /tmp/ts.zip -d /Applications/ && xattr -cr /Applications/TaskSplitter.app && open /Applications/TaskSplitter.app
```
