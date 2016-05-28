require "redditkit"
require "json"
require_relative "process_line.rb"

link_id = "t3_" + $*[0]
$pseudonyms = JSON.parse(File.read("pseudonyms.json"))
$points = JSON.parse(File.read("points.json"))
$pointsdelta = {}
$results = {}
$skipped = []

# Convert a known pseudonym into a standard key.
def get_key(p)
  $pseudonyms.each_key do |k|
    if $pseudonyms[k].include?(p)
      return k
    end
  end
  return nil
end

# Convert a string into a float value.
def get_float(result)
  if result =~ /(\d+):([\d\.]+)/
    return $~[1].to_f() * 60.0 + $~[2].to_f()
  else
    return result.to_f()
  end
end

# Add a result to the results hash.
def add_result(un, event, result)
  if $results.has_key?(event)
    $results[event] << [un, get_float(result)]
    puts "Result added: #{event}, #{get_float(result)}."
  else
    k = get_key(event)
    if !k.nil?()
      $results[k] << [un, get_float(result)]
      puts "Result added: #{k}, #{get_float(result)}."
    elsif !event.nil?() && event.strip() != ""
      puts "Error: can't identify event: \"#{event}\""
      print "Please enter correct event key, or leave blank to skip.\n> "
      k = $stdin.gets.chomp().downcase()
      if k != ""
        $pseudonyms[k] << event.downcase()
        $results[k] << [un, get_float(result)]
        puts "Result added: #{k}, #{get_float(result)}."
      else
        return false
      end
    else
      return false
    end
  end
  
  return true
end

# Process this comment line-by-line.
def process(un, body)
  body.gsub!(/\*/, "")
  body.gsub!(/&gt;/, "")
  body.gsub!(/,/, " ")
  body.gsub!(/\x20+/, " ")
  body.gsub!(/DNF/i, "1000000000.00")
  
  puts "Processing user \"#{un}\"."
  
  body.each_line do |l|
    extracted = process_line_v2(l)
    
    if !extracted.nil?()
      if !add_result(un, extracted[0], extracted[1])
        $skipped << (un + ": " + l)
      end 
    end
  end
  
  puts
end

# A quicksort implementation for pairs of data, where the second value
# is used as a comparator.
def quicksort(a)
  if a.size() <= 1
    return a
  else
    al = []
    ar = []
    p = a[0]
    
    1.upto(a.size() - 1) do |i|
      if a[i][1] < p[1]
        al << a[i]
      else
        ar << a[i]
      end
    end
    
    al = quicksort(al)
    ar = quicksort(ar)
    al << p
    al.concat(ar)
    
    if a.size() != al.size()
      puts "#{a.size()} #{al.size()}"
    end
    
    return al
  end
end

# Converts a float back into a string format.
def print_number(n)
  mins = 0
  while n >= 60
    mins += 1
    n -= 60
  end
  
  if mins == 0
    return "%.2f" % n
  else
    return "#{mins}:#{"%05.2f" % n}"
  end
end

### main

# Prepare the results hash.
$pseudonyms.keys().each do |k|
  $results[k] = []
end

# Process the comments.
link = RedditKit.link(link_id)
comments = RedditKit.comments(RedditKit.link(link_id))
comments.each do |c|
  process(c[:author], c[:body])
end

print "You skipped the following lines:\n* "
puts $skipped.join("\n* ")
while true
  print "Manually add any additional results, or 'q' to finish. Use the format [username] [event] [result].\n> "
  s = $stdin.gets.chomp().strip()
  if s == "q"
    break
  else
    sp = s.split(" ")
    $results[sp[1].downcase()] << [sp[0], get_float(sp[2])]
  end
end

# Process and sort the results.
$results.each_key do |k|
  $results[k].delete_if { |r| r[1] <= 0.0 }

  $results[k] = quicksort($results[k])
end

# Output the results.
File.open("results.txt", "w") do |f|
  # Output individual event results.
  $results.each_key do |k|
    participants = $results[k].size()
    if participants > 0
      f << "**#{k}:**\n\n"
      
      n = 1
      $results[k].each_index do |i|
        f << "#{n}. /u/#{$results[k][i][0]}: #{print_number($results[k][i][1])}\n\n"
        
        if !$pointsdelta.has_key?($results[k][i][0])
          $pointsdelta[$results[k][i][0]] = 0
        end
        $pointsdelta[$results[k][i][0]] += participants - n + 1
        
        n += 1
      end
      
      f << "\n\n"
    end
  end
  
  # Add the points and sort both hashes.
  pd = []
  p = []
  $pointsdelta.each_key do |k|
    if !$points.has_key?(k)
      $points[k] = $pointsdelta[k]
    else
      $points[k] += $pointsdelta[k]
    end
    
    pd << [k, $pointsdelta[k]]
  end
  $points.each_key do |k|
    p << [k, $points[k]]
  end
  pd = quicksort(pd).reverse()
  p = quicksort(p).reverse()
  
  # Print this week's points.
  f << "**Points from this week (participants - place + 1):**\n\n"
  n = 1
  pd.each do |r|
    f << "#{n}. /u/#{r[0]}: #{r[1]}\n\n"
    n += 1
  end
  
  # Print the overall points.
  f << "\n\n**Total points:**\n\n"
  n = 1
  p.each do |r|
    f << "#{n}. /u/#{r[0]}: #{r[1]}\n\n"
    n += 1
  end
end

File.open("pseudonyms.json", "w") do |f|
  f << JSON.generate($pseudonyms)
end

File.open("points.json", "w") do |f|
  f << JSON.generate($points)
end
