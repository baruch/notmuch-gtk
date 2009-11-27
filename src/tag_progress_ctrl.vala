namespace NotMuch.TagProgress {
	class Controller : GLib.Object {
		private View view;
		private GLib.List<Gtk.TreePath> selection_list;
		private Gtk.ListStore list;
		private int total;
		private int count;
		string[] add_tags;
		string[] remove_tags;
		private NotMuch.Exec.Executor notmuch;

		public void run(GLib.List<Gtk.TreePath> selection_list, string[] add_tags, string[] remove_tags) {
			debug("Will now show progress to update tags");
			this.selection_list = selection_list.copy();

			this.list = Global.builder.get_object("list_threads") as Gtk.ListStore;
			this.total = (int)this.selection_list.length();
			this.count = 0;
			this.add_tags = add_tags;
			this.remove_tags = remove_tags;

			Idle.add(idle_do_tag_thread);

			this.view = new View();
			this.view.run();
		}

		private void end_tagging() {
			this.view.done();
		}

		private string? get_thread_id() {
			Gtk.TreePath path = selection_list.data;
			selection_list.remove_link(selection_list);
			this.count++;
			this.view.update_progress(this.count, this.total);

			Gtk.TreeIter iter;
			bool success = this.list.get_iter(out iter, path);
			if (!success) {
				debug("Failed to get iterator from path, skipping");
				Idle.add(idle_do_tag_thread);
				return null;
			}

			string val;
			this.list.get(iter, 0, out val, -1);
			debug("thread id %s", val);

			return val;
		}

		private bool idle_do_tag_thread() {
			do_tag_thread();
			return false;
		}

		private void do_tag_thread() {
			if (selection_list == null) {
				debug("List is empty, finishing things");
				end_tagging();
				return;
			}

			var query = new GLib.StringBuilder();
			int i = 0;
			while (i < 50 && selection_list != null) {
				string? thread_id = get_thread_id();
				if (thread_id == null)
					continue;

				if (i > 0)
					query.append(" OR ");
				query.append(thread_id);
				i++;
			}

			this.notmuch = NotMuch.Exec.tag(query.str, this.add_tags, this.remove_tags);
			this.notmuch.process_died.connect(do_tag_thread);
			this.notmuch.exec();
		}
	}
}
