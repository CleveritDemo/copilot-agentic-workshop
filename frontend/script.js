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
  li.innerHTML = `
    <span class="${task.completed ? 'completed' : ''}" data-task-id="${task.id}">${task.title}</span>
    <div>
      <button onclick="editTask('${task.id}')" title="Edit task">✎</button>
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

function editTask(id) {
  const span = document.querySelector(`span[data-task-id="${id}"]`);
  if (!span) return;

  const currentTitle = span.textContent;
  const wasCompleted = span.classList.contains('completed');

  // Create input field
  const input = document.createElement('input');
  input.type = 'text';
  input.value = currentTitle;
  input.className = 'edit-input';
  input.setAttribute('data-task-id', id);

  // Create save button
  const saveBtn = document.createElement('button');
  saveBtn.textContent = '✓';
  saveBtn.className = 'save-btn';
  saveBtn.title = 'Save changes';
  saveBtn.onclick = () => saveEdit(id);

  // Create cancel button
  const cancelBtn = document.createElement('button');
  cancelBtn.textContent = '✕';
  cancelBtn.className = 'cancel-btn';
  cancelBtn.title = 'Cancel editing';
  cancelBtn.onclick = () => cancelEdit(id, currentTitle, wasCompleted);

  // Replace span with input
  span.replaceWith(input);

  // Replace action buttons with save/cancel buttons
  const buttonDiv = input.parentElement.querySelector('div');
  buttonDiv.innerHTML = '';
  buttonDiv.appendChild(saveBtn);
  buttonDiv.appendChild(cancelBtn);

  // Focus input and select text
  input.focus();
  input.select();

  // Allow Enter key to save
  input.addEventListener('keypress', (e) => {
    if (e.key === 'Enter') {
      saveEdit(id);
    }
  });

  // Allow Escape key to cancel
  input.addEventListener('keydown', (e) => {
    if (e.key === 'Escape') {
      cancelEdit(id, currentTitle, wasCompleted);
    }
  });
}

async function saveEdit(id) {
  const input = document.querySelector(`input[data-task-id="${id}"]`);
  if (!input) return;

  const newTitle = input.value.trim();

  // Validate that title is not empty
  if (!newTitle) {
    alert('El título de la tarea no puede estar vacío');
    input.focus();
    return;
  }

  try {
    await fetch(`${API_URL}/${id}`, {
      method: 'PUT',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ title: newTitle })
    });
    fetchTasks();
  } catch (error) {
    alert('Error al actualizar la tarea');
    console.error(error);
  }
}

function cancelEdit(id, originalTitle, wasCompleted) {
  fetchTasks();
}

fetchTasks();
