extends SceneTree
func _init():
	var c = Callable(self, "async_func")
	print("Before call")
	await c.call()
	print("Async call finished!")
	quit()

func async_func():
	print("Async func run start!")
	await create_timer(0.1).timeout
	print("Async func run end!")
