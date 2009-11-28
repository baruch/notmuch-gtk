namespace NotMuch.Background {
	class Manager : GLib.Object {
		private Gee.LinkedList<NotMuch.Exec.Executor> ops;

		construct {
			this.ops = new Gee.LinkedList<NotMuch.Exec.Executor>();
		}

		private void background_op_finished(NotMuch.Exec.Executor e) {
			ops.remove(e);
		}

		public bool tag(string query, string[] add_tags, string[] remove_tags) {
			var e = NotMuch.Exec.tag(query, add_tags, remove_tags);
			e.process_died.connect(this.background_op_finished);
			ops.add(e);
			return e.exec();
		}

		public bool remove_tag(string query, string tag) {
			string[] remove_tags = new string[1];
			remove_tags[0] = "unread";
			string[] add_tags = null;
			return this.tag(query, add_tags, remove_tags);
		}
	}
}
