namespace NotMuch.Thread {
	class View : GLib.Object {
		private Gtk.Window window;
		private Gtk.TextView text;
		private Gtk.TreeView treeview;
		private Gtk.TreeStore treestore;

		public signal void closed();
		public signal void thread_selected(Gtk.TreeIter path);

		private Gtk.Widget create_pane1() {
			this.treestore = new Gtk.TreeStore(3, typeof(string), typeof(string), typeof(string));

			this.treeview = new Gtk.TreeView.with_model(this.treestore);
			this.treeview.insert_column_with_attributes(-1, "From", new Gtk.CellRendererText(), "text", 0, null);
			this.treeview.get_selection().changed.connect(this.selection_changed);
			return this.treeview as Gtk.Widget;
		}

		private Gtk.Widget create_pane2() {
			var scrolled_window = new Gtk.ScrolledWindow(null, null);
			this.text = new Gtk.TextView();
			this.text.editable = false;
			scrolled_window.add(this.text);

			return scrolled_window as Gtk.Widget;
		}

		private Gtk.Window create_window() {
			var w = new Gtk.Window(Gtk.WindowType.TOPLEVEL);
			w.delete_event.connect(this.window_deleted);
			w.wm_role = "THREAD_MSG";

			var hpaned = new Gtk.HPaned();
			hpaned.pack1(this.create_pane1(), false, true);
			hpaned.pack2(this.create_pane2(), true, true);
			w.add(hpaned);
			w.set_default_size(400,400);

			return w;
		}

		public void show_all() {
			this.window = create_window();
			this.window.show_all();
		}

		private bool window_deleted(Gdk.Event event) {
			debug("Msg read window deleted");
			this.window.hide();
			this.closed();
			return true;
		}

		public void get_model(out Gtk.TextBuffer buffer, out Gtk.TreeStore treestore) {
			buffer = this.text.get_buffer();
			treestore = this.treestore;
		}

		private void selection_changed() {
			var selection = this.treeview.get_selection();
			Gtk.TreeModel model;
			Gtk.TreeIter iter;
			bool success = selection.get_selected(out model, out iter);
			if (!success)
				return;

			this.thread_selected(iter);
		}
	}
}
