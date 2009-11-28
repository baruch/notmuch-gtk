namespace NotMuch.Threads {
	class Controller : GLib.Object {
		private View view;
		private GLib.Regex search_re;
		private GLib.List<NotMuch.Thread.Controller> thread_view_list;
		private NotMuch.Exec.Executor notmuch;
		private NotMuch.Background.Manager bg_ops;

		construct {
			try {
				string search_re_str = """^([^ ]+) \s*(.+) \[([[:digit:]]+)/([[:digit:]]+)\] ([^;]*); (\C*) \((.*)\)\s*$""";
				this.search_re = new Regex(search_re_str, RegexCompileFlags.OPTIMIZE|RegexCompileFlags.RAW, 0);
			} catch (GLib.RegexError e) {
				error("Failed to compile regex: %s", e.message);
			}

			this.bg_ops = new NotMuch.Background.Manager();
		}

		public Controller() {
			this.view = new View();
			this.view.tag_threads.connect(this.do_tag_threads);
			this.view.start_search.connect(this.start_search);
			this.view.thread_view.connect(this.thread_view);
		}

		private bool initial_search() {
			this.start_search("tag:inbox");
			return false;
		}

		public void begin() {
			this.view.show();
			Timeout.add_seconds(0, initial_search);
		}

		private void start_search(string query) {
			this.view.set_query(query);

			this.notmuch = NotMuch.Exec.search(query);
			this.notmuch.stdout_line_read.connect(this.handle_stdout);
			bool success = this.notmuch.exec();
			if (!success)
				return;

			this.view.clear_list();
		}

		private void handle_stdout(string line) {
			MatchInfo match;
			bool success = search_re.match(line, 0, out match);
			if (!success || !match.matches()) {
				debug("Failed to match line: %s", line);
				return;
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

			this.bg_ops.remove_tag(thread_id, "unread");
		}

		private void thread_view_closed(NotMuch.Thread.Controller thread_view) {
			debug("viewed thread got closed");
			thread_view_list.remove(thread_view);
		}
	}
}
