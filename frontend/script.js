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
  li.setAttribute('data-id', task.id);
  li.innerHTML = `
    <span class="${task.completed ? 'completed' : ''}">${task.title}</span>
    <div>
      <button onclick="editTask('${task.id}', this)" title="Edit task title">✎</button>
      <button onclick="toggleComplete('${task.id}', ${!task.completed})">✓</button>
      <button onclick="deleteTask('${task.id}')">✕</button>
    </div>
  `;
  taskList.appendChild(li);
}

function editTask(id, btn) {
  const li = document.querySelector(`li[data-id="${id}"]`);
  const span = li.querySelector('span');
  const currentTitle = span.textContent;

  const input = document.createElement('input');
  input.type = 'text';
  input.value = currentTitle;
  input.className = 'edit-input';

  span.replaceWith(input);
  input.focus();
  input.select();

  btn.textContent = '💾';
  btn.setAttribute('onclick', `saveTask('${id}', this)`);

  input.addEventListener('keydown', e => {
    if (e.key === 'Enter') saveTask(id, btn);
    if (e.key === 'Escape') fetchTasks();
  });
}

async function saveTask(id, btn) {
  const li = document.querySelector(`li[data-id="${id}"]`);
  const input = li.querySelector('input.edit-input');
  const newTitle = input.value.trim();

  if (!newTitle) {
    input.classList.add('edit-input--error');
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
    input.classList.add('edit-input--error');
    input.title = 'Could not save changes. Please try again.';
    input.focus();
  }
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
