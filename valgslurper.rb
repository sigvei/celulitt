#!/usr/bin/ruby
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
require "hpricot"
require "open-uri"
require "iconv"
KCODE="u"

# Doc is an Hpricot instance
def get_name(doc)
	doc.search("meta[@name='WT.ti']").first.attributes["content"].to_s
end

def get_mandates(doc)
	(doc/"tr.total"/"td")[-2].inner_html.to_i
end

def get_parties(doc)
	parties={}
	(doc/"table[@CELLPADDING='2']").first.search("tr").each do |party|
		if (party/"td.tbtl").count > 0
			name = (party/"td.tbtl").first.inner_html
			votes = (party/"td.tbtr").first.inner_html.to_i
			parties[name.to_sym] = votes
		end
	end
	parties
end

class Array
	def map_to_hash
		map {|e| yield e}.inject({}) {|carry, e| carry.merge! e}
	end
end


ELECTION = "valg2009"

# Norwegian counties are numbered [1,20] - 13
ids = (1..12).to_a + (14..20).to_a

districts = ids.map_to_hash do |id|
  url = "http://www.regjeringen.no/krd/html/#{ELECTION}/bs4_#{id}.html"
	doc = Hpricot(Iconv.conv("utf-8", "iso-8859-1", open(url).read))
	name = get_name(doc)
	STDERR << "Parsing #{id}: #{name}"
	{id => {:name => name, :mandates => get_mandates(doc), 
			:parties => get_parties(doc)}}
end

STDOUT << districts.to_yaml

