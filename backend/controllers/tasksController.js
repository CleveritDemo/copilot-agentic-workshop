const fs = require('fs');
const path = require('path');
const { v4: uuidv4 } = require('uuid');

const filePath = path.join(__dirname, '../data/tasks.json');
const ALLOWED_CATEGORIES = ['Low', 'Medium', 'High'];

function normalizeTitle(title) {
  const trimmedTitle = title?.trim();
  return trimmedTitle || null;
}

function readTasks() {
  return JSON.parse(fs.readFileSync(filePath, 'utf-8'));
}

function writeTasks(tasks) {
  fs.writeFileSync(filePath, JSON.stringify(tasks, null, 2));
}

exports.getAllTasks = (req, res) => {
  res.json(readTasks());
};

exports.createTask = (req, res) => {
  const tasks = readTasks();
  const { title, completed = false, category = 'Medium' } = req.body;
  const normalizedTitle = normalizeTitle(title);

  if (!normalizedTitle) {
    return res.status(400).json({ message: 'Title is required' });
  }

  const normalizedCategory = ALLOWED_CATEGORIES.includes(category) ? category : 'Medium';
  const newTask = { id: uuidv4(), title: normalizedTitle, category: normalizedCategory, completed };
  tasks.push(newTask);
  writeTasks(tasks);
  res.status(201).json(newTask);
};

exports.updateTask = (req, res) => {
  const tasks = readTasks();
  const task = tasks.find(t => t.id === req.params.id);
  if (!task) return res.status(404).json({ message: 'Task not found' });

  if (req.body.title !== undefined) {
    const normalizedTitle = normalizeTitle(req.body.title);
    if (!normalizedTitle) {
      return res.status(400).json({ message: 'Title cannot be empty' });
    }
    task.title = normalizedTitle;
  }

  if (req.body.category !== undefined) {
    if (!ALLOWED_CATEGORIES.includes(req.body.category)) {
      return res.status(400).json({ message: 'Invalid category' });
    }
    task.category = req.body.category;
  }

  task.completed = req.body.completed ?? task.completed;
  writeTasks(tasks);
  res.json(task);
};

exports.deleteTask = (req, res) => {
  let tasks = readTasks();
  tasks = tasks.filter(t => t.id !== req.params.id);
  writeTasks(tasks);
  res.status(204).send();
};
