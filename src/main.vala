public static int main(string[] args)
{
	Gtk.init(ref args);

	var controller = new NotMuch.Threads.Controller();
	var gui = new NotMuch.Threads.View(controller);
	controller.set_view(gui);

	gui.show();
	controller.start_search("tag:inbox");

	Gtk.main();
	return 0;
}
