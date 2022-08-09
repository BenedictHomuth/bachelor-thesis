package api

import (
	"encoding/json"
	"io/ioutil"
	"net/http"
	"strconv"
	"todo-app/db"

	"github.com/labstack/echo"
	"github.com/labstack/echo/middleware"
)

type Repository interface {
	Create(todo db.Todos) (int64, error)
	Update(todo db.Todos) (int64, error)
	Get(todoID string) (db.Todos, error)
	GetAll() ([]db.Todos, error)
	Delete(todoID string) (int64, error)
}

type Controller struct {
	repo Repository
}

type apiError struct {
	Error   string `json:"error"`
	Message string `json:"message"`
}

func (c Controller) createTodo(ctx echo.Context) error {
	todo := &db.Todos{}
	defer ctx.Request().Body.Close()
	b, err := ioutil.ReadAll(ctx.Request().Body)
	if err != nil {
		return ctx.JSON(http.StatusBadRequest, apiError{
			Error:   err.Error(),
			Message: "Your todo could not be created! Please try again later.",
		})
	}
	err = json.Unmarshal(b, &todo)
	if err != nil {
		return ctx.JSON(http.StatusInternalServerError, apiError{
			Error:   err.Error(),
			Message: "Something went wrong while creating your todo! Please try again.",
		})
	}
	statusCode, err := c.repo.Create(*todo)
	if err != nil {
		return ctx.JSON(http.StatusInternalServerError, apiError{
			Error:   err.Error(),
			Message: "Your todo was not saved to the database. Please try again.",
		})
	}

	return ctx.JSON(http.StatusOK, map[string]string{
		"message":    "Your todo was successfully created!",
		"statusCode": strconv.FormatInt(statusCode, 10),
	})
}

func (c Controller) getTodos(ctx echo.Context) error {
	todos, err := c.repo.GetAll()
	if err != nil {
		return ctx.JSON(http.StatusInternalServerError, apiError{
			Error:   err.Error(),
			Message: "There was an error retrieving your todos. Please try again later",
		})
	}

	return ctx.JSON(http.StatusOK, todos)
}

func (c Controller) getTodo(ctx echo.Context) error {
	qID := ctx.Param("uid")
	result, err := c.repo.Get(qID)
	if err != nil {
		return ctx.JSON(http.StatusInternalServerError, apiError{
			Error:   err.Error(),
			Message: "Your todo could not be retrieved! Please try again later.",
		})
	}

	return ctx.JSON(http.StatusOK, result)
}

func (c Controller) updateTodo(ctx echo.Context) error {
	qid := ctx.Param("uid")
	todo := &db.Todos{}
	defer ctx.Request().Body.Close()
	b, err := ioutil.ReadAll(ctx.Request().Body)
	if err != nil {
		return ctx.JSON(http.StatusBadRequest, apiError{
			Error:   err.Error(),
			Message: "Your query was insufficient! Please try again.",
		})
	}
	err = json.Unmarshal(b, &todo)
	if err != nil {
		return ctx.JSON(http.StatusInternalServerError, apiError{
			Error:   err.Error(),
			Message: "Something went wrong while updating your todo! Please try again.",
		})
	}
	todo.Uid = qid
	statusCode, err := c.repo.Update(*todo)
	if err != nil {
		return ctx.JSON(http.StatusInternalServerError, apiError{
			Error:   err.Error(),
			Message: "Your todo was not updated to the database. Please try again.",
		})
	}

	return ctx.JSON(http.StatusOK, map[string]string{
		"message":    "Your todo was successfully updated!",
		"statusCode": strconv.FormatInt(statusCode, 10),
	})

}

func (c Controller) deleteTodo(ctx echo.Context) error {
	qID := ctx.Param("uid")
	result, err := c.repo.Delete(qID)
	if err != nil {
		return ctx.JSON(http.StatusBadRequest, apiError{
			Error:   err.Error(),
			Message: "Your todo could not be deleted! Please try again later.",
		})
	}

	return ctx.JSON(http.StatusOK, map[string]string{
		"deletedRecord": strconv.FormatInt(result, 10),
	})
}

func healthCheck(c echo.Context) error {
	return c.JSON(http.StatusOK, "Backend is reachable")
}

func CreateAPI(c Controller) *echo.Echo {

	//// ECHO SETUP ////
	e := echo.New()
	e.Use(middleware.Logger())

	//// HEALTH ////
	e.GET("/health", healthCheck)

	//// GROUPS ////
	gt := e.Group("/todos")

	//// TODO ROUTES ////
	gt.POST("/create", c.createTodo)
	gt.GET("/get", c.getTodos)
	gt.GET("/get/:uid", c.getTodo)
	gt.PUT("/update/:uid", c.updateTodo)
	gt.DELETE("/delete/:uid", c.deleteTodo)

	return e
}
