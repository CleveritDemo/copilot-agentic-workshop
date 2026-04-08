const API_URL = 'http://localhost:3000/api/tasks';
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
  const li = document.createElement('li');
  const categoryClass = `category-${task.category ? task.category.toLowerCase() : 'medium'}`;
  li.innerHTML = `
    <span class="${task.completed ? 'completed' : ''}">${task.title}</span>
    <div class="task-actions">
      <span class="category-badge ${categoryClass}">${task.category || 'Medium'}</span>
      <button onclick="toggleComplete('${task.id}', ${!task.completed})">✓</button>
      <button onclick="deleteTask('${task.id}')">✕</button>
    </div>
  `;
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
  categorySelect.value = 'Medium';
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
