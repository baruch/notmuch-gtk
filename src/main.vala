public static int main(string[] args)
{
	Gtk.init(ref args);

	var controller = new NotMuch.Controller();
	var gui = new NotMuch.View(controller);
	controller.set_view(gui);

	gui.show();
	controller.start_search("tag:inbox");

	Gtk.main();
	return 0;
}
