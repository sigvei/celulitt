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


# A District is merely a PartyCollection with a +name+ and +mandates+
# attribute.
class District
	attr_accessor :name, :mandates

	def initialize(name, mandates)
		self.name = name
		self.mandates = mandates
		@parties=PartyCollection.new(self)
	end

	# Returns the number of votes in the District.
	def total_votes
		@parties.total_votes
	end

	# Returns a CandidateCollection of the candidates who have won
	# a mandate
	def winners
		@parties.winners mandates
	end

	# Returns the first +num+ non-winners of an election in this district.
	def nonwinners(num=1)
		@parties.nonwinners mandates, num
	end

	# Returns a PartyCollection
	def parties
		@parties
	end
end
