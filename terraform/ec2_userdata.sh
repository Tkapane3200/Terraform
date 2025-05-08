#!/bin/bash
# Update system packages
yum update -y

# Install required software
amazon-linux-extras install epel -y
yum install -y git python3 python3-pip nginx

# Install Python dependencies
pip3 install --upgrade pip
pip3 install flask flask-sqlalchemy flask-cors pymysql python-dotenv gunicorn

# Create app directory
mkdir -p /var/www/todo-app

# Clone or copy application files (in a real scenario, you would pull from a repository)
cat > /var/www/todo-app/config.py << 'EOL'
import os
from dotenv import load_dotenv

load_dotenv()

class Config:
    SECRET_KEY = os.environ.get('SECRET_KEY') or 'dev-key-for-development'
    SQLALCHEMY_TRACK_MODIFICATIONS = False
    
class DevelopmentConfig(Config):
    DEBUG = True
    SQLALCHEMY_DATABASE_URI = 'mysql+pymysql://root:password@localhost/todo_app'

class ProductionConfig(Config):
    DEBUG = False
    # Using the passed RDS endpoint from Terraform
    SQLALCHEMY_DATABASE_URI = 'mysql+pymysql://${db_username}:${db_password}@${db_host}/${db_name}'

config = {
    'development': DevelopmentConfig,
    'production': ProductionConfig,
    'default': ProductionConfig
}
EOL

cat > /var/www/todo-app/models.py << 'EOL'
from flask_sqlalchemy import SQLAlchemy
from datetime import datetime

db = SQLAlchemy()

class Todo(db.Model):
    __tablename__ = 'todos'

    id = db.Column(db.Integer, primary_key=True)
    title = db.Column(db.String(255), nullable=False)
    completed = db.Column(db.Boolean, default=False)
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    updated_at = db.Column(db.DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

    def to_dict(self):
        return {
            'id': self.id,
            'title': self.title,
            'completed': self.completed,
            'created_at': self.created_at.isoformat(),
            'updated_at': self.updated_at.isoformat()
        }
EOL

cat > /var/www/todo-app/app.py << 'EOL'
import os
from flask import Flask, jsonify, request, send_from_directory
from flask_cors import CORS
from models import db, Todo
from config import config

def create_app(config_name='default'):
    app = Flask(__name__, static_folder='static')
    app.config.from_object(config[config_name])
    
    # Initialize extensions
    db.init_app(app)
    CORS(app)
    
    # Create database tables
    with app.app_context():
        db.create_all()
    
    # API Routes
    @app.route('/api/todos', methods=['GET'])
    def get_todos():
        todos = Todo.query.order_by(Todo.created_at.desc()).all()
        return jsonify([todo.to_dict() for todo in todos])
    
    @app.route('/api/todos', methods=['POST'])
    def create_todo():
        data = request.get_json()
        
        if not data or not data.get('title'):
            return jsonify({'error': 'Title is required'}), 400
        
        new_todo = Todo(
            title=data.get('title'),
            completed=data.get('completed', False)
        )
        
        db.session.add(new_todo)
        db.session.commit()
        
        return jsonify(new_todo.to_dict()), 201
    
    @app.route('/api/todos/<int:todo_id>', methods=['GET'])
    def get_todo(todo_id):
        todo = Todo.query.get_or_404(todo_id)
        return jsonify(todo.to_dict())
    
    @app.route('/api/todos/<int:todo_id>', methods=['PUT'])
    def update_todo(todo_id):
        todo = Todo.query.get_or_404(todo_id)
        data = request.get_json()
        
        if 'title' in data:
            todo.title = data['title']
        
        if 'completed' in data:
            todo.completed = data['completed']
        
        db.session.commit()
        
        return jsonify(todo.to_dict())
    
    @app.route('/api/todos/<int:todo_id>', methods=['DELETE'])
    def delete_todo(todo_id):
        todo = Todo.query.get_or_404(todo_id)
        
        db.session.delete(todo)
        db.session.commit()
        
        return jsonify({'message': 'Todo deleted successfully'})
    
    # Serve the frontend
    @app.route('/', defaults={'path': ''})
    @app.route('/<path:path>')
    def serve_frontend(path):
        if path and os.path.exists(os.path.join(app.static_folder, path)):
            return send_from_directory(app.static_folder, path)
        return send_from_directory(app.static_folder, 'index.html')
    
    return app

if __name__ == '__main__':
    app = create_app(os.getenv('FLASK_ENV', 'production'))
    app.run(host='0.0.0.0', port=int(os.getenv('PORT', 5000)))
EOL

# Create static directory and add frontend files
mkdir -p /var/www/todo-app/static
cat > /var/www/todo-app/static/index.html << 'EOL'
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Todo App</title>
    <link rel="stylesheet" href="styles.css">
</head>
<body>
    <div class="container">
        <h1>Todo Application</h1>
        <div class="todo-form">
            <input type="text" id="todo-input" placeholder="Add a new task...">
            <button id="add-btn">Add Task</button>
        </div>
        <div class="filters">
            <button class="filter-btn active" data-filter="all">All</button>
            <button class="filter-btn" data-filter="active">Active</button>
            <button class="filter-btn" data-filter="completed">Completed</button>
        </div>
        <ul id="todo-list"></ul>
    </div>
    <script src="script.js"></script>
</body>
</html>
EOL

cat > /var/www/todo-app/static/styles.css << 'EOL'
* {
    margin: 0;
    padding: 0;
    box-sizing: border-box;
    font-family: 'Arial', sans-serif;
}

body {
    background-color: #f5f5f5;
    display: flex;
    justify-content: center;
    padding-top: 50px;
}

.container {
    width: 100%;
    max-width: 600px;
    background-color: white;
    border-radius: 8px;
    box-shadow: 0 2px 10px rgba(0, 0, 0, 0.1);
    padding: 20px;
}

h1 {
    color: #333;
    text-align: center;
    margin-bottom: 20px;
}

.todo-form {
    display: flex;
    margin-bottom: 20px;
}

#todo-input {
    flex-grow: 1;
    padding: 10px;
    border: 1px solid #ddd;
    border-radius: 4px 0 0 4px;
    font-size: 16px;
}

#add-btn {
    padding: 10px 15px;
    background-color: #4caf50;
    color: white;
    border: none;
    border-radius: 0 4px 4px 0;
    cursor: pointer;
    font-size: 16px;
}

#add-btn:hover {
    background-color: #45a049;
}

.filters {
    display: flex;
    justify-content: center;
    margin-bottom: 15px;
}

.filter-btn {
    margin: 0 5px;
    padding: 8px 12px;
    background-color: #f1f1f1;
    border: none;
    border-radius: 4px;
    cursor: pointer;
    font-size: 14px;
}

.filter-btn.active {
    background-color: #2196F3;
    color: white;
}

#todo-list {
    list-style-type: none;
}

.todo-item {
    display: flex;
    align-items: center;
    padding: 10px;
    border-bottom: 1px solid #eee;
}

.todo-item:last-child {
    border-bottom: none;
}

.todo-check {
    margin-right: 10px;
    width: 18px;
    height: 18px;
}

.todo-text {
    flex-grow: 1;
    font-size: 16px;
}

.todo-text.completed {
    text-decoration: line-through;
    color: #888;
}

.todo-delete {
    background-color: #f44336;
    color: white;
    border: none;
    border-radius: 4px;
    padding: 5px 10px;
    cursor: pointer;
}

.todo-delete:hover {
    background-color: #d32f2f;
}
EOL

cat > /var/www/todo-app/static/script.js << 'EOL'
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
            const response = await fetch(API_URL + '/' + id, {
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
            const response = await fetch(API_URL + '/' + id, {
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
EOL

# Setup Nginx
cat > /etc/nginx/conf.d/todo-app.conf << 'EOL'
server {
    listen 80;
    server_name _;

    location / {
        proxy_pass http://127.0.0.1:5000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
}
EOL

# Remove default Nginx configuration
rm -f /etc/nginx/conf.d/default.conf

# Create systemd service for Flask app
cat > /etc/systemd/system/todo-app.service << 'EOL'
[Unit]
Description=Todo App Flask Service
After=network.target

[Service]
User=root
WorkingDirectory=/var/www/todo-app
Environment=FLASK_ENV=production
ExecStart=/usr/local/bin/gunicorn --workers 3 --bind 127.0.0.1:5000 "app:create_app()"
Restart=always

[Install]
WantedBy=multi-user.target
EOL

# Start and enable services
systemctl daemon-reload
systemctl enable nginx
systemctl enable todo-app
systemctl start nginx
systemctl start todo-app

echo "Todo App setup completed successfully"

