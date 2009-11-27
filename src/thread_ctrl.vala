namespace NotMuch.Thread {
	class Controller : GLib.Object {
		private string thread_id;
		private View view;
		private Gtk.TextBuffer model_text;
		private GLib.DataInputStream child_stdout_stream;

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
			int child_stdout;
			bool success = NotMuch.Exec.thread_read(thread_id, out child_stdout);
			if (!success) {
				debug("Error starting a message read for %s", thread_id);
				return;
			}

			this.child_stdout_stream = new DataInputStream(new GLib.UnixInputStream(child_stdout, true));
			handle_stdout.begin();
		}

		private void view_closed() {
			debug("View got closed");
			this.closed(this);
		}

		private async void handle_stdout() {
			while (true) {
				try {
					size_t len;
					string line = yield this.child_stdout_stream.read_line_async(0, null, out len);
					if (line == null)
						break;
					debug("STDOUT: %s", line);
					Gtk.TextIter end_iter;
					this.model_text.get_end_iter(out end_iter);
					this.model_text.insert(end_iter, line + "\n", (int)line.size() + 1);
				} catch (GLib.Error e) {
					debug("Error reading stdout: %s", e.message);
					break;
				}
			}

			try {
				debug("Closing stdout stream");
				this.child_stdout_stream.close(null);
			} catch (GLib.Error e1) {
				debug("Error closing stdout: %s", e1.message);
			}
			this.child_stdout_stream = null;
		}
	}
}
