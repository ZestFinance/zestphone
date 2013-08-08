xml.instruct!

xml.Response do
  @files.each do |file|
    xml.Play file
  end
end
