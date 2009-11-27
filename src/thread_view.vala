namespace NotMuch.Thread {
	class View : GLib.Object {
		private Gtk.Window window;
		private Gtk.TextView text;

		public signal void closed();

		public void show_all() {
			this.window = new Gtk.Window(Gtk.WindowType.TOPLEVEL);
			this.window.delete_event.connect(this.window_deleted);
			//this.window.wm_role = "THREAD_MSG";

			this.text = new Gtk.TextView();
			this.text.editable = false;
			this.text.wrap_mode = Gtk.WrapMode.WORD_CHAR;
			this.window.add(this.text);

			this.window.set_default_size(400,400);
			this.window.show_all();
		}

		private bool window_deleted(Gdk.Event event) {
			debug("Msg read window deleted");
			this.window.hide();
			this.closed();
			return true;
		}

		public void get_model(out Gtk.TextBuffer buffer) {
			buffer = this.text.get_buffer();
		}
	}
}
