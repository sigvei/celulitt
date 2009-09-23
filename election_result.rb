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

class ElectionReport
	def initialize(election)
		@election = election
		collect_data
	end

	def to_html
	  @data.to_html if @data
	end

	def to_text
		@data.to_text if @data
	end

	def to_pdf
		@data.to_pdf if @data
	end

	private

	def collect_data
		@data = Ruport::Data::Grouping.new
		@data << overall_party_distribution
	end

	def overall_party_distribution
		winners = election.winners_by_party.to_a
		tbl=Ruport::Data::Group.new(
			:name => "Partienes mandater totalt",
			:data => winners,
			:column_names => ["Parti", "Mandater"]
		).sort_rows_by("Mandater", :order => :descending)

		tbl << ["Sum", tbl.sigma("Mandater")]
	end
end
