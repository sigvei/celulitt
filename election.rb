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


# Election acts as a collection of Districts, but also as a special wrapper
# to distribute utjevningsmandater. 
class Election
	attr_accessor :districts
	SPERREGRENSE=0.04
	UTJMND=1

	def initialize
		self.districts = []
		@total = District.new("Landet", 0)
	end

	# Adds a new district to the election. The +hsh+ should have a
	# +name+, +mandates+ and +parties+ field. +mandates+ is the number
	# of mandates /including/ utjevningsmandater.
	def add_district(hsh)
		d = District.new(hsh[:name], hsh[:mandates]-UTJMND)
		hsh[:parties].each do |party, votes|
			# Add votes for each party both to the district and to our "total"
			# meta-district.
			[d.parties, @total.parties].each {|obj| obj.add_to_vote party, votes}
		end
		self.districts << d

		# Also add the district's mandates to our "total"-meta-district
		@total.mandates += d.mandates
	end

	# Returns the total number of votes in the election
	def total_votes
		@total.total_votes
	end

	# Returns the total number of votes in the election per party. This returns
	# a Hash.
	def total_votes_per_party
		@total.parties
	end

	# This method should only be called after all districts are added.
	# It calculates district winners and adds utjevningsmandater to districts.
	# Returns a CandidateCollection of winners.
	def winners
		district_winners + utjevningsmandater
	end

	# Returns the +num+ candidates who were closest to win mandates in each district
	def nonwinners(num=1)
		CandidateCollection.new districts.map{|dist| dist.nonwinners(num)}.flatten
	end

	# Returns a CandidateCollection with the district mandate winners
	def district_winners
		districts.map do |dist| 
			dist.winners
		end.inject(CandidateCollection.new) do |coll,item| 
			coll = coll + item
		end	
	end

	# Returns a CandidateCollection of utjevningsmandater. Grunnloven § 59
	# regulates how the mandates are distributed among parties, while
	# Valgloven describes how the mandates are distributed among districts.
	def utjevningsmandater
		# sieve out parties < 4.0 percent
		total = total_votes
		eligible = total_votes_per_party.select{|p,vot| (vot.to_f/total >= SPERREGRENSE)}
		
		# "ideal_winners" is the correct national distribution of mandates among the
		# eligible parties, ie. parties above SPERREGRENSE
		ideal_winners = winners_election(eligible, 169).count_by_party
		dst_mandates = district_winners.count_by_party 

		# sieve out parties with enough mandates
		eligible2 = Hash[eligible.select do |party,votes|
			ideal_winners[party] > dst_mandates[party]
		end]

		# do the final distribution of utjevningsmandates

		# Number of mandates to distribute is equal to 
		# remaining mandates to share by national tally
		remaining_mnd = districts.count*UTJMND + dst_mandates.inject(0) do |sum,item| 
			if eligible2.keys.include?(item[0])
				sum += item[1]
			else
				sum
			end
		end	

		# The final winners; by party. Remove parties with 0 won mandates.
		winners = Hash[
			winners_election(eligible2, remaining_mnd).count_by_party.map do |party, mandates|
				[party, mandates - dst_mandates[party]]
			end.select{|w| w[1] > 0}
		]

		# Generate quotients for each party and each district
		quotients = CandidateCollection.new(
			districts.map do |district|
				dp = district.parties
				dw = district.winners.count_by_party

				winners.map do |party, num|
					dwp = dw[party]
					quotient = dp[party].to_f / (dwp + 1)
					Candidate.new(:party => party, :number => dwp, 
												:district => district,
												:quotient => quotient,
											  :divisor => "U")
				end
			end.flatten.sort {|a,b| b.quotient <=> a.quotient}
		)

		won_mandates = CandidateCollection.new
		while(winners.inject(0){|sum, item| sum += item[1]} > 0) do
			winner = quotients.shift
			won_mandates << winner
			winners[winner.party] -= 1
			
			if (winners[winner.party] == 0)
				quotients.delete_if{|q| q.party == winner.party}
			end

			quotients.delete_if{|q| q.district == winner.district}
		end
		won_mandates
		
	end

	private

	# This creates a single district with the eligible parties and elects the
	# chosen number of mandates. Returns a CandidateCollection
	def winners_election(eligible, mandates)
		dist = District.new("temporary", mandates)
		eligible.each{|party,votes| dist.parties.add_to_vote(party, votes)}
		dist.winners
	end
end

