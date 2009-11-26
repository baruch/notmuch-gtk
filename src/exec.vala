namespace NotMuch.Exec {
	private int count_array(string[] array) {
		int count = 0;
		while (array[count] != null)
			count++;
		return count;
	}

	private bool do_exec(string[] argv, out GLib.Pid pid, out int child_stdout, out int child_stderr) {
		try {
			GLib.SpawnFlags flags = GLib.SpawnFlags.DO_NOT_REAP_CHILD;
			bool success = GLib.Process.spawn_async_with_pipes("/", argv, null, flags, null, out pid, null, out child_stdout, out child_stderr);
			if (!success) {
				debug("Failed to run notmuch");
				return false;
			}
		} catch (GLib.SpawnError e) {
			debug("Error spawning notmuch: %s", e.message);
			return false;
		}

		return true;
	}

	public bool search(string query, out GLib.Pid pid, out int child_stdout, out int child_stderr) {
		string[] parts = query.split(" ");
		int count = count_array(parts);
		
		string[] argv = new string[3+count];
		argv[0] = "/usr/local/bin/notmuch";
		argv[1] = "search";
		
		for (int i = 0; i < count; i++) {
			argv[2 + i] = parts[i];
			argv[2 + i + 1] = null;
		}

		return do_exec(argv, out pid, out child_stdout, out child_stderr);
	}

	private void add_array(string[] array, char? prefix, ref string[] argv, ref int argv_idx) {
		if (array == null)
			return;

		for (int i = 0; array[i] != null; i++) {
			string val;
			if (prefix != null)
				val = "%c%s".printf(prefix, array[i]);
			else
				val = array[i];
			argv[argv_idx++] = val;
		}
	}

	public bool tag(string query, string[] add_tags, string[] remove_tags, out GLib.Pid pid) {
		string[] parts = query.split(" ");
		int parts_count = count_array(parts);

		int argv_idx = 0;;
		string[] argv = new string[4 + parts_count + add_tags.length + remove_tags.length];
		argv[argv_idx++] = "/usr/local/bin/notmuch";
		argv[argv_idx++] = "tag";
		add_array(add_tags, '+', ref argv, ref argv_idx);
		add_array(remove_tags, '-', ref argv, ref argv_idx);
		argv[argv_idx++] = "--";
		add_array(parts, null, ref argv, ref argv_idx);
		argv[argv_idx++] = null;

		int child_stdout;
		int child_stderr;
		bool result = do_exec(argv, out pid, out child_stdout, out child_stderr);
		Posix.close(child_stdout);
		Posix.close(child_stderr);
		return result;
	}
}
