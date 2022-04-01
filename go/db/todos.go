package db

import (
	"database/sql"
	"fmt"
)

type Todos struct {
	Uid         string `json:"uid"`
	Title       string `json:"title"`
	Description string `json:"description"`
	Created_at  string `json:"created_at"`
	Updated_at  string `json:"updated_at"`
}

func CreateTodo(con *sql.DB, todo Todos) (int64, error) {
	result, err := con.Exec("INSERT INTO todos (title, description) VALUES ($1,$2)", todo.Title, todo.Description)

	if err != nil {
		return -1, err
	}
	fmt.Println(result)
	return 0, err
}

func GetTodos(con *sql.DB) ([]Todos, error) {
	var uid string
	var title string
	var description string
	var updated_at string
	var created_at string
	var todos []Todos

	rows, err := con.Query("SELECT * FROM todos")
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

func GetTodo(con *sql.DB, todoID string) (Todos, error) {
	var uid string
	var title string
	var description string
	var created_at string
	var updated_at string

	err := con.QueryRow("SELECT * FROM todos WHERE uid = $1", todoID).Scan(&uid, &title, &description, &created_at, &updated_at)
	fmt.Printf("Err: %s", err)
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

func DeleteTodo(con *sql.DB, todoID string) (int64, error) {
	result, err := con.Exec("DELETE FROM todos WHERE uid = $1", todoID)
	if err != nil {
		return -1, err
	}
	return result.RowsAffected()
}
