require "json"
require_relative "process_line.rb"

$pseudonyms = JSON.parse(File.read("pseudonyms.json"))

# Convert a known pseudonym into a standard key.
def get_key(p)
  $pseudonyms.each_key do |k|
    if $pseudonyms[k].include?(p)
      return k
    end
  end
  return nil
end

strs = [
  ["3x3: 40.03 = (1000000000.00) 38.88 47.00 34.27 (29.11)", "3x3", "40.03"],
  ["2X2: 5.44 // 4.89, 6.27, (4.82), 5.14, (6.42)", "2x2", "5.44"],
  ["3x3: 19.05 = (15.13), (21.87), 19.73, 20.31, 17.07", "3x3", "19.05"],
  ["LSE: (5.512), (10.365), 8.425, 6.895, 7.036 = 7.452", "lse", "7.452"],
  ["2x2, 3x3, 4x4 Relay: 1:57.23", "234relay", "1:57.23"],
  ["3x3 16.45 15.54, (20.02), 17.35, (14.12), 16.45", "3x3", "16.45"],
  ["4x4 1:13.99 1:07.76, (1:06.00), 1:16.90, (1:23.80), 1:17.31", "4x4", "1:13.99"],
  ["2x2, 3x3, 4x4 Relay: 2:20.23", "234relay", "2:20.23"],
  ["2x2, 3x3, 4x4 Relay: = 1:35.24 Absolutely awful. Had an ugly pause on the 3x3, and screwed up the cross on the 4x4. ", "234relay", "1:35.24"],
  ["3x3 FMC: 45 // Solution, insertions in brackets.", "fmc", "45"],
  ["2x2, 3x3, 4x4 Relay: 1.29.37", "234relay", "1:29.37"],
  ["Reddit pb's: OH single and average.", nil, nil],
  ["Quite dissapointed in such inconsistent times...", nil, nil],
  ["Pyraminx: // (27.23), 26.69, 18.98, 26.08, (16.93) Needs better pyraminx then crap shengshou", nil, nil],
  ["4x4: 1:05.12 = (1000000000.00(52.15)) 1:04.20 (55.48) 1:08.23 1:02.92", "4x4", "1:05.12"],
  ["LSE: 5.33 = (4.49) (1000000000.00(5.80)) 5.08 6.07 4.82", "lse", "5.33"],
  ["3x3: (39.53) 33.53 34.16 (32.04) 39.52 = 35.74", "3x3", "35.74"],
  ["3x3OH: 1:20.747 = 2:06.309 1:31.812 1:20.996 (1000000000.00(1:26.771)) (1:20.747)", "3x3oh", "1:20.747"],
  ["2GEN: 22.280 = 19.146 (13.801) 28.452 (1000000000.00(38.150)) 19.241 // .........Terrible.........", "2gen", "22.280"],
  ["3x3: 17.06 16.45 15.55 (1000000000.00) (19.15) = 17.55", "3x3", "17.55"],
  ["4x4: (1:14.93) 1:11.12 1:06.56 (59.97) 1:00.90 = 1:06.19", "4x4", "1:06.19"],
  ["Pyra: (17.81) (8.91) 13.55 14.98 14.22 = 14.25", "pyraminx", "14.25"],
  ["3x3: 17.58 17.12+ 15.04 (18.08) (13.85) = 16.58", "3x3", "16.58"]
]

puts
strs.each do |line, t_event, t_result|
  extracted = process_line_v2(line)
  event = get_key(extracted[0])
  result = extracted[1]
  
  if !(event == t_event && result == t_result)
    puts
    puts "Test failed! (#{extracted[2]})"
    puts line
    puts "event: \"#{event}\", result: \"#{result}\""
  else
    puts "Test passed!"
  end
  puts
end
