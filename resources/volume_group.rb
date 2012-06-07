include Chef::Mixin::RecipeDefinitionDSLCore

def initialize *args
    super
    @logical_volumes = []
    @action = :create
end

actions :create
attr_reader :logical_volumes

attribute :name, :kind_of => String, :regex => /\w+/, :required => true, :name_attribute => true
attribute :physical_volumes, :kind_of => [ Array, String ], :required => true
attribute :physical_extent_size, :kind_of => String, :regex => /\d+[bBsSkKmMgGtTpPeE]?/

def logical_volume name, &block
    volume = super(:logical_volume, name, &block)
    volume.action = :nothing
    @logical_volumes << volume
    volume
end
