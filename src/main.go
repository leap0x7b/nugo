package main

import (
	"github.com/leapofazzam123/nugo/src/terminal"
	//"github.com/leapofazzam123/nugo/src/runtime"
)

func main() {
	//runtime.GOMAXPROCS(1)
	//nugoruntime.Init()

	terminal.Init()
	terminal.Puts("Hello, World!")
}
