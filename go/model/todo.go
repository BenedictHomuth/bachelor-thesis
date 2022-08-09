package model

type ID string

type Todo struct {
	Uid         ID     `json:"uid"`
	Title       string `json:"title"`
	Description string `json:"description"`
	Created_at  string `json:"created_at"`
	Updated_at  string `json:"updated_at"`
}
