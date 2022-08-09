package api

import (
	"encoding/json"
	"io/ioutil"
	"net/http"

	"todo-app/model"

	"github.com/labstack/echo"
	"github.com/labstack/echo/middleware"
)

// Repository stores Todos persistent
type Repository interface {
	// Create creates a todo in the repository. It can return an error in case there is an issue with the
	// underlying storage. Create returns the generated ID.
	Create(todo model.Todo) (model.ID, error)
	// Update set all fields to the given model.Todo
	Update(todo model.Todo) error
	// Get returns the model.Todo with the given ID
	Get(todoID model.ID) (model.Todo, error)
	GetAll() ([]model.Todo, error)
	Delete(todoID model.ID) error
}

type apiError struct {
	Error   string `json:"error"`
	Message string `json:"message"`
}

// Service knows how to parse the echo.Context and process the requests.
type Service struct {
	// repo stores the model.Todo We keep this private so it's clear that this is an implementation detail
	repo Repository
}

// NewService returns a new service
func NewService(repo Repository) Service {
	return Service{repo: repo}
}

func (s Service) createTodo(ctx echo.Context) error {
	todo := &model.Todo{}
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
		return ctx.JSON(http.StatusBadRequest, apiError{
			Error:   err.Error(),
			Message: "Something went wrong while creating your todo! Please try again.",
		})
	}

	id, err := s.repo.Create(*todo)
	if err != nil {
		return ctx.JSON(http.StatusInternalServerError, apiError{
			Error:   err.Error(),
			Message: "Your todo was not saved to the database. Please try again.",
		})
	}
	todo.Uid = id
	// We created the ToDo and return the created todo. This helps frontends to show the real created
	return ctx.JSON(http.StatusOK, todo)
}

func (s Service) getTodos(ctx echo.Context) error {
	todos, err := s.repo.GetAll()
	if err != nil {
		return ctx.JSON(http.StatusInternalServerError, apiError{
			Error:   err.Error(),
			Message: "There was an error retrieving your todos. Please try again later",
		})
	}

	return ctx.JSON(http.StatusOK, todos)
}

func (s Service) getTodo(ctx echo.Context) error {
	qID := ctx.Param("uid")
	result, err := s.repo.Get(model.ID(qID))
	if err != nil {
		return ctx.JSON(http.StatusInternalServerError, apiError{
			Error:   err.Error(),
			Message: "Your todo could not be retrieved! Please try again later.",
		})
	}

	return ctx.JSON(http.StatusOK, result)
}

func (s Service) updateTodo(ctx echo.Context) error {
	qid := ctx.Param("uid")
	todo := &model.Todo{}
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
	todo.Uid = model.ID(qid)

	err = s.repo.Update(*todo)
	if err != nil {
		return ctx.JSON(http.StatusInternalServerError, apiError{
			Error:   err.Error(),
			Message: "Your todo was not updated to the database. Please try again.",
		})
	}

	return ctx.JSON(http.StatusOK, todo)

}

func (s Service) deleteTodo(ctx echo.Context) error {
	qID := ctx.Param("uid")
	err := s.repo.Delete(model.ID(qID))

	if err != nil {
		return ctx.JSON(http.StatusBadRequest, apiError{
			Error:   err.Error(),
			Message: "Your todo could not be deleted! Please try again later.",
		})
	}

	// We deleted the element, so we don't return anything.
	return ctx.JSON(http.StatusCreated, nil)
}

func healthCheck(c echo.Context) error {
	return c.JSON(http.StatusOK, "Backend is reachable")
}

func CreateAPI(s Service) *echo.Echo {

	//// ECHO SETUP ////
	e := echo.New()
	e.Use(middleware.Logger())

	//// HEALTH ////
	e.GET("/health", healthCheck)

	//// GROUPS ////
	gt := e.Group("/todos")

	//// TODO ROUTES ////
	gt.POST("/create", s.createTodo)
	gt.GET("/get", s.getTodos)
	gt.GET("/get/:uid", s.getTodo)
	gt.PUT("/update/:uid", s.updateTodo)
	gt.DELETE("/delete/:uid", s.deleteTodo)

	return e
}
