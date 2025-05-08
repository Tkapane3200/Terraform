import os
from flask import Flask, jsonify, request, send_from_directory
from flask_cors import CORS
from models import db, Todo
from config import config


def create_app(config_name='default'):
    app = Flask(__name__)
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

    # Serve the frontend in production
    @app.route('/', defaults={'path': ''})
    @app.route('/<path:path>')
    def serve_frontend(path):
        if path and os.path.exists(os.path.join(app.static_folder, path)):
            return send_from_directory(app.static_folder, path)
        return send_from_directory(app.static_folder, 'index.html')

    return app


if __name__ == '__main__':
    app = create_app(os.getenv('FLASK_ENV', 'development'))
    app.run(host='0.0.0.0', port=int(os.getenv('PORT', 5000)))
