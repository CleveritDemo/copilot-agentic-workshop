const API_URL = 'http://localhost:3000/api/tasks';
const taskList = document.getElementById('taskList');
const taskForm = document.getElementById('taskForm');
const taskInput = document.getElementById('taskInput');
const taskCategory = document.getElementById('taskCategory');
const themeToggle = document.getElementById('themeToggle');
const CATEGORIES = ['Low', 'Medium', 'High'];

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
  const category = CATEGORIES.includes(task.category) ? task.category : 'Medium';
  li.innerHTML = `
    <div class="task-main">
      <span class="${task.completed ? 'completed' : ''}">${task.title}</span>
      <small class="task-category task-category-${category.toLowerCase()}">${category}</small>
    </div>
    <div>
      <button onclick="toggleComplete('${task.id}', ${!task.completed})">✓</button>
      <button onclick="editTask('${task.id}', '${encodeURIComponent(task.title)}', '${category}')">✎</button>
      <button onclick="deleteTask('${task.id}')">✕</button>
    </div>
  `;
  taskList.appendChild(li);
}

taskForm.addEventListener('submit', async e => {
  e.preventDefault();
  const title = taskInput.value.trim();
  if (!title) return;

  const category = CATEGORIES.includes(taskCategory.value) ? taskCategory.value : 'Medium';
  const res = await fetch(API_URL, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ title, category })
  });

  if (!res.ok) return;

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

async function editTask(id, encodedCurrentTitle, currentCategory) {
  const currentTitle = decodeURIComponent(encodedCurrentTitle);
  const newTitle = prompt('Edit task title:', currentTitle);
  if (newTitle === null) return;

  const normalizedTitle = newTitle.trim();
  if (!normalizedTitle) {
    alert('Title cannot be empty.');
    return;
  }

  const newCategory = prompt(
    `Edit category (${CATEGORIES.join(', ')}):`,
    currentCategory
  );
  if (newCategory === null) return;

  const normalizedCategory = newCategory.trim();
  if (!CATEGORIES.includes(normalizedCategory)) {
    alert(`Invalid category. Use one of: ${CATEGORIES.join(', ')}.`);
    return;
  }

  const res = await fetch(`${API_URL}/${id}`, {
    method: 'PUT',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ title: normalizedTitle, category: normalizedCategory })
  });

  if (!res.ok) {
    alert('Could not update task.');
    return;
  }

  fetchTasks();
}

fetchTasks();
