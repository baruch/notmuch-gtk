namespace NotMuch.TagProgress {
	class View : GLib.Object {
		private Gtk.Dialog dialog;
		private Gtk.ProgressBar progress;

		public void run() {
			this.dialog = Global.builder.get_object("dialog_progress") as Gtk.Dialog;
			this.progress = Global.builder.get_object("progressbar") as Gtk.ProgressBar;

			this.progress.fraction = 0.0;
			
			this.dialog.run();
			this.dialog.hide();
		}

		public void done() {
			this.dialog.response(Gtk.ResponseType.CLOSE);
		}

		public void update_progress(int count, int total) {
			this.progress.fraction = (float)count/(float)total;
			this.progress.text = "%d/%d".printf(count, total);
		}
	}
}
