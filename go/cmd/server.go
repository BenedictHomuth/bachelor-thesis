package main

import (
	"fmt"
	"os"

	"todo-app/api"
	"todo-app/db"
)

func getEnv(key, fallback string) string {
	value, exists := os.LookupEnv(key)
	if !exists {
		value = fallback
	}
	return value
}

func main() {
	host := getEnv("DB_HOST", "postgres")
	port := getEnv("DB_PORT", "5432")
	dbname := getEnv("DB_NAME", "todo-db")
	user := getEnv("DB_USER", "dbUser")
	password := getEnv("DB_PW", "helloWorld!")

	psqlInfo := fmt.Sprintf("host=%s port=%s user=%s password=%s dbname=%s sslmode=disable", host, port, user, password, dbname)
	dbClient, _ := db.CreatePostgreSQLConnection(psqlInfo)
	svc := api.NewService(db.NewRepository(dbClient))
	srv := api.CreateAPI(svc)
	srv.Start(":8080")
}
