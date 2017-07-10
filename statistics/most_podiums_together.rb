require_relative "../core/grouped_statistic"

class MostPodiumsTogether < GroupedStatistic
  def initialize
    @title = "Most podiums together"
    @table_header = { "Podiums" => :right, "People" => :left }
  end

  def query
    <<-SQL
      SELECT
        GROUP_CONCAT(
          CONCAT('[', person.name, '](https://www.worldcubeassociation.org/persons/', person.id, ')')
          ORDER BY person.name
        ) people
      FROM Results
      JOIN Persons person ON person.id = personId AND person.subId = 1
      JOIN RoundTypes round_type ON round_type.id = roundTypeId
      WHERE 1
        AND round_type.final = 1
        AND pos <= 3
        AND best > 0
      GROUP BY eventId, competitionId
    SQL
  end

  def transform(query_results)
    podiums = query_results.map { |result| result["people"].split(',') }
    { 2 => "Pairs", 3 => "Triples" }.map do |people_count, header|
      people_with_podiums_together = podiums
        .map { |people| people.combination(people_count).to_a }
        .flatten!(1)
        .reduce(Hash.new(0)) do |hash, people|
          hash[people] += 1
          hash
        end
        .sort_by { |people, podiums_together| -podiums_together }
        .first(100)
        .map! do |people, podiums_together|
          [podiums_together, people.join(" & ")]
        end
      [header, people_with_podiums_together]
    end
  end
end
