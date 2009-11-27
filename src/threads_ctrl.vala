namespace NotMuch.Threads {
	class Controller : GLib.Object {
		private View view;
		private GLib.DataInputStream child_stderr_stream;
		private GLib.Cancellable child_stderr_cancel;
		private GLib.DataInputStream child_stdout_stream;
		private GLib.Regex search_re;
		private GLib.List<NotMuch.Thread.Controller> thread_view_list;

		construct {
			this.child_stderr_cancel = new GLib.Cancellable();
			try {
				string search_re_str = """^([^ ]+) \s*(.+) \[([[:digit:]]+)/([[:digit:]]+)\] ([^;]*); (\C*) \((.*)\)\s*$""";
				this.search_re = new Regex(search_re_str, RegexCompileFlags.OPTIMIZE|RegexCompileFlags.RAW, 0);
			} catch (GLib.RegexError e) {
				error("Failed to compile regex: %s", e.message);
			}
		}

		public Controller() {
			this.view = new View();
			this.view.tag_threads.connect(this.do_tag_threads);
			this.view.start_search.connect(this.start_search);
			this.view.thread_view.connect(this.thread_view);
		}

		private bool initial_search() {
			this.start_search("tag:inbox and tag:unread");
			return false;
		}

		public void begin() {
			this.view.show();
			Timeout.add_seconds(0, initial_search);
		}

		private void start_search(string query) {
			this.view.set_query(query);

			int child_stdout;
			int child_stderr;
			GLib.Pid pid;
			bool success = NotMuch.Exec.search(query, out pid, out child_stdout, out child_stderr);
			if (!success)
				return;

			ChildWatch.add(pid, (pid, status) => { debug("search process is done"); });
			this.child_stderr_stream = new DataInputStream(new GLib.UnixInputStream(child_stderr, true));
			this.child_stdout_stream = new DataInputStream(new GLib.UnixInputStream(child_stdout, true));

			this.view.clear_list();

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
					//debug("STDOUT: %s", line);
					MatchInfo match;
					bool success = search_re.match(line, 0, out match);
					if (!success || !match.matches()) {
						debug("Failed to match line: %s", line);
						continue;
					}

					assert(match.get_match_count() == 1 + 7);
					string thread_id = match.fetch(1);
					string relative_date = match.fetch(2);
					string num_msgs = match.fetch(3);
					string total_msgs = match.fetch(4);
					string authors = match.fetch(5);
					string subject = match.fetch(6);
					string tags = match.fetch(7);
					this.view.add_list(thread_id, relative_date, num_msgs.to_int(), total_msgs.to_int(), authors, subject, tags);
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

		private void do_tag_threads() {
			debug("Do tag threads");
			var selected = this.view.get_selected_threads();
			var list = selected.get_selected_rows(null);
			if (list == null) {
				debug("Nothing is selected");
				return;
			}

			debug("Selected some items");

			// Start a controller for tagging
			var tag_ctrl = new NotMuch.Tag.Controller();
			tag_ctrl.run(list);
		}

		private void thread_view(string thread_id) {
			debug("View thread %s", thread_id);
			NotMuch.Thread.Controller thread_view = new NotMuch.Thread.Controller(thread_id);
			thread_view.closed.connect(this.thread_view_closed);
			thread_view_list.append(thread_view);
		}

		private void thread_view_closed(NotMuch.Thread.Controller thread_view) {
			debug("viewed thread got closed");
			thread_view_list.remove(thread_view);
		}
	}
}
