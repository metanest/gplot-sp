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
	primary = nil
	indices = {}
	labels = []
	data = {}

	open(filename){|file|
		lbl = nil
		file.each_line{|line|
			line.chomp!

			if /\AIndex/.match(line) then
				lbl = (line.split)[1 .. -1]

				primary = lbl[0]

				lbl.each{|s|
					unless labels.include? s then
						labels << s
					end
				}
			end

			if m = /\A\d+/.match(line) then
				idx = m[0]
				indices[idx.to_i] = true
				(line.split)[1 .. -1].each_with_index{|datum, i|
					data[idx + lbl[i]] = datum
				}
			end
		}
	}

	return indices.keys.sort, labels, data
end

def plot_data indices, labels, data
	Tempfile.open("plotdata"){|tmpfile|
		begin
			indices.each{|i|
				tmpfile.puts(labels.map{|s|data[i.to_s + s]}.join(" "))
			}
			tmpfile.close false
			cmds = []
			cmds << "set xzeroaxis"
			cmds << "set yzeroaxis"
			cmds << "set xlabel \"#{labels[0]}\""
			plots = []
			labels[1 .. -1].each_with_index{|label, i|
				plots << "\"#{tmpfile.path}\" using 1:#{2+i} ti \"#{label}\" with lines"
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

indices, labels, data = read_data ARGV[0]
plot_data indices, labels, data
