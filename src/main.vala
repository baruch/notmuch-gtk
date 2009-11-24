public static int main(string[] args)
{
	Gtk.init(ref args);

	var threads = new NotMuch.Threads.Controller();

	threads.begin();
	Gtk.main();
	return 0;
}
