using Gtk;

namespace NotMuch.Threads {

	class View : GLib.Object {
		private Gtk.Window main;
		private Gtk.Entry search;
		private Gtk.TreeView treeview;
		private Gtk.ListStore list;

		public signal void tag_threads();
		public signal void thread_view(string thread_id);
		public signal void start_search(string query);

		private CellRendererText cell_ellipsize() {
			var cell = new CellRendererText();
			cell.ellipsize = Pango.EllipsizeMode.END;
			cell.ellipsize_set = true;
			cell.width_chars = 20;
			return cell;
		}

		private CellRendererText cell_msgs() {
			var cell = new CellRendererText();
			cell.xalign = (float)0.5;
			return cell;
		}

		private void list_view_col(TreeView view, string title, int col, CellRendererText? cell = null) {
			var lcell = cell;
			if (lcell == null)
				lcell = new CellRendererText();
			view.insert_column_with_attributes(-1, title, lcell, "text", col, null);
		}

		public View() {
			this.main = Global.builder.get_object("main_window") as Window;
			this.search = Global.builder.get_object("text_search") as Entry;
			this.list = Global.builder.get_object("list_threads") as ListStore;
			this.treeview = Global.builder.get_object("threads_view") as TreeView;

			// Handle the user clicking on the search button
			var search_button = Global.builder.get_object("button_search") as Button;
			search_button.clicked.connect(this.on_search);

			// Handle the case that the user just presses enter in the entry box
			this.search.activate.connect(this.on_search);

			var list_view = Global.builder.get_object("threads_view") as TreeView;
			list_view_col(list_view, "Date", 1);
			list_view_col(list_view, "Messages", 3, cell_msgs());
			list_view_col(list_view, "Authors", 4, cell_ellipsize());
			list_view_col(list_view, "Subject", 5, cell_ellipsize());
			list_view_col(list_view, "Tags", 6, cell_ellipsize());

			for (int i = 2; i < 5; i++) {
				var col = list_view.get_column(i);
				if (i == 3) // Expand the subject
					col.expand = true;
				col.resizable = true;
			}

			// Mark tree selection to allow multiple selections
			get_selected_threads().set_mode(Gtk.SelectionMode.MULTIPLE);

			// Attach signals to actions
			var action_tag = Global.builder.get_object("action_tag") as Action;
			assert(action_tag != null);
			action_tag.activate.connect(this.on_tag);

			var action_view = Global.builder.get_object("action_view") as Action;
			assert(action_view != null);
			action_view.activate.connect(this.on_view);

			// Handle the user double clicking on a row to view message
			this.treeview.row_activated.connect(this.row_activated);
		}

		public void show() {
			main.show_all();
		}

		private void view_path(Gtk.TreePath path) {
			// Get Iterator from path
			TreeIter iter;
			bool found = this.list.get_iter(out iter, path);
			if (!found) {
				debug("Couldn't find an iterator for a path we just received, strange!");
				return;
			}

			// Get thread id from iterator
			string thread_id;
			this.list.get(iter, 0, out thread_id, -1);

			// Tell anyone who is interested of this request
			this.thread_view(thread_id);
		}

		public void on_view() {
			// Get path of current cursor in the view
			Gtk.TreePath path;
			this.treeview.get_cursor(out path, null);
			this.view_path(path);
		}

		private void row_activated(Gtk.TreePath path, Gtk.TreeViewColumn column) {
			this.view_path(path);
		}

		public void on_tag() {
			this.tag_threads();
		}

		public void on_search() {
			string query = search.get_text();
			this.start_search(query);
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

		public Gtk.TreeSelection get_selected_threads() {
			return this.treeview.get_selection();
		}
	}
}
