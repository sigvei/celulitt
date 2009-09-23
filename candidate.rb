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

# Represents a single Candidate in an election.
class Candidate
	attr_accessor :party, :number, :quotient, :district, :divisor

	def initialize(attribs={})
		self.party = attribs[:party]
		self.number = attribs[:number]
		self.quotient = attribs[:quotient]
		self.district = attribs[:district]
		self.divisor = attribs[:divisor]
	end

	def <=>(b)
		b.quotient <=> quotient
	end
end

