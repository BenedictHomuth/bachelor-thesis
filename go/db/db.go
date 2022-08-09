package db

import (
	"database/sql"

	_ "github.com/lib/pq"
)

// CreatePostgreSQLConnection creates a PostgreSQL database connection
func CreatePostgreSQLConnection(dsn string) (*sql.DB, error) {
	db, err := sql.Open("postgres", dsn)
	if err != nil {
		return nil, err
	}

	return db, err
}
