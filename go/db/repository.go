package db

import (
	"database/sql"
	"fmt"

	"todo-app/model"
)

// Connection knows how to execute SQL queries on a given database
type Connection interface {
	Exec(query string, args ...interface{}) (sql.Result, error)
	QueryRow(query string, args ...interface{}) *sql.Row
	Query(query string, args ...interface{}) (*sql.Rows, error)
}

// Repository stores model.Todo and offers ways to fetch, update and delete model.Todo
type Repository struct {
	con Connection
}

// NewRepository creates a new Database repository based on the given DatabaseConnection
func NewRepository(con Connection) *Repository {
	return &Repository{con: con}
}

// Create creates the Todo in the storage
func (r Repository) Create(todo model.Todo) (model.ID, error) {
	row := r.con.QueryRow("INSERT INTO todos (title, description) VALUES ($1,$2) RETURNING uid", todo.Title, todo.Description)
	var id model.ID
	err := row.Scan(&id)
	if err != nil {
		return "", fmt.Errorf("failed to insert todo into database: %w", err)
	}
	return id, err
}

func (r Repository) Update(todo model.Todo) error {
	_, err := r.con.Exec("UPDATE todos SET title = $1, description = $2 WHERE uid = $3", todo.Title, todo.Description, todo.Uid)
	if err != nil {
		return err
	}
	return err
}

func (r Repository) GetAll() ([]model.Todo, error) {
	var todos []model.Todo

	rows, err := r.con.Query("SELECT * FROM todos")
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	for rows.Next() {
		todo := model.Todo{}
		err = rows.Scan(&todo.Uid, &todo.Title, &todo.Description, &todo.Created_at, &todo.Updated_at)
		if err != nil {
			return todos, fmt.Errorf("failed to scan line: %w", err)
		}
		todos = append(todos, todo)
	}
	return todos, nil
}

func (r Repository) Get(todoID model.ID) (model.Todo, error) {
	var todo model.Todo
	err := r.con.QueryRow("SELECT * FROM todos WHERE uid = $1", todoID).Scan(&todo.Uid, &todo.Title, &todo.Description, &todo.Created_at, &todo.Updated_at)
	if err != nil {
		return model.Todo{}, err
	}

	return todo, nil
}

func (r Repository) Delete(todoID model.ID) error {
	result, err := r.con.Exec("DELETE FROM todos WHERE uid = $1", todoID)
	if err != nil {
		return err
	}
	_, err = result.RowsAffected()
	return err
}
