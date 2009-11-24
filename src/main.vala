namespace Global {
	public Gtk.Builder builder;
}

public static int main(string[] args)
{
	Gtk.init(ref args);

	Global.builder = new Gtk.Builder();
	try {
		Global.builder.add_from_file("glade/notmuch-gtk.glade");
		Global.builder.connect_signals(null);
	} catch (GLib.Error e) {
		error("Error reading glade file: %s", e.message);
		assert_not_reached();
	}

	var threads = new NotMuch.Threads.Controller();

	threads.begin();
	Gtk.main();
	return 0;
}
