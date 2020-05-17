package main

import (
	"net/http"

	"github.com/labstack/echo"
)

func main() {
	e := echo.New()
	e.GET("/", helloHandler)
	e.Start(":8080")
}

func helloHandler(c echo.Context) error {
	return c.String(http.StatusOK, "Hello, GKE!")
}
