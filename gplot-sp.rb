#!/bin/sh
exec ruby19 -x "$0" "$@"
#!ruby
# coding:utf-8
# vi:set ts=3 sw=3:
# vim:set sts=0 noet:
=begin
Copyright (c) 2011 KISHIMOTO, Makoto

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
'Software'), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED 'AS IS', WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
=end

require 'tempfile'

if ARGV.size != 1 then
	STDERR.puts "usage: plot.rb <filename>"
	exit
end

def read_data filename
	index = nil
	data = []

	open(filename){|file|
		file.each_line{|line|
			line.chomp!

			unless index then
				if /\AIndex/.match(line) then
					index = (line.split)[1 .. -1]
				end
			end

			if /\A\d/.match(line) then
				data << (line.split)[1 .. -1]
			end
		}
	}

	return index, data
end

def plot_data index, data
	Tempfile.open("plotdata"){|tmpfile|
		begin
			data.each{|datum|
				s = datum.map(&:to_s).join(" ")
				tmpfile.puts s
			}
			tmpfile.close false
			cmds = []
			cmds << "set xzeroaxis"
			cmds << "set yzeroaxis"
			cmds << "set xlabel \"#{index[0]}\""
			plots = []
			index[1 .. -1].each_with_index{|title, i|
				plots << "\"#{tmpfile.path}\" using 1:#{2+i} ti \"#{title}\" with lines"
			}
			cmds << "plot " + plots.join(" , ")
			cmds << "pause -1"
			s = cmds.join " ; "
			system "gnuplot -e '#{s}'"
		ensure
			tmpfile.delete
		end
	}
end

index, data = read_data ARGV[0]
plot_data index, data
