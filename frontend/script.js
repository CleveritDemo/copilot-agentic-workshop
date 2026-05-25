const API_URL = 'http://localhost:3000/api/tasks';
const taskList = document.getElementById('taskList');
const taskForm = document.getElementById('taskForm');
const taskInput = document.getElementById('taskInput');
const themeToggle = document.getElementById('themeToggle');
const searchInput = document.getElementById('searchInput');

let allTasks = [];

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
  allTasks = tasks;
  renderTasks();
}

function renderTasks(filterText = '') {
  const filteredTasks = filterText
    ? allTasks.filter(task => task.title.toLowerCase().includes(filterText.toLowerCase()))
    : allTasks;

  taskList.innerHTML = '';
  filteredTasks.forEach(addTaskToDOM);
}

function addTaskToDOM(task) {
  const li = document.createElement('li');
  li.innerHTML = `
    <span class="${task.completed ? 'completed' : ''}">${task.title}</span>
    <div>
      <button onclick="toggleComplete('${task.id}', ${!task.completed})">✓</button>
      <button onclick="deleteTask('${task.id}')">✕</button>
    </div>
  `;
  taskList.appendChild(li);
}

taskForm.addEventListener('submit', async e => {
  e.preventDefault();
  const title = taskInput.value;
  const res = await fetch(API_URL, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ title })
  });
  const task = await res.json();
  allTasks.push(task);
  renderTasks(searchInput.value);
  taskInput.value = '';
});

searchInput.addEventListener('input', e => {
  renderTasks(e.target.value);
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
