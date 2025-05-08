document.addEventListener('DOMContentLoaded', () => {
    const todoInput = document.getElementById('todo-input');
    const addBtn = document.getElementById('add-btn');
    const todoList = document.getElementById('todo-list');
    const filterButtons = document.querySelectorAll('.filter-btn');

    let currentFilter = 'all';

    // API Endpoints
    const API_URL = '/api/todos';

    // Load todos from the server
    fetchTodos();

    // Event listeners
    addBtn.addEventListener('click', addTodo);
    todoInput.addEventListener('keypress', (e) => {
        if (e.key === 'Enter') {
            addTodo();
        }
    });

    filterButtons.forEach(button => {
        button.addEventListener('click', () => {
            const filter = button.getAttribute('data-filter');
            setActiveFilter(filter);
            filterTodos(filter);
        });
    });

    // Functions
    async function fetchTodos() {
        try {
            const response = await fetch(API_URL);
            if (!response.ok) {
                throw new Error('Failed to fetch todos');
            }
            const todos = await response.json();
            renderTodos(todos);
        } catch (error) {
            console.error('Error fetching todos:', error);
        }
    }

    async function addTodo() {
        const text = todoInput.value.trim();
        if (!text) return;

        try {
            const response = await fetch(API_URL, {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json'
                },
                body: JSON.stringify({ title: text, completed: false })
            });

            if (!response.ok) {
                throw new Error('Failed to add todo');
            }

            const newTodo = await response.json();
            todoInput.value = '';
            fetchTodos(); // Refresh the list
        } catch (error) {
            console.error('Error adding todo:', error);
        }
    }

    async function toggleTodoStatus(id, completed) {
        try {
            const response = await fetch(`${API_URL}/${id}`, {
                method: 'PUT',
                headers: {
                    'Content-Type': 'application/json'
                },
                body: JSON.stringify({ completed: completed })
            });

            if (!response.ok) {
                throw new Error('Failed to update todo');
            }

            fetchTodos();
        } catch (error) {
            console.error('Error updating todo:', error);
        }
    }

    async function deleteTodo(id) {
        try {
            const response = await fetch(`${API_URL}/${id}`, {
                method: 'DELETE'
            });

            if (!response.ok) {
                throw new Error('Failed to delete todo');
            }

            fetchTodos();
        } catch (error) {
            console.error('Error deleting todo:', error);
        }
    }

    function renderTodos(todos) {
        todoList.innerHTML = '';

        const filteredTodos = filterTodosByStatus(todos, currentFilter);

        filteredTodos.forEach(todo => {
            const li = document.createElement('li');
            li.className = 'todo-item';

            const checkbox = document.createElement('input');
            checkbox.type = 'checkbox';
            checkbox.className = 'todo-check';
            checkbox.checked = todo.completed;
            checkbox.addEventListener('change', () => {
                toggleTodoStatus(todo.id, checkbox.checked);
            });

            const span = document.createElement('span');
            span.textContent = todo.title;
            span.className = 'todo-text' + (todo.completed ? ' completed' : '');

            const deleteBtn = document.createElement('button');
            deleteBtn.textContent = 'Delete';
            deleteBtn.className = 'todo-delete';
            deleteBtn.addEventListener('click', () => {
                deleteTodo(todo.id);
            });

            li.appendChild(checkbox);
            li.appendChild(span);
            li.appendChild(deleteBtn);
            todoList.appendChild(li);
        });
    }

    function filterTodosByStatus(todos, filter) {
        if (filter === 'all') {
            return todos;
        }
        return todos.filter(todo =>
            filter === 'active' ? !todo.completed : todo.completed
        );
    }

    function filterTodos(filter) {
        currentFilter = filter;
        fetchTodos();
    }

    function setActiveFilter(filter) {
        filterButtons.forEach(button => {
            if (button.getAttribute('data-filter') === filter) {
                button.classList.add('active');
            } else {
                button.classList.remove('active');
            }
        });
    }
});

