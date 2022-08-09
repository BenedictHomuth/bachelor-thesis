package db

import (
	"errors"
	"testing"

	"github.com/DATA-DOG/go-sqlmock"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"

	"todo-app/model"
)

const (
	testUUID = "ec2876f9-9d56-4cd9-adfd-563f5db74705"
)

func TestRepository_Create(t *testing.T) {
	type args struct {
		todo model.Todo
	}
	tests := []struct {
		name      string
		setupMock func(mock sqlmock.Sqlmock)
		args      args
		want      model.ID
		wantErr   bool
	}{
		{
			name: "database fails to insert element",
			args: args{todo: model.Todo{
				Title:       "Foo",
				Description: "bar",
				Created_at:  "",
				Updated_at:  "",
			}},
			setupMock: func(mock sqlmock.Sqlmock) {
				mock.
					ExpectQuery("INSERT INTO todos (title, description) VALUES ($1,$2) RETURNING uid").
					WithArgs("Foo", "bar").
					WillReturnError(errors.New("foo"))
			},
			want:    "",
			wantErr: true,
		},
		{
			name: "database insert element",
			args: args{todo: model.Todo{
				Title:       "Foo",
				Description: "bar",
				Created_at:  "",
				Updated_at:  "",
			}},
			setupMock: func(mock sqlmock.Sqlmock) {
				mock.
					ExpectPrepare("INSERT INTO todos (title, description) VALUES ($1,$2) RETURNING uid").
					ExpectQuery().WithArgs("Foo", "bar").
					WillReturnError(nil).WillReturnRows(sqlmock.NewRows([]string{testUUID}))
			},
			want:    testUUID,
			wantErr: false,
		},
	}
	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			db, mock, err := sqlmock.New()
			require.Nil(t, err)
			defer db.Close()

			tt.setupMock(mock)

			r := Repository{
				con: db,
			}
			got, err := r.Create(tt.args.todo)
			if (err != nil) != tt.wantErr {
				t.Errorf("Create() error = %v, wantErr %v", err, tt.wantErr)
				return
			}
			if got != tt.want {
				t.Errorf("Create() got = %v, want %v", got, tt.want)
			}

			assert.Nil(t, mock.ExpectationsWereMet(), "sqlmock expectation are not met")
		})
	}
}
