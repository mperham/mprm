#
# arr-pm is unmaintained
#
class RPM::File::Tag
  def initialize(tag_id, type, offset, count, data)
    @tag = tag_id
    @type = type
    @offset = offset
    @count = count

    @data = data
    @value = nil

    @inspectables = [:@tag, :@type, :@offset, :@count, :@value]
  end
end

class RPM::File
  def initialize(file)
    if file.is_a?(String)
      file = File.new(file, "r")
    end
    @file = file
    @lead = @header = @signature = @tags = @files = @payload = nil
  end
end
