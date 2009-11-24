namespace NotMuch.Tag {
	class Controller : GLib.Object {
		private View view;
		private GLib.List<Gtk.TreePath> selection_list;

		public void run(GLib.List<Gtk.TreePath> selection_list) {
			debug("Starting the path to tagging selected messages");
			this.view = new View();

			string add_tags;
			string remove_tags;
			bool ok = this.view.run(out add_tags, out remove_tags);
			if (!ok) {
				debug("Dialog was canceled, not tagging anything");
				return;
			}

			debug("Dialog was okayed, verifying fields");
			debug("add: %s", add_tags);
			debug("remove: %s", remove_tags);
		}
	}
}
