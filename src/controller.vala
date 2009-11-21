namespace NotMuch {
	class Controller : GLib.Object {
		private weak View view;
		private GLib.DataInputStream child_stderr_stream;
		private GLib.Cancellable child_stderr_cancel;
		private GLib.DataInputStream child_stdout_stream;

		construct {
			this.child_stderr_cancel = new GLib.Cancellable();
		}

		public void set_view(View view) {
			this.view = view;
		}

		public void start_search(string query) {
			this.view.set_query(query);

			string[] argv = new string[4];
			argv[0] = "/usr/local/bin/notmuch";
			argv[1] = "search";
			argv[2] = query;
			argv[3] = null;

			int child_stdout;
			int child_stderr;
			try {
				bool success = GLib.Process.spawn_async_with_pipes("/", argv, null, 0, null, null, null, out child_stdout, out child_stderr);
				if (!success) {
					debug("Failed to run notmuch");
					return;
				}
			} catch (GLib.SpawnError e) {
				debug("Error spawning notmuch: %s", e.message);
				return;
			}

			this.child_stderr_stream = new DataInputStream(new GLib.UnixInputStream(child_stderr, true));
			this.child_stdout_stream = new DataInputStream(new GLib.UnixInputStream(child_stdout, true));

			handle_stderr.begin();
			handle_stdout.begin();
		}

		private async void handle_stderr() {
			while (true) {
				if (this.child_stdout_stream == null)
					return;

				try {
					size_t len;
					string line = yield this.child_stderr_stream.read_line_async(0, this.child_stderr_cancel, out len);
					if (line == null)
						continue;

					debug("STDERR: %s", line);
				} catch (GLib.Error e) {
					debug("Error reading stderr: %s", e.message);
					break;
				}

				try {
					this.child_stderr_stream.close(null);
				} catch (GLib.Error e1) {
					debug("Error closing stderr: %s", e1.message);
				}
				this.child_stderr_stream = null;
			}
		}

		private async void handle_stdout() {
			while (true) {
				try {
					size_t len;
					string line = yield this.child_stdout_stream.read_line_async(0, null, out len);
					if (line == null)
						break;
					debug("STDOUT: %s", line);
				} catch (GLib.Error e) {
					debug("Error reading stdout: %s", e.message);
					break;
				}
			}

			this.child_stderr_cancel.cancel();
			try {
				this.child_stdout_stream.close(null);
			} catch (GLib.Error e1) {
				debug("Error closing stdout: %s", e1.message);
			}
			this.child_stdout_stream = null;
		}
	}
}
