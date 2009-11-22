using Gtk;

namespace NotMuch {

	class View : GLib.Object {
		private Gtk.Builder builder;
		private Gtk.Window main;
		private Gtk.Entry search;
		private Gtk.ListStore list;
		private weak Controller ctrl;

		private void list_view_col(TreeView view, string title, int col) {
			view.insert_column_with_attributes(-1, title, new CellRendererText(), "text", col, null);
		}
		construct {
			this.builder = new Builder();
			try {
				this.builder.add_from_file("glade/notmuch-gtk.glade");
				this.builder.connect_signals(null);
			} catch (GLib.Error e) {
				error("Error reading glade file: %s", e.message);
				assert_not_reached();
			}

			this.main = this.builder.get_object("main_window") as Window;
			this.search = this.builder.get_object("text_search") as Entry;
			this.list = this.builder.get_object("list_threads") as ListStore;

			var search_button = this.builder.get_object("button_search") as Button;
			search_button.clicked.connect(this.on_search);

			var list_view = this.builder.get_object("threads_view") as TreeView;
			list_view_col(list_view, "Date", 1);
			list_view_col(list_view, "Messages", 3);
			list_view_col(list_view, "Authors", 4);
			list_view_col(list_view, "Subject", 5);
			list_view_col(list_view, "Tags", 6);
		}

		public View(Controller ctrl) {
			this.ctrl = ctrl;
		}

		public void show() {
			main.show_all();
		}

		public void on_search() {
			string query = search.get_text();
			ctrl.start_search(query);
		}

		public void set_query(string query) {
			this.search.set_text(query);
		}

		public void clear_list() {
			this.list.clear();
		}

		public void add_list(string thread_id, string relative_date, int num_msgs, int total_msgs, string authors, string subject, string tags) {
			TreeIter iter;
			this.list.append(out iter);
			this.list.set(iter, 0, thread_id, 1, relative_date, 2, num_msgs, 3, total_msgs, 4, authors, 5, subject, 6, tags, -1);
		}
	}
}
