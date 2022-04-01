package api

import (
	"database/sql"
	"encoding/json"
	"fmt"
	"io/ioutil"
	"net/http"
	"strconv"
	"todo-app/db"

	"github.com/labstack/echo"
	"github.com/labstack/echo/middleware"
)

var dbCon *sql.DB

func createTodo(c echo.Context) error {
	todo := &db.Todos{}
	defer c.Request().Body.Close()
	b, err := ioutil.ReadAll(c.Request().Body)
	if err != nil {
		return c.JSON(http.StatusBadRequest, map[string]string{
			"err":     err.Error(),
			"message": "Your todo could not be created! Please try again later.",
		})
	}
	err = json.Unmarshal(b, &todo)
	if err != nil {
		return c.JSON(http.StatusInternalServerError, map[string]string{
			"error":   err.Error(),
			"message": "Something went wrong while creating your todo! Please try again.",
		})
	}

	fmt.Println(todo.Title, todo.Description)

	statusCode, err := db.CreateTodo(dbCon, *todo)
	if err != nil {
		return c.JSON(http.StatusInternalServerError, map[string]string{
			"error":   err.Error(),
			"message": "Your todo was not saved to the database. Please try again.",
		})
	}

	return c.JSON(http.StatusOK, map[string]string{
		"message":    "Your todo was successfully created!",
		"statusCode": strconv.FormatInt(statusCode, 10),
	})
}

func getTodos(c echo.Context) error {
	todos, err := db.GetTodos(dbCon)
	if err != nil {
		return c.JSON(http.StatusInternalServerError, map[string]string{
			"err":   err.Error(),
			"error": "There was an error retrieving your todos. Please try again later",
		})
	}

	return c.JSON(http.StatusOK, todos)
}

func getTodo(c echo.Context) error {
	qID := c.Param("uid")
	fmt.Println(qID)
	result, err := db.GetTodo(dbCon, qID)
	if err != nil {
		return c.JSON(http.StatusOK, "Your todo could not be retrieved! Please try again later.")
	}

	return c.JSON(http.StatusOK, result)
}

func deleteTodo(c echo.Context) error {
	qID := c.Param("uid")
	result, err := db.DeleteTodo(dbCon, qID)
	if err != nil {
		return c.JSON(http.StatusBadRequest, "Your todo could not be deleted! Please try again later.")
	}

	return c.JSON(http.StatusOK, map[string]string{
		"deletedRecord": strconv.FormatInt(result, 10),
	})
}

func CreateAPI(con *sql.DB) *echo.Echo {
	dbCon = con

	//// ECHO SETUP ////
	e := echo.New()
	e.Use(middleware.Logger())

	//// GROUPS ////
	gt := e.Group("/todos")

	//// TODO ROUTES ////
	gt.POST("/create", createTodo)
	gt.GET("/get", getTodos)
	gt.GET("/get/:uid", getTodo)
	gt.DELETE("/delete/:uid", deleteTodo)

	return e
}
