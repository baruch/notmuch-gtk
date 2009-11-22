using Gtk;

namespace NotMuch {

	class View : GLib.Object {
		private Gtk.Builder builder;
		private Gtk.Window main;
		private Gtk.Entry search;
		private Gtk.ListStore list;
		private weak Controller ctrl;

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
		}
	}
}
