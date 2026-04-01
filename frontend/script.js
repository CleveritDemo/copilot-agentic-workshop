const API_URL = 'http://localhost:3000/api/tasks';
const CATEGORIES = ['Low', 'Medium', 'High'];
const DEFAULT_CATEGORY = 'Medium';
const taskList = document.getElementById('taskList');
const taskForm = document.getElementById('taskForm');
const taskInput = document.getElementById('taskInput');
const categorySelect = document.getElementById('categorySelect');
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
  const category = task.category || DEFAULT_CATEGORY;
  const li = document.createElement('li');
  const titleSpan = document.createElement('span');
  titleSpan.className = task.completed ? 'completed' : '';
  titleSpan.textContent = task.title;
  const categoryBadge = document.createElement('span');
  categoryBadge.className = `category-badge category-${category.toLowerCase()}`;
  categoryBadge.textContent = category;
  const actions = document.createElement('div');
  const completeBtn = document.createElement('button');
  completeBtn.textContent = '✓';
  completeBtn.onclick = () => toggleComplete(task.id, !task.completed);
  const deleteBtn = document.createElement('button');
  deleteBtn.textContent = '✕';
  deleteBtn.onclick = () => deleteTask(task.id);
  actions.appendChild(completeBtn);
  actions.appendChild(deleteBtn);
  li.appendChild(titleSpan);
  li.appendChild(categoryBadge);
  li.appendChild(actions);
  taskList.appendChild(li);
}

taskForm.addEventListener('submit', async e => {
  e.preventDefault();
  const title = taskInput.value;
  const category = categorySelect.value;
  const res = await fetch(API_URL, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ title, category })
  });
  const task = await res.json();
  addTaskToDOM(task);
  taskInput.value = '';
  categorySelect.value = DEFAULT_CATEGORY;
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
