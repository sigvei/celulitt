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


# A party collection is a set of parties with vote numbers. It is typically
# used as the data structure of an election district.
class PartyCollection < Hash
	# +district+ must be an instance of District.
	def initialize(district)
		@candidates = nil
		@candidate_mandates=nil
		@district=district
		super(0)
	end
				
	# Adds a new party to the structure with name +name+ (normally a symbol)
	# and +votes+ number of votes.
	def add(name, votes)
		@candidates = nil
		@candidate_mandates = nil

		store(name.to_sym, votes)
	end

	alias :<< :add

	# Adds +votes+ votes to party +name+, or creates party +name+ with +votes+
	# votes.
	def add_to_vote(name, votes)
		now = fetch(name, 0)
		add(name, votes + now)
	end
	
	# Returns the total number of votes for the collection.
	def total_votes
		inject(0){|sum,item| sum += fetch(item[0], 0)}
	end

	# Returns the first +mandates+ candidates sorted by quotient.
	def winners(mandates)
		candidates(mandates+1)[0, mandates]
	end

	# The first +num+ non-winners in an election with +mandates+ number
	# of mandates, given the votes at hand in the collection.
	# This sorts NOT by quotient, but by number of extra votes required
	# to beat the last winner.
	def nonwinners(mandates, num)
		all = candidates(mandates+1)
		lastq = all[mandates-1].quotient
		rest = all[mandates,999999].sort do |a,b|
		 ((lastq-a.quotient) * a.divisor) <=> ((lastq-b.quotient) * b.divisor) 
		end
		rest[0, num]
	end
				
	# Returns the full collection of candidates -- +mandates+ candidates per
	# party. The collection is sorted descending on quotient. The return
	# value is a CandidateCollection.
	def candidates(mandates)
		# These divisors are the modified St. Laguë method.
		divisors = [1.4] + (2..(mandates-2)).map{|div| (div*2)-1}

		# Memoize this collection
		if @candidate_mandates != mandates
			@candidates = CandidateCollection.new
			@candidate_mandates = mandates
			map do |party,votes|
				i = 0
				divisors.map do |divisor|
					@candidates << Candidate.new(:party => party, 
																			 :number => (i += 1), 
																			 :quotient => votes.to_f/divisor,
																			 :district => @district,
																			 :divisor => divisor)
				end
			end
		end

		@candidates.sort
	end
end
