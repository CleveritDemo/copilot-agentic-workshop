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

function buildTaskItem(id, title, completed) {
  const li = document.createElement('li');
  li.dataset.id = id;

  const span = document.createElement('span');
  span.textContent = title;
  if (completed) span.classList.add('completed');

  const editBtn = document.createElement('button');
  editBtn.textContent = '✎';
  editBtn.title = 'Edit task title';
  editBtn.addEventListener('click', () => startEditTask(id));

  const toggleBtn = document.createElement('button');
  toggleBtn.textContent = '✓';
  toggleBtn.addEventListener('click', () => toggleComplete(id, !completed));

  const deleteBtn = document.createElement('button');
  deleteBtn.textContent = '✕';
  deleteBtn.addEventListener('click', () => deleteTask(id));

  const div = document.createElement('div');
  div.append(editBtn, toggleBtn, deleteBtn);

  li.append(span, div);
  return li;
}

function addTaskToDOM(task) {
  taskList.appendChild(buildTaskItem(task.id, task.title, task.completed));
}

function startEditTask(id) {
  const li = taskList.querySelector(`li[data-id="${id}"]`);
  if (!li) return;
  const span = li.querySelector('span');
  const currentTitle = span.textContent;
  const isCompleted = span.classList.contains('completed');

  const input = document.createElement('input');
  input.type = 'text';
  input.className = 'edit-input';
  input.value = currentTitle;
  input.setAttribute('aria-label', 'Edit task title');

  const saveBtn = document.createElement('button');
  saveBtn.textContent = '💾';
  saveBtn.title = 'Save changes';
  saveBtn.addEventListener('click', () => saveEditTask(id, isCompleted));

  const cancelBtn = document.createElement('button');
  cancelBtn.textContent = '✕';
  cancelBtn.title = 'Cancel editing';
  cancelBtn.addEventListener('click', () => cancelEditTask(id, currentTitle, isCompleted));

  const div = document.createElement('div');
  div.append(saveBtn, cancelBtn);

  li.innerHTML = '';
  li.append(input, div);

  input.focus();
  input.select();
  input.addEventListener('keydown', e => {
    if (e.key === 'Enter') saveEditTask(id, isCompleted);
    if (e.key === 'Escape') cancelEditTask(id, currentTitle, isCompleted);
  });
}

async function saveEditTask(id, isCompleted) {
  const li = taskList.querySelector(`li[data-id="${id}"]`);
  if (!li) return;
  const input = li.querySelector('.edit-input');
  const newTitle = input.value.trim();

  if (!newTitle) {
    input.classList.add('edit-input--error');
    input.setAttribute('aria-invalid', 'true');
    input.placeholder = 'Title cannot be empty';
    input.focus();
    return;
  }

  try {
    const res = await fetch(`${API_URL}/${id}`, {
      method: 'PUT',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ title: newTitle })
    });
    if (!res.ok) throw new Error('Failed to update task');
    fetchTasks();
  } catch (err) {
    console.error('Error saving task:', err);
    input.classList.add('edit-input--error');
    input.setAttribute('aria-invalid', 'true');
    input.placeholder = 'Failed to save. Try again.';
    input.value = '';
    input.focus();
  }
}

function cancelEditTask(id, originalTitle, isCompleted) {
  const li = taskList.querySelector(`li[data-id="${id}"]`);
  if (!li) return;
  li.replaceWith(buildTaskItem(id, originalTitle, isCompleted));
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
  addTaskToDOM(task);
  taskInput.value = '';
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
