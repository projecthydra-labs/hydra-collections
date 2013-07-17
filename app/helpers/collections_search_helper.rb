# View Helper methods for Hydra Collections in search results
module CollectionsSearchHelper

  # @param [String] collection_pid the pid of a collection
  # @return [String] the title of the collection if available, otherwise its pid
  def collection_name(collection_pid)
    Collection.load_instance_from_solr(collection_pid).title || collection_pid
  end

end
