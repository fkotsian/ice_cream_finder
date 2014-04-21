api_key = nil
begin
  api_key = File.read('./secret.rb').chomp
rescue
  puts "Unable to read './secret.rb'. Please provide a valid Google API key."
  exit
end
