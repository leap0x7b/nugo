package nugoruntime

import _ "unsafe"

var (
	mallocInitFn    = mallocInit
	algInitFn       = algInit
	modulesInitFn   = modulesInit
	typeLinksInitFn = typeLinksInit
	itabsInitFn     = itabsInit
	procResizeFn    = procResize

	// A seed for the pseudo-random number generator used by getRandomData
	prngSeed uint32 = 0xdeadc0de
)

//go:redirect-from runtime.init
//go:noinline
func runtimeInit() {}

//go:redirect-from runtime.nanotime
//go:nosplit
func nanotime() uint64 {
	// Use a dummy loop to prevent the compiler from inlining this function.
	for i := 0; i < 100; i++ {
	}
	return 1
}

//go:redirect-from runtime.getRandomData
func getRandomData(r []byte) {
	for i := 0; i < len(r); i++ {
		prngSeed = (prngSeed * 58321) + 11113
		r[i] = byte((prngSeed >> 16) & 255)
	}
}

//go:linkname algInit runtime.alginit
func algInit()

//go:linkname modulesInit runtime.modulesinit
func modulesInit()

//go:linkname typeLinksInit runtime.typelinksinit
func typeLinksInit()

//go:linkname itabsInit runtime.itabsinit
func itabsInit()

//go:linkname mallocInit runtime.mallocinit
func mallocInit()

//go:linkname mSysStatInc runtime.mSysStatInc
func mSysStatInc(*uint64, uintptr)

//go:linkname procResize runtime.procresize
func procResize(int32) uintptr

func Init() {
	algInitFn()
	modulesInitFn()
	typeLinksInitFn()
	itabsInitFn()
}

func dummy() {
	// Dummy calls so the compiler does not optimize away the functions in
	// this file.
	var (
		stat uint64
	)
	_ = stat

	runtimeInit()
	getRandomData(nil)
	stat = nanotime()
}
