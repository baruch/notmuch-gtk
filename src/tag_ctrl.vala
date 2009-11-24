namespace NotMuch.Tag {
	class Controller : GLib.Object {
		//private NotMuch.View.Tag view;
		private GLib.List<Gtk.TreePath> selection_list;

		public void start(GLib.List<Gtk.TreePath> selection_list) {
			debug("Starting the path to tagging selected messages");
		}
	}
}
