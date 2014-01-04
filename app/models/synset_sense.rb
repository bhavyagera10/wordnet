class SynsetSense < ActiveRecord::Base

  belongs_to :synset
  belongs_to :sense

  include Importable
  include Exportable

  def self.uuid_mappings
    {
      :synset_id => { model: Synset, attribute: :external_id },
      :sense_id => { model: Sense, attribute: :external_id }
    }
  end

  def self.unique_attributes
    [:synset_id, :sense_id]
  end

  def self.wordnet_count(connection)
    connection[:unitandsynset].max(:LEX_ID)
  end

  def self.wordnet_load(connection, offset, limit)
    raw = connection[:unitandsynset].select(:LEX_ID, :SYN_ID).order(:LEX_ID).
      where('LEX_ID >= ? AND LEX_ID < ?', offset, offset + limit).to_a

    raw.map do |membership|
      {
        sense_id: membership[:LEX_ID],
        synset_id: membership[:SYN_ID]
      }
    end
  end

  def self.export_index(connection)
    nil
  end

  def self.export_query
    "MATCH (a:Sense { id: {sense_id} }), " +
          "(b:Synset { id: {synset_id} }) " +
    "MERGE (a)-[r:belongs_to]->(b)"
  end

  def self.export_properties(entity)
    { synset_id: entity.synset_id, sense_id: entity.sense_id }
  end
end
