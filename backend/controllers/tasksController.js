const fs = require('fs');
const path = require('path');
const { v4: uuidv4 } = require('uuid');

const filePath = path.join(__dirname, '../data/tasks.json');
const VALID_CATEGORIES = ['High', 'Medium', 'Low'];

function normalizeCategory(category) {
  return VALID_CATEGORIES.includes(category) ? category : 'Medium';
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
  if (typeof title !== 'string' || title.trim() === '') {
    return res.status(400).json({ message: 'Title is required and cannot be empty' });
  }
  const normalizedCategory = normalizeCategory(category);
  const newTask = { id: uuidv4(), title: title.trim(), completed, category: normalizedCategory };
  tasks.push(newTask);
  writeTasks(tasks);
  res.status(201).json(newTask);
};

exports.updateTask = (req, res) => {
  const tasks = readTasks();
  const task = tasks.find(t => t.id === req.params.id);
  if (!task) return res.status(404).json({ message: 'Task not found' });

  if (req.body.title !== undefined) {
    if (typeof req.body.title !== 'string' || req.body.title.trim() === '') {
      return res.status(400).json({ message: 'Title is required and cannot be empty' });
    }
    task.title = req.body.title.trim();
  }
  task.completed = req.body.completed ?? task.completed;
  if (req.body.category !== undefined) {
    task.category = normalizeCategory(req.body.category);
  }
  writeTasks(tasks);
  res.json(task);
};

exports.deleteTask = (req, res) => {
  let tasks = readTasks();
  tasks = tasks.filter(t => t.id !== req.params.id);
  writeTasks(tasks);
  res.status(204).send();
};
