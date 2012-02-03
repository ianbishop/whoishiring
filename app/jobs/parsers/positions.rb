class Positions
 def initialize
   @positions_list = [
     "Engineer",
     "Designer",
     "Marketing",
     "Support",
     "Systems Analyst",
     "System Administrator",
     "Developer"]
 end 

 def match(document)
   positions = []
   document = document.gsub("-", " ")
   @positions_list.each do |position|
     if document.downcase.include? position.downcase
       positions << position
     end
   end
   return positions
 end
end
