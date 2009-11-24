public static int main(string[] args)
{
	Gtk.init(ref args);

	var builder = new Gtk.Builder();
	try {
		builder.add_from_file("glade/notmuch-gtk.glade");
		builder.connect_signals(null);
	} catch (GLib.Error e) {
		error("Error reading glade file: %s", e.message);
		assert_not_reached();
	}

	var threads = new NotMuch.Threads.Controller(builder);

	threads.begin();
	Gtk.main();
	return 0;
}
