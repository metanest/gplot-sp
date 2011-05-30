#!/bin/sh
exec ruby19 -x "$0" "$@"
#!ruby
# coding:utf-8
# vi:set ts=3 sw=3:
# vim:set sts=0 noet:

require 'tempfile'

require 'pp'

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
