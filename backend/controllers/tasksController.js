const fs = require('fs');
const path = require('path');
const { v4: uuidv4 } = require('uuid');

const filePath = path.join(__dirname, '../data/tasks.json');
const VALID_CATEGORIES = ['Low', 'Medium', 'High'];

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
  const { title, completed = false } = req.body;
  const rawCategory = req.body.category ?? 'Medium';
  const normalizedCategory = VALID_CATEGORIES.find(c => c.toLowerCase() === String(rawCategory).toLowerCase());
  if (!normalizedCategory) {
    return res.status(400).json({ message: 'Invalid category. Must be one of: Low, Medium, High' });
  }
  const newTask = { id: uuidv4(), title, completed, category: normalizedCategory };
  tasks.push(newTask);
  writeTasks(tasks);
  res.status(201).json(newTask);
};

exports.updateTask = (req, res) => {
  const tasks = readTasks();
  const task = tasks.find(t => t.id === req.params.id);
  if (!task) return res.status(404).json({ message: 'Task not found' });

  task.title = req.body.title ?? task.title;
  task.completed = req.body.completed ?? task.completed;
  if (req.body.category !== undefined) {
    const normalizedCategory = VALID_CATEGORIES.find(c => c.toLowerCase() === String(req.body.category).toLowerCase());
    if (!normalizedCategory) {
      return res.status(400).json({ message: 'Invalid category. Must be one of: Low, Medium, High' });
    }
    task.category = normalizedCategory;
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
