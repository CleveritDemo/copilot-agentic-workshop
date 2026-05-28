const API_URL = 'http://localhost:3000/api/tasks';
const taskList = document.getElementById('taskList');
const taskForm = document.getElementById('taskForm');
const taskInput = document.getElementById('taskInput');
const taskCategory = document.getElementById('taskCategory');
const themeToggle = document.getElementById('themeToggle');
const CATEGORIES = ['Low', 'Medium', 'High'];
const DEFAULT_CATEGORY = 'Medium';

function isValidCategory(category) {
  return CATEGORIES.includes(category);
}

function normalizeCategory(category) {
  return isValidCategory(category) ? category : DEFAULT_CATEGORY;
}

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
  const category = normalizeCategory(task.category);

  const taskMain = document.createElement('div');
  taskMain.className = 'task-main';

  const titleSpan = document.createElement('span');
  if (task.completed) titleSpan.classList.add('completed');
  titleSpan.textContent = task.title;

  const categoryBadge = document.createElement('small');
  categoryBadge.className = `task-category task-category-${category.toLowerCase()}`;
  categoryBadge.textContent = category;

  taskMain.appendChild(titleSpan);
  taskMain.appendChild(categoryBadge);

  const actions = document.createElement('div');

  const completeButton = document.createElement('button');
  completeButton.textContent = '✓';
  completeButton.addEventListener('click', () => toggleComplete(task.id, !task.completed));

  const editButton = document.createElement('button');
  editButton.textContent = '✎';
  editButton.addEventListener('click', () => editTask(task.id, task.title, category));

  const deleteButton = document.createElement('button');
  deleteButton.textContent = '✕';
  deleteButton.addEventListener('click', () => deleteTask(task.id));

  actions.appendChild(completeButton);
  actions.appendChild(editButton);
  actions.appendChild(deleteButton);

  li.appendChild(taskMain);
  li.appendChild(actions);
  taskList.appendChild(li);
}

taskForm.addEventListener('submit', async e => {
  e.preventDefault();
  const title = taskInput.value.trim();
  if (!title) return;

  const category = normalizeCategory(taskCategory.value);
  const res = await fetch(API_URL, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ title, category })
  });

  if (!res.ok) {
    const error = await res.json().catch(() => ({}));
    alert(error.message || 'Could not create task.');
    return;
  }

  const task = await res.json();
  addTaskToDOM(task);
  taskInput.value = '';
  taskCategory.value = DEFAULT_CATEGORY;
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

async function editTask(id, currentTitle, currentCategory) {
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

  const requestedCategory = newCategory.trim();
  if (!isValidCategory(requestedCategory)) {
    alert(`Invalid category. Use one of: ${CATEGORIES.join(', ')}.`);
    return;
  }
  const normalizedCategory = normalizeCategory(requestedCategory);

  const res = await fetch(`${API_URL}/${id}`, {
    method: 'PUT',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ title: normalizedTitle, category: normalizedCategory })
  });

  if (!res.ok) {
    const error = await res.json().catch(() => ({}));
    alert(error.message || 'Could not update task.');
    return;
  }

  fetchTasks();
}

fetchTasks();
