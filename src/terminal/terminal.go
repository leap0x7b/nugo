package terminal

import (
	"fmt"
	"github.com/leapofazzam123/nugo/src/io"
	"unsafe"
)

const (
	Black        = 0
	Blue         = 1
	Green        = 2
	Cyan         = 3
	Red          = 4
	Magenta      = 5
	Brown        = 6
	LightGrey    = 7
	DarkGrey     = 8
	LightBlue    = 9
	LightGreen   = 10
	LightCyan    = 11
	LightRed     = 12
	LightMagenta = 13
	LightBrown   = 14
	White        = 15
)

var Column, Row int
var Color byte
var Vram *[25][80][2]byte

func Init() {
	Vram = (*[25][80][2]byte)(unsafe.Pointer(uintptr(0xB8000)))
	Color = VgaColorEntry(LightGrey, Black)
	Column = 0
	Row = 0
}

func VgaColorEntry(fg, bg byte) byte {
	return fg | bg<<4
}

func EnableCursor(start, end byte) {
	io.Outb(0x3D4, 0x0A)
	io.Outb(0x3D5, (io.Inb(0x3D5)&0xC0)|start)

	io.Outb(0x3D4, 0x0B)
	io.Outb(0x3D5, (io.Inb(0x3D5)&0xE0)|end)
}

func DisableCursor() {
	io.Outb(0x3D4, 0x0A)
	io.Outb(0x3D5, 0x20)
}

func SetCursorPosition(x, y int) {
	var pos uint16 = uint16(y*80) + uint16(x)

	io.Outb(0x3D4, 0x0F)
	io.Outb(0x3D5, uint8(pos&0xFF))
	io.Outb(0x3D4, 0x0E)
	io.Outb(0x3D5, uint8((pos>>8)&0xFF))
}

func GetCursorPosition() uint16 {
	var pos uint16

	io.Outb(0x3D4, 0x0F)
	pos |= uint16(io.Inb(0x3D5))

	io.Outb(0x3D4, 0x0E)
	pos |= uint16(io.Inb(0x3D5) << 8)

	return pos
}

func ScrollUp() {
	var x, y int

	for y = 0; y < 24; y++ {
		for x = 0; x < 80; x++ {
			Vram[y][x] = Vram[y+1][x]
		}
	}

	for x = 0; x < 80; x++ {
		Vram[y][x][0] = 32
		Vram[y][x][1] = Color
	}

	Column = 0
	Row = 24
}

func Clear() {
	for r := 0; r < 25; r++ {
		for c := 0; c < 80; c++ {
			Vram[r][c][0] = 32
			Vram[r][c][1] = Color
		}
	}
	SetCursorPosition(Column, Row)
}

func PutChar(c rune) {
	if c == '\n' {
		Column = 0
		Row++
		if Row > 24 {
			ScrollUp()
		}
	} else {
		Vram[Row][Column][0] = byte(c)
		Vram[Row][Column][1] = Color
		Column++
		if Column > 79 {
			Column = 0
			Row++
			if Row > 24 {
				ScrollUp()
			}
		}
	}
	SetCursorPosition(Column, Row)
}

func Puts(s string) {
	for c := 0; c < len(s); c++ {
		PutChar(rune(s[c]))
	}
}

func Print(a ...interface{}) {
	Puts(fmt.Sprint(a))
}

func Println(a ...interface{}) {
	Puts(fmt.Sprintln(a))
}
