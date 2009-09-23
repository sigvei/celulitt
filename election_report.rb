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


# This class circumscribes the different Ruport reports used in celulitt.
class ElectionReport
	def initialize(election)
		@election = election
		collect_data
	end

	def to_html
		output(:to_html)
	end

	def to_text
		output(:to_text)
	end

	private

	def collect_data
		@reports = [ mandater, fylker, partier_fylker, 
						partier_fylker_prosenter,
						winners_and_nonwinners
		]
	end

	def output(command)
		@reports.map{|r| r.send(command)}.join
	end

	def mandater
		dst = @election.district_winners.count_by_party
		utj = @election.utjevningsmandater.count_by_party
		tot = @election.winners.count_by_party

		parties = dst.keys | utj.keys | tot.keys
		data = parties.map{|p| [p, (dst[p] || 0), (utj[p] || 0), (tot[p] || 0)]}
		names = ["Parti", "Distriktsmandater", "Utjevningsmandater", "Mandater"]
		create_group data, names, "Mandatfordeling", "Mandater", names[1,3]
	end

	def fylker
		tot = @election.winners.count_by_district.map{|dist,mnd| [(dist ? dist.name : "Ingen"), mnd]}
		create_group tot, ["Fylke", "Mandater"], "Fylker", "Mandater", "Mandater"
	end

	def partier_fylker
		parties = @election.winners.count_by_party.keys.sort{|a,b| a.to_s <=> b.to_s}
		names = ["Fylke"] + parties + ["Sum"]
		data = @election.winners.group_by_district.map do |district, candidates|
			c = CandidateCollection.new(candidates).count_by_party

			[district.name] + parties.map{|x| c[x]} + [c.inject(0){|sum,item| sum += item[1]}]
		end

		create_group data, names, "Fylkesfordeling", "Sum", parties
	end

	def partier_fylker_prosenter
		parties = @election.winners.count_by_party.keys.sort{|a,b| a.to_s <=> b.to_s}
		names = ["Fylke"] + parties + ["Andre"]
		data = @election.districts.map do |district|
			tot = district.total_votes
			andresum = district.parties.inject(0){|sum,item| sum += (parties.include?(item[0]) ? 0 : item[1])}
			
			[district.name] + parties.map{|x| "%0.1f" % ((district.parties[x].to_f/tot)*100)} +
				["%0.1f" % ((andresum.to_f/tot)*100)]
		end

		create_group data, names, "Stemmeandel per fylke", "Fylke"
	end

	def winners_and_nonwinners
		w = @election.winners.sort.map{|c| [true, c.divisor=="U", c.party, c.district.name, c.number, c.quotient, c.divisor]}
		w += @election.nonwinners.map{|c| [false, false, c.party, c.district.name, c.number, c.quotient, c.divisor]}
		tbl = Ruport::Data::Table :data => w, :column_names => %w[Valgt Utjevning Parti Fylke Nr Kvotient Divisor]
		groups = Ruport::Data::Grouping.new tbl, :by => "Fylke"

		groups.each do |fylke,t|
			t.add_column("Stemmer opp")
			i = 0
			t.each do |r|
				# do unless this is utjevning
				unless r["Utjevning"] == true					
					prev = t[0,i].reverse.detect{|x| x["Utjevning"] == false && x["Valgt"] == true}
					unless prev.nil?
						prevq = prev["Kvotient"]
						thisq = r["Kvotient"]
						thisd = r["Divisor"]
						r["Stemmer opp"] = ((prevq-thisq)*thisd).ceil
					end
				end
				i += 1
			end
		end
		groups.each do |fylke,t|
			t.each do |r|
				r["Kvotient"] = "%0.1f" % r["Kvotient"]
			end
		end

		groups
	end

	def people
		# Beregn antall stemmer opp til neste plass på listen
		data.each_index do |i|
			unless i == 0 || data[i][5] == nil
				thisq = data[i][4]
				thisd = data[i][5]
				prevq = data[i-1][4]

				data[i][6] = ((prevq-thisq) / thisd).ceil
			end
		end	

		# Formater kvotienten med to desimaler
		data.each{|d| d[4] = "%0.2f" % d[4]}

		create_group data, ["Valgt?", "Parti", "Fylke", "Nr.", "Kvotient", "Divisor", "Stemmer opp"], "Valgte representanter"
	end

	def create_group(data, columns, name, sort_by = nil, sum_by=nil)
		grp = Ruport::Data::Group.new(:data => data, :column_names => columns, 
																	:name => name)
		if sort_by
			grp.sort_rows_by!(sort_by, :order => :descending)
		end

		if sum_by
			grp << columns.map do |x|
				if (sum_by.is_a?(Array) && sum_by.include?(x)) || sum_by == x
					grp.sigma(x)
				else
					""
				end
			end
		end
		grp
	end
end
