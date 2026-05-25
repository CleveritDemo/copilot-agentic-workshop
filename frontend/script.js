const API_URL = 'http://localhost:3000/api/tasks';
const taskList = document.getElementById('taskList');
const taskForm = document.getElementById('taskForm');
const taskInput = document.getElementById('taskInput');
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
  li.dataset.id = task.id;

  const taskInfo = document.createElement('div');
  taskInfo.className = 'task-info';

  const titleSpan = document.createElement('span');
  titleSpan.className = task.completed ? 'completed' : '';
  titleSpan.textContent = task.title;
  taskInfo.appendChild(titleSpan);

  if (task.category) {
    const categorySpan = document.createElement('span');
    categorySpan.className = 'task-category';
    categorySpan.textContent = task.category;
    taskInfo.appendChild(categorySpan);
  }

  const actions = document.createElement('div');

  const editBtn = document.createElement('button');
  editBtn.title = 'Edit task';
  editBtn.textContent = '✏️';
  editBtn.addEventListener('click', () => startEditTask(task.id, task.title, task.category || ''));

  const toggleBtn = document.createElement('button');
  toggleBtn.title = 'Toggle complete';
  toggleBtn.textContent = '✓';
  toggleBtn.addEventListener('click', () => toggleComplete(task.id, !task.completed));

  const deleteBtn = document.createElement('button');
  deleteBtn.title = 'Delete task';
  deleteBtn.textContent = '✕';
  deleteBtn.addEventListener('click', () => deleteTask(task.id));

  actions.appendChild(editBtn);
  actions.appendChild(toggleBtn);
  actions.appendChild(deleteBtn);

  li.appendChild(taskInfo);
  li.appendChild(actions);
  taskList.appendChild(li);
}

taskForm.addEventListener('submit', async e => {
  e.preventDefault();
  const title = taskInput.value.trim();
  const category = document.getElementById('categoryInput').value.trim();
  const res = await fetch(API_URL, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ title, category })
  });
  const task = await res.json();
  addTaskToDOM(task);
  taskInput.value = '';
  document.getElementById('categoryInput').value = '';
});

async function toggleComplete(id, completed) {
  await fetch(`${API_URL}/${id}`, {
    method: 'PUT',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ completed })
  });
  fetchTasks();
}

function startEditTask(id, currentTitle, currentCategory) {
  const li = taskList.querySelector(`li[data-id="${id}"]`);
  if (!li) return;

  li.innerHTML = '';

  const editForm = document.createElement('div');
  editForm.className = 'task-edit-form';

  const titleInput = document.createElement('input');
  titleInput.className = 'edit-title-input';
  titleInput.type = 'text';
  titleInput.value = currentTitle;
  titleInput.placeholder = 'Task title';
  titleInput.required = true;

  const categoryInput = document.createElement('input');
  categoryInput.className = 'edit-category-input';
  categoryInput.type = 'text';
  categoryInput.value = currentCategory;
  categoryInput.placeholder = 'Category (optional)';

  editForm.appendChild(titleInput);
  editForm.appendChild(categoryInput);

  const actions = document.createElement('div');

  const saveBtn = document.createElement('button');
  saveBtn.title = 'Save changes';
  saveBtn.textContent = '💾';
  saveBtn.addEventListener('click', () => saveEditTask(id));

  const cancelBtn = document.createElement('button');
  cancelBtn.title = 'Cancel edit';
  cancelBtn.textContent = '✕';
  cancelBtn.addEventListener('click', () => fetchTasks());

  actions.appendChild(saveBtn);
  actions.appendChild(cancelBtn);

  li.appendChild(editForm);
  li.appendChild(actions);
  titleInput.focus();
}

async function saveEditTask(id) {
  const li = taskList.querySelector(`li[data-id="${id}"]`);
  if (!li) return;
  const title = li.querySelector('.edit-title-input').value.trim();
  const category = li.querySelector('.edit-category-input').value.trim();
  if (!title) return;
  await fetch(`${API_URL}/${id}`, {
    method: 'PUT',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ title, category })
  });
  fetchTasks();
}

async function deleteTask(id) {
  await fetch(`${API_URL}/${id}`, { method: 'DELETE' });
  fetchTasks();
}

fetchTasks();
