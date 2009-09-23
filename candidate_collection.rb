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


# A collection of candidates.
class CandidateCollection < Array
	def <<(object)
		raise "Not a Candidate object (is a #{object.class})" unless object.is_a?(Candidate)
		super(object)
	end

	def group_by_party
		group_by{|c| c.party}
	end

	def count_by_party
		h = Hash[group_by_party.map{|k,v| [k, v.count]}]
		h.default = 0
		h
	end

	def group_by_district
		group_by{|c| c.district}
	end

	def count_by_district
		h = Hash[group_by_district.map{|k,v| [k, v.count]}]
		h.default = 0
		h
	end
		

	def +(d)
		cc = CandidateCollection.new
		each{|c| cc << c}
	 	d.each{|c| cc << c}	
		cc
	end
end	
