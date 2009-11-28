namespace NotMuch.Thread {
	class Controller : GLib.Object {
		private string thread_id;
		private View view;
		private Gtk.TextBuffer model_text;
		private Gtk.TreeStore model_tree;
		private NotMuch.Exec.Executor notmuch;

		private enum ParseState {
			START,
			INTERIM,
			MESSAGE,
			HEADER,
			BODY,
			PART
		}
		private ParseState parse_state;
		private string parse_from;
		private string parse_header;
		private string parse_body;
		private StringBuilder parse_builder;
		private int parse_depth;
		private GLib.List<Gtk.TreeIter?> parse_thread;

		public signal void closed(Controller thread_view);

		public Controller(string thread_id) {
			// Start the process to get the messages of the thread
			this.start_msg_read(thread_id);

			// Initiate the window
			this.thread_id = thread_id;
			this.view = new View();
			this.view.closed.connect(this.view_closed);
			this.view.show_all();

			this.view.get_model(out this.model_text, out this.model_tree);
			this.view.thread_selected.connect(this.thread_selected);
		}

		private void start_msg_read(string thread_id) {
			debug("Starting to load thread %s", thread_id);
			this.parse_state = ParseState.START;
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

		private void thread_selected(Gtk.TreeIter iter) {
			string header;
			string body;
			this.model_tree.get(iter, 1, out header, 2, out body, -1);
			this.model_text.set_text(header + "\n" + body, -1);
		}

		private int extract_depth(string line) {
			int depth = 0;

			string[] parts = line.split(" ");
			for (int i = 0; i < parts.length; i++) {
				if (parts[i].has_prefix("depth:")) {
					depth = parts[i].substring((int)"depth:".size()).to_int();
					debug("Depth found %d", depth);
					break;
				}
			}

			return depth;
		}

		private void handle_code(string line) {
			if (line.has_prefix("\fmessage{")) {
				assert(this.parse_state == ParseState.START || this.parse_state == ParseState.INTERIM);
				this.parse_state = ParseState.MESSAGE;
				if (this.parse_builder == null)
					this.parse_builder = new StringBuilder();
				else
					this.parse_builder.truncate(0);
				this.parse_from = "Unknown";
				this.parse_header = null;
				this.parse_body = null;

				this.parse_depth = extract_depth(line);
			} else if (line.has_prefix("\fmessage}")) {
				assert(this.parse_state == ParseState.MESSAGE);
				this.parse_state = ParseState.INTERIM;
				Gtk.TreeIter? iter = null;
				if (this.parse_depth > 0) {
					debug("Parse depth is %d", this.parse_depth);
					unowned GLib.List<Gtk.TreeIter?> cur = this.parse_thread.nth(this.parse_depth);
					if (cur != null) {
						debug("nth element found");
						iter = cur.data;
						while (cur.next != null)
							cur.remove_link(cur.next);
					} else {
						debug("nth element not found");
					}
				}
				this.add_message(iter, this.parse_from, this.parse_header, this.parse_body);
			} else if (line.has_prefix("\fheader{")) {
				assert(this.parse_state == ParseState.MESSAGE);
				this.parse_state = ParseState.HEADER;
			} else if (line.has_prefix("\fheader}")) {
				assert(this.parse_state == ParseState.HEADER);
				this.parse_state = ParseState.MESSAGE;
				this.parse_header = this.parse_builder.str.dup();
				this.parse_builder.truncate(0);
			} else if (line.has_prefix("\fbody{")) {
				assert(this.parse_state == ParseState.MESSAGE);
				this.parse_state = ParseState.BODY;
			} else if (line.has_prefix("\fbody}")) {
				assert(this.parse_state == ParseState.BODY);
				this.parse_state = ParseState.MESSAGE;
				this.parse_body = this.parse_builder.str.dup();
				this.parse_builder.truncate(0);
			} else if (line.has_prefix("\fpart{")) {
				assert(this.parse_state == ParseState.BODY);
				this.parse_state = ParseState.PART;
			} else if (line.has_prefix("\fpart}")) {
				assert(this.parse_state == ParseState.PART);
				this.parse_state = ParseState.BODY;
			} else {
				debug("Unknown code: %s", line);
			}
		}

		private void handle_body(string line) {
			switch (this.parse_state) {
				case ParseState.MESSAGE:
				case ParseState.START:
				case ParseState.INTERIM:
					error("Shouldn't have content in this state");
					break;

				case ParseState.HEADER:
					if (line.has_prefix("From: ")) {
						this.parse_from = line.substring((long)"From: ".size());
					}
					this.parse_builder.append(line);
					this.parse_builder.append("\n");
					break;

				case ParseState.BODY:
				case ParseState.PART:
					this.parse_builder.append(line);
					this.parse_builder.append("\n");
					break;
			}
		}

		private void handle_stdout(string line) {
			if (line.has_prefix("\f")) {
				this.handle_code(line);
			} else {
				string code = line.rchr(-1, '\f');
				if (code == null)
					this.handle_body(line);
				else {
					string[] parts = line.split("\f", 2);
					this.handle_body(parts[0]);
					this.handle_code("\f" + parts[1]);
				}
			}
		}

		private void add_message(Gtk.TreeIter? parent, string from, string header, string message) {
			Gtk.TreeIter iter;
			this.model_tree.insert_with_values(out iter, parent, -1, 0, from, 1, header, 2, message, -1);
			this.parse_thread.append(iter);
		}
	}
}
