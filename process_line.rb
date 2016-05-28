# Count the number of characters that are numbers.
def count_digits(s)
  total = 0
  s.each_char do |c|
    if c =~ /\d/
      total += 1
    end
  end
  return total
end

# Try to extract a result from a line.
def process_line(l)
  if l =~ /(.*?):([\d\s\.\(\):,]+)(=|-|\/\/|\\\\)([\d\s\.\(\):,]+)/
    event = $~[1].strip().downcase()
    result = $~[2]
    if $~[4].strip().size() < $~[2].strip().size()
      result = $~[4]
    end
    result.strip!()
    
    return [event, result]
  elsif l =~ /(.*?)[:=]([\d\s\.:]+)/
    event = $~[1].strip().downcase()
    result = $~[2].strip()
  
    return [event, result]
  elsif count_digits(l) > l.size() / 2 || count_digits(l) > 10
    puts "Possible poor formatting detected:"
    puts l
    print "Please enter this result by hand, or 'q' to skip. Use the format [event] [result].\n> "
    k = $stdin.gets.chomp().downcase().strip()
    if k != "q"
      sp = k.split(" ")
      return [sp[0], sp[1]]
    else
      return nil
    end
  else
    return nil
  end
end

def process_line_v2(l)
  num_regex = /\(?(1000000000\.00\(\d*\:?\d+\.\d+\)|\d*\.?\d+\.\d+|\d*:?\d+\.\d+)\+?\)?/
  front_regex = /^NNN\s*(=|\|\||\/\/|\\\\|-)?\s*(NNN[,;]\s*)+NNN\.?$/
  front_regex_2 = /^NNN\s*(=|\|\||\/\/|\\\\|-)(\s*NNN\s*)+\.?$/
  front_regex_3 = /^(\s*NNN\s*)+\.?$/
  back_regex = /^(NNN[,;]?\s*)+NNN\s*(=|\|\||\/\/|\\\\|-)?\s*NNN\.?$/
  back_grab_regex = /(\d*\.?\d+\.\d+|\d*:?\d+\.\d+)$/
  p_to_c_regex = /^(\d+)\.(\d+)\.(\d+)$/
  
  event = nil
  result = nil
  c = 0
  
  # Replace recognized times with a token string to make the format
  # detection much easier.
  tl = l.gsub(num_regex, "NNN")
  
  # This should only return false for FMC, or if the formatting is beyond
  # hideous.
  if tl.include?("NNN")
    # The event should be everything preceding the first time. This will
    # be cleaned up at the end of the code.
    event = tl.split("NNN")[0]
    
    # Crop the event out of the string.
    cl = l[event.size()..-1]
    tcl = tl[event.size()..-1]
    
    # Remove comments from the back of the string.
    while tcl[-3..-1] != "NNN" && tcl.size() > 0
      cl = cl[0..-2]
      tcl = tcl[0..-2]
    end
    
    # Compare to known patterns.
    if tcl == "NNN"
      result = cl
      c = 1
    elsif tcl =~ front_regex || tcl =~ front_regex_2 || tcl =~ front_regex_3
      result = cl[num_regex]
      c = 2
    elsif tcl =~ back_regex && cl =~ back_grab_regex
      result = $~[1]
      c = 3
    end
    
    # If the time uses a period instead of a colon, fix it.
    if result =~ p_to_c_regex
      result = "#{$~[1]}:#{$~[2]}.#{$~[3]}"
    end
    
    # Clean up the event.
    event = event.gsub(/[:=]/, "").strip().downcase()
  end
  
  if count_digits(l) >= 2 && (event.nil?() || result.nil?() || event.size() == 0 || result.size() == 0)
    puts
    puts "\"#{l.strip()}\""
    print "  This line appears to have poor formatting. Please enter the time manually, or leave blank to skip.\n> "
    k = $stdin.gets.chomp().downcase().strip()
    if k != ""
      sp = k.split(" ")
      event = sp[0]
      result = sp[1]
    end
  end
  
  return [event, result, c]
end
