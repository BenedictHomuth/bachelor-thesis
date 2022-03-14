package main

import (
	"fmt"
	"runtime"
	"time"
)

func main() {
	fmt.Printf("Running on %s/%s with %d CPU cores!\n", runtime.GOOS, runtime.GOARCH, runtime.NumCPU())
	for i := 0; i < 10; i++ {
		x := 0
		start := time.Now()
		for i := 0; i < 10000000; i++ {
			x = x + 1
		}
		elapsed := time.Since(start)
		fmt.Printf("Time to calculate: %s \n", elapsed)
	}
}
