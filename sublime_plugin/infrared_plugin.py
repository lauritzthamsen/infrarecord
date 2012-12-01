import sublime, sublime_plugin
import httplib

IRHost = "localhost"
IRPort = 4567
IRRoute = "/"
IRTimeout = 2


def eval_ruby_line(a_string):
	conn = httplib.HTTPConnection(IRHost, IRPort, timeout=IRTimeout)
	conn.request("GET", IRRoute + a_string)
	r1 = conn.getresponse()
	return r1.read()

class EvalRubyCommand(sublime_plugin.TextCommand):
	def run(self, edit):
		line = self.view.substr(
			self.view.line(self.view.sel()[0]))
		self.view.insert(edit, 0, 
			eval_ruby_line(line))


class InfrarecordListener(sublime_plugin.EventListener):
	def on_selection_modified(self, view):
		pass
