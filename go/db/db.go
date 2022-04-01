package db

import (
	"database/sql"

	_ "github.com/lib/pq"
)

func CreateConnection(dsn string) (*sql.DB, error) {
	db, err := sql.Open("postgres", dsn)
	if err != nil {
		return nil, err
	}

	return db, err
}
