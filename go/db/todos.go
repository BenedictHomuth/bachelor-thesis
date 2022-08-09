package db

import (
	"database/sql"
)

type Todos struct {
	Uid         string `json:"uid"`
	Title       string `json:"title"`
	Description string `json:"description"`
	Created_at  string `json:"created_at"`
	Updated_at  string `json:"updated_at"`
}

type Connection interface {
	Exec(query string, args ...interface{}) (sql.Result, error)
	Query(query string, args ...interface{}) (*sql.Rows, error)
	QueryRow(query string, args ...interface{}) *sql.Row
}

func (r Repository) Create(todo Todos) (int64, error) {
	_, err := r.con.Exec("INSERT INTO todos (title, description) VALUES ($1,$2)", todo.Title, todo.Description)

	if err != nil {
		return -1, err
	}
	return 0, err
}

func (r Repository) Update(todo Todos) (int64, error) {
	_, err := r.con.Exec("UPDATE todos SET title = $1, description = $2 WHERE uid = $3", todo.Title, todo.Description, todo.Uid)
	if err != nil {
		return -1, err
	}
	return 0, err
}

func (r Repository) GetAll() ([]Todos, error) {
	var uid string
	var title string
	var description string
	var updated_at string
	var created_at string
	var todos []Todos

	rows, err := r.con.Query("SELECT * FROM todos")
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	for rows.Next() {
		rows.Scan(&uid, &title, &description, &created_at, &updated_at)
		todo := Todos{
			Uid:         uid,
			Title:       title,
			Description: description,
			Created_at:  created_at,
			Updated_at:  updated_at,
		}
		todos = append(todos, todo)
	}
	return todos, nil
}

func (r Repository) Get(todoID string) (Todos, error) {
	var uid string
	var title string
	var description string
	var created_at string
	var updated_at string

	err := r.con.QueryRow("SELECT * FROM todos WHERE uid = $1", todoID).Scan(&uid, &title, &description, &created_at, &updated_at)
	if err != nil {
		return Todos{}, err
	}
	todo := Todos{
		Uid:         uid,
		Title:       title,
		Description: description,
		Created_at:  created_at,
		Updated_at:  updated_at,
	}
	return todo, nil
}

func (r Repository) Delete(todoID string) (int64, error) {
	result, err := r.con.Exec("DELETE FROM todos WHERE uid = $1", todoID)
	if err != nil {
		return -1, err
	}
	return result.RowsAffected()
}
