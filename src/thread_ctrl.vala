namespace NotMuch.Thread {
	class Controller : GLib.Object {
		private string thread_id;
		private View view;
		private Gtk.TextBuffer model_text;
		private NotMuch.Exec.Executor notmuch;

		public signal void closed(Controller thread_view);

		public Controller(string thread_id) {
			// Start the process to get the messages of the thread
			this.start_msg_read(thread_id);

			// Initiate the window
			this.thread_id = thread_id;
			this.view = new View();
			this.view.closed.connect(this.view_closed);
			this.view.show_all();

			this.view.get_model(out this.model_text);
		}

		private void start_msg_read(string thread_id) {
			debug("Starting to load thread %s", thread_id);
			this.notmuch = NotMuch.Exec.thread_read(thread_id);
			this.notmuch.stdout_line_read.connect(this.handle_stdout);
			bool success = this.notmuch.exec();
			if (!success) {
				debug("Error starting a message read for %s", thread_id);
				return;
			}
		}

		private void view_closed() {
			debug("View got closed");
			this.closed(this);
		}

		private void handle_stdout(string line) {
			Gtk.TextIter end_iter;
			this.model_text.get_end_iter(out end_iter);
			this.model_text.insert(end_iter, line + "\n", (int)line.size() + 1);
		}
	}
}
