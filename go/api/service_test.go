package api

import (
	"encoding/json"
	"errors"
	"fmt"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"

	"github.com/labstack/echo"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"

	"todo-app/model"
)

const (
	testUUID = "ec2876f9-9d56-4cd9-adfd-563f5db74705"
)

type mockedRepository struct {
	createFunc func(todo model.Todo) (model.ID, error)
}

func (m mockedRepository) Create(todo model.Todo) (model.ID, error) {
	return m.createFunc(todo)
}

func (m mockedRepository) Update(todo model.Todo) error {
	//TODO implement me
	panic("implement me")
}

func (m mockedRepository) Get(todoID model.ID) (model.Todo, error) {
	//TODO implement me
	panic("implement me")
}

func (m mockedRepository) GetAll() ([]model.Todo, error) {
	//TODO implement me
	panic("implement me")
}

func (m mockedRepository) Delete(todoID model.ID) error {
	//TODO implement me
	panic("implement me")
}

func TestService_createTodo(t *testing.T) {
	type fields struct {
		repo Repository
	}
	tests := []struct {
		name           string
		fields         fields
		todoString     string
		wantErr        assert.ErrorAssertionFunc
		wantResponse   interface{}
		wantStatusCode int
	}{
		{
			name: "repository has an error",
			fields: fields{
				repo: mockedRepository{
					createFunc: func(todo model.Todo) (model.ID, error) {
						return "", errors.New("repository error")
					}},
			},
			todoString:     "{}",
			wantErr:        assert.NoError,
			wantResponse:   apiError{Error: "repository error", Message: "Your todo was not saved to the database. Please try again."},
			wantStatusCode: http.StatusInternalServerError,
		},
		{
			name: "JSON is invalid",
			fields: fields{
				repo: mockedRepository{
					createFunc: func(todo model.Todo) (model.ID, error) {
						panic("this should never be called if the JSON is invalid")
					}},
			},
			todoString:     "{",
			wantErr:        assert.NoError,
			wantResponse:   apiError{Error: "unexpected end of JSON input", Message: "Something went wrong while creating your todo! Please try again."},
			wantStatusCode: http.StatusBadRequest,
		},
		{
			name: "todo is stored",
			fields: fields{
				repo: mockedRepository{
					createFunc: func(todo model.Todo) (model.ID, error) {
						return testUUID, nil
					}},
			},
			todoString:     "{}",
			wantErr:        assert.NoError,
			wantResponse:   model.Todo{Uid: testUUID},
			wantStatusCode: http.StatusOK,
		},
	}
	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			e := echo.New()
			req := httptest.NewRequest(http.MethodGet, "/", strings.NewReader(tt.todoString))
			req.Header.Set(echo.HeaderContentType, echo.MIMEApplicationJSON)
			rec := httptest.NewRecorder()

			s := Service{
				repo: tt.fields.repo,
			}

			err := s.createTodo(e.NewContext(req, rec))

			// Assertions
			if tt.wantErr(t, err, fmt.Sprintf("createTodo(%v)", tt.todoString)) {
				assert.Equal(t, tt.wantStatusCode, rec.Code)
				wantData, err := json.Marshal(tt.wantResponse)
				// In contrast to assert, require will stop the test immediatly. One, should only use require if we want to
				// assert that some test precondition is met. Normally, we want to see all assertions which fails so we can fix as many
				// bugs as possible.
				require.Nil(t, err)
				assert.JSONEq(t, string(wantData), rec.Body.String())
			}

		})
	}
}
