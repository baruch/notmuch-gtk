namespace NotMuch.Tag {
	class View : GLib.Object {
		private Gtk.Dialog dialog;

		private string get_entry_text(string name) {
			var entry = Global.builder.get_object(name) as Gtk.Entry;
			return entry.get_text();
		}

		public bool run(out string add_tags, out string remove_tags) {
			this.dialog = Global.builder.get_object("dialog_tag") as Gtk.Dialog;
			var cancel = Global.builder.get_object("button_cancel") as Gtk.Button;
			var ok = Global.builder.get_object("button_ok") as Gtk.Button;
			cancel.clicked.connect((src)=>{ this.dialog.response(Gtk.ResponseType.CANCEL); });
			ok.clicked.connect((src)=>{ this.dialog.response(Gtk.ResponseType.OK); });

			int response = this.dialog.run();
			debug("Got response: %d", response);

			this.dialog.hide();

			add_tags = get_entry_text("entry_tag_add");
			remove_tags = get_entry_text("entry_tag_remove");
			return response == Gtk.ResponseType.OK;
		}
	}
}
