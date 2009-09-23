#!/usr/bin/ruby
#  == Synopsis
#
#  valg: Beregner utfallet av et norsk stortingsvalg. Systemet beregner
#  mandater per parti og fylker/valgdistrikter.
#
#  == Bruk
#  
#  valg.rb [ALTERNATIVER] [DATAFIL]
#
#  -u, --utfil <fil>::
#  	Bestem hvilken fil rapporten skal lagres i. Filetternavnet bestemmer
#  	hvilken type rapport som genereres: enten PDF, tekst eller HTML. Dersom
#  	filnavnet ikke slutter på .pdf eller .html genereres en rapport i ren
#  	tekst.
#
#  -h, --hjelp::
#  	Vis denne hjelpeteksten
#
#  DATAFIL::
#  	En datafil i Yaml-format. Filen skal ha inneholde ett objekt, en Hash
#  	med ett objekt per valgdistrikt. Hvert valgdistrikt er representert
#  	av en Hash med tre nøkler: mandates, som angir antall mandater
#  	distriktet har til fordeling (inkl. utjevningsmandater); name,
#  	distrikets navn og parties, en Hash med partiforkortelser som nøkler
#  	og antall stemmer som verdier.


# This file is part of Celulitt.
#
# Copyright 2009 Sigve Indregard.
#
# Celulitt is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# Celulitt is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with Celulitt.  If not, see <http://www.gnu.org/licenses/>.
require "rubygems"
require "ruby-debug"
require "ruport"
require "getoptlong"
require "rdoc/usage"

require "election.rb"
require "district.rb"
require "candidate.rb"
require "candidate_collection.rb"
require "party_collection.rb"
require "election_report.rb"

opt=GetoptLong.new(
	['--utfil', '-u', GetoptLong::REQUIRED_ARGUMENT],
	['--hjelp', '-h', GetoptLong::NO_ARGUMENT]
)

infile = nil
outfile = STDOUT
outtype = "text"
opt.each do |opt, arg|
	case opt
	when '--hjelp'
		RDoc::usage
	when '--utfil'
		outfile=File.open(arg, "w")
		pat = /\.(\w*)$/
		match = pat.match arg
		if match
			case match[1]
			when "html"
				outtype="html"
			when "txt"
				outtype="text"
			when "pdf"
				outtype="pdf"
			end
		end
	end
end

unless ARGV.length == 1
	RDoc::usage
	exit(0)
end

infile = ARGV.shift

unless File.exists?(infile) && File.file?(infile)
	STDERR.puts "File '#{infile}' not found"
	exit(1)
end

STDERR.puts "Laster datafil #{infile}..."
data = YAML::load(File.open(infile, "r").read)
STDERR.puts "#{data.length} distrikter er lastet"

election = Election.new
data.each {|d| election.add_district(d[1])}

report = ElectionReport.new(election).send("to_#{outtype}")
outfile << report
outfile.close unless outfile == STDOUT
