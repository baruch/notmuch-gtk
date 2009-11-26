namespace NotMuch.Tag {
	class Controller : GLib.Object {
		private View view;

		public void run(GLib.List<Gtk.TreePath> selection_list) {
			debug("Starting the path to tagging selected messages");
			this.view = new View();

			string add_tags_str;
			string remove_tags_str;
			bool ok = this.view.run(out add_tags_str, out remove_tags_str);
			if (!ok) {
				debug("Dialog was canceled, not tagging anything");
				return;
			}

			debug("Dialog was okayed, verifying fields");
			debug("add: %s", add_tags_str);
			debug("remove: %s", remove_tags_str);

			string[] add_tags = add_tags_str.split(" ");
			string[] remove_tags = remove_tags_str.split(" ");
			
			var tag_progress = new NotMuch.TagProgress.Controller();
			tag_progress.run(selection_list, add_tags, remove_tags);
		}
	}
}
