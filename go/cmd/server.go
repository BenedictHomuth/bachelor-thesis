package main

import (
	"fmt"
	"todo-app/api"
	"todo-app/db"
)

const (
	host     = "10.43.91.88"
	port     = "5432"
	user     = "dbUser"
	password = "helloWorld!"
	dbname   = "todo-db"
)

func main() {
	psqlInfo := fmt.Sprintf("host=%s port=%s user=%s password=%s dbname=%s sslmode=disable", host, port, user, password, dbname)
	dbClient, _ := db.CreateConnection(psqlInfo)
	srv := api.CreateAPI(dbClient)
	srv.Start(":8080")
}
