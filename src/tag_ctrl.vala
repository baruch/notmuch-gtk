namespace NotMuch.Tag {
	class Controller : GLib.Object {
		private View view;
		private GLib.List<Gtk.TreePath> selection_list;

		public void start(GLib.List<Gtk.TreePath> selection_list) {
			debug("Starting the path to tagging selected messages");
			this.view = new View();
			this.view.show_all();
		}
	}
}
