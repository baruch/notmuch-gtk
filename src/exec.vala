namespace NotMuch.Exec {
	class ProcessReader : GLib.Object {
		private DataInputStream stream;
		private string name;
		private bool log_stdout;

		public signal void line_read(string line);

		public ProcessReader(int fd, string name) {
			this.log_stdout = true;
			this.name = name;
			this.stream = new DataInputStream(new GLib.UnixInputStream(fd, true));
		}

		public void start() {
			this.read_stream.begin();
		}

		public void set_log_stdout(bool log_stdout) {
			this.log_stdout = log_stdout;
		}

		private async void read_stream() {
			while (this.stream != null) {
				try {
					size_t len;
					string line = yield this.stream.read_line_async(0, null, out len);
					if (line == null) {
						debug("Stream for %s returned null", this.name);
						break;
					}

					if (this.log_stdout)
						debug("Reader %s: %s", this.name, line);
					this.line_read(line);
				} catch (GLib.Error e) {
					debug("Error reading %s: %s", this.name, e.message);
					break;
				}
			}

			debug("Stream for %s closing", this.name);
			try {
				this.stream.close(null);
			} catch (GLib.Error e1) {
				debug("Error closing %s: %s", this.name, e1.message);
			}
			this.stream = null;
		}
	}

	public class Executor : GLib.Object {
		private ProcessReader child_stdout_reader;
		private ProcessReader child_stderr_reader;
		private string[] argv;
		private bool log_stdout;
		private bool log_stderr;

		public signal void process_died(Executor self);
		public signal void stdout_line_read(string line);
		public signal void stderr_line_read(string line);

		public Executor(string[] argv, bool log_stdout, bool log_stderr = true) {
			this.argv = argv;
			this.log_stdout = log_stdout;
			this.log_stderr = log_stderr;
		}

		public bool exec() {
			int child_stdout;
			int child_stderr;
			GLib.Pid pid;

			for (int i = 0; i < this.argv.length; i++) {
				debug("argv %d: %s", i, this.argv[i]);
			}

			try {
				GLib.SpawnFlags flags = GLib.SpawnFlags.DO_NOT_REAP_CHILD;
				bool success = GLib.Process.spawn_async_with_pipes("/", this.argv, null, flags, null, out pid, null, out child_stdout, out child_stderr);
				if (!success) {
					debug("Failed to run notmuch");
					return false;
				}
			} catch (GLib.SpawnError e) {
				debug("Error spawning notmuch: %s", e.message);
				return false;
			}

			this.child_stdout_reader = new ProcessReader(child_stdout, "stdout");
			this.child_stdout_reader.set_log_stdout(this.log_stdout);
			this.child_stdout_reader.line_read.connect((line)=>{this.stdout_line_read(line);});
			this.child_stdout_reader.start();

			this.child_stderr_reader = new ProcessReader(child_stderr, "stderr");
			this.child_stderr_reader.set_log_stdout(this.log_stderr);
			this.child_stderr_reader.line_read.connect((line)=>{this.stderr_line_read(line);});
			this.child_stderr_reader.start();

			ChildWatch.add(pid, this.handle_process_died);

			return true;
		}

		private void handle_process_died(GLib.Pid pid, int status) {
			debug("Process died with status %d", status);
			GLib.Process.close_pid(pid);
			this.process_died(this);
		}
	}

	public Executor search(string query) {
		string[] parts = query.split(" ");
		int count = parts.length;
		
		string[] argv = new string[3+count];
		argv[0] = "/usr/local/bin/notmuch";
		argv[1] = "search";
		
		for (int i = 0; i < count; i++) {
			argv[2 + i] = parts[i];
			argv[2 + i + 1] = null;
		}

		return new Executor(argv, false, true);
	}

	private void add_array(string[] array, char? prefix, ref string[] argv, ref int argv_idx) {
		if (array == null)
			return;

		for (int i = 0; i < array.length; i++) {
			string val;
			if (prefix != null)
				val = "%c%s".printf(prefix, array[i]);
			else
				val = array[i];
			argv[argv_idx++] = val;
		}
	}

	public Executor tag(string query, string[] add_tags, string[] remove_tags) {
		string[] parts = query.split(" ");
		int parts_count = parts.length;

		int argv_idx = 0;;
		string[] argv = new string[4 + parts_count + add_tags.length + remove_tags.length];
		argv[argv_idx++] = "/usr/local/bin/notmuch";
		argv[argv_idx++] = "tag";
		add_array(add_tags, '+', ref argv, ref argv_idx);
		add_array(remove_tags, '-', ref argv, ref argv_idx);
		argv[argv_idx++] = "--";
		add_array(parts, null, ref argv, ref argv_idx);
		argv[argv_idx++] = null;

		return new Executor(argv, true, true);
	}

	public Executor thread_read(string query) {
		string[] argv = new string[4];
		argv[0] = "/usr/local/bin/notmuch";
		argv[1] = "show";
		argv[2] = query;
		argv[3] = null;

		return new Executor(argv, false, true);
	}
}
