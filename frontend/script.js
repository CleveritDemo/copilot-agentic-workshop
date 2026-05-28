const API_URL = 'http://localhost:3000/api/tasks';
const taskList = document.getElementById('taskList');
const taskForm = document.getElementById('taskForm');
const taskInput = document.getElementById('taskInput');
const taskCategory = document.getElementById('taskCategory');
const themeToggle = document.getElementById('themeToggle');

// Theme functionality
function initTheme() {
  const savedTheme = localStorage.getItem('theme') || 'light';
  applyTheme(savedTheme);
}

function applyTheme(theme) {
  document.documentElement.setAttribute('data-theme', theme);
  themeToggle.textContent = theme === 'dark' ? '☀️' : '🌙';
  localStorage.setItem('theme', theme);
}

function toggleTheme() {
  const currentTheme = document.documentElement.getAttribute('data-theme') || 'light';
  const newTheme = currentTheme === 'dark' ? 'light' : 'dark';
  applyTheme(newTheme);
}

themeToggle.addEventListener('click', toggleTheme);

// Initialize theme on page load
initTheme();

async function fetchTasks() {
  const res = await fetch(API_URL);
  const tasks = await res.json();
  taskList.innerHTML = '';
  tasks.forEach(addTaskToDOM);
}

function addTaskToDOM(task) {
  const category = task.category || 'Medium';
  const li = document.createElement('li');
  const taskContent = document.createElement('div');
  taskContent.className = 'task-content';

  const title = document.createElement('span');
  title.className = `task-title ${task.completed ? 'completed' : ''}`;
  title.textContent = task.title;

  const badge = document.createElement('span');
  badge.className = `category-badge category-${category.toLowerCase()}`;
  badge.textContent = category;

  const actions = document.createElement('div');

  const completeButton = document.createElement('button');
  completeButton.textContent = '✓';
  completeButton.setAttribute('aria-label', task.completed ? 'Mark task as incomplete' : 'Mark task as complete');
  completeButton.addEventListener('click', () => toggleComplete(task.id, !task.completed));

  const deleteButton = document.createElement('button');
  deleteButton.textContent = '✕';
  deleteButton.setAttribute('aria-label', 'Delete task');
  deleteButton.addEventListener('click', () => deleteTask(task.id));

  taskContent.appendChild(title);
  taskContent.appendChild(badge);
  actions.appendChild(completeButton);
  actions.appendChild(deleteButton);
  li.appendChild(taskContent);
  li.appendChild(actions);
  taskList.appendChild(li);
}

taskForm.addEventListener('submit', async e => {
  e.preventDefault();
  const title = taskInput.value.trim();
  if (!title) return;
  const category = taskCategory.value || 'Medium';
  const res = await fetch(API_URL, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ title, category })
  });
  const task = await res.json();
  addTaskToDOM(task);
  taskInput.value = '';
  taskCategory.value = 'Medium';
});

async function toggleComplete(id, completed) {
  await fetch(`${API_URL}/${id}`, {
    method: 'PUT',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ completed })
  });
  fetchTasks();
}

async function deleteTask(id) {
  await fetch(`${API_URL}/${id}`, { method: 'DELETE' });
  fetchTasks();
}

fetchTasks();
