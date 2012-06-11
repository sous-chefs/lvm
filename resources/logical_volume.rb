actions :create

def initialize *args
    super
    @action = :create
end

must_be_greater_than_0 = {
   'must be greater than 0' => Proc.new { |value| value > 0 }
}

attribute :name, :kind_of => String, :name_attribute => true, :required => true
attribute :group, :kind_of => String
attribute :size, :kind_of => String, :regex => /\d+[kKmMgGtT]|(\d{2}|100)%(FREE|VG)|\d+ extents/, :required => true
attribute :filesystem, :kind_of => String
attribute :mount_point, :kind_of => Hash, :callbacks => {
    ': location is required!' => Proc.new do |value| 
        value['location'] && !value['location'].empty?
    end,
    ': location must be an absolute path!' => Proc.new do |value| 
        matches = value['location'] =~ %r{^/[^\0]*} 
        !matches.nil?
    end 
}
attribute :mount_options, :kind_of => String
attribute :physical_volumes, :kind_of => [String, Array]
attribute :stripes, :kind_of => Integer, :callbacks => must_be_greater_than_0
attribute :stripe_size, :kind_of => Integer, :callbacks => {
    'must be a power of 2 from 2^2 to 2^9' => Proc.new do |value| 
        2..9.each do |pwr| 
            return true if 2**pwr == value
        end
    end
}
attribute :mirrors, :kind_of => Integer, :callbacks => must_be_greater_than_0
attribute :contiguous, :kind_of => [TrueClass, FalseClass]
attribute :readahead, :kind_of => [ Integer, String ], :equal_to => [ 2..120, 'auto', 'none' ].flatten!
